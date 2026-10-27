package io.morde.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MordeHostTicketUrlTest {
    private val host = "https://host.example"

    @Test fun acceptsTicketForSelectedHost() {
        assertTrue(isValidMordeHostTicketUrl("https://host.example/__ch/auth?t=secret", host))
        assertTrue(isValidMordeHostTicketUrl("https://HOST.example:443/__ch/auth?x=1&t=a%2Bb", host))
    }

    @Test fun rejectsRepeatedTicketParameters() {
        assertFalse(isValidMordeHostTicketUrl("https://host.example/__ch/auth?t=one&t=two", host))
        assertFalse(isValidMordeHostTicketUrl("https://host.example/__ch/auth?t=one&%74=two", host))
    }

    @Test fun rejectsEmptyTicket() {
        assertFalse(isValidMordeHostTicketUrl("https://host.example/__ch/auth?t=", host))
        assertFalse(isValidMordeHostTicketUrl("https://host.example/__ch/auth?t=%20", host))
    }

    @Test fun rejectsOtherHostAndPath() {
        assertFalse(isValidMordeHostTicketUrl("https://other.example/__ch/auth?t=secret", host))
        assertFalse(isValidMordeHostTicketUrl("https://host.example/other?t=secret", host))
    }

    @Test fun hostNavigationNormalizesHostCaseAndDefaultHttpsPort() {
        assertTrue(isAllowedMordeHostNavigationUrl("https://HOST.example:443/tasks/1", host))
        assertTrue(isAllowedMordeHostNavigationUrl("https://host.example/tasks/1", "https://HOST.example:443"))
    }

    @Test fun hostNavigationRejectsDifferentOriginAndCredentials() {
        assertFalse(isAllowedMordeHostNavigationUrl("https://other.example/tasks", host))
        assertFalse(isAllowedMordeHostNavigationUrl("https://host.example:444/tasks", host))
        assertFalse(isAllowedMordeHostNavigationUrl("http://host.example/tasks", host))
        assertFalse(isAllowedMordeHostNavigationUrl("https://user@host.example/tasks", host))
    }

    @Test fun taskActionsAreUnavailableWhileBusy() {
        assertTrue(canStartMordeAction(busy = false))
        assertFalse(canStartMordeAction(busy = true))
    }

    @Test fun onlyFailedBatchItemsOnFailedTasksCanBeRetried() {
        assertTrue(canRetryMordeBatchItem("failed", "failed"))
        assertFalse(canRetryMordeBatchItem("running", "failed"))
        assertFalse(canRetryMordeBatchItem("failed", "succeeded"))
    }
}
