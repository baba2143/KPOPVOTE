//
//  Bias.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Bias (推し) Model
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

    init(artistId: String, artistName: String, memberIds: [String], memberNames: [String]) {
        self.artistId = artistId
        self.artistName = artistName
        self.memberIds = memberIds
        self.memberNames = memberNames
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
