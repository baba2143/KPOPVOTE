//
//  FollowService.swift
//  OSHI Pick
//
//  OSHI Pick - Follow Service
//

import Foundation
import FirebaseAuth

class FollowService {
    static let shared = FollowService()

    private init() {}

    // MARK: - Follow User
    /// Follow a user
    /// - Parameter userId: User ID to follow
    /// - Returns: Follow data
    func followUser(userId: String) async throws -> FollowData {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.followUser) else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["userId": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        debugLog("👥 [FollowService] Following user: \(userId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        debugLog("📥 [FollowService] HTTP Status: \(httpResponse.statusCode)")

        // Handle "Already following" as success (HTTP 400 with specific error)
        if httpResponse.statusCode == 400 {
            if let errorString = String(data: data, encoding: .utf8),
               errorString.contains("Already following") {
                debugLog("ℹ️ [FollowService] Already following this user - treating as success")
                // Return dummy FollowData since user is already following
                return FollowData(
                    followId: "",
                    followerId: Auth.auth().currentUser?.uid ?? "",
                    followingId: userId,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )
            }
        }

        guard httpResponse.statusCode == 201 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [FollowService] Error: \(errorString)")
            }
            throw CommunityError.createFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(FollowResponse.self, from: data)
        debugLog("✅ [FollowService] User followed successfully")

        return result.data
    }

    // MARK: - Unfollow User
    /// Unfollow a user
    /// - Parameter userId: User ID to unfollow
    func unfollowUser(userId: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.unfollowUser) else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["userId": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        debugLog("👥 [FollowService] Unfollowing user: \(userId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        debugLog("📥 [FollowService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [FollowService] Error: \(errorString)")
            }
            throw CommunityError.deleteFailed
        }

        debugLog("✅ [FollowService] User unfollowed successfully")
    }

    // MARK: - Get Following
    /// Fetch following users list
    /// - Parameters:
    ///   - userId: User ID (optional, defaults to current user)
    ///   - limit: Number of users to fetch
    ///   - lastFollowId: Last follow ID for pagination
    /// - Returns: Array of users and hasMore flag
    func fetchFollowing(userId: String? = nil, limit: Int = 20, lastFollowId: String? = nil) async throws -> (users: [FollowUser], hasMore: Bool) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getFollowing)!
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        if let userId = userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }

        if let lastFollowId = lastFollowId {
            queryItems.append(URLQueryItem(name: "lastFollowId", value: lastFollowId))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [FollowService] Fetching following list")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        debugLog("📥 [FollowService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [FollowService] Error: \(errorString)")
            }
            throw CommunityError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(UserListResponse.self, from: data)
        debugLog("✅ [FollowService] Fetched \(result.data.users.count) following users")

        return (result.data.users, result.data.hasMore)
    }

    // MARK: - Get Followers
    /// Fetch followers list
    /// - Parameters:
    ///   - userId: User ID (optional, defaults to current user)
    ///   - limit: Number of users to fetch
    ///   - lastFollowId: Last follow ID for pagination
    /// - Returns: Array of users and hasMore flag
    func fetchFollowers(userId: String? = nil, limit: Int = 20, lastFollowId: String? = nil) async throws -> (users: [FollowUser], hasMore: Bool) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getFollowers)!
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        if let userId = userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }

        if let lastFollowId = lastFollowId {
            queryItems.append(URLQueryItem(name: "lastFollowId", value: lastFollowId))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [FollowService] Fetching followers list")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        debugLog("📥 [FollowService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [FollowService] Error: \(errorString)")
            }
            throw CommunityError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(UserListResponse.self, from: data)
        debugLog("✅ [FollowService] Fetched \(result.data.users.count) followers")

        return (result.data.users, result.data.hasMore)
    }

    // MARK: - Get Recommended Users
    /// Fetch recommended users based on shared biasIds
    /// - Parameter limit: Number of users to fetch
    /// - Returns: Array of recommended users
    func fetchRecommendedUsers(limit: Int = 10) async throws -> [RecommendedUser] {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getRecommendedUsers)!
        urlComponents.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🔍 [FollowService] Fetching recommended users")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        debugLog("📥 [FollowService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [FollowService] Error: \(errorString)")
            }
            throw CommunityError.fetchFailed
        }

        let result = try JSONDecoder().decode(RecommendedUsersResponse.self, from: data)
        debugLog("✅ [FollowService] Fetched \(result.data.users.count) recommended users")

        return result.data.users
    }
}

// MARK: - Response Models
struct FollowResponse: Codable {
    let success: Bool
    let data: FollowData
}

struct FollowData: Codable {
    let followId: String
    let followerId: String
    let followingId: String
    let createdAt: String
}

struct UserListResponse: Codable {
    let success: Bool
    let data: UserListData
}

struct UserListData: Codable {
    let users: [FollowUser]
    let hasMore: Bool
}

struct FollowUser: Codable, Identifiable {
    let followId: String
    let userId: String
    let displayName: String?
    let photoURL: String?
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let isFollowedByCurrentUser: Bool
    let followedAt: String?

    var id: String { followId }
}

struct RecommendedUsersResponse: Codable {
    let success: Bool
    let data: RecommendedUsersData
}

struct RecommendedUsersData: Codable {
    let users: [RecommendedUser]
}

struct RecommendedUser: Codable {
    let userId: String
    let displayName: String?
    let photoURL: String?
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let sharedBiasCount: Int
    let sharedBiasIds: [String]
}
