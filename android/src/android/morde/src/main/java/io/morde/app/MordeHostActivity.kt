package io.morde.app

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.os.Bundle
import android.webkit.CookieManager
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import java.time.Instant

class MordeHostActivity : Activity() {
    private var web: WebView? = null
    private var clientExpiresAt: Instant? = null
    private val expiryHandler = Handler(Looper.getMainLooper())
    private val expireHostView = Runnable { enforceClientExpiry() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val ticket = intent.getStringExtra("ticket_url") ?: return finish()
        val hostOrigin = intent.getStringExtra("host_origin") ?: return finish()
        clientExpiresAt = intent.getStringExtra("client_expires_at")?.let { runCatching { Instant.parse(it) }.getOrNull() }
        if (clientExpiresAt == null || mordeHostSessionExpired(clientExpiresAt!!, Instant.now())) return finish()
        if (!isValidMordeHostTicketUrl(ticket, hostOrigin)) return finish()
        web = WebView(this).also { view ->
            // The Host viewer needs JavaScript; the one-time ticket stays on the selected HTTPS Host.
            view.settings.javaScriptEnabled = true
            view.settings.domStorageEnabled = true
            view.settings.allowFileAccess = false
            view.settings.allowContentAccess = false
            view.settings.mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW
            CookieManager.getInstance().setAcceptThirdPartyCookies(view, false)
            view.webViewClient = object : WebViewClient() {
                override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                    return !isAllowedMordeHostNavigationUrl(request.url.toString(), hostOrigin)
                }
            }
            setContentView(view)
            view.loadUrl(ticket)
        }
    }

    override fun onResume() {
        super.onResume()
        enforceClientExpiry()
    }

    private fun enforceClientExpiry() {
        val expiresAt = clientExpiresAt ?: return finish()
        if (mordeHostSessionExpired(expiresAt, Instant.now())) {
            web?.stopLoading()
            web?.loadUrl("about:blank")
            finish()
            return
        }
        expiryHandler.removeCallbacks(expireHostView)
        expiryHandler.postDelayed(expireHostView, (expiresAt.toEpochMilli() - System.currentTimeMillis()).coerceAtLeast(1))
    }

    override fun onDestroy() {
        expiryHandler.removeCallbacks(expireHostView)
        web?.stopLoading()
        web?.destroy()
        web = null
        super.onDestroy()
    }
}
