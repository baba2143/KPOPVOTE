//
//  EarnAction.swift
//  OSHI Pick
//
//  OSHI Pick - Point Earning Actions Model
//  ポイント獲得アクションの定義
//

import SwiftUI

// MARK: - Earn Category
enum EarnCategory: String, CaseIterable {
    case voting = "投票系"
    case content = "コンテンツ系"
    case community = "コミュニティ系"
    case special = "特別報酬"

    var icon: String {
        switch self {
        case .voting: return "checkmark.seal.fill"
        case .content: return "doc.text.fill"
        case .community: return "person.2.fill"
        case .special: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .voting: return Constants.Colors.accentPink
        case .content: return Constants.Colors.accentBlue
        case .community: return Color.green
        case .special: return Color.yellow
        }
    }

    var subtitle: String {
        switch self {
        case .voting: return "高報酬"
        case .content: return "中報酬"
        case .community: return "低報酬"
        case .special: return "ボーナス"
        }
    }
}

// MARK: - Earn Action
struct EarnAction: Identifiable {
    let id: String
    let name: String
    let points: Int
    let dailyLimit: Int?
    let category: EarnCategory
    let icon: String

    var limitText: String? {
        guard let limit = dailyLimit else { return nil }
        return "1日\(limit)回まで"
    }

    // MARK: - All Actions
    static let allActions: [EarnAction] = [
        // 投票系（高報酬）
        EarnAction(id: "task_registration", name: "タスク登録", points: 10, dailyLimit: nil, category: .voting, icon: "plus.circle.fill"),
        EarnAction(id: "task_share", name: "タスク共有", points: 5, dailyLimit: 3, category: .voting, icon: "square.and.arrow.up"),

        // コンテンツ系（中報酬）
        EarnAction(id: "post_mv", name: "MV投稿", points: 5, dailyLimit: nil, category: .content, icon: "play.rectangle.fill"),
        EarnAction(id: "mv_watch", name: "MV視聴報告", points: 2, dailyLimit: 3, category: .content, icon: "eye.fill"),
        EarnAction(id: "collection_create", name: "コレクション作成", points: 10, dailyLimit: nil, category: .content, icon: "folder.fill"),
        EarnAction(id: "post_image", name: "画像投稿", points: 3, dailyLimit: nil, category: .content, icon: "photo.fill"),
        EarnAction(id: "post_goods_exchange", name: "グッズ交換投稿", points: 5, dailyLimit: nil, category: .content, icon: "gift.fill"),

        // コミュニティ系（低報酬）
        EarnAction(id: "post_text", name: "テキスト投稿", points: 2, dailyLimit: nil, category: .community, icon: "text.bubble.fill"),
        EarnAction(id: "community_like", name: "いいね", points: 1, dailyLimit: 10, category: .community, icon: "heart.fill"),
        EarnAction(id: "community_comment", name: "コメント", points: 2, dailyLimit: 10, category: .community, icon: "bubble.left.fill"),
        EarnAction(id: "follow_user", name: "フォロー", points: 3, dailyLimit: 5, category: .community, icon: "person.badge.plus"),

        // 特別報酬
        EarnAction(id: "friend_invite", name: "友達招待", points: 50, dailyLimit: nil, category: .special, icon: "person.2.badge.gearshape.fill"),
    ]

    // MARK: - Helper Methods
    static func actions(for category: EarnCategory) -> [EarnAction] {
        allActions.filter { $0.category == category }
    }
}
