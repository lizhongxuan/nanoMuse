package io.morde.app

import java.security.MessageDigest

internal fun loginAttemptFingerprint(server: String, name: String, password: String): String =
    MessageDigest.getInstance("SHA-256")
        .digest("$server\u0000$name\u0000$password".toByteArray(Charsets.UTF_8))
        .joinToString("") { (it.toInt() and 0xff).toString(16).padStart(2, '0') }
