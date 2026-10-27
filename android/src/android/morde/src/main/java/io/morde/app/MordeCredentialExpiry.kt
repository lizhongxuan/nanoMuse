package io.morde.app

import java.time.Instant
import java.time.temporal.ChronoUnit

internal enum class CredentialExpiryStatus { EXPIRED, EXPIRING_SOON, VALID }

internal fun credentialExpiryStatus(expiresAt: Instant, now: Instant): CredentialExpiryStatus = when {
    !expiresAt.isAfter(now) -> CredentialExpiryStatus.EXPIRED
    !expiresAt.isAfter(now.plus(7, ChronoUnit.DAYS)) -> CredentialExpiryStatus.EXPIRING_SOON
    else -> CredentialExpiryStatus.VALID
}

internal fun hasUsableCredential(token: String?, expiresAt: Instant?, now: Instant): Boolean =
    !token.isNullOrBlank() && expiresAt?.isAfter(now) == true

internal fun mordeHostSessionExpired(expiresAt: Instant, now: Instant): Boolean =
    credentialExpiryStatus(expiresAt, now) == CredentialExpiryStatus.EXPIRED
