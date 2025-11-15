//
//  VoteHistory.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote History Model
//

import Foundation

struct VoteHistory: Codable, Identifiable {
    let id: String
    let userId: String
    let voteId: String
    var voteTitle: String
    var voteCoverImageUrl: String?
    var selectedChoiceId: String?
    var selectedChoiceLabel: String?
    var pointsUsed: Int
    var votedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case voteId
        case voteTitle
        case voteCoverImageUrl
        case selectedChoiceId
        case selectedChoiceLabel
        case pointsUsed
        case votedAt
    }

    init(id: String = UUID().uuidString, userId: String, voteId: String, voteTitle: String, voteCoverImageUrl: String? = nil, selectedChoiceId: String? = nil, selectedChoiceLabel: String? = nil, pointsUsed: Int) {
        self.id = id
        self.userId = userId
        self.voteId = voteId
        self.voteTitle = voteTitle
        self.voteCoverImageUrl = voteCoverImageUrl
        self.selectedChoiceId = selectedChoiceId
        self.selectedChoiceLabel = selectedChoiceLabel
        self.pointsUsed = pointsUsed
        self.votedAt = Date()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        voteId = try container.decode(String.self, forKey: .voteId)
        voteTitle = try container.decode(String.self, forKey: .voteTitle)
        voteCoverImageUrl = try container.decodeIfPresent(String.self, forKey: .voteCoverImageUrl)
        selectedChoiceId = try container.decodeIfPresent(String.self, forKey: .selectedChoiceId)
        selectedChoiceLabel = try container.decodeIfPresent(String.self, forKey: .selectedChoiceLabel)
        pointsUsed = try container.decode(Int.self, forKey: .pointsUsed)

        if let timestamp = try? container.decode(Double.self, forKey: .votedAt) {
            votedAt = Date(timeIntervalSince1970: timestamp)
        } else {
            votedAt = Date()
        }
    }
}

// MARK: - Vote History Extension
extension VoteHistory {
    var formattedVotedAt: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: votedAt)
    }

    var relativeVotedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: votedAt, relativeTo: Date())
    }

    var hasChoice: Bool {
        return selectedChoiceId != nil && selectedChoiceLabel != nil
    }

    var displayChoice: String {
        if let label = selectedChoiceLabel {
            return label
        }
        return "未投票"
    }
}
