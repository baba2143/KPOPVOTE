//
//  Bias.swift
//  OSHI Pick
//
//  OSHI Pick - Bias (推し) Model
//

import Foundation

struct Bias: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    var group: String?
    var imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id = "biasId"
        case name
        case group
        case imageUrl
    }

    init(id: String = UUID().uuidString, name: String, group: String? = nil, imageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.group = group
        self.imageUrl = imageUrl
    }
}

// MARK: - Bias Extension
extension Bias {
    var displayName: String {
        if let group = group {
            return "\(name) (\(group))"
        }
        return name
    }

    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1))
        }
        return String(name.prefix(2))
    }
}

// MARK: - User Bias Settings (Legacy)
struct UserBiasSettings: Codable {
    var biases: [Bias]
    var updatedAt: Date

    init(biases: [Bias] = []) {
        self.biases = biases
        self.updatedAt = Date()
    }
}

// MARK: - Bias Settings (API Model)
struct BiasSettings: Codable, Hashable {
    let artistId: String
    let artistName: String
    let memberIds: [String]
    let memberNames: [String]
    let isGroupLevel: Bool

    init(artistId: String, artistName: String, memberIds: [String], memberNames: [String], isGroupLevel: Bool = false) {
        self.artistId = artistId
        self.artistName = artistName
        self.memberIds = memberIds
        self.memberNames = memberNames
        self.isGroupLevel = isGroupLevel
    }

    // Custom decoder to handle missing isGroupLevel from existing data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        artistId = try container.decode(String.self, forKey: .artistId)
        artistName = try container.decode(String.self, forKey: .artistName)
        memberIds = try container.decode([String].self, forKey: .memberIds)
        memberNames = try container.decode([String].self, forKey: .memberNames)
        isGroupLevel = try container.decodeIfPresent(Bool.self, forKey: .isGroupLevel) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case artistId
        case artistName
        case memberIds
        case memberNames
        case isGroupLevel
    }
}

// MARK: - BiasSettings Extension
extension BiasSettings {
    var displayMembers: String {
        memberNames.joined(separator: ", ")
    }

    var memberCount: Int {
        memberNames.count
    }
}
