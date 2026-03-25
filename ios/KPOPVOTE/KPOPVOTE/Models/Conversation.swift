//
//  Conversation.swift
//  OSHI Pick
//
//  OSHI Pick - Conversation Model
//

import Foundation

// MARK: - Conversation
struct Conversation: Codable, Identifiable {
    let id: String
    let participantId: String
    let participantName: String?
    let participantPhotoURL: String?
    let lastMessage: String?
    let lastMessageAt: Date?
    let unreadCount: Int
    let updatedAt: Date

    // Custom coding keys for API response mapping
    enum CodingKeys: String, CodingKey {
        case id
        case participantId
        case participantName
        case participantPhotoURL
        case lastMessage
        case lastMessageAt
        case unreadCount
        case updatedAt
    }

    // Custom date decoding from ISO8601 string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        participantId = try container.decode(String.self, forKey: .participantId)
        participantName = try container.decodeIfPresent(String.self, forKey: .participantName)
        participantPhotoURL = try container.decodeIfPresent(String.self, forKey: .participantPhotoURL)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        unreadCount = try container.decodeIfPresent(Int.self, forKey: .unreadCount) ?? 0

        // Decode lastMessageAt - optional date
        if let dateString = try? container.decode(String.self, forKey: .lastMessageAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            lastMessageAt = formatter.date(from: dateString)
        } else if let date = try? container.decode(Date.self, forKey: .lastMessageAt) {
            lastMessageAt = date
        } else {
            lastMessageAt = nil
        }

        // Decode updatedAt
        if let date = try? container.decode(Date.self, forKey: .updatedAt) {
            updatedAt = date
        } else if let dateString = try? container.decode(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            updatedAt = formatter.date(from: dateString) ?? Date()
        } else {
            updatedAt = Date()
        }
    }

    // Manual initializer
    init(id: String, participantId: String, participantName: String?, participantPhotoURL: String?, lastMessage: String?, lastMessageAt: Date?, unreadCount: Int, updatedAt: Date) {
        self.id = id
        self.participantId = participantId
        self.participantName = participantName
        self.participantPhotoURL = participantPhotoURL
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.updatedAt = updatedAt
    }
}

// MARK: - Conversations Response
struct ConversationsResponse: Codable {
    let conversations: [Conversation]
    let hasMore: Bool
    let totalUnreadCount: Int
}
