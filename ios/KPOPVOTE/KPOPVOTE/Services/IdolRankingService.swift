//
//  IdolRankingService.swift
//  KPOPVOTE
//
//  API service for Idol Ranking feature
//

import Foundation
import FirebaseAuth
import FirebaseAppCheck

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
            return "投票処理に失敗しました"
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

    // MARK: - Get App Check Token

    private func getAppCheckToken() async -> String? {
        #if DEBUG
        debugLog("⚠️ [IdolRankingService] App Check skipped in DEBUG mode")
        return nil
        #else
        do {
            let token = try await AppCheck.appCheck().token(forcingRefresh: false)
            return token.token
        } catch {
            debugLog("❌ [IdolRankingService] App Check token error: \(error)")
            return nil
        }
        #endif
    }

    // MARK: - Get Ranking

    func getRanking(
        type: RankingType,
        period: RankingPeriod,
        limit: Int = 50,
        offset: Int = 0,
        refresh: Bool = false
    ) async throws -> GetRankingResponse {
        var components = URLComponents(string: Constants.API.idolRankingGetRanking)!
        var queryItems = [
            URLQueryItem(name: "rankingType", value: type.rawValue),
            URLQueryItem(name: "period", value: period.rawValue),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        // Add refresh parameter to bypass CDN cache after voting
        if refresh {
            queryItems.append(URLQueryItem(name: "refresh", value: "true"))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw IdolRankingError.networkError(URLError(.badURL))
        }

        let token = try await getAuthToken()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Bypass URLSession cache when refresh is requested
        if refresh {
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Debug logging
            #if DEBUG
            if let httpResponse = response as? HTTPURLResponse {
                print("[IdolRankingService] getRanking HTTP Status: \(httpResponse.statusCode), refresh=\(refresh)")
            }
            if refresh {
                // Log first ranking entry to verify data
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("[IdolRankingService] Response preview: \(jsonStr.prefix(500))")
                }
            }
            #endif

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
        let appCheckToken = await getAppCheckToken()

        guard let url = URL(string: Constants.API.idolRankingVote) else {
            throw IdolRankingError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let appCheckToken = appCheckToken {
            request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
        }

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

            // HTTP 400もチェック（サーバーが投票制限エラーで400を返す場合がある）
            if httpResponse.statusCode == 400 {
                if let errorResponse = try? JSONDecoder().decode(ApiResponse<VoteResponse>.self, from: data),
                   let errorMessage = errorResponse.error,
                   errorMessage.contains("Daily vote limit") {
                    throw IdolRankingError.dailyLimitExceeded
                }
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

            let decoder = JSONDecoder()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                if let date = formatter.date(from: dateString) {
                    return date
                }
                // フォールバック: ミリ秒なしの形式も試す
                let fallbackFormatter = ISO8601DateFormatter()
                fallbackFormatter.formatOptions = [.withInternetDateTime]
                if let date = fallbackFormatter.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
            }
            let apiResponse = try decoder.decode(ApiResponse<DailyLimitResponse>.self, from: data)

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

    // MARK: - Get Archive List

    func getArchiveList() async throws -> ArchiveListResponse {
        var components = URLComponents(string: Constants.API.idolRankingGetArchiveList)!
        components.queryItems = [
            URLQueryItem(name: "archiveType", value: "monthly")
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

            guard let httpResponse = response as? HTTPURLResponse else {
                throw IdolRankingError.networkError(URLError(.badServerResponse))
            }

            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ApiResponse<ArchiveListResponse>.self, from: data) {
                    throw IdolRankingError.serverError(errorResponse.error ?? "Unknown error")
                }
                throw IdolRankingError.serverError("Server error: \(httpResponse.statusCode)")
            }

            let apiResponse = try JSONDecoder().decode(ApiResponse<ArchiveListResponse>.self, from: data)

            guard let archiveData = apiResponse.data else {
                throw IdolRankingError.serverError(apiResponse.error ?? "No data received")
            }

            return archiveData
        } catch let error as IdolRankingError {
            throw error
        } catch let decodingError as DecodingError {
            throw IdolRankingError.decodingError(decodingError)
        } catch {
            throw IdolRankingError.networkError(error)
        }
    }

    // MARK: - Get Archive Detail

    func getArchive(
        archiveId: String,
        rankingType: RankingType,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> ArchiveDetailResponse {
        var components = URLComponents(string: Constants.API.idolRankingGetArchive)!
        components.queryItems = [
            URLQueryItem(name: "archiveType", value: "monthly"),
            URLQueryItem(name: "archiveId", value: archiveId),
            URLQueryItem(name: "rankingType", value: rankingType.rawValue),
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

            guard let httpResponse = response as? HTTPURLResponse else {
                throw IdolRankingError.networkError(URLError(.badServerResponse))
            }

            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode(ApiResponse<ArchiveDetailResponse>.self, from: data) {
                    throw IdolRankingError.serverError(errorResponse.error ?? "Unknown error")
                }
                throw IdolRankingError.serverError("Server error: \(httpResponse.statusCode)")
            }

            let apiResponse = try JSONDecoder().decode(ApiResponse<ArchiveDetailResponse>.self, from: data)

            guard let archiveData = apiResponse.data else {
                throw IdolRankingError.serverError(apiResponse.error ?? "No data received")
            }

            return archiveData
        } catch let error as IdolRankingError {
            throw error
        } catch let decodingError as DecodingError {
            throw IdolRankingError.decodingError(decodingError)
        } catch {
            throw IdolRankingError.networkError(error)
        }
    }
}
