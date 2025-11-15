//
//  Follow.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Follow Relationship Model
//

import Foundation

struct Follow: Codable, Identifiable {
    let id: String // {followerId}_{followingId}
    let followerId: String
    let followingId: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case followerId
        case followingId
        case createdAt
    }

    init(id: String, followerId: String, followingId: String) {
        self.id = id
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = Date()
    }

    init(followerId: String, followingId: String) {
        self.id = "\(followerId)_\(followingId)"
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = Date()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        followerId = try container.decode(String.self, forKey: .followerId)
        followingId = try container.decode(String.self, forKey: .followingId)

        if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            createdAt = Date()
        }
    }
}

// MARK: - Follow Extension
extension Follow {
    var formattedCreatedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: createdAt)
    }

    var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
