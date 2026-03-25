//
//  GroupMaster.swift
//  OSHI Pick
//
//  OSHI Pick - Group Master Model
//

import Foundation

struct GroupMaster: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let imageUrl: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "groupId"
        case name
        case imageUrl
        case createdAt
        case updatedAt
    }

    // ISO8601 date handling for API response
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)

        // Handle ISO8601 date strings from API
        if let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            let formatter = ISO8601DateFormatter()
            createdAt = formatter.date(from: dateString)
        } else {
            createdAt = nil
        }

        if let dateString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            let formatter = ISO8601DateFormatter()
            updatedAt = formatter.date(from: dateString)
        } else {
            updatedAt = nil
        }
    }

    // Manual initializer for testing
    init(
        id: String,
        name: String,
        imageUrl: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - GroupMaster Extension
extension GroupMaster {
    var hasImage: Bool {
        imageUrl != nil && !(imageUrl?.isEmpty ?? true)
    }
}
