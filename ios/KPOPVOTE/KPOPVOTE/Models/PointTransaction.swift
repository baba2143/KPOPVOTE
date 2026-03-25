//
//  PointTransaction.swift
//  OSHI Pick
//
//  OSHI Pick - Point Transaction Model
//  単一ポイント制（2024/02 移行）
//

import Foundation
import SwiftUI

/// ポイント履歴トランザクション
struct PointTransaction: Codable, Identifiable {
    let id: String
    let points: Int
    let type: String
    let relatedId: String?
    let voteCount: Int?
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
        // 投票系
        case "task_registration":
            return "タスク登録報酬"
        case "task_completion":
            return "タスク完了報酬"
        case "task_share":
            return "タスク共有報酬"

        // コンテンツ系
        case "post_mv":
            return "MV投稿報酬"
        case "mv_watch":
            return "MV視聴報酬"
        case "collection_create":
            return "コレクション作成報酬"
        case "post_image":
            return "画像投稿報酬"
        case "post_goods_exchange":
            return "グッズ交換投稿報酬"
        case "post_text":
            return "テキスト投稿報酬"

        // コミュニティ系 - する側
        case "community_like":
            return "いいね報酬"
        case "community_comment":
            return "コメント報酬"
        case "follow_user":
            return "フォロー報酬"

        // コミュニティ系 - される側（双方向報酬）
        case "received_like":
            return "いいね獲得"
        case "received_comment":
            return "コメント獲得"
        case "received_follow":
            return "フォロワー獲得"

        // 特別報酬
        case "friend_invite":
            return "友達招待報酬"

        // その他
        case "vote":
            return "投票"
        case "purchase":
            return "ポイント購入"
        case "grant":
            return "付与"
        case "deduct":
            return "減算"
        case "campaign_bonus":
            return "キャンペーンボーナス"
        case "coupon":
            return "クーポン"

        // 廃止（後方互換性）
        case "daily_login":
            return "ログインボーナス"
        case "community_post":
            return "投稿報酬"

        default:
            return type
        }
    }

    /// トランザクションアイコン
    var icon: String {
        switch type {
        // 投票系
        case "task_registration":
            return "plus.circle.fill"
        case "task_completion":
            return "checkmark.circle.fill"
        case "task_share":
            return "square.and.arrow.up.fill"

        // コンテンツ系
        case "post_mv":
            return "play.rectangle.fill"
        case "mv_watch":
            return "eye.fill"
        case "collection_create":
            return "folder.fill"
        case "post_image":
            return "photo.fill"
        case "post_goods_exchange":
            return "arrow.left.arrow.right"
        case "post_text":
            return "text.bubble.fill"

        // コミュニティ系 - する側
        case "community_like":
            return "heart.fill"
        case "community_comment":
            return "bubble.left.fill"
        case "follow_user":
            return "person.badge.plus"

        // コミュニティ系 - される側（双方向報酬）
        case "received_like":
            return "heart.circle.fill"
        case "received_comment":
            return "bubble.left.circle.fill"
        case "received_follow":
            return "person.crop.circle.badge.checkmark"

        // 特別報酬
        case "friend_invite":
            return "person.2.fill"

        // その他
        case "vote":
            return "heart.fill"
        case "purchase":
            return "cart.fill"
        case "grant":
            return "gift.fill"
        case "deduct":
            return "minus.circle.fill"
        case "campaign_bonus":
            return "star.fill"
        case "coupon":
            return "ticket.fill"

        // 廃止（後方互換性）
        case "daily_login":
            return "calendar.badge.clock"
        case "community_post":
            return "text.bubble.fill"

        default:
            return "circle.fill"
        }
    }
}

/// ポイント残高レスポンス（単一ポイント制）
struct PointBalanceResponse: Codable {
    let points: Int
    let lastUpdated: String?
}

/// ポイント履歴レスポンス
struct PointHistoryResponse: Codable {
    let transactions: [PointTransaction]
    let totalCount: Int
}
