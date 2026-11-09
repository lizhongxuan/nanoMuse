package io.morde.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MordeMessageSendPolicyTest {
    @Test fun existingConversationCanAcceptTextWithoutHostOrModel() {
        assertTrue(canSendMordeMessage("Hello", busy = false, hasConversation = true, hasHost = false, hasModel = false))
    }

    @Test fun standaloneTaskStillNeedsHostAndModel() {
        assertFalse(canSendMordeMessage("Task", busy = false, hasConversation = false, hasHost = false, hasModel = true))
        assertFalse(canSendMordeMessage("Task", busy = false, hasConversation = false, hasHost = true, hasModel = false))
        assertTrue(canSendMordeMessage("Task", busy = false, hasConversation = false, hasHost = true, hasModel = true))
    }

    @Test fun blankOrBusyMessageCannotBeSent() {
        assertFalse(canSendMordeMessage("  ", busy = false, hasConversation = true, hasHost = false, hasModel = false))
        assertFalse(canSendMordeMessage("Hello", busy = true, hasConversation = true, hasHost = false, hasModel = false))
    }
}
