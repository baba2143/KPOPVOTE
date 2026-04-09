//
//  FanCardService.swift
//  KPOPVOTE
//
//  FanCard API Service
//

import Foundation
import FirebaseAuth

enum FanCardError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case odDisplayNameTaken
    case fanCardNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログインが必要です"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .serverError(let message):
            return message
        case .odDisplayNameTaken:
            return "このIDは既に使用されています"
        case .fanCardNotFound:
            return "FanCardが見つかりません"
        }
    }
}

class FanCardService {
    static let shared = FanCardService()
    private init() {}

    private let baseURL = Constants.API.baseURL

    // MARK: - Get Auth Token
    private func getAuthToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw FanCardError.notAuthenticated
        }
        return try await user.getIDToken()
    }

    // MARK: - Check odDisplayName Availability
    func checkOdDisplayName(_ name: String) async throws -> (available: Bool, normalized: String) {
        let url = URL(string: "\(baseURL)/checkOdDisplayName?odDisplayName=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)")!

        var request = URLRequest.withTimeout(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FanCardError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(FanCardAPIResponse<CheckNameDataResponse>.self, from: data)

        if httpResponse.statusCode == 200, decoded.success, let responseData = decoded.data {
            return (responseData.available, responseData.normalizedName)
        } else {
            throw FanCardError.serverError(decoded.error ?? "Unknown error")
        }
    }

    // MARK: - Create FanCard
    func createFanCard(request: FanCardCreateRequest) async throws -> FanCard {
        let token = try await getAuthToken()
        let url = URL(string: "\(baseURL)/createFanCard")!

        var urlRequest = URLRequest.withTimeout(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FanCardError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(FanCardAPIResponse<FanCardDataResponse>.self, from: data)

        if httpResponse.statusCode == 201 || httpResponse.statusCode == 200,
           decoded.success,
           let responseData = decoded.data {
            return responseData.fanCard
        } else if httpResponse.statusCode == 409 {
            throw FanCardError.odDisplayNameTaken
        } else {
            throw FanCardError.serverError(decoded.error ?? "Unknown error")
        }
    }

    // MARK: - Get My FanCard
    func getMyFanCard() async throws -> FanCard {
        let token = try await getAuthToken()
        let url = URL(string: "\(baseURL)/getFanCard")!

        var request = URLRequest.withTimeout(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FanCardError.invalidResponse
        }

        if httpResponse.statusCode == 404 {
            throw FanCardError.fanCardNotFound
        }

        let decoded = try JSONDecoder().decode(FanCardAPIResponse<FanCardDataResponse>.self, from: data)

        if decoded.success, let responseData = decoded.data {
            return responseData.fanCard
        } else {
            throw FanCardError.serverError(decoded.error ?? "Unknown error")
        }
    }

    // MARK: - Update FanCard
    func updateFanCard(request: FanCardUpdateRequest) async throws -> FanCard {
        let token = try await getAuthToken()
        let url = URL(string: "\(baseURL)/updateFanCard")!

        var urlRequest = URLRequest.withTimeout(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FanCardError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(FanCardAPIResponse<FanCardDataResponse>.self, from: data)

        if httpResponse.statusCode == 200, decoded.success, let responseData = decoded.data {
            return responseData.fanCard
        } else {
            throw FanCardError.serverError(decoded.error ?? "Unknown error")
        }
    }

    // MARK: - Delete FanCard
    func deleteFanCard() async throws {
        let token = try await getAuthToken()
        let url = URL(string: "\(baseURL)/deleteFanCard")!

        var request = URLRequest.withTimeout(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FanCardError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let decoded = try? JSONDecoder().decode(FanCardAPIResponse<String>.self, from: data)
            throw FanCardError.serverError(decoded?.error ?? "Unknown error")
        }
    }

    // MARK: - Get FanCard Share URL
    func getFanCardShareURL(odDisplayName: String) -> URL {
        // Vercel deployment URL
        URL(string: "https://kpopvote-fancard.vercel.app/\(odDisplayName)")!
    }
}
