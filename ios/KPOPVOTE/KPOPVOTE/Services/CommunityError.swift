//
//  CommunityError.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Community Service Errors
//

import Foundation

// MARK: - Community Error
enum CommunityError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case fetchFailed
    case createFailed
    case updateFailed
    case deleteFailed
    case alreadyFollowing
    case notFollowing
    case cannotFollowSelf
    case invalidPostType
    case invalidContent
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .fetchFailed:
            return "データの取得に失敗しました"
        case .createFailed:
            return "作成に失敗しました"
        case .updateFailed:
            return "更新に失敗しました"
        case .deleteFailed:
            return "削除に失敗しました"
        case .alreadyFollowing:
            return "すでにフォローしています"
        case .notFollowing:
            return "フォローしていません"
        case .cannotFollowSelf:
            return "自分自身をフォローできません"
        case .invalidPostType:
            return "無効な投稿タイプです"
        case .invalidContent:
            return "無効なコンテンツです"
        case .unauthorized:
            return "権限がありません"
        }
    }
}

// MARK: - Notification Error
enum NotificationError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case fetchFailed
    case markAsReadFailed
    case notificationNotFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .fetchFailed:
            return "通知の取得に失敗しました"
        case .markAsReadFailed:
            return "既読化に失敗しました"
        case .notificationNotFound:
            return "通知が見つかりません"
        case .unauthorized:
            return "権限がありません"
        }
    }
}
