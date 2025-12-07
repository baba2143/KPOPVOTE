//
//  CreateCollectionViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Create Collection ViewModel (Phase 2 - Week 3)
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import UIKit

@MainActor
class CreateCollectionViewModel: ObservableObject {
    // MARK: - Published Properties

    // Form Fields
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var tags: [String] = []
    @Published var coverImage: UIImage?
    @Published var selectedTasks: [VoteTask] = []
    @Published var visibility: CollectionVisibility = .public

    // Available Tasks
    @Published var userTasks: [VoteTask] = []

    // UI State
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showImagePicker: Bool = false
    @Published var showCommunityShareDialog: Bool = false
    @Published var showBiasSelectionSheet: Bool = false
    @Published var isSharing: Bool = false
    @Published var createdCollectionId: String?

    // MARK: - Private Properties
    private let taskService = TaskService()
    private let collectionService = CollectionService.shared

    // MARK: - Validation

    /// Check if form can be submitted
    var canCreate: Bool {
        !title.isEmpty &&
        title.count <= 50 &&
        description.count <= 500 &&
        tags.count <= 10 &&
        selectedTasks.count > 0 &&
        selectedTasks.count <= 50
    }

    // MARK: - Load Data

    /// Load user's existing tasks for selection
    func loadUserTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get all non-completed tasks
            userTasks = try await taskService.getUserTasks(isCompleted: false)
            debugLog("✅ [CreateCollectionViewModel] Loaded \(userTasks.count) user tasks")
        } catch {
            let errorType = NetworkErrorHandler.parseError(error)
            errorMessage = errorType.userMessage
            showError = true
            debugLog("❌ [CreateCollectionViewModel] Failed to load tasks: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Task Selection

    /// Toggle task selection
    func toggleTaskSelection(_ task: VoteTask) {
        if selectedTasks.contains(where: { $0.id == task.id }) {
            selectedTasks.removeAll { $0.id == task.id }
            debugLog("📋 [CreateCollectionViewModel] Deselected task: \(task.title)")
        } else {
            // Check max limit
            if selectedTasks.count >= 50 {
                errorMessage = "最大50個のタスクまで選択できます"
                showError = true
                return
            }
            selectedTasks.append(task)
            debugLog("📋 [CreateCollectionViewModel] Selected task: \(task.title)")
        }
    }

    // MARK: - Create Collection

    /// Create new collection
    /// - Returns: Success status
    func createCollection() async -> Bool {
        // Detailed validation with specific error messages
        if title.isEmpty {
            errorMessage = "タイトルを入力してください"
            showError = true
            return false
        }

        if title.count > 50 {
            errorMessage = "タイトルは50文字以内にしてください"
            showError = true
            return false
        }

        if description.count > 500 {
            errorMessage = "説明は500文字以内にしてください"
            showError = true
            return false
        }

        if tags.count > 10 {
            errorMessage = "タグは10個までです"
            showError = true
            return false
        }

        if selectedTasks.isEmpty {
            errorMessage = "タスクを1つ以上選択してください"
            showError = true
            return false
        }

        if selectedTasks.count > 50 {
            errorMessage = "タスクは50個までです"
            showError = true
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            // Step 1: Upload cover image if present
            var coverImageUrl: String?
            if let image = coverImage {
                coverImageUrl = try await uploadCoverImage(image)
                debugLog("✅ [CreateCollectionViewModel] Cover image uploaded: \(coverImageUrl ?? "")")
            }

            // Step 2: Get authentication token
            guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                throw CreateCollectionError.notAuthenticated
            }

            // Step 3: Prepare collection data
            let collectionData = CreateCollectionRequest(
                title: title,
                description: description,
                tags: tags,
                coverImage: coverImageUrl,
                tasks: selectedTasks.enumerated().map { (index, task) in
                    CreateCollectionRequest.TaskInput(
                        taskId: task.id,
                        orderIndex: index
                    )
                },
                visibility: visibility.rawValue
            )

            // Step 4: Create API request
            guard let url = URL(string: Constants.API.collections) else {
                throw CreateCollectionError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(collectionData)

            debugLog("📡 [CreateCollectionViewModel] Creating collection: \(title)")

            // Step 5: Send request
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CreateCollectionError.invalidResponse
            }

            debugLog("📥 [CreateCollectionViewModel] HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 201 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    debugLog("❌ [CreateCollectionViewModel] Error response: \(errorString)")
                }
                throw CreateCollectionError.serverError(httpResponse.statusCode)
            }

            // Step 6: Parse response
            let result = try JSONDecoder().decode(CreateCollectionResponse.self, from: data)
            debugLog("✅ [CreateCollectionViewModel] Collection created: \(result.data.collectionId)")

            // Store collection ID and show community share dialog
            createdCollectionId = result.data.collectionId
            isLoading = false
            showCommunityShareDialog = true

            return true

        } catch {
            // Use NetworkErrorHandler for better error messages
            let errorType = NetworkErrorHandler.parseError(error)
            errorMessage = errorType.userMessage
            showError = true
            isLoading = false
            debugLog("❌ [CreateCollectionViewModel] Create failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Image Upload

    /// Upload cover image to Firebase Storage
    /// - Parameter image: UIImage to upload
    /// - Returns: Download URL string
    private func uploadCoverImage(_ image: UIImage) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw CreateCollectionError.notAuthenticated
        }

        // Compress and convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CreateCollectionError.imageCompressionFailed
        }

        // Check file size (max 10MB)
        let maxSize = 10 * 1024 * 1024 // 10MB
        guard imageData.count <= maxSize else {
            throw CreateCollectionError.imageTooLarge
        }

        // Create unique filename
        let filename = "\(UUID().uuidString).jpg"
        let storagePath = "collection-cover-images/\(userId)/\(filename)"

        // Get Firebase Storage reference
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child(storagePath)

        debugLog("📤 [CreateCollectionViewModel] Uploading cover image to: \(storagePath)")

        // Upload image data
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await imageRef.downloadURL()
        let downloadURLString = downloadURL.absoluteString

        debugLog("✅ [CreateCollectionViewModel] Cover image uploaded: \(downloadURLString)")

        return downloadURLString
    }

    // MARK: - Helper Methods

    /// Clear all form fields
    func clearForm() {
        title = ""
        description = ""
        tags = []
        coverImage = nil
        selectedTasks = []
        visibility = .public
    }

    // MARK: - Share to Community

    /// Share collection to community timeline
    /// - Parameters:
    ///   - biasIds: Selected bias (idol) IDs for post targeting
    ///   - text: Optional message text
    func shareToCommunity(biasIds: [String], text: String? = nil) async {
        guard let collectionId = createdCollectionId else {
            errorMessage = "コレクションIDが見つかりません"
            showError = true
            return
        }

        guard !biasIds.isEmpty else {
            errorMessage = "推しを選択してください"
            showError = true
            return
        }

        isSharing = true
        errorMessage = nil

        do {
            debugLog("📤 [CreateCollectionViewModel] Sharing collection to community...")
            debugLog("   CollectionId: \(collectionId)")
            debugLog("   BiasIds: \(biasIds)")

            _ = try await collectionService.shareCollectionToCommunity(
                collectionId: collectionId,
                biasIds: biasIds,
                text: text
            )

            debugLog("✅ [CreateCollectionViewModel] Successfully shared to community")
            isSharing = false

            // Success - the view will dismiss automatically

        } catch {
            debugLog("❌ [CreateCollectionViewModel] Failed to share: \(error.localizedDescription)")
            errorMessage = "コミュニティへの投稿に失敗しました: \(error.localizedDescription)"
            showError = true
            isSharing = false
        }
    }
}

// MARK: - Request Model

struct CreateCollectionRequest: Codable {
    let title: String
    let description: String
    let tags: [String]
    let coverImage: String?
    let tasks: [TaskInput]
    let visibility: String

    struct TaskInput: Codable {
        let taskId: String
        let orderIndex: Int
    }
}

// MARK: - Response Model

struct CreateCollectionResponse: Codable {
    let success: Bool
    let data: CreateCollectionData

    struct CreateCollectionData: Codable {
        let collectionId: String
        let title: String
        let createdAt: String
    }
}

// MARK: - Error Types

enum CreateCollectionError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case imageCompressionFailed
    case imageTooLarge

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .serverError(let code):
            return "サーバーエラーが発生しました (コード: \(code))"
        case .imageCompressionFailed:
            return "画像の圧縮に失敗しました"
        case .imageTooLarge:
            return "画像サイズが大きすぎます (最大10MB)"
        }
    }
}
