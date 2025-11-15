//
//  VoteService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - In-App Vote Service
//

import Foundation
import FirebaseAuth

class VoteService {
    static let shared = VoteService()

    private init() {}

    /// Fetch featured votes for HOME display
    /// - Returns: Array of featured InAppVote
    func fetchFeaturedVotes() async throws -> [InAppVote] {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw VoteError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.listInAppVotes)!
        urlComponents.queryItems = [URLQueryItem(name: "featured", value: "true")]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [VoteService] Fetching featured votes from: \(urlComponents.url!.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.invalidResponse
        }

        print("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw VoteError.fetchFailed
        }

        let result = try JSONDecoder().decode(VoteListResponse.self, from: data)
        print("✅ [VoteService] Successfully fetched \(result.data.count) featured votes")

        return result.data.votes
    }

    /// Fetch votes list
    /// - Parameter status: Optional filter by status (upcoming/active/ended)
    /// - Returns: Array of InAppVote
    func fetchVotes(status: VoteStatus? = nil) async throws -> [InAppVote] {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw VoteError.notAuthenticated
        }

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
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [VoteService] Fetching votes from: \(urlComponents.url!.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.invalidResponse
        }

        print("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [VoteService] Error response: \(errorString)")
            }
            throw VoteError.fetchFailed
        }

        let result = try JSONDecoder().decode(VoteListResponse.self, from: data)
        print("✅ [VoteService] Successfully fetched \(result.data.count) votes")

        return result.data.votes
    }

    /// Fetch vote detail
    /// - Parameter voteId: Vote ID
    /// - Returns: InAppVote with full details
    func fetchVoteDetail(voteId: String) async throws -> InAppVote {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw VoteError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getInAppVoteDetail)!
        urlComponents.queryItems = [URLQueryItem(name: "voteId", value: voteId)]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [VoteService] Fetching vote detail: \(voteId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.invalidResponse
        }

        print("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [VoteService] Error response: \(errorString)")
            }
            throw VoteError.fetchFailed
        }

        let result = try JSONDecoder().decode(VoteDetailResponse.self, from: data)
        print("✅ [VoteService] Successfully fetched vote detail")

        return result.data
    }

    /// Execute vote
    /// - Parameters:
    ///   - voteId: Vote ID
    ///   - choiceId: Choice ID to vote for
    /// - Returns: VoteExecuteResult
    func executeVote(voteId: String, choiceId: String) async throws -> VoteExecuteResult {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw VoteError.notAuthenticated
        }

        let url = URL(string: Constants.API.executeVote)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["voteId": voteId, "choiceId": choiceId]
        request.httpBody = try JSONEncoder().encode(body)

        print("📤 [VoteService] Executing vote")
        print("  URL: \(url.absoluteString)")
        print("  Method: POST")
        print("  Authorization: Bearer \(String(token.prefix(20)))...")
        print("  Content-Type: application/json")
        print("  Body: \(String(data: request.httpBody!, encoding: .utf8) ?? "nil")")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.executeFailed
        }

        print("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        // Handle specific error cases
        if httpResponse.statusCode == 400 {
            let errorResult = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            if let error = errorResult?.error {
                print("❌ [VoteService] 400 Error: \(error)")
                if error.contains("Already voted") {
                    throw VoteError.alreadyVoted
                } else if error.contains("Insufficient points") {
                    throw VoteError.insufficientPoints
                } else if error.contains("not active") {
                    throw VoteError.voteNotActive
                }
            }
            throw VoteError.executeFailed
        }

        if httpResponse.statusCode == 401 {
            let errorResult = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let errorMessage = errorResult?.error ?? "No error message"
            let responseBody = String(data: data, encoding: .utf8) ?? "nil"
            print("❌ [VoteService] 401 Unauthorized")
            print("  Error message: \(errorMessage)")
            print("  Response body: \(responseBody)")
            throw VoteError.notAuthenticated
        }

        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "nil"
            print("❌ [VoteService] Unexpected status code: \(httpResponse.statusCode)")
            print("  Response body: \(responseBody)")
            throw VoteError.executeFailed
        }

        let result = try JSONDecoder().decode(VoteExecuteResponse.self, from: data)
        print("✅ [VoteService] Successfully executed vote")

        return result.data
    }

    /// Fetch ranking
    /// - Parameter voteId: Vote ID
    /// - Returns: VoteRanking with all rankings
    func fetchRanking(voteId: String) async throws -> VoteRanking {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw VoteError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getRanking)!
        urlComponents.queryItems = [URLQueryItem(name: "voteId", value: voteId)]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [VoteService] Fetching ranking: \(voteId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw VoteError.invalidResponse
        }

        print("📥 [VoteService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [VoteService] Error response: \(errorString)")
            }
            throw VoteError.fetchFailed
        }

        let result = try JSONDecoder().decode(RankingResponse.self, from: data)
        print("✅ [VoteService] Successfully fetched ranking")

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

struct VoteExecuteResult: Codable {
    let voteId: String
    let choiceId: String
    let pointsDeducted: Int
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
        }
    }
}
