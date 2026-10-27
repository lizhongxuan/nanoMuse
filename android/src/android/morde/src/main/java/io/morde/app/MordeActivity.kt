package io.morde.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import okhttp3.Response
import okhttp3.sse.EventSource
import okhttp3.sse.EventSourceListener
import okhttp3.sse.EventSources
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

class MordeActivity : ComponentActivity() {
    private lateinit var api: MordeClient
    private var serverText by mutableStateOf("")
    private var loginName by mutableStateOf("")
    private var loginPassword by mutableStateOf("")
    private var loginKey: String? = null
    private var loginFingerprint = ""
    private var signedIn by mutableStateOf(false)
    private var busy by mutableStateOf(false)
    private var error by mutableStateOf("")
    private var tab by mutableIntStateOf(0)
    private var hosts by mutableStateOf<List<JSONObject>>(emptyList())
    private var shared by mutableStateOf<List<JSONObject>>(emptyList())
    private var workspaces by mutableStateOf<List<JSONObject>>(emptyList())
    private var models by mutableStateOf<List<JSONObject>>(emptyList())
    private var conversations by mutableStateOf<List<JSONObject>>(emptyList())
    private var messages by mutableStateOf<List<JSONObject>>(emptyList())
    private var tasks by mutableStateOf<List<JSONObject>>(emptyList())
    private var notifications by mutableStateOf<List<JSONObject>>(emptyList())
    private var selectedConversation by mutableStateOf("")
    private var selectedTask by mutableStateOf<JSONObject?>(null)
    private var selectedHost by mutableStateOf("")
    private var selectedModel by mutableStateOf("")
    private var draft by mutableStateOf("")
    private var answer by mutableStateOf("")
    private var retrySend: Pair<String, String>? = null
    private var retryAction: Pair<String, String>? = null
    private var authorizationJob: Job? = null
    private val taskEventRefreshMutex = Mutex()
    private var eventSource: EventSource? = null
    private var eventCursor = ""
    private var streamTaskId = ""
    private var streamGeneration = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        api = MordeClient(this)
        val expired = api.clearExpiredAuthorization()
        serverText = api.server
        signedIn = api.token != null
        if (expired) error = "Login expired. Sign in again."
        setContent { MaterialTheme { Content() } }
    }

    override fun onStart() {
        super.onStart()
        expireAuthorizationIfNeeded()
        if (signedIn) lifecycleScope.launch { load() }
        if (streamTaskId.isNotBlank()) startStream(streamTaskId)
        authorizationJob = lifecycleScope.launch {
            while (isActive && signedIn) {
                val expiresAt = api.clientExpiresAt
                val untilExpiry = expiresAt?.toEpochMilli()?.minus(Instant.now().toEpochMilli()) ?: 0L
                if (untilExpiry <= 0L) {
                    expireAuthorizationIfNeeded()
                    break
                }
                delay(minOf(untilExpiry.coerceAtLeast(1L), 30_000L))
                expireAuthorizationIfNeeded()
            }
        }
    }

    override fun onStop() {
        authorizationJob?.cancel()
        authorizationJob = null
        stopStream()
        super.onStop()
    }

    private fun expireAuthorizationIfNeeded() {
        if (signedIn && api.clearExpiredAuthorization()) {
            signedIn = false
            reset()
            error = "Login expired. Sign in again."
        }
    }

    private fun fail(reason: Throwable) {
        error = reason.message ?: "Request failed"
        if (reason is MordeHttpException && reason.status == 401) {
            signedIn = false; reset()
        }
    }

    private fun reset() {
        stopStream(); streamTaskId = ""; eventCursor = ""
        hosts = emptyList(); shared = emptyList(); workspaces = emptyList(); models = emptyList()
        conversations = emptyList(); messages = emptyList(); tasks = emptyList(); notifications = emptyList()
        selectedConversation = ""; selectedTask = null; selectedHost = ""; selectedModel = ""
        draft = ""; answer = ""; retrySend = null; retryAction = null
    }

    private fun beginLogin() {
        if (busy) return
        val name = loginName.trim()
        val password = loginPassword
        if (name.isEmpty() || password.isEmpty()) return
        val fingerprint = loginAttemptFingerprint(serverText.trim(), name, password)
        if (loginFingerprint != fingerprint) {
            loginFingerprint = fingerprint
            loginKey = UUID.randomUUID().toString()
        }
        val key = loginKey!!
        loginPassword = ""
        busy = true
        lifecycleScope.launch {
            try {
                api.server = serverText
                reset()
                val body = MordeClient.json(
                    "name" to name, "password" to password,
                    "platform" to "android", "display_name" to android.os.Build.MODEL)
                api.rememberedInstallation(name)?.let { body.put("renewal_installation_id", it) }
                val reply = api.request("/api/auth/client-login", "POST", body, key = key, authorized = false)
                api.saveAuthorization(reply.getString("client_credential"), reply.getString("client_expires_at"),
                    reply.getString("installation_id"), name)
                loginKey = null; loginFingerprint = ""
                signedIn = true
                error = ""
                load()
            } catch (reason: Throwable) {
                if (reason is MordeHttpException && reason.status in 400..499) {
                    loginKey = null; loginFingerprint = ""
                }
                fail(reason)
            } finally { busy = false }
        }
    }

    private fun signOut() {
        if (busy) return
        busy = true
        lifecycleScope.launch {
            var remoteFailed = false
            try { api.request("/api/auth/client-logout", "POST") }
            catch (_: Throwable) { remoteFailed = true }
            try {
                api.clear()
                api.forgetInstallation()
                signedIn = false
                reset()
                error = if (remoteFailed) "Signed out locally. Revoke this installation in Portal when online." else ""
            } catch (reason: Throwable) { fail(reason) }
            finally { busy = false }
        }
    }

    private suspend fun load() {
        if (!signedIn) return
        try {
            api.request("/api/me")
            hosts = api.page("/api/hosts")
            shared = api.page("/api/shared-hosts")
            workspaces = api.page("/api/workspaces")
            models = api.page("/api/available-models").filter {
                val caps = it.optJSONObject("capabilities")
                caps?.optBoolean("text") == true && caps.optBoolean("tools")
            }
            conversations = api.page("/api/conversations?limit=100")
            tasks = api.page("/api/tasks?limit=100")
            notifications = api.page("/api/notifications?limit=100")
            if (selectedHost.isBlank()) selectedHost = hosts.firstOrNull { it.optString("state") == "running" }?.optString("id") ?: ""
            if (selectedModel.isBlank()) selectedModel = models.firstOrNull()?.optString("id") ?: ""
            if (selectedConversation.isNotBlank()) loadConversation(selectedConversation)
            error = ""
        } catch (reason: Throwable) { fail(reason) }
    }

    private suspend fun loadConversation(id: String) {
        selectedConversation = id
        try {
            messages = api.page("/api/conversations/${MordeClient.encode(id)}/messages?limit=100")
            val latest = tasks.filter { it.optString("conversation_id") == id }.maxByOrNull { it.optString("updated_at") }
            selectedTask = latest?.let { api.request("/api/tasks/${MordeClient.encode(it.getString("id"))}") }
            selectedTask?.optString("id")?.let { startStream(it) }
        } catch (reason: Throwable) { fail(reason) }
    }

    private fun send() {
        val text = draft.trim()
        val host = conversations.firstOrNull { it.optString("id") == selectedConversation }?.optString("host_id") ?: selectedHost
        if (text.isEmpty() || host.isBlank() || selectedModel.isBlank() || busy) return
        val fingerprint = "$selectedConversation|$host|$selectedModel|$text"
        if (retrySend?.first != fingerprint) retrySend = fingerprint to UUID.randomUUID().toString()
        lifecycleScope.launch {
            busy = true
            try {
                val reply = if (selectedConversation.isBlank()) api.request("/api/tasks", "POST",
                    MordeClient.json("host_id" to host, "model_id" to selectedModel, "objective" to text), retrySend?.second)
                else api.request("/api/conversations/${MordeClient.encode(selectedConversation)}/messages", "POST",
                    MordeClient.json("host_id" to host, "model_id" to selectedModel, "content" to text), retrySend?.second).getJSONObject("task")
                retrySend = null; draft = ""; selectedConversation = reply.getString("conversation_id"); selectedTask = reply
                load(); startStream(reply.getString("id"))
            } catch (reason: Throwable) { fail(reason) }
            finally { busy = false }
        }
    }

    private fun act(body: JSONObject) {
        if (!canStartMordeAction(busy)) return
        val task = selectedTask ?: return
        val id = task.optString("id")
        val fingerprint = "$id|${body}"
        if (retryAction?.first != fingerprint) retryAction = fingerprint to UUID.randomUUID().toString()
        // Set this before launching so another UI event cannot start a parallel action.
        busy = true
        lifecycleScope.launch {
            try {
                api.request("/api/tasks/${MordeClient.encode(id)}/actions", "POST", body, retryAction?.second)
                retryAction = null; answer = ""
                selectedTask = api.request("/api/tasks/${MordeClient.encode(id)}")
            } catch (reason: Throwable) {
                fail(reason)
                if (reason is MordeHttpException && reason.status == 409) {
                    retryAction = null
                    selectedTask = runCatching { api.request("/api/tasks/${MordeClient.encode(id)}") }.getOrNull()
                }
            } finally { busy = false }
        }
    }

    private fun openHost(id: String, sharedHost: Boolean) {
        lifecycleScope.launch {
            try {
                val host = (if (sharedHost) shared else hosts).firstOrNull { it.optString("id") == id }
                    ?: throw IllegalArgumentException("Host is no longer available")
                val origin = host.getString("url")
                val endpoint = if (sharedHost) "observation-ticket" else "enter"
                val ticket = api.request("/api/hosts/${MordeClient.encode(id)}/$endpoint", "POST")
                val url = ticket.getString("url")
                require(isValidMordeHostTicketUrl(url, origin)) { "Invalid Host ticket" }
                val expiresAt = api.clientExpiresAt ?: throw IllegalStateException("Authorization expiry is unavailable")
                startActivity(Intent(this@MordeActivity, MordeHostActivity::class.java)
                    .putExtra("ticket_url", url).putExtra("host_origin", origin)
                    .putExtra("client_expires_at", expiresAt.toString()))
            } catch (reason: Throwable) { fail(reason) }
        }
    }

    private fun stopStream() { streamGeneration++; eventSource?.cancel(); eventSource = null }
    private suspend fun recoverSnapshot(taskId: String, sequence: String, generation: Int) {
        while (generation == streamGeneration && lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED)) {
            try {
                val task = api.request("/api/tasks/${MordeClient.encode(taskId)}")
                val conversationId = task.getString("conversation_id")
                val latestMessages = api.page("/api/conversations/${MordeClient.encode(conversationId)}/messages?limit=100")
                if (generation != streamGeneration) return
                selectedTask = task; selectedConversation = conversationId; messages = latestMessages
                eventCursor = sequence
                if (task.optString("status") in listOf("completed", "failed", "cancelled")) {
                    streamTaskId = ""
                } else startStream(taskId)
                return
            } catch (reason: Throwable) {
                fail(reason)
                if (!signedIn) return
                delay(2_000)
            }
        }
    }
    private fun startStream(taskId: String) {
        if (taskId.isBlank() || api.token == null) return
        if (taskId != streamTaskId) eventCursor = ""
        stopStream(); streamTaskId = taskId
        val generation = streamGeneration
        val request = try { api.streamRequest(taskId, eventCursor) } catch (reason: Throwable) { fail(reason); return }
        eventSource = EventSources.createFactory(api.eventSourceClient()).newEventSource(request, object : EventSourceListener() {
            override fun onEvent(eventSource: EventSource, id: String?, type: String?, data: String) {
                if (generation != streamGeneration) return
                if (type == "task.snapshot_required") {
                    val sequence = runCatching { JSONObject(data).getLong("sequence").toString() }.getOrNull()
                    lifecycleScope.launch {
                        if (generation != streamGeneration) return@launch
                        stopStream()
                        if (sequence.isNullOrBlank()) { error = "Task snapshot cursor is invalid"; return@launch }
                        recoverSnapshot(taskId, sequence, streamGeneration)
                    }
                    return
                }
                lifecycleScope.launch {
                    taskEventRefreshMutex.withLock {
                        if (generation != streamGeneration) return@withLock
                        try {
                            advanceTaskEventCursorAfterRefresh(id, refresh = {
                                val current = api.request("/api/tasks/${MordeClient.encode(taskId)}")
                                val conversationId = current.getString("conversation_id")
                                val latestMessages = api.page("/api/conversations/${MordeClient.encode(conversationId)}/messages?limit=100")
                                if (generation != streamGeneration) false else {
                                    selectedTask = current
                                    selectedConversation = conversationId
                                    messages = latestMessages
                                    if (current.optString("status") in listOf("completed", "failed", "cancelled")) stopStream()
                                    true
                                }
                            }, advance = { eventCursor = it })
                        } catch (reason: Throwable) {
                            if (generation == streamGeneration) {
                                fail(reason)
                                if (signedIn && generation == streamGeneration) {
                                    // Stop this stream so later events cannot skip the failed event's cursor.
                                    stopStream()
                                    val retryGeneration = streamGeneration
                                    lifecycleScope.launch {
                                        delay(2_000)
                                        if (streamGeneration == retryGeneration && signedIn && streamTaskId == taskId &&
                                            lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED)) {
                                            startStream(taskId)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            override fun onFailure(eventSource: EventSource, t: Throwable?, response: Response?) {
                if (generation != streamGeneration) return
                lifecycleScope.launch {
                    if (response?.code == 401) { api.clear(); signedIn = false; reset(); return@launch }
                    if (response?.code == 204) { stopStream(); streamTaskId = ""; return@launch }
                    delay(2_000)
                    if (generation == streamGeneration && lifecycle.currentState.isAtLeast(androidx.lifecycle.Lifecycle.State.STARTED)) startStream(taskId)
                }
            }
        })
    }

    @Composable private fun Content() {
        val now by produceState(initialValue = Instant.now(), signedIn) {
            while (signedIn) { delay(60_000); value = Instant.now() }
        }
        if (!signedIn) {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Morde", style = MaterialTheme.typography.headlineLarge)
                OutlinedTextField(serverText, { serverText = it }, label = { Text("HTTPS Morde address") }, modifier = Modifier.fillMaxWidth(), enabled = !busy)
                OutlinedTextField(loginName, { loginName = it }, label = { Text("Account") }, modifier = Modifier.fillMaxWidth(), enabled = !busy)
                OutlinedTextField(loginPassword, { loginPassword = it }, label = { Text("Password") }, modifier = Modifier.fillMaxWidth(),
                    enabled = !busy, visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password))
                Button(onClick = ::beginLogin, enabled = !busy && serverText.isNotBlank() && loginName.isNotBlank() && loginPassword.isNotBlank()) {
                    Text(if (busy) "Signing in…" else "Sign in")
                }
                if (error.isNotBlank()) Text(error, color = MaterialTheme.colorScheme.error)
            }
            return
        }
        Scaffold(bottomBar = {
            NavigationBar {
                listOf("Chat", "Hosts", "Projects", "Notices").forEachIndexed { index, title ->
                    NavigationBarItem(selected = tab == index, onClick = { tab = index }, icon = { Text("·") }, label = { Text(title) })
                }
            }
        }) { padding ->
            Column(Modifier.fillMaxSize().padding(padding).verticalScroll(rememberScrollState()).padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Morde", style = MaterialTheme.typography.headlineMedium)
                    Text("Sign out", modifier = Modifier.clickable { signOut() })
                }
                api.clientExpiresAt?.let { expiry ->
                    val notice = when (credentialExpiryStatus(expiry, now)) {
                        CredentialExpiryStatus.EXPIRED -> "Login expired. Sign in again."
                        CredentialExpiryStatus.EXPIRING_SOON -> "Login expires within 7 days. Sign in again to renew."
                        CredentialExpiryStatus.VALID -> null
                    }
                    if (notice != null) Text(notice,
                        modifier = Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.errorContainer).padding(12.dp),
                        color = MaterialTheme.colorScheme.onErrorContainer, style = MaterialTheme.typography.titleMedium)
                }
                if (error.isNotBlank()) Text(error, color = MaterialTheme.colorScheme.error)
                when (tab) {
                    0 -> Chat()
                    1 -> {
                        Text("My computers", style = MaterialTheme.typography.titleLarge)
                        hosts.forEach { host -> Button(onClick = { openHost(host.optString("id"), false) }, enabled = host.optString("state") == "running") { Text("${host.optString("name")} · ${host.optString("state")}") } }
                        Text("Shared computers", style = MaterialTheme.typography.titleMedium)
                        shared.forEach { host -> Button(onClick = { openHost(host.optString("id"), true) }, enabled = host.optString("state") == "running") { Text(host.optString("name")) } }
                    }
                    2 -> {
                        Text("Projects", style = MaterialTheme.typography.titleLarge)
                        workspaces.forEach { workspace -> Text("${workspace.optString("name")} · revision ${workspace.optInt("revision")}") }
                    }
                    else -> {
                        Text("Notifications", style = MaterialTheme.typography.titleLarge)
                        notifications.forEach { notice ->
                            Text(notice.optString("summary", "Task update"), modifier = Modifier.clickable {
                                val id = notice.optString("task_id")
                                lifecycleScope.launch {
                                    try {
                                        api.request("/api/notifications/${MordeClient.encode(notice.getString("id"))}/read", "POST")
                                        if (id.isNotBlank()) {
                                            selectedTask = api.request("/api/tasks/${MordeClient.encode(id)}")
                                            loadConversation(selectedTask!!.getString("conversation_id"))
                                            tab = 0
                                        }
                                        notifications = api.page("/api/notifications?limit=100")
                                    } catch (reason: Throwable) { fail(reason) }
                                }
                            })
                        }
                    }
                }
            }
        }
    }

    @Composable private fun Chat() {
        Text("Conversations", style = MaterialTheme.typography.titleLarge)
        Text("New task", modifier = Modifier.clickable { selectedConversation = ""; selectedTask = null; messages = emptyList(); retrySend = null })
        conversations.forEach { item ->
            Text(item.optString("title", "New conversation"), modifier = Modifier.clickable {
                lifecycleScope.launch { loadConversation(item.optString("id")) }
            })
        }
        messages.forEach { message -> Text("${if (message.optString("role") == "user") "You" else "Morde"}: ${message.optString("content")}") }
        selectedTask?.let { task ->
            val status = task.optString("status")
            Text("$status · ${task.optString("current_step", task.optString("objective"))}")
            task.optJSONObject("pending_request")?.let { pending ->
                Text(pending.optString("title")); Text(pending.optString("content")); Text(pending.optString("impact"))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(onClick = { act(MordeClient.json("action" to "respond", "pending_id" to pending.getString("id"), "pending_version" to pending.getInt("version"), "decision" to "approve")) }, enabled = !busy) { Text("Approve") }
                    Button(onClick = { act(MordeClient.json("action" to "respond", "pending_id" to pending.getString("id"), "pending_version" to pending.getInt("version"), "decision" to "reject")) }, enabled = !busy) { Text("Reject") }
                }
            }
            task.optJSONObject("clarification_request")?.let { clarification ->
                Text(clarification.optString("question"))
                OutlinedTextField(answer, { answer = it }, label = { Text("Your answer") }, modifier = Modifier.fillMaxWidth())
                Button(onClick = { act(MordeClient.json("action" to "answer_clarification", "clarification_id" to clarification.getString("id"), "clarification_version" to clarification.getInt("version"), "answer" to answer.trim())) }, enabled = !busy && answer.isNotBlank()) { Text("Reply") }
            }
            if (status == "failed") task.optJSONArray("batch_items")?.let { items ->
                for (index in 0 until items.length()) {
                    val item = items.optJSONObject(index) ?: continue
                    if (canRetryMordeBatchItem(status, item.optString("status"))) {
                        val itemID = item.optString("id")
                        val label = item.optString("key").ifBlank { itemID }
                        Button(onClick = { act(MordeClient.json("action" to "retry_batch_item", "batch_item_id" to itemID)) }, enabled = canStartMordeAction(busy)) { Text("Retry batch: $label") }
                    }
                }
            }
            if (status in listOf("queued", "running")) Button(onClick = { act(MordeClient.json("action" to "pause", "expected_status" to status)) }, enabled = canStartMordeAction(busy)) { Text("Pause") }
            if (status == "paused") Button(onClick = { act(MordeClient.json("action" to "resume", "expected_status" to "paused")) }, enabled = canStartMordeAction(busy)) { Text("Resume") }
            if (status in listOf("queued", "running", "waiting_user", "paused")) Button(onClick = { act(MordeClient.json("action" to "cancel", "expected_status" to status)) }, enabled = canStartMordeAction(busy)) { Text("Cancel") }
        }
        Text("Computer")
        hosts.filter { it.optString("state") == "running" }.forEach { host ->
            Text("${if (selectedHost == host.optString("id")) "●" else "○"} ${host.optString("name")}", modifier = Modifier.clickable { selectedHost = host.optString("id") })
        }
        Text("Model")
        models.forEach { model -> Text("${if (selectedModel == model.optString("id")) "●" else "○"} ${model.optString("name")}", modifier = Modifier.clickable { selectedModel = model.optString("id") }) }
        OutlinedTextField(draft, { draft = it }, label = { Text("Describe the task") }, modifier = Modifier.fillMaxWidth(), minLines = 2)
        Button(onClick = ::send, enabled = !busy && draft.isNotBlank() && (selectedConversation.isNotBlank() || selectedHost.isNotBlank()) && selectedModel.isNotBlank()) { Text("Send") }
    }
}
