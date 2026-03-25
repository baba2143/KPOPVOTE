//
//  Notification.swift
//  OSHI Pick
//
//  OSHI Pick - Notification Model
//

import Foundation

// MARK: - Notification Type
enum NotificationType: String, Codable {
    case follow = "follow"
    case like = "like"
    case comment = "comment"
    case mention = "mention"
    case vote = "vote"
    case system = "system"
    case sameBiasFans = "sameBiasFans"

    var displayName: String {
        switch self {
        case .follow:
            return "フォロー"
        case .like:
            return "いいね"
        case .comment:
            return "コメント"
        case .mention:
            return "メンション"
        case .vote:
            return "投票"
        case .system:
            return "システム"
        case .sameBiasFans:
            return "同じ推しファン"
        }
    }

    var icon: String {
        switch self {
        case .follow:
            return "person.badge.plus"
        case .like:
            return "heart.fill"
        case .comment:
            return "message.fill"
        case .mention:
            return "at"
        case .vote:
            return "checkmark.circle.fill"
        case .system:
            return "bell.fill"
        case .sameBiasFans:
            return "person.2.fill"
        }
    }
}

// MARK: - Notification
struct AppNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let type: NotificationType
    var title: String
    var body: String
    var isRead: Bool
    var actionUserId: String? // Who performed the action
    var actionUserDisplayName: String?
    var actionUserPhotoURL: String?
    var relatedPostId: String?
    var relatedVoteId: String?
    var relatedCommentId: String?
    var relatedBiasId: String?
    var relatedBiasType: String?
    var relatedBiasName: String?
    var newUserCount: Int?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case title
        case body
        case isRead
        case actionUserId
        case actionUserDisplayName
        case actionUserPhotoURL
        case relatedPostId
        case relatedVoteId
        case relatedCommentId
        case relatedBiasId
        case relatedBiasType
        case relatedBiasName
        case newUserCount
        case createdAt
    }

    init(id: String = UUID().uuidString, userId: String, type: NotificationType, title: String, body: String, isRead: Bool = false, actionUserId: String? = nil, actionUserDisplayName: String? = nil, actionUserPhotoURL: String? = nil, relatedPostId: String? = nil, relatedVoteId: String? = nil, relatedCommentId: String? = nil, relatedBiasId: String? = nil, relatedBiasType: String? = nil, relatedBiasName: String? = nil, newUserCount: Int? = nil) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.isRead = isRead
        self.actionUserId = actionUserId
        self.actionUserDisplayName = actionUserDisplayName
        self.actionUserPhotoURL = actionUserPhotoURL
        self.relatedPostId = relatedPostId
        self.relatedVoteId = relatedVoteId
        self.relatedCommentId = relatedCommentId
        self.relatedBiasId = relatedBiasId
        self.relatedBiasType = relatedBiasType
        self.relatedBiasName = relatedBiasName
        self.newUserCount = newUserCount
        self.createdAt = Date()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        type = try container.decode(NotificationType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        actionUserId = try container.decodeIfPresent(String.self, forKey: .actionUserId)
        actionUserDisplayName = try container.decodeIfPresent(String.self, forKey: .actionUserDisplayName)
        actionUserPhotoURL = try container.decodeIfPresent(String.self, forKey: .actionUserPhotoURL)
        relatedPostId = try container.decodeIfPresent(String.self, forKey: .relatedPostId)
        relatedVoteId = try container.decodeIfPresent(String.self, forKey: .relatedVoteId)
        relatedCommentId = try container.decodeIfPresent(String.self, forKey: .relatedCommentId)
        relatedBiasId = try container.decodeIfPresent(String.self, forKey: .relatedBiasId)
        relatedBiasType = try container.decodeIfPresent(String.self, forKey: .relatedBiasType)
        relatedBiasName = try container.decodeIfPresent(String.self, forKey: .relatedBiasName)
        newUserCount = try container.decodeIfPresent(Int.self, forKey: .newUserCount)

        if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            createdAt = Date()
        }
    }
}

// MARK: - Notification Extension
extension AppNotification {
    var formattedCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var isRecent: Bool {
        let hoursSinceCreation = Date().timeIntervalSince(createdAt) / 3600
        return hoursSinceCreation < 24
    }

    var displayTitle: String {
        if let actionUserName = actionUserDisplayName {
            return "\(actionUserName) \(title)"
        }
        return title
    }
}
