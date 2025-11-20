//
//  User.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - User Model
//

import Foundation

struct User: Codable, Identifiable {
    let id: String // Firebase UID
    let email: String
    var displayName: String?
    var photoURL: String?
    var bio: String?
    var points: Int
    var biasIds: [String]
    var followingCount: Int
    var followersCount: Int
    var postsCount: Int
    var isPrivate: Bool
    var isSuspended: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case email
        case displayName
        case photoURL
        case bio
        case points
        case biasIds
        case followingCount
        case followersCount
        case postsCount
        case isPrivate
        case isSuspended
        case createdAt
        case updatedAt
    }

    // Firestore Date conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        points = try container.decode(Int.self, forKey: .points)
        biasIds = try container.decodeIfPresent([String].self, forKey: .biasIds) ?? []
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount) ?? 0
        postsCount = try container.decodeIfPresent(Int.self, forKey: .postsCount) ?? 0
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        isSuspended = try container.decode(Bool.self, forKey: .isSuspended)

        // Handle Firestore Timestamp
        if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            createdAt = Date()
        }

        if let timestamp = try? container.decode(Double.self, forKey: .updatedAt) {
            updatedAt = Date(timeIntervalSince1970: timestamp)
        } else {
            updatedAt = Date()
        }
    }

    // Default initializer
    init(id: String, email: String, displayName: String? = nil, photoURL: String? = nil, bio: String? = nil, points: Int = 0, biasIds: [String] = [], followingCount: Int = 0, followersCount: Int = 0, postsCount: Int = 0, isPrivate: Bool = false, isSuspended: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.bio = bio
        self.points = points
        self.biasIds = biasIds
        self.followingCount = followingCount
        self.followersCount = followersCount
        self.postsCount = postsCount
        self.isPrivate = isPrivate
        self.isSuspended = isSuspended
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - User Profile Extension
extension User {
    var isActive: Bool {
        return !isSuspended
    }

    var formattedPoints: String {
        return "\(points)pt"
    }

    var displayNameOrEmail: String {
        return displayName ?? email.components(separatedBy: "@").first ?? email
    }
}
