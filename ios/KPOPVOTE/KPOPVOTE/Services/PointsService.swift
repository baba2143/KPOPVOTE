//
//  PointsService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Points Service
//

import Foundation
import FirebaseAuth

class PointsService {
    static let shared = PointsService()

    private init() {}

    // MARK: - Get Points
    /// Fetch user's current point balance
    /// - Returns: Point balance response with points and premium status
    func fetchPoints() async throws -> PointBalanceResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw PointsError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.getPoints) else {
            throw PointsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [PointsService] Fetching points balance")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        print("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct GetPointsResponse: Codable {
            let success: Bool
            let data: PointBalanceResponse
        }

        let result = try JSONDecoder().decode(GetPointsResponse.self, from: data)
        print("✅ [PointsService] Fetched points: \(result.data.points), isPremium: \(result.data.isPremium)")

        return result.data
    }

    // MARK: - Get Point History
    /// Fetch user's point transaction history
    /// - Parameters:
    ///   - limit: Number of transactions to fetch (default: 20, max: 100)
    ///   - offset: Pagination offset (default: 0)
    /// - Returns: Point history response with transactions and total count
    func fetchPointHistory(limit: Int = 20, offset: Int = 0) async throws -> PointHistoryResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw PointsError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getPointHistory)!
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: "\(min(limit, 100))"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        guard let url = urlComponents.url else {
            throw PointsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [PointsService] Fetching point history: limit=\(limit), offset=\(offset)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        print("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct GetPointHistoryResponse: Codable {
            let success: Bool
            let data: PointHistoryResponse
        }

        let result = try JSONDecoder().decode(GetPointHistoryResponse.self, from: data)
        print("✅ [PointsService] Fetched \(result.data.transactions.count) transactions, total: \(result.data.totalCount)")

        return result.data
    }
}

// MARK: - Errors
enum PointsError: Error {
    case notAuthenticated
    case invalidResponse
    case fetchFailed

    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidResponse:
            return "無効なレスポンス"
        case .fetchFailed:
            return "データの取得に失敗しました"
        }
    }
}
