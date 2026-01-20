//
//  IdolRanking.swift
//  KPOPVOTE
//
//  Data models for Idol Ranking feature
//

import Foundation

// MARK: - Enums

enum RankingType: String, Codable, CaseIterable {
    case individual
    case group

    var displayName: String {
        switch self {
        case .individual:
            return "アイドル"
        case .group:
            return "グループ"
        }
    }
}

enum RankingPeriod: String, Codable, CaseIterable {
    case weekly
    case allTime

    var displayName: String {
        switch self {
        case .weekly:
            return "週間"
        case .allTime:
            return "累計"
        }
    }
}

// MARK: - Ranking Entry

struct IdolRankingEntry: Identifiable, Codable, Equatable {
    let rank: Int
    let entityId: String
    let entityType: RankingType
    let name: String
    let groupName: String?
    let imageUrl: String?
    let weeklyVotes: Int
    let totalVotes: Int
    let previousRank: Int?
    let rankChange: Int?

    var id: String { entityId }

    /// Compatibility property for views that use votes
    var votes: Int { weeklyVotes }

    var displayName: String {
        if let groupName = groupName, !groupName.isEmpty {
            return "\(name) (\(groupName))"
        }
        return name
    }

    var rankMedal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}

// MARK: - Vote Detail

struct VoteDetail: Codable, Identifiable {
    let entityId: String
    let entityType: RankingType
    let votedAt: Date

    var id: String { "\(entityId)_\(votedAt.timeIntervalSince1970)" }
}

// MARK: - Daily Limit

struct DailyLimit: Codable {
    let votesUsed: Int
    let maxVotes: Int
    let remainingVotes: Int
    let voteDetails: [VoteDetail]
}

// MARK: - API Responses

struct GetRankingResponse: Codable {
    let rankings: [IdolRankingEntry]
    let total: Int
    let period: RankingPeriod
    let rankingType: RankingType
    let lastUpdated: String?
}

struct VoteResponse: Codable {
    let success: Bool
    let remainingVotes: Int
    let totalVotes: Int
}

struct DailyLimitResponse: Codable {
    let votesUsed: Int
    let maxVotes: Int
    let remainingVotes: Int
    let voteDetails: [VoteDetail]
}

// MARK: - API Request

struct VoteRequest: Codable {
    let entityId: String
    let entityType: RankingType
    let name: String
    let groupName: String?
    let imageUrl: String?
}

// MARK: - Generic API Response

struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}
