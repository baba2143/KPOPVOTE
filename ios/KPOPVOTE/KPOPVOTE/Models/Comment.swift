//
//  Comment.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Comment Model
//

import Foundation

// MARK: - Comment User
struct CommentUser: Codable {
    let displayName: String?
    let photoURL: String?
}

// MARK: - Comment
struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    let text: String
    let createdAt: Date
    let updatedAt: Date
    let user: CommentUser

    // Custom coding keys for API response mapping
    enum CodingKeys: String, CodingKey {
        case id
        case postId
        case userId
        case text
        case createdAt
        case updatedAt
        case user
    }

    // Custom date decoding from ISO8601 string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        postId = try container.decode(String.self, forKey: .postId)
        userId = try container.decode(String.self, forKey: .userId)
        text = try container.decode(String.self, forKey: .text)
        user = try container.decode(CommentUser.self, forKey: .user)

        // Decode dates - try both Date and String (ISO8601)
        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            createdAt = formatter.date(from: dateString) ?? Date()
        } else {
            createdAt = Date()
        }

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

    // Manual initializer for testing
    init(id: String, postId: String, userId: String, text: String, createdAt: Date, updatedAt: Date, user: CommentUser) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.user = user
    }
}

// MARK: - Comments Response
struct CommentsResponse: Codable {
    let comments: [Comment]
    let hasMore: Bool
}
