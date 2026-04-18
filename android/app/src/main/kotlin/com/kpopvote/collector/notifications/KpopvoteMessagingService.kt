package com.kpopvote.collector.notifications

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.kpopvote.collector.core.auth.AuthStateHolder
import com.kpopvote.collector.data.repository.FcmTokenRepository
import com.kpopvote.collector.di.ApplicationScope
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * Receives FCM messages and token refreshes. Hilt-managed so repositories/presenters
 * can be injected despite being instantiated by the Android framework.
 *
 * - [onNewToken] registers the new token only if a user is logged in. Unauthenticated
 *   token refreshes are dropped; [com.kpopvote.collector.core.auth.FcmLifecycleObserver]
 *   will pick the token up at login time.
 * - [onMessageReceived] delegates to [NotificationPresenter]; foreground parity with iOS
 *   ensures the user sees the banner even when the app is active.
 */
@AndroidEntryPoint
class KpopvoteMessagingService : FirebaseMessagingService() {

    @Inject lateinit var fcmTokenRepository: FcmTokenRepository
    @Inject lateinit var authStateHolder: AuthStateHolder
    @Inject lateinit var notificationPresenter: NotificationPresenter
    @Inject @ApplicationScope lateinit var appScope: CoroutineScope

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        if (authStateHolder.currentUid == null) {
            Timber.d("FCM token refreshed but no user is logged in; deferring registration")
            return
        }
        appScope.launch {
            fcmTokenRepository.register(token)
                .onFailure { Timber.w(it, "FCM token register failed in onNewToken") }
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        notificationPresenter.show(message)
    }
}
