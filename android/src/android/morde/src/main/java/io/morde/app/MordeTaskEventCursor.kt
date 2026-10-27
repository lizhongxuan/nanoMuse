package io.morde.app

internal suspend fun advanceTaskEventCursorAfterRefresh(
    eventId: String?,
    refresh: suspend () -> Boolean,
    advance: (String) -> Unit,
) {
    if (!eventId.isNullOrBlank() && refresh()) advance(eventId)
}
