package com.kpopvote.collector.core.appcheck

import com.google.firebase.appcheck.FirebaseAppCheck
import com.kpopvote.collector.BuildConfig
import kotlinx.coroutines.tasks.await
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Resolves a Firebase App Check token for requests that require bot protection
 * (currently only `executeVote`). In DEBUG builds (`USE_APP_CHECK_DEBUG=true`)
 * returns `null` to mirror iOS behaviour and keep local runs frictionless.
 */
@Singleton
class AppCheckTokenProvider @Inject constructor(
    private val appCheck: FirebaseAppCheck,
) {
    suspend fun getToken(forceRefresh: Boolean = false): String? {
        if (BuildConfig.USE_APP_CHECK_DEBUG) return null
        return runCatching {
            appCheck.getAppCheckToken(forceRefresh).await().token
        }.getOrElse {
            Timber.w(it, "AppCheck token fetch failed")
            null
        }
    }
}
