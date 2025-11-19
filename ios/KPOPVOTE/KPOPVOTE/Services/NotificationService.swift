//
//  NotificationService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Notification Service
//

import Foundation
import FirebaseAuth

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Get Notifications
    /// Fetch notifications list
    /// - Parameters:
    ///   - unreadOnly: Fetch only unread notifications
    ///   - limit: Number of notifications to fetch
    ///   - lastNotificationId: Last notification ID for pagination
    /// - Returns: Array of notifications, hasMore flag, and unread count
    func fetchNotifications(unreadOnly: Bool = false, limit: Int = 20, lastNotificationId: String? = nil) async throws -> (notifications: [AppNotification], hasMore: Bool, unreadCount: Int) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw NotificationError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getNotifications)!
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        if unreadOnly {
            queryItems.append(URLQueryItem(name: "unreadOnly", value: "true"))
        }

        if let lastNotificationId = lastNotificationId {
            queryItems.append(URLQueryItem(name: "lastNotificationId", value: lastNotificationId))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔔 [NotificationService] Fetching notifications: unreadOnly=\(unreadOnly)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotificationError.invalidResponse
        }

        print("📥 [NotificationService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [NotificationService] Error: \(errorString)")
            }
            throw NotificationError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(NotificationListResponse.self, from: data)
        print("✅ [NotificationService] Fetched \(result.data.notifications.count) notifications")

        return (result.data.notifications, result.data.hasMore, result.data.unreadCount)
    }

    // MARK: - Mark as Read
    /// Mark a notification as read
    /// - Parameter notificationId: Notification ID
    func markAsRead(notificationId: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw NotificationError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.markNotificationAsRead) else {
            throw NotificationError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["notificationId": notificationId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("📖 [NotificationService] Marking notification as read: \(notificationId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotificationError.invalidResponse
        }

        print("📥 [NotificationService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [NotificationService] Error: \(errorString)")
            }
            throw NotificationError.markAsReadFailed
        }

        print("✅ [NotificationService] Notification marked as read")
    }

    // MARK: - Mark All as Read
    /// Mark all notifications as read
    func markAllAsRead() async throws -> Int {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw NotificationError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.markNotificationAsRead) else {
            throw NotificationError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["markAll": true]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("📖 [NotificationService] Marking all notifications as read")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotificationError.invalidResponse
        }

        print("📥 [NotificationService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [NotificationService] Error: \(errorString)")
            }
            throw NotificationError.markAsReadFailed
        }

        let result = try JSONDecoder().decode(MarkAllAsReadResponse.self, from: data)
        print("✅ [NotificationService] Marked \(result.data.count) notifications as read")

        return result.data.count
    }

    // MARK: - Get My Votes
    /// Fetch my votes history
    /// - Parameters:
    ///   - status: Filter by status (all, active, ended)
    ///   - sort: Sort order (date, points)
    ///   - limit: Number of votes to fetch
    ///   - lastVoteHistoryId: Last vote history ID for pagination
    /// - Returns: Array of vote history, hasMore flag, and summary stats
    func fetchMyVotes(status: String = "all", sort: String = "date", limit: Int = 20, lastVoteHistoryId: String? = nil) async throws -> (voteHistory: [VoteHistory], hasMore: Bool, summary: NotificationVoteSummary) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw NotificationError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getMyVotes)!
        var queryItems = [
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        if let lastVoteHistoryId = lastVoteHistoryId {
            queryItems.append(URLQueryItem(name: "lastVoteHistoryId", value: lastVoteHistoryId))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🗳️ [NotificationService] Fetching my votes: status=\(status), sort=\(sort)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotificationError.invalidResponse
        }

        print("📥 [NotificationService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [NotificationService] Error: \(errorString)")
            }
            throw NotificationError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(NotificationMyVotesResponse.self, from: data)
        print("✅ [NotificationService] Fetched \(result.data.voteHistory.count) vote history items")

        return (result.data.voteHistory, result.data.hasMore, result.data.summary)
    }
}

// MARK: - Response Models
struct NotificationListResponse: Codable {
    let success: Bool
    let data: NotificationListData
}

struct NotificationListData: Codable {
    let notifications: [AppNotification]
    let hasMore: Bool
    let unreadCount: Int
}

struct MarkAsReadResponse: Codable {
    let success: Bool
    let data: MarkAsReadData
}

struct MarkAsReadData: Codable {
    let message: String
    let notificationId: String
}

struct MarkAllAsReadResponse: Codable {
    let success: Bool
    let data: MarkAllAsReadData
}

struct MarkAllAsReadData: Codable {
    let message: String
    let count: Int
}

struct NotificationMyVotesResponse: Codable {
    let success: Bool
    let data: NotificationMyVotesData
}

struct NotificationMyVotesData: Codable {
    let voteHistory: [VoteHistory]
    let hasMore: Bool
    let summary: NotificationVoteSummary
}

struct NotificationVoteSummary: Codable {
    let totalVotes: Int
    let totalPointsUsed: Int
}
