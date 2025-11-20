//
//  ProfileService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Profile Service
//

import Foundation
import FirebaseAuth

class ProfileService {
    static let shared = ProfileService()

    private init() {}

    // MARK: - Update Profile
    func updateProfile(displayName: String?, bio: String?, biasIds: [String]?) async throws -> User {
        guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
            throw ProfileError.notAuthenticated
        }

        let url = URL(string: "\(Constants.API.baseURL)/updateUserProfile")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [:]
        if let displayName = displayName {
            body["displayName"] = displayName
        }
        if let bio = bio {
            body["bio"] = bio
        }
        if let biasIds = biasIds {
            body["biasIds"] = biasIds
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📱 [ProfileService] Updating profile...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileError.invalidResponse
        }

        print("📥 [ProfileService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw ProfileError.updateFailed
        }

        let result = try JSONDecoder().decode(UpdateProfileResponse.self, from: data)

        guard result.success, let userData = result.data else {
            throw ProfileError.updateFailed
        }

        print("✅ [ProfileService] Profile updated successfully")

        return userData
    }
}

// MARK: - Response Types
struct UpdateProfileResponse: Codable {
    let success: Bool
    let data: User?
}

// MARK: - Profile Errors
enum ProfileError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case updateFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証されていません"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .updateFailed:
            return "プロフィールの更新に失敗しました"
        }
    }
}
