package com.kpopvote.collector

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.getValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.kpopvote.collector.core.notifications.NotificationPermissionController
import com.kpopvote.collector.navigation.DeepLinkIntent
import com.kpopvote.collector.navigation.KpopvoteNavHost
import com.kpopvote.collector.ui.theme.KpopvoteTheme
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.MutableStateFlow
import timber.log.Timber

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission(),
    ) { granted ->
        Timber.i("POST_NOTIFICATIONS permission result: granted=$granted")
    }

    private val deepLinkFlow = MutableStateFlow<DeepLinkIntent?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        deepLinkFlow.value = DeepLinkIntent.fromBundle(intent?.extras)
        requestNotificationPermissionIfNeeded()
        setContent {
            val deepLink by deepLinkFlow.collectAsStateWithLifecycle()
            KpopvoteTheme {
                KpopvoteNavHost(initialDeepLink = deepLink)
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deepLinkFlow.value = DeepLinkIntent.fromBundle(intent.extras)
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (!NotificationPermissionController.requiresRuntimeRequest()) return
        if (NotificationPermissionController.isGranted(this)) return
        notificationPermissionLauncher.launch(NotificationPermissionController.PERMISSION)
    }
}
