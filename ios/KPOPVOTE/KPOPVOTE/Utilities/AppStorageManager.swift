//
//  AppStorageManager.swift
//  OSHI Pick
//
//  OSHI Pick - App Storage Manager
//

import Foundation

class AppStorageManager {
    static let shared = AppStorageManager()

    private let userDefaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isGuestMode = "isGuestMode"
        static let lastAuthenticatedUserId = "lastAuthenticatedUserId"
        static let pendingBiasIds = "pendingBiasIds"
        static let pendingGroupIds = "pendingGroupIds"
    }

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool {
        get {
            userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }

    // MARK: - Guest Mode
    var isGuestMode: Bool {
        get {
            userDefaults.bool(forKey: Keys.isGuestMode)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.isGuestMode)
        }
    }

    // MARK: - Last Authenticated User
    var lastAuthenticatedUserId: String? {
        get {
            userDefaults.string(forKey: Keys.lastAuthenticatedUserId)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.lastAuthenticatedUserId)
        }
    }

    // MARK: - Pending Bias (チュートリアル中の一時保存)
    var pendingBiasIds: [String]? {
        get {
            userDefaults.stringArray(forKey: Keys.pendingBiasIds)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.pendingBiasIds)
        }
    }

    var pendingGroupIds: [String]? {
        get {
            userDefaults.stringArray(forKey: Keys.pendingGroupIds)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.pendingGroupIds)
        }
    }

    func clearPendingBias() {
        userDefaults.removeObject(forKey: Keys.pendingBiasIds)
        userDefaults.removeObject(forKey: Keys.pendingGroupIds)
    }

    // MARK: - Reset
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }

    func clearAllData() {
        userDefaults.removeObject(forKey: Keys.hasCompletedOnboarding)
        userDefaults.removeObject(forKey: Keys.isGuestMode)
        userDefaults.removeObject(forKey: Keys.lastAuthenticatedUserId)
        userDefaults.removeObject(forKey: Keys.pendingBiasIds)
        userDefaults.removeObject(forKey: Keys.pendingGroupIds)
    }
}
