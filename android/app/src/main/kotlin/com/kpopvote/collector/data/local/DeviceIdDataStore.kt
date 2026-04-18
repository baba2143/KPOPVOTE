package com.kpopvote.collector.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Stable per-install device identifier used as the Firestore `fcmTokens` sub-collection key.
 *
 * Mirrors iOS `UserDefaults.standard.string(forKey: "fcm_device_id")` flow in
 * `PushNotificationManager.swift` — once generated, the UUID persists across app sessions
 * so that token register/unregister target the same document.
 */
@Singleton
class DeviceIdDataStore @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val dataStore: DataStore<Preferences> get() = context.dataStore

    suspend fun getOrCreate(): String {
        val current = dataStore.data.first()[KEY_DEVICE_ID]
        if (current != null) return current
        val fresh = UUID.randomUUID().toString()
        dataStore.edit { it[KEY_DEVICE_ID] = fresh }
        return fresh
    }

    private companion object {
        val KEY_DEVICE_ID = stringPreferencesKey("fcm_device_id")
        val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "fcm_prefs")
    }
}
