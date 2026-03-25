//
//  PointsService.swift
//  OSHI Pick
//
//  OSHI Pick - Points Service
//

import Foundation
import FirebaseAuth

class PointsService {
    static let shared = PointsService()

    private init() {}

    // MARK: - Get Points Balance (単一ポイント制)
    /// Fetch user's current point balance
    /// - Returns: Point balance response
    func fetchPointBalance() async throws -> PointBalanceResponse {
        let token = try await FirebaseTokenHelper.shared.getToken()

        guard let url = URL(string: Constants.API.getPoints) else {
            throw PointsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [PointsService] Fetching point balance")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        debugLog("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct GetPointsResponse: Codable {
            let success: Bool
            let data: PointBalanceResponse
        }

        let result = try JSONDecoder().decode(GetPointsResponse.self, from: data)
        debugLog("✅ [PointsService] Fetched points: \(result.data.points)")

        return result.data
    }

    // MARK: - Get Point History
    /// Fetch user's point transaction history
    /// - Parameters:
    ///   - limit: Number of transactions to fetch (default: 20, max: 100)
    ///   - offset: Pagination offset (default: 0)
    /// - Returns: Point history response with transactions and total count
    func fetchPointHistory(limit: Int = 20, offset: Int = 0) async throws -> PointHistoryResponse {
        let token = try await FirebaseTokenHelper.shared.getToken()

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

        debugLog("🔍 [PointsService] Fetching point history: limit=\(limit), offset=\(offset)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        debugLog("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct GetPointHistoryResponse: Codable {
            let success: Bool
            let data: PointHistoryResponse
        }

        let result = try JSONDecoder().decode(GetPointHistoryResponse.self, from: data)
        debugLog("✅ [PointsService] Fetched \(result.data.transactions.count) transactions, total: \(result.data.totalCount)")

        return result.data
    }

    // MARK: - Daily Login Bonus
    /// デイリーログインボーナス取得
    /// - Returns: Daily login response with granted points info
    func claimDailyLoginBonus() async throws -> DailyLoginResponse {
        let token = try await FirebaseTokenHelper.shared.getToken()

        guard let url = URL(string: Constants.API.dailyLogin) else {
            throw PointsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        debugLog("🔍 [PointsService] Claiming daily login bonus")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        debugLog("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct DailyLoginApiResponse: Codable {
            let success: Bool
            let data: DailyLoginResponse
        }

        let result = try JSONDecoder().decode(DailyLoginApiResponse.self, from: data)
        debugLog("✅ [PointsService] Daily login: +\(result.data.pointsGranted)P, streak: \(result.data.loginStreak)")

        return result.data
    }

    // MARK: - Share Task (新報酬設計)
    /// タスク共有報酬を取得
    /// - Parameters:
    ///   - taskId: 共有するタスクのID
    ///   - platform: 共有プラットフォーム (twitter, instagram, line, other)
    /// - Returns: Share task response
    func shareTask(taskId: String, platform: String) async throws -> ShareTaskResponse {
        let token = try await FirebaseTokenHelper.shared.getToken()

        guard let url = URL(string: Constants.API.shareTask) else {
            throw PointsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "taskId": taskId,
            "platform": platform
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("🔍 [PointsService] Sharing task: \(taskId) on \(platform)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        debugLog("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct ShareTaskApiResponse: Codable {
            let success: Bool
            let data: ShareTaskResponse
        }

        let result = try JSONDecoder().decode(ShareTaskApiResponse.self, from: data)
        debugLog("✅ [PointsService] Share task: +\(result.data.pointsGranted)P, daily: \(result.data.dailyShareCount)/\(result.data.dailyLimit)")

        return result.data
    }

    // MARK: - Report MV Watch (新報酬設計)
    /// MV視聴報告報酬を取得
    /// - Parameter postId: MV投稿のID
    /// - Returns: Report MV watch response
    func reportMvWatch(postId: String) async throws -> ReportMvWatchResponse {
        let token = try await FirebaseTokenHelper.shared.getToken()

        guard let url = URL(string: Constants.API.reportMvWatch) else {
            throw PointsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["postId": postId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("🔍 [PointsService] Reporting MV watch: \(postId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        debugLog("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct ReportMvWatchApiResponse: Codable {
            let success: Bool
            let data: ReportMvWatchResponse
        }

        let result = try JSONDecoder().decode(ReportMvWatchApiResponse.self, from: data)
        debugLog("✅ [PointsService] Report MV watch: +\(result.data.pointsGranted)P, daily: \(result.data.dailyWatchCount)/\(result.data.dailyLimit)")

        return result.data
    }

    // MARK: - Generate Invite Code (新報酬設計)
    /// 招待コードを生成・取得
    /// - Returns: Generate invite code response
    func generateInviteCode() async throws -> GenerateInviteCodeResponse {
        let token = try await FirebaseTokenHelper.shared.getToken()

        guard let url = URL(string: Constants.API.generateInviteCode) else {
            throw PointsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        debugLog("🔍 [PointsService] Generating invite code")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        debugLog("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct GenerateInviteCodeApiResponse: Codable {
            let success: Bool
            let data: GenerateInviteCodeResponse
        }

        let result = try JSONDecoder().decode(GenerateInviteCodeApiResponse.self, from: data)
        debugLog("✅ [PointsService] Generated invite code: \(result.data.inviteCode)")

        return result.data
    }

    // MARK: - Apply Invite Code (新報酬設計)
    /// 招待コードを適用
    /// - Parameter inviteCode: 招待コード
    /// - Returns: Apply invite code response
    func applyInviteCode(inviteCode: String) async throws -> ApplyInviteCodeResponse {
        let token = try await FirebaseTokenHelper.shared.getToken()

        guard let url = URL(string: Constants.API.applyInviteCode) else {
            throw PointsError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["inviteCode": inviteCode]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("🔍 [PointsService] Applying invite code: \(inviteCode)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PointsError.invalidResponse
        }

        debugLog("📥 [PointsService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [PointsService] Error: \(errorString)")
            }
            throw PointsError.fetchFailed
        }

        struct ApplyInviteCodeApiResponse: Codable {
            let success: Bool
            let data: ApplyInviteCodeResponse
        }

        let result = try JSONDecoder().decode(ApplyInviteCodeApiResponse.self, from: data)
        debugLog("✅ [PointsService] Applied invite code, inviter: \(result.data.inviterDisplayName ?? "unknown")")

        return result.data
    }
}

// MARK: - Share Task Response (新報酬設計)
struct ShareTaskResponse: Codable {
    let success: Bool
    let pointsGranted: Int
    let dailyShareCount: Int
    let dailyLimit: Int
}

// MARK: - Report MV Watch Response (新報酬設計)
struct ReportMvWatchResponse: Codable {
    let success: Bool
    let pointsGranted: Int
    let dailyWatchCount: Int
    let dailyLimit: Int
    let alreadyReported: Bool
}

// MARK: - Generate Invite Code Response (新報酬設計)
struct GenerateInviteCodeResponse: Codable {
    let inviteCode: String
    let inviteLink: String
}

// MARK: - Apply Invite Code Response (新報酬設計)
struct ApplyInviteCodeResponse: Codable {
    let success: Bool
    let inviterDisplayName: String?
}

// MARK: - Daily Login Response (廃止 - 後方互換性のため残す)
struct DailyLoginResponse: Codable {
    let pointsGranted: Int
    let loginStreak: Int
    let isFirstTimeToday: Bool
    let message: String
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
