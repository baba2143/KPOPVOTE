//
//  InAppVote.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - In-App Vote Model
//

import Foundation

struct InAppVote: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let choices: [VoteChoice]
    let startDate: Date
    let endDate: Date
    let requiredPoints: Int
    let status: VoteStatus
    let totalVotes: Int
    let coverImageUrl: String?
    let isFeatured: Bool?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "voteId"
        case title
        case description
        case choices
        case startDate
        case endDate
        case requiredPoints
        case status
        case totalVotes
        case coverImageUrl
        case isFeatured
        case createdAt
        case updatedAt
    }

    // Custom decoding for ISO8601 dates
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        choices = try container.decode([VoteChoice].self, forKey: .choices)
        requiredPoints = try container.decode(Int.self, forKey: .requiredPoints)
        status = try container.decode(VoteStatus.self, forKey: .status)
        totalVotes = try container.decode(Int.self, forKey: .totalVotes)
        coverImageUrl = try container.decodeIfPresent(String.self, forKey: .coverImageUrl)
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured)

        // Parse ISO8601 dates
        let formatter = ISO8601DateFormatter()

        if let startDateString = try container.decodeIfPresent(String.self, forKey: .startDate) {
            startDate = formatter.date(from: startDateString) ?? Date()
        } else {
            startDate = Date()
        }

        if let endDateString = try container.decodeIfPresent(String.self, forKey: .endDate) {
            endDate = formatter.date(from: endDateString) ?? Date()
        } else {
            endDate = Date()
        }

        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = formatter.date(from: createdAtString)
        } else {
            createdAt = nil
        }

        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = formatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }

    // Manual initializer for testing
    init(
        id: String,
        title: String,
        description: String,
        choices: [VoteChoice],
        startDate: Date,
        endDate: Date,
        requiredPoints: Int,
        status: VoteStatus,
        totalVotes: Int,
        coverImageUrl: String? = nil,
        isFeatured: Bool? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.choices = choices
        self.startDate = startDate
        self.endDate = endDate
        self.requiredPoints = requiredPoints
        self.status = status
        self.totalVotes = totalVotes
        self.coverImageUrl = coverImageUrl
        self.isFeatured = isFeatured
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - InAppVote Extension
extension InAppVote {
    var isActive: Bool {
        status == .active
    }

    var hasEnded: Bool {
        status == .ended
    }

    var isUpcoming: Bool {
        status == .upcoming
    }

    var formattedPeriod: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var statusDisplayName: String {
        switch status {
        case .upcoming: return "開催前"
        case .active: return "開催中"
        case .ended: return "終了"
        }
    }

    var statusColor: String {
        switch status {
        case .upcoming: return "blue"
        case .active: return "green"
        case .ended: return "gray"
        }
    }
}

// MARK: - VoteChoice
struct VoteChoice: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "choiceId"
        case label
        case voteCount
    }

    init(id: String, label: String, voteCount: Int) {
        self.id = id
        self.label = label
        self.voteCount = voteCount
    }
}

// MARK: - VoteStatus
enum VoteStatus: String, Codable {
    case upcoming
    case active
    case ended

    var displayName: String {
        switch self {
        case .upcoming: return "開催前"
        case .active: return "開催中"
        case .ended: return "終了"
        }
    }
}

// MARK: - VoteRanking
struct VoteRanking: Codable {
    let voteId: String
    let title: String
    let totalVotes: Int
    let ranking: [RankingItem]
}

// MARK: - RankingItem
struct RankingItem: Codable, Identifiable {
    let id: String
    let label: String
    let voteCount: Int
    let percentage: Double

    enum CodingKeys: String, CodingKey {
        case id = "choiceId"
        case label
        case voteCount
        case percentage
    }

    init(id: String, label: String, voteCount: Int, percentage: Double) {
        self.id = id
        self.label = label
        self.voteCount = voteCount
        self.percentage = percentage
    }
}

// MARK: - RankingItem Extension
extension RankingItem {
    var formattedPercentage: String {
        String(format: "%.1f%%", percentage)
    }

    var rank: Int {
        // This will be set by the view model
        0
    }
}
