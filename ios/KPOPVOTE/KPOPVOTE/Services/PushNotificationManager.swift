//
//  PushNotificationManager.swift
//  OSHI Pick
//
//  OSHI Pick - FCM Token Management
//

import Foundation
import UIKit

/// Manages FCM token registration and unregistration with the server
class PushNotificationManager {
    static let shared = PushNotificationManager()

    private let deviceIdKey = "fcm_device_id"
    private var currentToken: String?

    private init() {}

    // MARK: - Device ID Management

    /// Get or create a unique device ID
    private var deviceId: String {
        if let existingId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return existingId
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }

    // MARK: - Token Registration

    /// Register FCM token with the server
    /// - Parameter token: The FCM token to register
    func registerToken(_ token: String) async {
        currentToken = token

        // Only register if user is logged in
        guard let authToken = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.authToken) else {
            debugLog("📱 [PushNotificationManager] User not logged in, skipping token registration")
            return
        }

        do {
            let url = URL(string: Constants.API.registerFcmToken)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "token": token,
                "deviceId": deviceId,
                "platform": "ios"
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                debugLog("❌ [PushNotificationManager] Invalid response")
                return
            }

            if httpResponse.statusCode == 200 {
                debugLog("✅ [PushNotificationManager] Token registered successfully")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                debugLog("❌ [PushNotificationManager] Token registration failed: \(httpResponse.statusCode) - \(errorMessage)")
            }
        } catch {
            debugLog("❌ [PushNotificationManager] Token registration error: \(error.localizedDescription)")
        }
    }

    /// Unregister FCM token from the server (call on logout)
    func unregisterToken() async {
        guard let authToken = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.authToken) else {
            debugLog("📱 [PushNotificationManager] No auth token, skipping token unregistration")
            return
        }

        do {
            let url = URL(string: Constants.API.unregisterFcmToken)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "deviceId": deviceId
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                debugLog("❌ [PushNotificationManager] Invalid response")
                return
            }

            if httpResponse.statusCode == 200 {
                debugLog("✅ [PushNotificationManager] Token unregistered successfully")
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                debugLog("❌ [PushNotificationManager] Token unregistration failed: \(httpResponse.statusCode) - \(errorMessage)")
            }
        } catch {
            debugLog("❌ [PushNotificationManager] Token unregistration error: \(error.localizedDescription)")
        }

        currentToken = nil
    }

    // MARK: - User Login/Logout Handlers

    /// Called when user logs in - register current token if available
    func onUserLogin() {
        debugLog("📱 [PushNotificationManager] User logged in, checking for pending token registration")

        if let token = currentToken {
            Task {
                await registerToken(token)
            }
        }
    }

    /// Called when user logs out - unregister token
    func onUserLogout() {
        debugLog("📱 [PushNotificationManager] User logging out, unregistering token")

        Task {
            await unregisterToken()
        }
    }
}
