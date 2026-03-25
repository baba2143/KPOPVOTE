//
//  DirectMessage.swift
//  OSHI Pick
//
//  OSHI Pick - Direct Message Model
//

import Foundation

// MARK: - Direct Message
struct DirectMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: String
    let senderName: String?
    let senderPhotoURL: String?
    let text: String?
    let imageURL: String?
    let isRead: Bool
    let createdAt: Date

    // Custom coding keys for API response mapping
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId
        case senderId
        case senderName
        case senderPhotoURL
        case text
        case imageURL
        case isRead
        case createdAt
    }

    // Custom date decoding from ISO8601 string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        senderId = try container.decode(String.self, forKey: .senderId)
        senderName = try container.decodeIfPresent(String.self, forKey: .senderName)
        senderPhotoURL = try container.decodeIfPresent(String.self, forKey: .senderPhotoURL)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false

        // Decode date - try both Date and String (ISO8601)
        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? Date()
        } else {
            createdAt = Date()
        }
    }

    // Manual initializer
    init(id: String, conversationId: String, senderId: String, senderName: String?, senderPhotoURL: String?, text: String?, imageURL: String?, isRead: Bool, createdAt: Date) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderName = senderName
        self.senderPhotoURL = senderPhotoURL
        self.text = text
        self.imageURL = imageURL
        self.isRead = isRead
        self.createdAt = createdAt
    }
}

// MARK: - Messages Response
struct MessagesResponse: Codable {
    let messages: [DirectMessage]
    let hasMore: Bool
}

// MARK: - Send Message Response
struct SendMessageResponse: Codable {
    let messageId: String
    let conversationId: String
    let createdAt: String
}
