package io.morde.app

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.net.URI
import java.time.Instant
import java.util.UUID
import java.util.concurrent.TimeUnit

internal class MordeHttpException(val status: Int, message: String) : Exception(message)

internal class MordeClient(context: Context) {
    private val preferences = context.getSharedPreferences("morde.config", Context.MODE_PRIVATE)
    private val secrets = EncryptedSharedPreferences.create(
        context, "morde.credentials", MasterKey.Builder(context).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build(),
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )
    private val http = OkHttpClient.Builder().callTimeout(30, TimeUnit.SECONDS).build()
    var server: String
        get() = preferences.getString("server", "") ?: ""
        set(value) {
            val uri = URI(value.trim())
            require(uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo == null &&
                (uri.path.isNullOrEmpty() || uri.path == "/") && uri.query == null && uri.fragment == null) { "Use an HTTPS Morde address" }
            val normalized = uri.toString().trimEnd('/')
            if (normalized != server) {
                clear()
                forgetInstallation()
                check(preferences.edit().putString("server", normalized).commit()) { "Server address storage failed" }
            }
        }

    fun rememberedInstallation(name: String): String? =
        secrets.getString("installation_id", null)
            ?.takeIf { secrets.getString("installation_account", null) == name }

    fun forgetInstallation() {
        check(secrets.edit().remove("installation_id").remove("installation_account").commit()) {
            "Installation identity storage failed"
        }
    }
    val token: String?
        get() {
            val value = secrets.getString("token", null)
            return value.takeIf { hasUsableCredential(it, clientExpiresAt, Instant.now()) }
        }

    val clientExpiresAt: Instant?
        get() = secrets.getString("client_expires_at", null)?.let { runCatching { Instant.parse(it) }.getOrNull() }

    fun clear() { check(secrets.edit().remove("token").remove("client_expires_at").commit()) { "Secure storage failed" } }
    fun clearExpiredAuthorization(): Boolean {
        val value = secrets.getString("token", null) ?: return false
        if (hasUsableCredential(value, clientExpiresAt, Instant.now())) return false
        clear()
        return true
    }
    fun saveAuthorization(value: String, expiresAt: String, installationId: String, accountName: String) {
        require(value.isNotBlank() && installationId.isNotBlank() && accountName.isNotBlank())
        require(Instant.parse(expiresAt).isAfter(Instant.now())) { "Client credential has expired" }
        check(secrets.edit().putString("token", value).putString("client_expires_at", expiresAt)
            .putString("installation_id", installationId).putString("installation_account", accountName).commit()) {
            "Secure storage failed"
        }
    }

    suspend fun request(path: String, method: String = "GET", body: JSONObject? = null,
                        key: String? = null, authorized: Boolean = true): JSONObject = withContext(Dispatchers.IO) {
        val origin = URI(server)
        require(origin.scheme == "https" && origin.host != null)
        val url = origin.resolve(path)
        require(url.scheme == "https" && url.host == origin.host && url.port == origin.port) { "Invalid Morde API address" }
        val builder = Request.Builder().url(url.toString()).header("X-Request-Id", UUID.randomUUID().toString())
            .header("Cache-Control", "no-store")
        if (authorized) {
            clearExpiredAuthorization()
            val credential = token ?: throw MordeHttpException(401, "Login expired. Sign in again.")
            builder.header("Authorization", "Bearer $credential")
        }
        if (key != null) builder.header("Idempotency-Key", key)
        val requestBody = if (method == "GET") null else
            (body?.toString() ?: "").toRequestBody("application/json".toMediaType())
        builder.method(method, requestBody)
        http.newCall(builder.build()).execute().use { response ->
            if (response.code == 401) clear()
            val raw = response.body?.string().orEmpty()
            if (!response.isSuccessful) {
                val message = runCatching { JSONObject(raw).optJSONObject("error")?.optString("message") }.getOrNull()
                throw MordeHttpException(response.code, message?.takeIf { it.isNotBlank() } ?: "Request failed (${response.code})")
            }
            if (raw.isBlank()) JSONObject() else JSONObject(raw)
        }
    }

    suspend fun page(path: String): List<JSONObject> {
        val items: JSONArray = request(path).getJSONArray("items")
        return (0 until items.length()).map { items.getJSONObject(it) }
    }

    fun streamRequest(taskId: String, after: String = ""): Request {
        val credential = token
            ?: throw MordeHttpException(401, "Login expired. Sign in again.")
        val url = URI(server).resolve("/api/tasks/${encode(taskId)}/events" +
            if (after.isBlank()) "" else "?after=${encode(after)}")
        return Request.Builder().url(url.toString()).header("Authorization", "Bearer $credential")
            .header("Cache-Control", "no-store").build()
    }

    fun eventSourceClient(): OkHttpClient = http.newBuilder()
        .callTimeout(0, TimeUnit.SECONDS).readTimeout(0, TimeUnit.SECONDS).build()
    companion object {
        fun encode(value: String): String = java.net.URLEncoder.encode(value, "UTF-8")
        fun json(vararg values: Pair<String, Any>): JSONObject = JSONObject().apply { values.forEach { (key, value) -> put(key, value) } }
    }
}
