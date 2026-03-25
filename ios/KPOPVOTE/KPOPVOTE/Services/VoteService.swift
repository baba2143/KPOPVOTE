//
//  VoteService.swift
//  OSHI Pick
//
//  OSHI Pick - In-App Vote Service
//

import Foundation
import FirebaseAuth
import FirebaseAppCheck

class VoteService {
    static let shared = VoteService()

    private init() {}

    // MARK: - Get App Check Token

    private func getAppCheckToken() async -> String? {
        #if DEBUG
        debugLog("⚠️ [VoteService] App Check skipped in DEBUG mode")
        return nil
        #else
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: false)
            return token.token
        } catch {
            debugLog("❌ [VoteService] App Check token error: \(error)")
            return nil
        }
        #endif
    }

    /// Fetch featured votes for HOME display
    /// - Returns: Array of featured InAppVote
    func fetchFeaturedVotes() async throws -> [InAppVote] {
        let token = try await FirebaseTokenHelper.shared.getToken()

        var urlComponents = URLComponents(string: Constants.API.listInAppVotes)!
        urlComponents.queryItems = [URLQueryItem(name: "featured", value: "true")]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = NetworkConfig.defaultTimeout
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [VoteService] Fetching featured votes from: \(urlComponents.url!.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.invalidResponse
        }

        debugLog("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw VoteError.fetchFailed
        }

        let result = try JSONDecoder().decode(VoteListResponse.self, from: data)
        debugLog("✅ [VoteService] Successfully fetched \(result.data.count) featured votes")

        return result.data.votes
    }

    /// Fetch votes list
    /// - Parameter status: Optional filter by status (upcoming/active/ended)
    /// - Returns: Array of InAppVote
    func fetchVotes(status: VoteStatus? = nil) async throws -> [InAppVote] {
        let token = try await FirebaseTokenHelper.shared.getToken()

        var urlComponents = URLComponents(string: Constants.API.listInAppVotes)!
        var queryItems: [URLQueryItem] = []

        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status.rawValue))
        }

        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = NetworkConfig.defaultTimeout
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [VoteService] Fetching votes from: \(urlComponents.url!.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.invalidResponse
        }

        debugLog("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [VoteService] Error response: \(errorString)")
            }
            throw VoteError.fetchFailed
        }

        let result = try JSONDecoder().decode(VoteListResponse.self, from: data)
        debugLog("✅ [VoteService] Successfully fetched \(result.data.count) votes")

        return result.data.votes
    }

    /// Fetch vote detail
    /// - Parameter voteId: Vote ID
    /// - Returns: InAppVote with full details
    func fetchVoteDetail(voteId: String) async throws -> InAppVote {
        let token = try await FirebaseTokenHelper.shared.getToken()

        var urlComponents = URLComponents(string: Constants.API.getInAppVoteDetail)!
        urlComponents.queryItems = [URLQueryItem(name: "voteId", value: voteId)]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = NetworkConfig.defaultTimeout
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [VoteService] Fetching vote detail: \(voteId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.invalidResponse
        }

        debugLog("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [VoteService] Error response: \(errorString)")
            }
            throw VoteError.fetchFailed
        }

        // デバッグ: 生のAPIレスポンスをログ出力
        if let jsonString = String(data: data, encoding: .utf8) {
            debugLog("📦 [VoteService] fetchVoteDetail raw response: \(jsonString)")
        }

        let result = try JSONDecoder().decode(VoteDetailResponse.self, from: data)
        debugLog("✅ [VoteService] Successfully fetched vote detail")

        return result.data
    }

    /// Execute vote
    /// - Parameters:
    ///   - voteId: Vote ID
    ///   - choiceId: Choice ID to vote for
    ///   - voteCount: Number of votes (default: 1)
    ///   - pointSelection: Point selection mode (default: "auto")
    /// - Returns: VoteExecuteResult
    func executeVote(voteId: String, choiceId: String, voteCount: Int = 1, pointSelection: String = "auto") async throws -> VoteExecuteResult {
        let token = try await FirebaseTokenHelper.shared.getToken()

        let appCheckToken = await getAppCheckToken()

        let url = URL(string: Constants.API.executeVote)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = NetworkConfig.defaultTimeout
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let appCheckToken = appCheckToken {
            request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
        }

        let body: [String: Any] = [
            "voteId": voteId,
            "choiceId": choiceId,
            "voteCount": voteCount,
            "pointSelection": pointSelection
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("📤 [VoteService] Executing vote")
        debugLog("  URL: \(url.absoluteString)")
        debugLog("  Method: POST")
        debugLog("  Authorization: Bearer [REDACTED]")
        debugLog("  Content-Type: application/json")
        debugLog("  Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.executeFailed
        }

        debugLog("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        // Handle specific error cases
        if httpResponse.statusCode == 400 {
            let errorResult = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            if let error = errorResult?.error {
                debugLog("❌ [VoteService] 400 Error: \(error)")
                if error.contains("Already voted") {
                    throw VoteError.alreadyVoted
                } else if error.contains("Insufficient points") {
                    throw VoteError.insufficientPoints
                } else if error.contains("not active") {
                    throw VoteError.voteNotActive
                } else if error.contains("投票上限") || error.contains("投票数制限") {
                    throw VoteError.dailyLimitReached(message: error)
                }
            }
            throw VoteError.executeFailed
        }

        if httpResponse.statusCode == 401 {
            let errorResult = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let errorMessage = errorResult?.error ?? "No error message"
            let responseBody = String(data: data, encoding: .utf8) ?? "nil"
            debugLog("❌ [VoteService] 401 Unauthorized")
            debugLog("  Error message: \(errorMessage)")
            debugLog("  Response body: \(responseBody)")
            throw VoteError.notAuthenticated
        }

        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "nil"
            debugLog("❌ [VoteService] Unexpected status code: \(httpResponse.statusCode)")
            debugLog("  Response body: \(responseBody)")
            throw VoteError.executeFailed
        }

        // デバッグ: 生のAPIレスポンスをログ出力
        if let jsonString = String(data: data, encoding: .utf8) {
            debugLog("📦 [VoteService] executeVote raw response: \(jsonString)")
        }

        let result = try JSONDecoder().decode(VoteExecuteResponse.self, from: data)
        debugLog("✅ [VoteService] Successfully executed vote")

        return result.data
    }

    /// Fetch ranking
    /// - Parameter voteId: Vote ID
    /// - Returns: VoteRanking with all rankings
    func fetchRanking(voteId: String) async throws -> VoteRanking {
        let token = try await FirebaseTokenHelper.shared.getToken()

        var urlComponents = URLComponents(string: Constants.API.getRanking)!
        urlComponents.queryItems = [URLQueryItem(name: "voteId", value: voteId)]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = NetworkConfig.defaultTimeout
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [VoteService] Fetching ranking: \(voteId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.invalidResponse
        }

        debugLog("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [VoteService] Error response: \(errorString)")
            }
            throw VoteError.fetchFailed
        }

        let result = try JSONDecoder().decode(RankingResponse.self, from: data)
        debugLog("✅ [VoteService] Successfully fetched ranking")

        return result.data
    }
}

// MARK: - Response Models
struct VoteListResponse: Codable {
    let success: Bool
    let data: VoteListData
}

struct VoteListData: Codable {
    let votes: [InAppVote]
    let count: Int
}

struct VoteDetailResponse: Codable {
    let success: Bool
    let data: InAppVote
}

struct VoteExecuteResponse: Codable {
    let success: Bool
    let data: VoteExecuteResult
}

// VoteExecuteResult（単一ポイント制）
struct VoteExecuteResult: Codable {
    let voteId: String
    let choiceId: String
    let voteCount: Int
    let pointsDeducted: Int  // 単一ポイント制
    // User's daily vote info after this vote
    let userDailyVotes: Int?
    let userDailyRemaining: Int?

    enum CodingKeys: String, CodingKey {
        case voteId
        case choiceId
        case voteCount
        case pointsDeducted = "totalPointsDeducted"
        case userDailyVotes
        case userDailyRemaining
    }
}

struct RankingResponse: Codable {
    let success: Bool
    let data: VoteRanking
}

struct ErrorResponse: Codable {
    let success: Bool
    let error: String
}

// MARK: - Errors
enum VoteError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case fetchFailed
    case executeFailed
    case alreadyVoted
    case insufficientPoints
    case voteNotActive
    case dailyLimitReached(message: String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .fetchFailed:
            return "投票の取得に失敗しました"
        case .executeFailed:
            return "投票の実行に失敗しました"
        case .alreadyVoted:
            return "既に投票済みです"
        case .insufficientPoints:
            return "ポイントが不足しています"
        case .voteNotActive:
            return "この投票は開催されていません"
        case .dailyLimitReached(let message):
            return message
        }
    }
}
