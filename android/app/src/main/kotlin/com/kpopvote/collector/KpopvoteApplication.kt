package com.kpopvote.collector

import android.app.Application
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.google.firebase.ktx.Firebase
import com.google.firebase.ktx.initialize
import com.kpopvote.collector.core.auth.CrashlyticsUserObserver
import com.kpopvote.collector.core.auth.FcmLifecycleObserver
import com.kpopvote.collector.notifications.NotificationChannelManager
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber
import javax.inject.Inject

@HiltAndroidApp
class KpopvoteApplication : Application() {

    @Inject lateinit var notificationChannelManager: NotificationChannelManager
    @Inject lateinit var fcmLifecycleObserver: FcmLifecycleObserver
    @Inject lateinit var crashlyticsUserObserver: CrashlyticsUserObserver

    override fun onCreate() {
        super.onCreate()
        initLogging()
        initFirebase()
        initAppCheck()
        notificationChannelManager.ensureDefaultChannel()
        fcmLifecycleObserver.start()
        crashlyticsUserObserver.start()
    }

    private fun initLogging() {
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            Timber.plant(CrashReportingTree())
        }
    }

    private fun initFirebase() {
        Firebase.initialize(this)
        FirebaseCrashlytics.getInstance().setCrashlyticsCollectionEnabled(!BuildConfig.DEBUG)
    }

    private fun initAppCheck() {
        val appCheck = FirebaseAppCheck.getInstance()
        if (BuildConfig.USE_APP_CHECK_DEBUG) {
            appCheck.installAppCheckProviderFactory(DebugAppCheckProviderFactory.getInstance())
        } else {
            appCheck.installAppCheckProviderFactory(PlayIntegrityAppCheckProviderFactory.getInstance())
        }
    }
}

private class CrashReportingTree : Timber.Tree() {
    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        if (priority == android.util.Log.VERBOSE || priority == android.util.Log.DEBUG) return
        val crashlytics = FirebaseCrashlytics.getInstance()
        tag?.let { crashlytics.setCustomKey("tag", it) }
        crashlytics.log(message)
        t?.let { crashlytics.recordException(it) }
    }
}
