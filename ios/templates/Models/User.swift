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
    var points: Int
    var isSuspended: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "uid"
        case email
        case displayName
        case points
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
        points = try container.decode(Int.self, forKey: .points)
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
    init(id: String, email: String, displayName: String? = nil, points: Int = 0, isSuspended: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.points = points
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
