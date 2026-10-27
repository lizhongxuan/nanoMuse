package io.morde.app

import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Test

class MordeCredentialExpiryTest {
    private val now = Instant.parse("2026-10-26T00:00:00Z")

    @Test fun expiresAtNowIsExpired() {
        assertEquals(CredentialExpiryStatus.EXPIRED, credentialExpiryStatus(now, now))
    }

    @Test fun remindsAtTheSevenDayBoundary() {
        assertEquals(CredentialExpiryStatus.EXPIRING_SOON, credentialExpiryStatus(now.plusSeconds(7 * 86_400), now))
    }

    @Test fun expiresAfterSevenDaysAreStillValid() {
        assertEquals(CredentialExpiryStatus.VALID, credentialExpiryStatus(now.plusSeconds(7 * 86_400 + 1), now))
    }

    @Test fun expiredOrIncompleteCredentialsCannotBeUsed() {
        assertEquals(false, hasUsableCredential("secret", now, now))
        assertEquals(false, hasUsableCredential("secret", null, now))
        assertEquals(false, hasUsableCredential(null, now.plusSeconds(1), now))
        assertEquals(true, hasUsableCredential("secret", now.plusSeconds(1), now))
    }

    @Test fun hostSessionExpiresWithItsClientCredential() {
        assertEquals(true, mordeHostSessionExpired(now, now))
        assertEquals(false, mordeHostSessionExpired(now.plusSeconds(1), now))
    }
}
