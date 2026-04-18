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

    /** Vote-specific business errors. Refined from 400 responses by VoteErrorMapper. */
    sealed class Vote : AppError() {
        object AlreadyVoted : Vote() {
            override val message: String = "既に投票済みです"
            private fun readResolve(): Any = AlreadyVoted
        }

        object InsufficientPoints : Vote() {
            override val message: String = "ポイントが不足しています"
            private fun readResolve(): Any = InsufficientPoints
        }

        object NotActive : Vote() {
            override val message: String = "この投票は開催されていません"
            private fun readResolve(): Any = NotActive
        }

        data class DailyLimitReached(override val message: String) : Vote()

        object AppCheckFailed : Vote() {
            override val message: String = "端末の検証に失敗しました。時間をおいて再度お試しください。"
            private fun readResolve(): Any = AppCheckFailed
        }
    }

    /** Collection-specific business errors. */
    sealed class Collection : AppError() {
        object NotOwner : Collection() {
            override val message: String = "このコレクションを編集する権限がありません"
            private fun readResolve(): Any = NotOwner
        }

        data class QuotaExceeded(override val message: String) : Collection()
    }

    /** Invite-code business errors. Refined from 400 responses by InviteErrorMapper. */
    sealed class Invite : AppError() {
        object AlreadyApplied : Invite() {
            override val message: String = "招待コードは既に適用されています"
            private fun readResolve(): Any = AlreadyApplied
        }

        object SelfInvite : Invite() {
            override val message: String = "自分の招待コードは使えません"
            private fun readResolve(): Any = SelfInvite
        }

        data class NotFound(override val message: String) : Invite()
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
