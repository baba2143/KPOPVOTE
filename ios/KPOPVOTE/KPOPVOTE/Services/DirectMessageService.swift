//
//  DirectMessageService.swift
//  OSHI Pick
//
//  OSHI Pick - Direct Message Service
//

import Foundation
import FirebaseAuth

class DirectMessageService {
    static let shared = DirectMessageService()

    private init() {}

    // MARK: - Get Conversations
    /// Fetch user's conversation list
    /// - Parameters:
    ///   - limit: Number of conversations to fetch
    ///   - lastConversationId: Last conversation ID for pagination
    /// - Returns: Conversations response with array and metadata
    func fetchConversations(limit: Int = 20, lastConversationId: String? = nil) async throws -> ConversationsResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw DirectMessageError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getConversations)!
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        if let lastConversationId = lastConversationId {
            queryItems.append(URLQueryItem(name: "lastConversationId", value: lastConversationId))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("💬 [DMService] Fetching conversations")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectMessageError.invalidResponse
        }

        debugLog("📥 [DMService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [DMService] Error: \(errorString)")
            }
            throw DirectMessageError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(ConversationsAPIResponse.self, from: data)
        debugLog("✅ [DMService] Fetched \(result.data.conversations.count) conversations")

        return result.data
    }

    // MARK: - Get Messages
    /// Fetch messages for a conversation
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - limit: Number of messages to fetch
    ///   - lastMessageId: Last message ID for pagination
    /// - Returns: Messages response with array and metadata
    func fetchMessages(conversationId: String, limit: Int = 50, lastMessageId: String? = nil) async throws -> MessagesResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw DirectMessageError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getMessages)!
        var queryItems = [
            URLQueryItem(name: "conversationId", value: conversationId),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        if let lastMessageId = lastMessageId {
            queryItems.append(URLQueryItem(name: "lastMessageId", value: lastMessageId))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("💬 [DMService] Fetching messages for conversation: \(conversationId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectMessageError.invalidResponse
        }

        debugLog("📥 [DMService] HTTP Status: \(httpResponse.statusCode)")

        // 404 means conversation doesn't exist yet (new conversation)
        if httpResponse.statusCode == 404 {
            debugLog("ℹ️ [DMService] Conversation not found (new conversation)")
            throw DirectMessageError.conversationNotFound
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [DMService] Error: \(errorString)")
            }
            throw DirectMessageError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(MessagesAPIResponse.self, from: data)
        debugLog("✅ [DMService] Fetched \(result.data.messages.count) messages")

        return result.data
    }

    // MARK: - Send Message
    /// Send a direct message to another user
    /// - Parameters:
    ///   - recipientId: Recipient user ID
    ///   - text: Message text (optional if imageURL provided)
    ///   - imageURL: Image URL (optional if text provided)
    /// - Returns: Send message response
    func sendMessage(recipientId: String, text: String? = nil, imageURL: String? = nil) async throws -> SendMessageResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw DirectMessageError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.sendDirectMessage) else {
            throw DirectMessageError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var requestBody: [String: Any] = ["recipientId": recipientId]
        if let text = text {
            requestBody["text"] = text
        }
        if let imageURL = imageURL {
            requestBody["imageURL"] = imageURL
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        debugLog("💬 [DMService] Sending message to: \(recipientId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectMessageError.invalidResponse
        }

        debugLog("📥 [DMService] HTTP Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode == 403 {
            throw DirectMessageError.mutualFollowRequired
        }

        guard httpResponse.statusCode == 201 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [DMService] Error: \(errorString)")
            }
            throw DirectMessageError.sendFailed
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(SendMessageAPIResponse.self, from: data)
        debugLog("✅ [DMService] Message sent successfully: \(result.data.messageId)")

        return result.data
    }

    // MARK: - Mark As Read
    /// Mark all messages in a conversation as read
    /// - Parameter conversationId: Conversation ID
    func markAsRead(conversationId: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw DirectMessageError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.markAsRead) else {
            throw DirectMessageError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["conversationId": conversationId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        debugLog("💬 [DMService] Marking conversation as read: \(conversationId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DirectMessageError.invalidResponse
        }

        debugLog("📥 [DMService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [DMService] Error: \(errorString)")
            }
            throw DirectMessageError.markReadFailed
        }

        debugLog("✅ [DMService] Conversation marked as read")
    }

    // MARK: - Check Mutual Follow
    /// Check if current user and target user mutually follow each other
    /// - Parameter userId: Target user ID
    /// - Returns: True if mutual follow exists
    func checkMutualFollow(userId: String) async throws -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw DirectMessageError.notAuthenticated
        }

        let followService = FollowService.shared

        // Check if we follow them
        let (following, _) = try await followService.fetchFollowing(limit: 1000)
        let weFollowThem = following.contains { $0.userId == userId }

        if !weFollowThem {
            return false
        }

        // Check if they follow us
        let (followers, _) = try await followService.fetchFollowers(limit: 1000)
        let theyFollowUs = followers.contains { $0.userId == userId }

        return theyFollowUs
    }
}

// MARK: - Error Types
enum DirectMessageError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case fetchFailed
    case sendFailed
    case markReadFailed
    case mutualFollowRequired
    case conversationNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログインが必要です"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .fetchFailed:
            return "メッセージの取得に失敗しました"
        case .sendFailed:
            return "メッセージの送信に失敗しました"
        case .markReadFailed:
            return "既読処理に失敗しました"
        case .mutualFollowRequired:
            return "相互フォローのユーザーにのみDMを送信できます"
        case .conversationNotFound:
            return nil  // Not an error, just a new conversation
        }
    }
}

// MARK: - API Response Models
struct ConversationsAPIResponse: Codable {
    let success: Bool
    let data: ConversationsResponse
}

struct MessagesAPIResponse: Codable {
    let success: Bool
    let data: MessagesResponse
}

struct SendMessageAPIResponse: Codable {
    let success: Bool
    let data: SendMessageResponse
}
