//
//  BiasService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Bias Settings Service
//

import Foundation
import FirebaseAuth

class BiasService {
    static let shared = BiasService()

    private init() {}

    /// Get user's current bias settings
    /// - Returns: Array of BiasSettings
    func getBias() async throws -> [BiasSettings] {
        // Get authentication token
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw BiasError.notAuthenticated
        }

        // Create request
        let url = URL(string: Constants.API.getBias)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [BiasService] Getting bias settings")

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BiasError.invalidResponse
        }

        print("📥 [BiasService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [BiasService] Error response: \(errorString)")
            }
            throw BiasError.fetchFailed
        }

        // Decode response
        let result = try JSONDecoder().decode(BiasResponse.self, from: data)

        print("✅ [BiasService] Successfully fetched bias settings: \(result.data.myBias.count) groups")

        return result.data.myBias
    }

    /// Set user's bias settings
    /// - Parameter biasSettings: Array of BiasSettings to save
    func setBias(_ biasSettings: [BiasSettings]) async throws {
        // Get authentication token
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw BiasError.notAuthenticated
        }

        // Create request
        let url = URL(string: Constants.API.setBias)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode body
        let body = ["myBias": biasSettings]
        request.httpBody = try JSONEncoder().encode(body)

        print("📤 [BiasService] Setting bias: \(biasSettings.count) groups")

        // Execute request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BiasError.invalidResponse
        }

        print("📥 [BiasService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [BiasService] Error response: \(errorString)")
            }
            throw BiasError.saveFailed
        }

        // Decode response to verify
        _ = try JSONDecoder().decode(BiasResponse.self, from: data)

        print("✅ [BiasService] Successfully saved bias settings")
    }
}

// MARK: - Response Models
struct BiasResponse: Codable {
    let success: Bool
    let data: BiasData
}

struct BiasData: Codable {
    let myBias: [BiasSettings]
}

// MARK: - Errors
enum BiasError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case fetchFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .fetchFailed:
            return "推し設定の取得に失敗しました"
        case .saveFailed:
            return "推し設定の保存に失敗しました"
        }
    }
}
