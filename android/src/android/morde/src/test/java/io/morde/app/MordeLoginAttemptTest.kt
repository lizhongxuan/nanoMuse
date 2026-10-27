package io.morde.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class MordeLoginAttemptTest {
    @Test fun retriesUseTheSameKeyOnlyForTheSameCredentials() {
        val first = loginAttemptFingerprint("https://morde.example", "alice", "secret")
        assertEquals(64, first.length)
        assertEquals(first, loginAttemptFingerprint("https://morde.example", "alice", "secret"))
        assertNotEquals(first, loginAttemptFingerprint("https://morde.example", "alice", "changed"))
        assertNotEquals(first, loginAttemptFingerprint("https://other.example", "alice", "secret"))
    }
}
