//
//  PointTransaction.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Point Transaction Model
//

import Foundation

/// ポイント履歴トランザクション
struct PointTransaction: Codable, Identifiable {
    let id: String
    let points: Int
    let type: String
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
        case "vote":
            return "投票"
        case "grant":
            return "付与"
        case "deduct":
            return "減算"
        case "daily_login":
            return "ログインボーナス"
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
        case "vote":
            return "heart.fill"
        case "grant":
            return "gift.fill"
        case "deduct":
            return "minus.circle.fill"
        case "daily_login":
            return "calendar.badge.clock"
        case "campaign_bonus":
            return "star.fill"
        case "coupon":
            return "ticket.fill"
        default:
            return "circle.fill"
        }
    }
}

/// ポイント残高レスポンス
struct PointBalanceResponse: Codable {
    let points: Int
    let isPremium: Bool
    let lastUpdated: String?
}

/// ポイント履歴レスポンス
struct PointHistoryResponse: Codable {
    let transactions: [PointTransaction]
    let totalCount: Int
}
