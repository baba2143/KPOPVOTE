//
//  AppDelegate.swift
//  OSHI Pick
//
//  OSHI Pick - Push Notification & Phone Auth Handling
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import FirebaseAuth
import FirebaseAppCheck
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // App Check を Firebase 初期化前に設定
        // DEBUG時はVoteService/IdolRankingServiceでスキップするため初期化不要
        #if !DEBUG
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        debugLog("🔧 [AppCheck] DeviceCheck provider factory configured")
        #else
        debugLog("⚠️ [AppCheck] Skipped in DEBUG mode")
        #endif

        // Firebase を最初に初期化（Auth.auth() を使う前に必須）
        FirebaseApp.configure()

        // Firestore キャッシュ設定（オフライン対応・パフォーマンス改善）
        configureFirestoreCache()

        // Set up push notifications
        setupPushNotifications(application: application)

        return true
    }

    // MARK: - Firestore Cache Configuration

    /// Firestoreのキャッシュ設定を最適化
    /// - オフラインでもデータ閲覧可能
    /// - ネットワーク遅延時のUX改善
    private func configureFirestoreCache() {
        let settings = Firestore.firestore().settings
        // キャッシュサイズ: 100MB（デフォルトは40MB）
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)
        Firestore.firestore().settings = settings
        debugLog("🔧 [Firestore] Cache configured: 100MB persistent cache")
    }

    // MARK: - URL Handling for Firebase Phone Auth (reCAPTCHA)

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle Firebase Auth URL (for reCAPTCHA verification)
        if Auth.auth().canHandle(url) {
            debugLog("✅ [AppDelegate] Firebase Auth handled URL: \(url.scheme ?? "unknown")")
            return true
        }
        return false
    }

    // MARK: - Universal Links Handling

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        // Handle Universal Links
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        debugLog("🔗 [AppDelegate] Universal Link received: \(url.absoluteString)")
        return DeepLinkManager.shared.handleURL(url)
    }

    // MARK: - Push Notification Setup

    private func setupPushNotifications(application: UIApplication) {
        // Set delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Request notification permission
        requestNotificationPermission()

        // Register for remote notifications
        application.registerForRemoteNotifications()

        debugLog("📱 [AppDelegate] Push notification setup completed")
    }

    /// Request notification permission from user
    private func requestNotificationPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                debugLog("❌ [AppDelegate] Notification permission error: \(error.localizedDescription)")
                return
            }

            if granted {
                debugLog("✅ [AppDelegate] Notification permission granted")
            } else {
                debugLog("⚠️ [AppDelegate] Notification permission denied")
            }
        }
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        debugLog("📱 [AppDelegate] APNs token received: \(tokenString.prefix(20))...")

        // Pass the APNs token to Firebase Auth (for Phone Authentication)
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)

        // Pass the APNs token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Handle Firebase Auth notifications (for phone auth verification)
        if Auth.auth().canHandleNotification(userInfo) {
            debugLog("✅ [AppDelegate] Firebase Auth handled notification")
            completionHandler(.noData)
            return
        }

        // Handle other notifications
        debugLog("📩 [AppDelegate] Remote notification received: \(userInfo)")
        completionHandler(.newData)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        debugLog("❌ [AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        debugLog("📩 [AppDelegate] Foreground notification received: \(userInfo)")

        // Show notification banner even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        debugLog("👆 [AppDelegate] Notification tapped: \(userInfo)")

        // Handle notification tap navigation
        handleNotificationTap(userInfo: userInfo)

        completionHandler()
    }

    /// Handle notification tap and navigate to appropriate screen
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else {
            debugLog("⚠️ [AppDelegate] Notification type not found")
            return
        }

        debugLog("🔗 [AppDelegate] Handling notification type: \(type)")

        // Post notification for navigation
        // Views can observe this to navigate appropriately
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .pushNotificationTapped,
                object: nil,
                userInfo: userInfo
            )
        }
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {

    /// Called when FCM token is received or refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            debugLog("⚠️ [AppDelegate] FCM token is nil")
            return
        }

        debugLog("🔑 [AppDelegate] FCM token received: \(token.prefix(20))...")

        // Register token with server
        Task {
            await PushNotificationManager.shared.registerToken(token)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
}
