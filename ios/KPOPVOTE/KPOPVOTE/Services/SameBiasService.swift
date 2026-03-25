//
//  SameBiasService.swift
//  OSHI Pick
//
//  OSHI Pick - Same Bias Fans Service
//

import Foundation
import FirebaseAuth

class SameBiasService {
    static let shared = SameBiasService()

    private init() {}

    // MARK: - Get Same Bias Users
    /// Fetch users who added the same bias in the past 24 hours
    /// - Parameters:
    ///   - biasId: The bias ID (idol or group ID)
    ///   - biasType: The bias type ("group" or "member")
    /// - Returns: SameBiasUsersResponse containing users list
    func fetchSameBiasUsers(biasId: String, biasType: String) async throws -> SameBiasUsersData {
        let token = try await FirebaseTokenHelper.shared.getToken()

        var urlComponents = URLComponents(string: Constants.API.getSameBiasUsers)!
        urlComponents.queryItems = [
            URLQueryItem(name: "biasId", value: biasId),
            URLQueryItem(name: "biasType", value: biasType)
        ]

        guard let url = urlComponents.url else {
            throw SameBiasError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("👥 [SameBiasService] Fetching same bias users: biasId=\(biasId), biasType=\(biasType)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SameBiasError.invalidResponse
        }

        debugLog("📥 [SameBiasService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [SameBiasService] Error: \(errorString)")
            }
            throw SameBiasError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(SameBiasUsersResponse.self, from: data)
        debugLog("✅ [SameBiasService] Fetched \(result.data.users.count) same bias users")

        return result.data
    }
}

// MARK: - Response Models
struct SameBiasUsersResponse: Codable {
    let success: Bool
    let data: SameBiasUsersData
}

struct SameBiasUsersData: Codable {
    let biasId: String
    let biasType: String
    let biasName: String
    let users: [SameBiasUser]
    let totalCount: Int
}

struct SameBiasUser: Codable, Identifiable {
    let userId: String
    let displayName: String?
    let photoURL: String?
    let addedAt: String

    var id: String { userId }

    var addedAtDate: Date? {
        ISO8601DateFormatter().date(from: addedAt)
    }
}

// MARK: - Errors
enum SameBiasError: Error, LocalizedError {
    case invalidResponse
    case fetchFailed
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .fetchFailed:
            return "Failed to fetch same bias users"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}
