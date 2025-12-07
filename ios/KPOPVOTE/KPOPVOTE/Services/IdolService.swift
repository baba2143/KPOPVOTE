//
//  IdolService.swift
//  OSHI Pick
//
//  OSHI Pick - Idol Master Service
//

import Foundation
import FirebaseAuth

class IdolService {
    static let shared = IdolService()

    private init() {}

    /// Fetch idols from backend
    /// - Parameter groupName: Optional filter by group name
    /// - Returns: Array of IdolMaster objects
    func fetchIdols(groupName: String? = nil) async throws -> [IdolMaster] {
        // Get authentication token
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw IdolError.notAuthenticated
        }

        // Build URL with optional query parameter
        var urlComponents = URLComponents(string: Constants.API.listIdols)!
        var queryItems: [URLQueryItem] = []

        // Always request all idols (no limit)
        queryItems.append(URLQueryItem(name: "limit", value: "10000"))

        if let groupName = groupName {
            queryItems.append(URLQueryItem(name: "groupName", value: groupName))
        }

        urlComponents.queryItems = queryItems

        // Create request
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [IdolService] Fetching idols from: \(urlComponents.url!.absoluteString)")

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IdolError.invalidResponse
        }

        print("📥 [IdolService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [IdolService] Error response: \(errorString)")
            }
            throw IdolError.fetchFailed
        }

        // Decode response
        let result = try JSONDecoder().decode(IdolListResponse.self, from: data)

        print("✅ [IdolService] Successfully fetched \(result.data.count) idols")

        return result.data.idols
    }
}

// MARK: - Response Models
struct IdolListResponse: Codable {
    let success: Bool
    let data: IdolListData
}

struct IdolListData: Codable {
    let idols: [IdolMaster]
    let count: Int
}

// MARK: - Errors
enum IdolError: LocalizedError {
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
            return "アイドル一覧の取得に失敗しました"
        }
    }
}
