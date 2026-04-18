package com.kpopvote.collector.core.common

/**
 * Common error hierarchy for the entire app.
 * Translate Firebase / network / validation errors into one of these
 * at the Repository layer so UI can map them to localized strings.
 */
sealed class AppError : Throwable() {
    object Network : AppError() {
        private fun readResolve(): Any = Network
    }

    object Unauthorized : AppError() {
        private fun readResolve(): Any = Unauthorized
    }

    data class Server(
        val code: Int,
        override val message: String,
    ) : AppError()

    data class Validation(
        override val message: String,
    ) : AppError()

    data class Auth(val reason: AuthFailureReason) : AppError()

    data class Unknown(override val cause: Throwable) : AppError() {
        override val message: String? = cause.message
    }
}

/**
 * Coerce any throwable into an [AppError]. Preserves [AppError] instances unchanged.
 * Network / Firebase-specific mappings happen in their respective layers
 * (e.g. `FunctionsClient` for HTTP codes, `AuthRepositoryImpl.toAuthError` for Firebase Auth).
 */
fun Throwable.toAppError(): AppError = when (this) {
    is AppError -> this
    else -> AppError.Unknown(this)
}

enum class AuthFailureReason {
    WRONG_CREDENTIALS,
    USER_NOT_FOUND,
    EMAIL_ALREADY_IN_USE,
    WEAK_PASSWORD,
    INVALID_EMAIL,
    GOOGLE_SIGN_IN_CANCELLED,
    GOOGLE_SIGN_IN_FAILED,
    UNKNOWN,
}
