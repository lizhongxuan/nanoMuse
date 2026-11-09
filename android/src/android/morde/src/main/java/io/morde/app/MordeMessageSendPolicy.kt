package io.morde.app

internal fun canSendMordeMessage(
    text: String,
    busy: Boolean,
    hasConversation: Boolean,
    hasHost: Boolean,
    hasModel: Boolean,
): Boolean = text.isNotBlank() && !busy && (hasConversation || hasHost && hasModel)
