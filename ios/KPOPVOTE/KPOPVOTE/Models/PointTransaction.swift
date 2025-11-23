//
//  PointTransaction.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Point Transaction Model
//

import Foundation
import SwiftUI

/// ポイント履歴トランザクション
struct PointTransaction: Codable, Identifiable {
    let id: String
    let points: Int
    let type: String
    let pointType: String?  // 🆕 "premium", "regular", "event", "gift"
    let relatedId: String?  // 🆕 Related post/vote/task ID
    let voteCount: Int?     // 🆕 Number of votes (for vote transactions)
    let conversionRate: Int? // 🆕 Conversion rate (for subscription_conversion)
    let reason: String
    let createdAt: String

    /// 日付オブジェクト
    var date: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: createdAt) ?? Date()
    }

    /// ポイント増減の符号（正: 獲得、負: 消費）
    var isPositive: Bool {
        return points > 0
    }

    /// トランザクションタイプの表示名
    var typeDisplayName: String {
        switch type {
        case "purchase":
            return "ポイント購入"
        case "subscription_first":
            return "プレミアム会員特典"
        case "subscription_monthly":
            return "月次ボーナス"
        case "subscription_conversion":
            return "ポイント変換"
        case "vote":
            return "投票"
        case "grant":
            return "付与"
        case "deduct":
            return "減算"
        case "daily_login":
            return "ログインボーナス"
        case "task_completion":
            return "タスク完了報酬"
        case "community_post":
            return "投稿報酬"
        case "community_like":
            return "いいね報酬"
        case "community_comment":
            return "コメント報酬"
        case "campaign_bonus":
            return "キャンペーンボーナス"
        case "coupon":
            return "クーポン"
        default:
            return type
        }
    }

    /// トランザクションアイコン
    var icon: String {
        switch type {
        case "purchase":
            return "cart.fill"
        case "subscription_first", "subscription_monthly":
            return "crown.fill"
        case "subscription_conversion":
            return "arrow.triangle.2.circlepath"
        case "vote":
            return "heart.fill"
        case "grant":
            return "gift.fill"
        case "deduct":
            return "minus.circle.fill"
        case "daily_login":
            return "calendar.badge.clock"
        case "task_completion":
            return "checkmark.circle.fill"
        case "community_post":
            return "text.bubble.fill"
        case "community_like":
            return "heart.fill"
        case "community_comment":
            return "bubble.left.fill"
        case "campaign_bonus":
            return "star.fill"
        case "coupon":
            return "ticket.fill"
        default:
            return "circle.fill"
        }
    }

    /// ポイントタイプの色を取得
    var pointTypeColor: Color? {
        guard let pointType = pointType else { return nil }
        switch pointType {
        case "premium": return Color.red
        case "regular": return Color.blue
        case "event": return Color.yellow
        case "gift": return Color.green
        default: return nil
        }
    }

    /// ポイントタイプのアイコンを取得
    var pointTypeIcon: String? {
        guard let pointType = pointType else { return nil }
        switch pointType {
        case "premium": return "🔴"
        case "regular": return "🔵"
        case "event": return "🟡"
        case "gift": return "🟢"
        default: return nil
        }
    }

    /// ポイントタイプの表示名を取得
    var pointTypeDisplayName: String? {
        guard let pointType = pointType else { return nil }
        switch pointType {
        case "premium": return "赤ポイント"
        case "regular": return "青ポイント"
        case "event": return "金ポイント"
        case "gift": return "緑ポイント"
        default: return nil
        }
    }
}

/// ポイント残高レスポンス（旧型 - 後方互換性のため残す）
struct PointBalanceResponse: Codable {
    let points: Int
    let isPremium: Bool
    let lastUpdated: String?
}

/// 複数ポイント残高レスポンス（新型）
struct MultiPointBalanceResponse: Codable {
    let premiumPoints: Int
    let regularPoints: Int
    let eventPoints: Int?
    let giftPoints: Int?
    let isPremium: Bool
    let lastUpdated: String?

    /// 合計投票可能数
    var totalVotesAvailable: Int {
        let premiumVotes = premiumPoints / 1
        let regularVotes = regularPoints / 5
        let eventVotes = (eventPoints ?? 0) / 5
        let giftVotes = (giftPoints ?? 0) / 5
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

/// ポイント履歴レスポンス
struct PointHistoryResponse: Codable {
    let transactions: [PointTransaction]
    let totalCount: Int
}
