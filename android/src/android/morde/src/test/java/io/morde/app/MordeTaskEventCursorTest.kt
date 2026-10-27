package io.morde.app

import java.io.IOException
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class MordeTaskEventCursorTest {
    @Test fun failedTaskRefreshKeepsThePreviousCursor() = runBlocking {
        var cursor = "7"
        try {
            advanceTaskEventCursorAfterRefresh("8", refresh = {
                throw IOException("task temporarily unavailable")
            }, advance = { cursor = it })
        } catch (_: IOException) {
            // A failed refresh must leave the event eligible for replay.
        }

        assertEquals("7", cursor)
    }

    @Test fun failedMessagesRefreshKeepsThePreviousCursor() = runBlocking {
        var cursor = "7"
        var taskWasRefreshed = false
        try {
            advanceTaskEventCursorAfterRefresh("8", refresh = {
                taskWasRefreshed = true
                throw IOException("messages temporarily unavailable")
            }, advance = { cursor = it })
        } catch (_: IOException) {
            // A failed refresh must leave the event eligible for replay.
        }

        assertTrue(taskWasRefreshed)
        assertEquals("7", cursor)
    }

    @Test fun retryAfterRefreshFailureCanReplayAndAdvanceTheSameEvent() = runBlocking {
        var cursor = "7"
        try {
            advanceTaskEventCursorAfterRefresh("8", refresh = {
                throw IOException("messages temporarily unavailable")
            }, advance = { cursor = it })
        } catch (_: IOException) {
            // The stream reconnects with the last successfully applied cursor.
        }
        assertEquals("7", cursor)

        advanceTaskEventCursorAfterRefresh("8", refresh = { true }, advance = { cursor = it })

        assertEquals("8", cursor)
    }

    @Test fun successfulRefreshFinishesBeforeCursorAdvances() = runBlocking {
        var cursor = "7"
        val order = mutableListOf<String>()

        advanceTaskEventCursorAfterRefresh("8", refresh = {
            order += "task-and-messages"
            true
        }, advance = {
            order += "cursor"
            cursor = it
        })

        assertEquals(listOf("task-and-messages", "cursor"), order)
        assertEquals("8", cursor)
    }

    @Test fun staleGenerationDoesNotAdvanceCursor() = runBlocking {
        var cursor = "7"

        advanceTaskEventCursorAfterRefresh("8", refresh = { false }, advance = { cursor = it })

        assertEquals("7", cursor)
    }
}
