package com.kpopvote.collector.core.notifications

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat

/**
 * Android 13 (TIRAMISU, SDK 33) 以降で必要になった `POST_NOTIFICATIONS` ランタイム
 * 権限の判定ヘルパ。12 以下では常に `true` を返す（インストール時許可済み）。
 *
 * 実際の権限要求は `ActivityResultContracts.RequestPermission` と組み合わせて
 * MainActivity 側で行う。
 */
object NotificationPermissionController {
    const val PERMISSION = Manifest.permission.POST_NOTIFICATIONS

    fun isGranted(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(context, PERMISSION) ==
            PackageManager.PERMISSION_GRANTED
    }

    fun requiresRuntimeRequest(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
}
