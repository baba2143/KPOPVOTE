//
//  IdolRankingService.swift
//  KPOPVOTE
//
//  API service for Idol Ranking feature
//

import Foundation
import FirebaseAuth

enum IdolRankingError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case serverError(String)
    case decodingError(Error)
    case dailyLimitExceeded

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログインが必要です"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let message):
            return message
        case .decodingError:
            return "データの読み込みに失敗しました"
        case .dailyLimitExceeded:
            return "本日の投票上限に達しました（1日5票まで）"
        }
    }
}

class IdolRankingService {
    static let shared = IdolRankingService()

    private init() {}

    // MARK: - Get Authentication Token

    private func getAuthToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw IdolRankingError.notAuthenticated
        }

        return try await user.getIDToken()
    }

    // MARK: - Get Ranking

    func getRanking(
        type: RankingType,
        period: RankingPeriod,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> GetRankingResponse {
        var components = URLComponents(string: Constants.API.idolRankingGetRanking)!
        components.queryItems = [
            URLQueryItem(name: "rankingType", value: type.rawValue),
            URLQueryItem(name: "period", value: period.rawValue),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components.url else {
            throw IdolRankingError.networkError(URLError(.badURL))
        }

        let token = try await getAuthToken()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Debug logging
            if let httpResponse = response as? HTTPURLResponse {
                print("[IdolRankingService] getRanking HTTP Status: \(httpResponse.statusCode)")
            }
            print("[IdolRankingService] getRanking Response: \(String(data: data, encoding: .utf8) ?? "nil")")

            guard let httpResponse = response as? HTTPURLResponse else {
                throw IdolRankingError.networkError(URLError(.badServerResponse))
            }

            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ApiResponse<GetRankingResponse>.self, from: data) {
                    throw IdolRankingError.serverError(errorResponse.error ?? "Unknown error")
                }
                throw IdolRankingError.serverError("Server error: \(httpResponse.statusCode)")
            }

            let apiResponse = try JSONDecoder().decode(ApiResponse<GetRankingResponse>.self, from: data)

            guard let rankingData = apiResponse.data else {
                throw IdolRankingError.serverError(apiResponse.error ?? "No data received")
            }

            return rankingData
        } catch let error as IdolRankingError {
            throw error
        } catch let decodingError as DecodingError {
            throw IdolRankingError.decodingError(decodingError)
        } catch {
            throw IdolRankingError.networkError(error)
        }
    }

    // MARK: - Vote

    func vote(
        entityId: String,
        entityType: RankingType,
        name: String,
        groupName: String? = nil,
        imageUrl: String? = nil
    ) async throws -> VoteResponse {
        let token = try await getAuthToken()

        guard let url = URL(string: Constants.API.idolRankingVote) else {
            throw IdolRankingError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let voteRequest = VoteRequest(
            entityId: entityId,
            entityType: entityType,
            name: name,
            groupName: groupName,
            imageUrl: imageUrl
        )

        request.httpBody = try JSONEncoder().encode(voteRequest)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw IdolRankingError.networkError(URLError(.badServerResponse))
            }

            if httpResponse.statusCode == 429 {
                throw IdolRankingError.dailyLimitExceeded
            }

            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ApiResponse<VoteResponse>.self, from: data) {
                    throw IdolRankingError.serverError(errorResponse.error ?? "Unknown error")
                }
                throw IdolRankingError.serverError("Server error: \(httpResponse.statusCode)")
            }

            let apiResponse = try JSONDecoder().decode(ApiResponse<VoteResponse>.self, from: data)

            guard let voteData = apiResponse.data else {
                throw IdolRankingError.serverError(apiResponse.error ?? "No data received")
            }

            return voteData
        } catch let error as IdolRankingError {
            throw error
        } catch let decodingError as DecodingError {
            throw IdolRankingError.decodingError(decodingError)
        } catch {
            throw IdolRankingError.networkError(error)
        }
    }

    // MARK: - Get Daily Limit

    func getDailyLimit() async throws -> DailyLimitResponse {
        let token = try await getAuthToken()

        guard let url = URL(string: Constants.API.idolRankingGetDailyLimit) else {
            throw IdolRankingError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw IdolRankingError.networkError(URLError(.badServerResponse))
            }

            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ApiResponse<DailyLimitResponse>.self, from: data) {
                    throw IdolRankingError.serverError(errorResponse.error ?? "Unknown error")
                }
                throw IdolRankingError.serverError("Server error: \(httpResponse.statusCode)")
            }

            let apiResponse = try JSONDecoder().decode(ApiResponse<DailyLimitResponse>.self, from: data)

            guard let limitData = apiResponse.data else {
                throw IdolRankingError.serverError(apiResponse.error ?? "No data received")
            }

            return limitData
        } catch let error as IdolRankingError {
            throw error
        } catch let decodingError as DecodingError {
            throw IdolRankingError.decodingError(decodingError)
        } catch {
            throw IdolRankingError.networkError(error)
        }
    }
}
