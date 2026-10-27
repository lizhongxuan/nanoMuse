package io.morde.app

import java.net.URI
import java.net.URLDecoder

internal fun canStartMordeAction(busy: Boolean): Boolean = !busy
internal fun canRetryMordeBatchItem(taskStatus: String, itemStatus: String): Boolean = taskStatus == "failed" && itemStatus == "failed"

internal fun isAllowedMordeHostNavigationUrl(candidateValue: String, originValue: String): Boolean = runCatching {
    val candidate = URI(candidateValue)
    val origin = URI(originValue)
    require(candidate.scheme.equals("https", ignoreCase = true) && !candidate.host.isNullOrBlank())
    require(origin.scheme.equals("https", ignoreCase = true) && !origin.host.isNullOrBlank())
    require(candidate.userInfo == null && origin.userInfo == null)
    require(candidate.host.equals(origin.host, ignoreCase = true))
    require((candidate.port.takeIf { it >= 0 } ?: 443) == (origin.port.takeIf { it >= 0 } ?: 443))
    true
}.getOrDefault(false)

internal fun isValidMordeHostTicketUrl(ticketValue: String, hostValue: String): Boolean = runCatching {
    val host = URI(hostValue)
    val ticket = URI(ticketValue)
    require(host.scheme.equals("https", ignoreCase = true) && !host.host.isNullOrBlank())
    require(host.userInfo == null && host.rawQuery == null && host.rawFragment == null)
    require(host.rawPath.isNullOrEmpty() || host.rawPath == "/")
    require(ticket.scheme.equals("https", ignoreCase = true))
    require(ticket.host?.equals(host.host, ignoreCase = true) == true)
    require((ticket.port.takeIf { it >= 0 } ?: 443) == (host.port.takeIf { it >= 0 } ?: 443))
    require(ticket.rawPath == "/__ch/auth" && ticket.userInfo == null && ticket.rawFragment == null)

    val tickets = ticket.rawQuery.orEmpty().split('&').mapNotNull { item ->
        val separator = item.indexOf('=')
        val name = if (separator < 0) item else item.substring(0, separator)
        if (URLDecoder.decode(name.replace("+", "%2B"), "UTF-8") != "t") return@mapNotNull null
        val value = if (separator < 0) "" else item.substring(separator + 1)
        URLDecoder.decode(value.replace("+", "%2B"), "UTF-8")
    }
    tickets.size == 1 && tickets.single().isNotBlank()
}.getOrDefault(false)
