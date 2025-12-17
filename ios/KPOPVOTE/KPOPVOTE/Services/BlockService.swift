//
//  BlockService.swift
//  OSHI Pick
//
//  OSHI Pick - Block Service
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class BlockService: ObservableObject {
    static let shared = BlockService()

    private let db = Firestore.firestore()

    @Published var blockedUserIds: Set<String> = []
    @Published var isLoading = false

    private init() {}

    // MARK: - Load Blocked Users
    /// Load blocked users for the current user
    func loadBlockedUsers() async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            debugLog("🚫 [BlockService] Not authenticated")
            return
        }

        debugLog("📥 [BlockService] Loading blocked users for: \(currentUserId)")

        let snapshot = try await db.collection("users")
            .document(currentUserId)
            .collection("blockedUsers")
            .getDocuments()

        let ids = Set(snapshot.documents.map { $0.documentID })

        await MainActor.run {
            self.blockedUserIds = ids
        }

        debugLog("✅ [BlockService] Loaded \(ids.count) blocked users")
    }

    // MARK: - Block User
    /// Block a user
    /// - Parameter userId: User ID to block
    func blockUser(userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw CommunityError.notAuthenticated
        }

        guard userId != currentUserId else {
            debugLog("⚠️ [BlockService] Cannot block yourself")
            return
        }

        debugLog("🚫 [BlockService] Blocking user: \(userId)")

        let blockedUserRef = db.collection("users")
            .document(currentUserId)
            .collection("blockedUsers")
            .document(userId)

        try await blockedUserRef.setData([
            "blockedAt": FieldValue.serverTimestamp(),
            "blockedUserId": userId
        ])

        // Also unfollow the user if following
        try? await FollowService.shared.unfollowUser(userId: userId)

        // Auto-report to developers (Apple App Store requirement)
        try await reportBlockedUser(userId: userId, reporterId: currentUserId)

        await MainActor.run {
            self.blockedUserIds.insert(userId)
            // Post notification for instant feed update
            NotificationCenter.default.post(
                name: NSNotification.Name("UserBlocked"),
                object: nil,
                userInfo: ["userId": userId]
            )
        }

        debugLog("✅ [BlockService] User blocked successfully")
    }

    // MARK: - Unblock User
    /// Unblock a user
    /// - Parameter userId: User ID to unblock
    func unblockUser(userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw CommunityError.notAuthenticated
        }

        debugLog("✅ [BlockService] Unblocking user: \(userId)")

        let blockedUserRef = db.collection("users")
            .document(currentUserId)
            .collection("blockedUsers")
            .document(userId)

        try await blockedUserRef.delete()

        await MainActor.run {
            self.blockedUserIds.remove(userId)
        }

        debugLog("✅ [BlockService] User unblocked successfully")
    }

    // MARK: - Check if Blocked
    /// Check if a user is blocked
    /// - Parameter userId: User ID to check
    /// - Returns: True if blocked
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUserIds.contains(userId)
    }

    // MARK: - Get Blocked Users List
    /// Get the list of blocked users with details
    /// - Returns: Array of BlockedUser
    func getBlockedUsersList() async throws -> [BlockedUser] {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw CommunityError.notAuthenticated
        }

        debugLog("📥 [BlockService] Fetching blocked users list")

        let snapshot = try await db.collection("users")
            .document(currentUserId)
            .collection("blockedUsers")
            .getDocuments()

        var blockedUsers: [BlockedUser] = []

        for doc in snapshot.documents {
            let blockedUserId = doc.documentID

            // Get user details
            let userDoc = try? await db.collection("users").document(blockedUserId).getDocument()

            let displayName = userDoc?.data()?["displayName"] as? String ?? "Unknown"
            let photoURL = userDoc?.data()?["photoURL"] as? String
            let blockedAt = (doc.data()["blockedAt"] as? Timestamp)?.dateValue() ?? Date()

            blockedUsers.append(BlockedUser(
                id: blockedUserId,
                userId: blockedUserId,
                displayName: displayName,
                photoURL: photoURL,
                blockedAt: blockedAt
            ))
        }

        // Sort by blockedAt descending (newest first) in Swift instead of Firestore
        // to avoid needing a Firestore index
        blockedUsers.sort { $0.blockedAt > $1.blockedAt }

        debugLog("✅ [BlockService] Fetched \(blockedUsers.count) blocked users")

        return blockedUsers
    }

    // MARK: - Auto-Report Blocked User (Apple Requirement)
    /// Automatically report blocked user to developers
    /// This satisfies Apple's requirement: "Blocking should also notify the developer of the inappropriate content"
    private func reportBlockedUser(userId: String, reporterId: String) async throws {
        debugLog("📝 [BlockService] Auto-reporting blocked user to developers")

        let reportData: [String: Any] = [
            "type": "user_block",
            "reporterId": reporterId,
            "reportedUserId": userId,
            "reason": "User blocked by another user (auto-report)",
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("blockReports").addDocument(data: reportData)
        debugLog("✅ [BlockService] Block report sent to developers")
    }

    // MARK: - Clear Cache
    /// Clear the blocked users cache (on logout)
    func clearCache() {
        blockedUserIds = []
        debugLog("🗑️ [BlockService] Cache cleared")
    }
}

// MARK: - Blocked User Model
struct BlockedUser: Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let photoURL: String?
    let blockedAt: Date
}
