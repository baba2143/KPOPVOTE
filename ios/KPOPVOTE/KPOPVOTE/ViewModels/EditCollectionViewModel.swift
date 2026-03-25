//
//  EditCollectionViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Edit Collection ViewModel
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import UIKit

@MainActor
class EditCollectionViewModel: ObservableObject {
    // MARK: - Published Properties

    // Form Fields
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var tags: [String] = []
    @Published var coverImage: UIImage?
    @Published var coverImageUrl: String?
    @Published var selectedTasks: [VoteTask] = []
    @Published var visibility: CollectionVisibility = .public

    // Available Tasks
    @Published var userTasks: [VoteTask] = []

    // UI State
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var showImagePicker: Bool = false

    // Collection Data
    let collectionId: String
    private var originalCollection: VoteCollection?

    // MARK: - Private Properties
    private let taskService = TaskService()
    private let collectionService = CollectionService.shared

    // MARK: - Initialization

    init(collectionId: String) {
        self.collectionId = collectionId
    }

    // MARK: - Validation

    /// Check if form can be updated
    var canUpdate: Bool {
        !title.isEmpty &&
        title.count <= 50 &&
        description.count <= 500 &&
        tags.count <= 10 &&
        selectedTasks.count > 0 &&
        selectedTasks.count <= 50
    }

    // MARK: - Load Data

    /// Load collection data and user tasks
    func loadCollectionData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load collection details
            let response = try await collectionService.getCollectionDetail(collectionId: collectionId)
            let collection = response.data.collection

            // Store original collection
            originalCollection = collection

            // Populate form fields
            title = collection.title
            description = collection.description
            tags = collection.tags
            coverImageUrl = collection.coverImage
            visibility = collection.visibility

            // Load user's tasks
            userTasks = try await taskService.getUserTasks(isCompleted: false)

            // Pre-select tasks that are in the collection
            selectedTasks = userTasks.filter { userTask in
                collection.tasks.contains(where: { $0.id == userTask.id })
            }

            debugLog("✅ [EditCollectionViewModel] Loaded collection data: \(collection.title)")
        } catch {
            let errorType = NetworkErrorHandler.parseError(error)
            errorMessage = errorType.userMessage
            showError = true
            debugLog("❌ [EditCollectionViewModel] Failed to load collection: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Task Selection

    /// Toggle task selection
    func toggleTaskSelection(_ task: VoteTask) {
        if selectedTasks.contains(where: { $0.id == task.id }) {
            selectedTasks.removeAll { $0.id == task.id }
        } else {
            if selectedTasks.count < 50 {
                selectedTasks.append(task)
            }
        }
    }

    // MARK: - Tag Management

    /// Add tag
    func addTag(_ tag: String) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespaces)
        guard !trimmedTag.isEmpty else { return }
        guard tags.count < 10 else { return }
        guard !tags.contains(trimmedTag) else { return }

        tags.append(trimmedTag)
    }

    /// Remove tag
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    // MARK: - Image Upload

    /// Upload cover image to Firebase Storage
    private func uploadCoverImage() async throws -> String? {
        guard let image = coverImage else {
            // If no new image, keep the existing URL
            return coverImageUrl
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "EditCollectionViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        // Compress image
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "EditCollectionViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        // Upload to Firebase Storage
        let fileName = "\(userId)_\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("collection_covers/\(fileName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }

    // MARK: - Update Collection

    /// Update the collection
    func updateCollection() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            // Upload cover image if changed
            let coverImageUrl = try await uploadCoverImage()

            // Get task IDs in order
            let taskIds = selectedTasks.map { $0.id }

            // Update collection
            let response = try await collectionService.updateCollection(
                collectionId: collectionId,
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                coverImage: coverImageUrl,
                tags: tags,
                taskIds: taskIds,
                visibility: visibility.rawValue
            )

            debugLog("✅ [EditCollectionViewModel] Collection updated: \(response.data.collection.id)")

            isLoading = false
            return true
        } catch {
            let errorType = NetworkErrorHandler.parseError(error)
            errorMessage = errorType.userMessage
            showError = true
            debugLog("❌ [EditCollectionViewModel] Failed to update collection: \(error.localizedDescription)")

            isLoading = false
            return false
        }
    }
}
