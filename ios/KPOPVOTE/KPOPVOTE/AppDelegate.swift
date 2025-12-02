//
//  AppDelegate.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Push Notification Handling
//

import UIKit
import UserNotifications
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Application Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set up push notifications
        setupPushNotifications(application: application)

        return true
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

        print("📱 [AppDelegate] Push notification setup completed")
    }

    /// Request notification permission from user
    private func requestNotificationPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]

        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("❌ [AppDelegate] Notification permission error: \(error.localizedDescription)")
                return
            }

            if granted {
                print("✅ [AppDelegate] Notification permission granted")
            } else {
                print("⚠️ [AppDelegate] Notification permission denied")
            }
        }
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 [AppDelegate] APNs token received: \(tokenString.prefix(20))...")

        // Pass the APNs token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ [AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
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
        print("📩 [AppDelegate] Foreground notification received: \(userInfo)")

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
        print("👆 [AppDelegate] Notification tapped: \(userInfo)")

        // Handle notification tap navigation
        handleNotificationTap(userInfo: userInfo)

        completionHandler()
    }

    /// Handle notification tap and navigate to appropriate screen
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else {
            print("⚠️ [AppDelegate] Notification type not found")
            return
        }

        print("🔗 [AppDelegate] Handling notification type: \(type)")

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
            print("⚠️ [AppDelegate] FCM token is nil")
            return
        }

        print("🔑 [AppDelegate] FCM token received: \(token.prefix(20))...")

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
