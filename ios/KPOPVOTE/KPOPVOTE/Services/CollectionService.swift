//
//  CollectionService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Collection Service (Phase 2)
//

import Foundation
import FirebaseAuth

class CollectionService {
    static let shared = CollectionService()

    private init() {}

    // MARK: - Get Collections

    /// Fetch collections list with pagination and filtering
    /// - Parameters:
    ///   - page: Page number (default: 1)
    ///   - limit: Items per page (default: 20, max: 50)
    ///   - sortBy: Sort option (latest/popular/trending)
    ///   - tags: Filter by tags (optional)
    /// - Returns: Collections list with pagination info
    func getCollections(
        page: Int = 1,
        limit: Int = 20,
        sortBy: String = "latest",
        tags: [String]? = nil
    ) async throws -> CollectionsListResponse {
        var urlComponents = URLComponents(string: Constants.API.collections)!

        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        if let tags = tags {
            for tag in tags {
                queryItems.append(URLQueryItem(name: "tags", value: tag))
            }
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"

        print("🔍 [CollectionService] Fetching collections from: \(urlComponents.url!.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollectionError.invalidResponse
        }

        print("📥 [CollectionService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw CollectionError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let dict = try? container.decode([String: Any].self),
               let seconds = dict["_seconds"] as? Double {
                return Date(timeIntervalSince1970: seconds)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        let result = try decoder.decode(CollectionsListResponse.self, from: data)
        print("✅ [CollectionService] Successfully fetched \(result.data.collections.count) collections")

        return result
    }

    /// Search collections by keyword
    /// - Parameters:
    ///   - query: Search keyword (required)
    ///   - page: Page number
    ///   - limit: Items per page
    ///   - sortBy: Sort option (relevance/latest/popular)
    ///   - tags: Filter by tags (optional)
    /// - Returns: Search results with pagination
    func searchCollections(
        query: String,
        page: Int = 1,
        limit: Int = 20,
        sortBy: String = "relevance",
        tags: [String]? = nil
    ) async throws -> CollectionsListResponse {
        var urlComponents = URLComponents(string: Constants.API.searchCollections)!

        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sortBy", value: sortBy)
        ]

        if let tags = tags {
            for tag in tags {
                queryItems.append(URLQueryItem(name: "tags", value: tag))
            }
        }

        urlComponents.queryItems = queryItems

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"

        print("🔍 [CollectionService] Searching collections: '\(query)'")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CollectionError.searchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let dict = try? container.decode([String: Any].self),
               let seconds = dict["_seconds"] as? Double {
                return Date(timeIntervalSince1970: seconds)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        let result = try decoder.decode(CollectionsListResponse.self, from: data)
        print("✅ [CollectionService] Found \(result.data.collections.count) collections")

        return result
    }

    /// Get trending collections based on recent engagement
    /// - Parameters:
    ///   - period: Time period (24h/7d/30d)
    ///   - limit: Number of items (max: 50)
    /// - Returns: Trending collections array
    func getTrendingCollections(
        period: String = "7d",
        limit: Int = 10
    ) async throws -> [VoteCollection] {
        var urlComponents = URLComponents(string: Constants.API.trendingCollections)!

        urlComponents.queryItems = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"

        print("🔍 [CollectionService] Fetching trending collections (period: \(period))")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CollectionError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let dict = try? container.decode([String: Any].self),
               let seconds = dict["_seconds"] as? Double {
                return Date(timeIntervalSince1970: seconds)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        let result = try decoder.decode(TrendingCollectionsResponse.self, from: data)
        print("✅ [CollectionService] Fetched \(result.data.collections.count) trending collections")

        return result.data.collections
    }

    /// Get collection detail by ID
    /// - Parameter collectionId: Collection ID
    /// - Returns: Collection detail with user-specific data
    func getCollectionDetail(collectionId: String) async throws -> CollectionDetailResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CollectionError.notAuthenticated
        }

        let url = URL(string: "\(Constants.API.collections)/\(collectionId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [CollectionService] Fetching collection detail: \(collectionId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CollectionError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let dict = try? container.decode([String: Any].self),
               let seconds = dict["_seconds"] as? Double {
                return Date(timeIntervalSince1970: seconds)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        let result = try decoder.decode(CollectionDetailResponse.self, from: data)
        print("✅ [CollectionService] Successfully fetched collection detail")

        return result
    }

    // MARK: - User Collections

    /// Get user's saved collections
    /// - Parameters:
    ///   - page: Page number
    ///   - limit: Items per page
    /// - Returns: Saved collections list
    func getSavedCollections(
        page: Int = 1,
        limit: Int = 20
    ) async throws -> CollectionsListResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CollectionError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.savedCollections)!

        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [CollectionService] Fetching saved collections")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CollectionError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let dict = try? container.decode([String: Any].self),
               let seconds = dict["_seconds"] as? Double {
                return Date(timeIntervalSince1970: seconds)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        let result = try decoder.decode(CollectionsListResponse.self, from: data)
        print("✅ [CollectionService] Fetched \(result.data.collections.count) saved collections")

        return result
    }

    /// Get user's created collections
    /// - Parameters:
    ///   - page: Page number
    ///   - limit: Items per page
    /// - Returns: User's collections list
    func getMyCollections(
        page: Int = 1,
        limit: Int = 20
    ) async throws -> CollectionsListResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CollectionError.notAuthenticated
        }

        var urlComponents = URLComponents(string: Constants.API.myCollections)!

        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("🔍 [CollectionService] Fetching my collections")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CollectionError.fetchFailed
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let dict = try? container.decode([String: Any].self),
               let seconds = dict["_seconds"] as? Double {
                return Date(timeIntervalSince1970: seconds)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
        }

        let result = try decoder.decode(CollectionsListResponse.self, from: data)
        print("✅ [CollectionService] Fetched \(result.data.collections.count) created collections")

        return result
    }

    // MARK: - Save/Unsave Collection

    /// Save or unsave a collection
    /// - Parameter collectionId: Collection ID
    /// - Returns: Save status response
    func toggleSaveCollection(collectionId: String) async throws -> SaveCollectionResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CollectionError.notAuthenticated
        }

        let url = URL(string: "\(Constants.API.collections)/\(collectionId)/save")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("🔄 [CollectionService] Toggling save for collection: \(collectionId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CollectionError.saveFailed
        }

        let result = try JSONDecoder().decode(SaveCollectionResponse.self, from: data)
        print("✅ [CollectionService] Save toggled: \(result.data.saved ? "Saved" : "Unsaved")")

        return result
    }

    // MARK: - Add Tasks to User's Task List

    /// Bulk add collection tasks to user's TASKS tab
    /// - Parameter collectionId: Collection ID
    /// - Returns: Add tasks response with counts
    func addCollectionToTasks(collectionId: String) async throws -> AddToTasksResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CollectionError.notAuthenticated
        }

        let url = URL(string: "\(Constants.API.collections)/\(collectionId)/add-to-tasks")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        print("📥 [CollectionService] Adding collection tasks: \(collectionId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CollectionError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CollectionError.addToTasksFailed
        }

        let result = try JSONDecoder().decode(AddToTasksResponse.self, from: data)
        print("✅ [CollectionService] Added \(result.data.addedCount) tasks (skipped \(result.data.skippedCount) duplicates)")

        return result
    }
}

// MARK: - Response Models

struct CollectionsListResponse: Codable {
    let success: Bool
    let data: CollectionsData
}

struct CollectionsData: Codable {
    let collections: [VoteCollection]
    let pagination: PaginationInfo
}

struct PaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalCount: Int
    let hasNext: Bool
}

struct TrendingCollectionsResponse: Codable {
    let success: Bool
    let data: TrendingData
}

struct TrendingData: Codable {
    let collections: [VoteCollection]
    let period: String
}

struct CollectionDetailResponse: Codable {
    let success: Bool
    let data: CollectionDetailData
}

struct CollectionDetailData: Codable {
    let collection: VoteCollection
    let isSaved: Bool
    let isLiked: Bool
    let isOwner: Bool
}

struct SaveCollectionResponse: Codable {
    let success: Bool
    let data: SaveData
}

struct SaveData: Codable {
    let saved: Bool
    let saveCount: Int
}

struct AddToTasksResponse: Codable {
    let success: Bool
    let data: AddToTasksData
}

struct AddToTasksData: Codable {
    let addedCount: Int
    let skippedCount: Int
    let totalCount: Int
    let addedTaskIds: [String]
}

// MARK: - Error Types

enum CollectionError: Error, LocalizedError {
    case notAuthenticated
    case invalidResponse
    case fetchFailed
    case searchFailed
    case saveFailed
    case addToTasksFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .fetchFailed:
            return "コレクションの取得に失敗しました"
        case .searchFailed:
            return "検索に失敗しました"
        case .saveFailed:
            return "保存に失敗しました"
        case .addToTasksFailed:
            return "タスクの追加に失敗しました"
        }
    }
}
