//
//  GroupService.swift
//  OSHI Pick
//
//  OSHI Pick - Group Master Service
//

import Foundation
import FirebaseAuth

class GroupService {
    static let shared = GroupService()

    private init() {}

    /// Fetch groups from backend
    /// - Returns: Array of GroupMaster objects
    func fetchGroups() async throws -> [GroupMaster] {
        // Get authentication token
        let token = try await FirebaseTokenHelper.shared.getToken()

        // Build URL with query parameter
        var urlComponents = URLComponents(string: Constants.API.listGroups)!
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "1000")
        ]

        // Create request
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [GroupService] Fetching groups from: \(urlComponents.url!.absoluteString)")

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroupError.invalidResponse
        }

        debugLog("📥 [GroupService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [GroupService] Error response: \(errorString)")
            }
            throw GroupError.fetchFailed
        }

        // Decode response
        let result = try JSONDecoder().decode(GroupListResponse.self, from: data)

        debugLog("✅ [GroupService] Successfully fetched \(result.data.count) groups")

        return result.data.groups
    }
}

// MARK: - Response Models
struct GroupListResponse: Codable {
    let success: Bool
    let data: GroupListData
}

struct GroupListData: Codable {
    let groups: [GroupMaster]
    let count: Int
}

// MARK: - Errors
enum GroupError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .fetchFailed:
            return "グループ一覧の取得に失敗しました"
        }
    }
}
