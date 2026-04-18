package com.kpopvote.collector.notifications

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.RemoteMessage
import com.kpopvote.collector.MainActivity
import com.kpopvote.collector.R
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.absoluteValue

/**
 * Builds and posts a visible notification from an FCM [RemoteMessage].
 *
 * Foreground presentation parity with iOS: `onMessageReceived` is invoked even when the
 * app is in the foreground, where iOS shows the banner via `.banner, .badge, .sound`
 * (see `AppDelegate.swift` `willPresent`). On Android this presenter explicitly posts
 * the notification to match that behavior.
 */
@Singleton
class NotificationPresenter @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    fun show(message: RemoteMessage) {
        if (!hasPostNotificationsPermission()) return
        val notification = message.notification ?: return
        val title = notification.title.orEmpty()
        val body = notification.body.orEmpty()
        val payload = NotificationPayload.fromDataMap(message.data)
        val pendingIntent = buildPendingIntent(payload)
        val builder = NotificationCompat.Builder(context, NotificationChannelManager.CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        NotificationManagerCompat.from(context).notify(payload.stableNotificationId(), builder.build())
    }

    @SuppressLint("MissingPermission")
    private fun hasPostNotificationsPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun buildPendingIntent(payload: NotificationPayload): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtras(payload.toBundle())
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(context, payload.stableRequestCode(), intent, flags)
    }
}

internal fun NotificationPayload.toBundle(): android.os.Bundle = android.os.Bundle().apply {
    putString(EXTRA_NOTIFICATION_TYPE, type)
    notificationId?.let { putString(EXTRA_NOTIFICATION_ID, it) }
    voteId?.let { putString(EXTRA_VOTE_ID, it) }
    postId?.let { putString(EXTRA_POST_ID, it) }
    commentId?.let { putString(EXTRA_COMMENT_ID, it) }
    userId?.let { putString(EXTRA_USER_ID, it) }
}

internal fun NotificationPayload.stableNotificationId(): Int =
    (notificationId ?: "${type}:${voteId ?: postId ?: ""}").hashCode().absoluteValue

internal fun NotificationPayload.stableRequestCode(): Int =
    stableNotificationId()

const val EXTRA_NOTIFICATION_TYPE = "kpopvote.notification.type"
const val EXTRA_NOTIFICATION_ID = "kpopvote.notification.id"
const val EXTRA_VOTE_ID = "kpopvote.notification.voteId"
const val EXTRA_POST_ID = "kpopvote.notification.postId"
const val EXTRA_COMMENT_ID = "kpopvote.notification.commentId"
const val EXTRA_USER_ID = "kpopvote.notification.userId"
