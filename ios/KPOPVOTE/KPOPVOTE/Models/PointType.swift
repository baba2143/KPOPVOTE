//
//  PointType.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Point Type Model
//

import Foundation
import SwiftUI

// MARK: - Point Type
enum PointType: String, Codable {
    case premium = "premium"  // 🔴 赤ポイント (サブスク会員)
    case regular = "regular"  // 🔵 青ポイント (全ユーザー)
    case event = "event"      // 🟡 金ポイント (イベント限定)
    case gift = "gift"        // 🟢 緑ポイント (ギフト)

    var displayName: String {
        switch self {
        case .premium:
            return "赤ポイント"
        case .regular:
            return "青ポイント"
        case .event:
            return "金ポイント"
        case .gift:
            return "緑ポイント"
        }
    }

    var shortName: String {
        switch self {
        case .premium:
            return "赤P"
        case .regular:
            return "青P"
        case .event:
            return "金P"
        case .gift:
            return "緑P"
        }
    }

    var color: Color {
        switch self {
        case .premium:
            return Color.red
        case .regular:
            return Color.blue
        case .event:
            return Color.yellow
        case .gift:
            return Color.green
        }
    }

    var icon: String {
        switch self {
        case .premium:
            return "🔴"
        case .regular:
            return "🔵"
        case .event:
            return "🟡"
        case .gift:
            return "🟢"
        }
    }

    /// 1票あたりのポイント消費量
    var voteRate: Int {
        switch self {
        case .premium:
            return 1  // 1P = 1票（効率的）
        case .regular:
            return 5  // 5P = 1票（標準）
        case .event:
            return 5  // 将来の実装
        case .gift:
            return 5  // 将来の実装
        }
    }

    /// 投票可能数を計算
    func calculateVotes(from points: Int) -> Int {
        return points / voteRate
    }

    /// 指定票数に必要なポイント数を計算
    func calculateRequiredPoints(for votes: Int) -> Int {
        return votes * voteRate
    }
}

// MARK: - Point Balance
struct PointBalance: Codable {
    var premiumPoints: Int
    var regularPoints: Int
    var eventPoints: Int?
    var giftPoints: Int?
    var isPremium: Bool
    var lastUpdated: String?

    init(premiumPoints: Int = 0, regularPoints: Int = 0, eventPoints: Int? = nil, giftPoints: Int? = nil, isPremium: Bool = false, lastUpdated: String? = nil) {
        self.premiumPoints = premiumPoints
        self.regularPoints = regularPoints
        self.eventPoints = eventPoints
        self.giftPoints = giftPoints
        self.isPremium = isPremium
        self.lastUpdated = lastUpdated
    }

    /// 合計投票可能数
    var totalVotesAvailable: Int {
        let premiumVotes = PointType.premium.calculateVotes(from: premiumPoints)
        let regularVotes = PointType.regular.calculateVotes(from: regularPoints)
        let eventVotes = eventPoints.map { PointType.event.calculateVotes(from: $0) } ?? 0
        let giftVotes = giftPoints.map { PointType.gift.calculateVotes(from: $0) } ?? 0
        return premiumVotes + regularVotes + eventVotes + giftVotes
    }

    /// 特定のポイントタイプの残高を取得
    func balance(for type: PointType) -> Int {
        switch type {
        case .premium:
            return premiumPoints
        case .regular:
            return regularPoints
        case .event:
            return eventPoints ?? 0
        case .gift:
            return giftPoints ?? 0
        }
    }

    /// 特定のポイントタイプで投票可能な数
    func votesAvailable(for type: PointType) -> Int {
        let points = balance(for: type)
        return type.calculateVotes(from: points)
    }
}

// MARK: - Point Selection Mode
enum PointSelectionMode: String, CaseIterable {
    case auto = "auto"
    case premium = "premium"
    case regular = "regular"

    var displayName: String {
        switch self {
        case .auto:
            return "効率的な順（推奨）"
        case .premium:
            return "🔴 赤ポイントのみ"
        case .regular:
            return "🔵 青ポイントのみ"
        }
    }

    var description: String {
        switch self {
        case .auto:
            return "赤ポイント → 青ポイントの順で使用"
        case .premium:
            return "赤ポイントのみを使用"
        case .regular:
            return "青ポイントのみを使用"
        }
    }
}
