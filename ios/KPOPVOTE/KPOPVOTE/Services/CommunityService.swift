//
//  CommunityService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Community Service (Posts)
//

import Foundation
import FirebaseAuth

class CommunityService {
    static let shared = CommunityService()

    private init() {}

    // MARK: - Create Post
    /// Create a new post
    /// - Parameters:
    ///   - type: Post type (vote_share, image, my_votes)
    ///   - content: Post content
    ///   - biasIds: Array of bias IDs
    /// - Returns: Created post data
    func createPost(type: PostType, content: PostContent, biasIds: [String]) async throws -> CommunityPost {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.createPost) else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "type": type.rawValue,
            "content": content.toDictionary(),
            "biasIds": biasIds
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("📤 [CommunityService] Creating post: type=\(type.rawValue), biasIds=\(biasIds.count)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 201 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.createFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(PostResponse.self, from: data)
        print("✅ [CommunityService] Post created successfully")

        return result.data
    }

    // MARK: - Get Post
    /// Fetch post detail
    /// - Parameter postId: Post ID
    /// - Returns: Post with full details
    func fetchPost(postId: String) async throws -> CommunityPost {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getPost)!
        urlComponents.queryItems = [URLQueryItem(name: "postId", value: postId)]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [CommunityService] Fetching post: \(postId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(PostResponse.self, from: data)
        print("✅ [CommunityService] Post fetched successfully")

        return result.data
    }

    // MARK: - Get Posts
    /// Fetch posts list (timeline)
    /// - Parameters:
    ///   - type: Timeline type (bias or following)
    ///   - biasId: Bias ID (required for bias timeline)
    ///   - limit: Number of posts to fetch
    ///   - lastPostId: Last post ID for pagination
    /// - Returns: Array of posts and hasMore flag
    func fetchPosts(type: String, biasId: String? = nil, limit: Int = 20, lastPostId: String? = nil) async throws -> (posts: [CommunityPost], hasMore: Bool) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getPosts)!
        var queryItems = [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        if let biasId = biasId {
            queryItems.append(URLQueryItem(name: "biasId", value: biasId))
        }

        if let lastPostId = lastPostId {
            queryItems.append(URLQueryItem(name: "lastPostId", value: lastPostId))
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [CommunityService] Fetching posts: type=\(type), biasId=\(biasId ?? "nil")")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(PostListResponse.self, from: data)
        print("✅ [CommunityService] Fetched \(result.data.posts.count) posts")

        return (result.data.posts, result.data.hasMore)
    }

    // MARK: - Like Post
    /// Like or unlike a post (toggle)
    /// - Parameter postId: Post ID
    /// - Returns: Action result (liked or unliked)
    func likePost(postId: String) async throws -> PostActionResult {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.likePost) else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["postId": postId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("💗 [CommunityService] Toggling like for post: \(postId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.updateFailed
        }

        let result = try JSONDecoder().decode(PostActionResponse.self, from: data)
        print("✅ [CommunityService] Like toggled: \(result.data.action)")

        return result.data
    }

    // MARK: - Get My Votes
    /// Fetch user's vote history
    /// - Returns: Array of user's votes
    func fetchMyVotes() async throws -> [MyVoteItem] {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.getMyVotes) else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [CommunityService] Fetching my votes")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let result = try decoder.decode(CommunityMyVotesResponse.self, from: data)
        print("✅ [CommunityService] Fetched \(result.data.voteHistory.count) votes")

        return result.data.voteHistory
    }

    // MARK: - Delete Post
    /// Delete a post
    /// - Parameter postId: Post ID
    func deletePost(postId: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.deletePost) else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["postId": postId]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("🗑️ [CommunityService] Deleting post: \(postId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.deleteFailed
        }

        print("✅ [CommunityService] Post deleted successfully")
    }

    // MARK: - Create Comment
    /// Create a comment on a post
    /// - Parameters:
    ///   - postId: Post ID
    ///   - text: Comment text
    /// - Returns: Comment ID and updated comments count
    func createComment(postId: String, text: String) async throws -> (commentId: String, commentsCount: Int) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.createComment) else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "postId": postId,
            "text": text
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("💬 [CommunityService] Creating comment on post: \(postId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 201 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.commentFailed
        }

        struct CreateCommentResponse: Codable {
            let success: Bool
            let data: CommentData

            struct CommentData: Codable {
                let commentId: String
                let commentsCount: Int
            }
        }

        let result = try JSONDecoder().decode(CreateCommentResponse.self, from: data)
        print("✅ [CommunityService] Comment created: \(result.data.commentId)")

        return (result.data.commentId, result.data.commentsCount)
    }

    // MARK: - Get Comments
    /// Fetch comments for a post
    /// - Parameters:
    ///   - postId: Post ID
    ///   - limit: Number of comments to fetch
    ///   - lastCommentId: Last comment ID for pagination
    /// - Returns: Comments array and hasMore flag
    func fetchComments(postId: String, limit: Int = 20, lastCommentId: String? = nil) async throws -> (comments: [Comment], hasMore: Bool) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.getComments)!
        urlComponents.queryItems = [
            URLQueryItem(name: "postId", value: postId),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let lastCommentId = lastCommentId {
            urlComponents.queryItems?.append(URLQueryItem(name: "lastCommentId", value: lastCommentId))
        }

        guard let url = urlComponents.url else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("📥 [CommunityService] Fetching comments for post: \(postId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.fetchFailed
        }

        struct GetCommentsResponse: Codable {
            let success: Bool
            let data: CommentsResponse
        }

        let result = try JSONDecoder().decode(GetCommentsResponse.self, from: data)
        print("✅ [CommunityService] Fetched \(result.data.comments.count) comments")

        return (result.data.comments, result.data.hasMore)
    }

    // MARK: - Delete Comment
    /// Delete a comment
    /// - Parameter commentId: Comment ID
    func deleteComment(commentId: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CommunityError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.deleteComment)!
        urlComponents.queryItems = [
            URLQueryItem(name: "commentId", value: commentId)
        ]

        guard let url = urlComponents.url else {
            throw CommunityError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🗑️ [CommunityService] Deleting comment: \(commentId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunityError.invalidResponse
        }

        print("📥 [CommunityService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [CommunityService] Error: \(errorString)")
            }
            throw CommunityError.deleteFailed
        }

        print("✅ [CommunityService] Comment deleted successfully")
    }
}

// MARK: - Response Models
struct PostResponse: Codable {
    let success: Bool
    let data: CommunityPost
}

struct PostListResponse: Codable {
    let success: Bool
    let data: PostListData
}

struct PostListData: Codable {
    let posts: [CommunityPost]
    let hasMore: Bool
}

struct PostActionResponse: Codable {
    let success: Bool
    let data: PostActionResult
}

struct PostActionResult: Codable {
    let postId: String
    let action: String
    let likesCount: Int
}

struct CommunityMyVotesResponse: Codable {
    let success: Bool
    let data: CommunityMyVotesData
}

struct CommunityMyVotesData: Codable {
    let voteHistory: [MyVoteItem]
    let hasMore: Bool
    let summary: CommunityMyVotesSummary
}

struct CommunityMyVotesSummary: Codable {
    let totalVotes: Int
    let totalPointsUsed: Int
}

// MARK: - Helper Extension
extension PostContent {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]

        if let text = text {
            dict["text"] = text
        }

        if let images = images {
            dict["images"] = images
        }

        if let voteId = voteId {
            dict["voteId"] = voteId
        }

        if let voteSnapshot = voteSnapshot {
            // Convert InAppVote to dictionary
            dict["voteSnapshot"] = voteSnapshot.toDictionary()
        }

        if let myVotes = myVotes {
            dict["myVotes"] = myVotes.map { $0.toDictionary() }
        }

        if let goodsTrade = goodsTrade {
            var goodsDict: [String: Any] = [
                "idolId": goodsTrade.idolId,
                "idolName": goodsTrade.idolName,
                "groupName": goodsTrade.groupName,
                "goodsImageUrl": goodsTrade.goodsImageUrl,
                "goodsTags": goodsTrade.goodsTags,
                "goodsName": goodsTrade.goodsName,
                "tradeType": goodsTrade.tradeType,
                "status": goodsTrade.status
            ]

            if let condition = goodsTrade.condition {
                goodsDict["condition"] = condition
            }

            if let description = goodsTrade.description {
                goodsDict["description"] = description
            }

            dict["goodsTrade"] = goodsDict
        }

        return dict
    }
}

extension InAppVote {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["voteId"] = id
        dict["title"] = title
        dict["description"] = description
        dict["choices"] = choices.map { ["choiceId": $0.id, "label": $0.label, "voteCount": $0.voteCount] }
        dict["startDate"] = ISO8601DateFormatter().string(from: startDate)
        dict["endDate"] = ISO8601DateFormatter().string(from: endDate)
        dict["requiredPoints"] = requiredPoints
        dict["status"] = status.rawValue
        dict["totalVotes"] = totalVotes
        if let coverImageUrl = coverImageUrl {
            dict["coverImageUrl"] = coverImageUrl
        }
        dict["isFeatured"] = isFeatured
        return dict
    }
}

extension MyVoteItem {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["id"] = id
        dict["voteId"] = voteId
        dict["title"] = title
        if let selectedChoiceId = selectedChoiceId {
            dict["selectedChoiceId"] = selectedChoiceId
        }
        if let selectedChoiceLabel = selectedChoiceLabel {
            dict["selectedChoiceLabel"] = selectedChoiceLabel
        }
        dict["pointsUsed"] = pointsUsed
        dict["votedAt"] = ISO8601DateFormatter().string(from: votedAt)
        return dict
    }
}
