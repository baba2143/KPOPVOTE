//
//  ExternalAppService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - External App Service
//

import Foundation
import FirebaseAuth

class ExternalAppService {

    // MARK: - Get External Apps
    func getExternalApps() async throws -> [ExternalAppMaster] {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw ExternalAppError.notAuthenticated
        }

        let urlString = Constants.API.listExternalApps
        guard let url = URL(string: urlString) else {
            throw ExternalAppError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("📡 [ExternalAppService] Fetching external apps from: \(urlString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExternalAppError.invalidResponse
        }

        print("📥 [ExternalAppService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [ExternalAppService] Error response: \(errorString)")
            }
            throw ExternalAppError.serverError(httpResponse.statusCode)
        }

        // Debug: レスポンスの生データを確認
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 [ExternalAppService] Response JSON: \(responseString)")
        }

        // Cloud Functionのレスポンスをデコード
        let result = try JSONDecoder().decode(ListExternalAppsResponse.self, from: data)
        print("✅ [ExternalAppService] Fetched \(result.data.apps.count) external apps")

        // ExternalAppMasterオブジェクトの配列を構築
        let externalApps = result.data.apps.map { app -> ExternalAppMaster in
            let isoFormatter = ISO8601DateFormatter()
            let createdAt = app.createdAt.flatMap { isoFormatter.date(from: $0) }
            let updatedAt = app.updatedAt.flatMap { isoFormatter.date(from: $0) }

            return ExternalAppMaster(
                id: app.appId,
                appName: app.appName,
                appUrl: app.appUrl,
                iconUrl: app.iconUrl,
                defaultCoverImageUrl: app.defaultCoverImageUrl,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }

        print("✅ [ExternalAppService] Converted \(externalApps.count) ExternalAppMasters")
        return externalApps
    }
}

// MARK: - External App Errors
enum ExternalAppError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .serverError(let code):
            return "サーバーエラーが発生しました (コード: \(code))"
        case .decodingError:
            return "データの解析に失敗しました"
        }
    }
}

// MARK: - Response Models
struct ListExternalAppsResponse: Codable {
    let success: Bool
    let data: ListExternalAppsData

    struct ListExternalAppsData: Codable {
        let apps: [AppItem]
        let count: Int

        struct AppItem: Codable {
            let appId: String
            let appName: String
            let appUrl: String
            let iconUrl: String?
            let defaultCoverImageUrl: String?
            let createdAt: String?
            let updatedAt: String?
        }
    }
}
