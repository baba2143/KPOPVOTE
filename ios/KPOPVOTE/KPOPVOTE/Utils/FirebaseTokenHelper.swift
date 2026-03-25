//
//  FirebaseTokenHelper.swift
//  OSHI Pick
//
//  OSHI Pick - Firebase ID Token Cache Helper
//

import FirebaseAuth
import Foundation

/// Firebase IDトークンをキャッシュしてAPI呼び出しを最適化
/// トークンは55分間キャッシュ（Firebase有効期限60分の5分前に更新）
actor FirebaseTokenHelper {
    static let shared = FirebaseTokenHelper()

    private var cachedToken: String?
    private var tokenExpiry: Date?

    /// キャッシュされたトークンを取得、または新規取得
    func getToken() async throws -> String {
        // 有効なキャッシュがあれば返す
        if let token = cachedToken,
           let expiry = tokenExpiry,
           Date() < expiry {
            return token
        }

        // 新規トークン取得
        guard let user = Auth.auth().currentUser else {
            throw AuthServiceError.notAuthenticated
        }

        let token = try await user.getIDToken()

        // 55分後に期限切れとしてキャッシュ
        cachedToken = token
        tokenExpiry = Date().addingTimeInterval(55 * 60)

        return token
    }

    /// キャッシュを無効化（ログアウト時に呼び出し）
    func invalidateCache() {
        cachedToken = nil
        tokenExpiry = nil
    }

    /// 強制的にトークンを更新
    func forceRefresh() async throws -> String {
        cachedToken = nil
        tokenExpiry = nil
        return try await getToken()
    }
}

/// FirebaseTokenHelper用のエラー
enum AuthServiceError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ユーザーが認証されていません"
        }
    }
}
