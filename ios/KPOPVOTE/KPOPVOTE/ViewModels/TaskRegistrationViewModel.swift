//
//  TaskRegistrationViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Task Registration ViewModel
//

import Foundation
import SwiftUI

@MainActor
class TaskRegistrationViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var url: String = ""
    @Published var deadline: Date = Date().addingTimeInterval(86400) // Default: 24 hours from now
    @Published var biasIdsText: String = "" // Comma-separated bias IDs

    // External App Selection
    @Published var externalApps: [ExternalAppMaster] = []
    @Published var selectedAppId: String? = nil

    // Cover Image Selection
    @Published var selectedCoverImage: UIImage? = nil
    @Published var coverImageURL: String? = nil
    @Published var coverImageSource: CoverImageSource? = nil
    @Published var isUploadingImage = false

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false

    private let taskService = TaskService()
    private let externalAppService = ExternalAppService()

    // MARK: - Load External Apps
    func loadExternalApps() async {
        do {
            print("📡 [TaskRegistrationViewModel] Loading external apps...")
            externalApps = try await externalAppService.getExternalApps()
            print("✅ [TaskRegistrationViewModel] Loaded \(externalApps.count) external apps")
        } catch {
            print("❌ [TaskRegistrationViewModel] Failed to load external apps: \(error.localizedDescription)")
            // Don't show error to user - external app selection is optional
        }
    }

    // MARK: - Handle External App Selection
    func handleExternalAppSelection(_ appId: String?) {
        selectedAppId = appId

        // Auto-set cover image from external app's defaultCoverImageUrl
        if let appId = appId,
           let selectedApp = externalApps.first(where: { $0.id == appId }),
           let defaultCoverImageUrl = selectedApp.defaultCoverImageUrl,
           !defaultCoverImageUrl.isEmpty {
            print("🖼️ [TaskRegistrationViewModel] Auto-setting cover image from external app: \(defaultCoverImageUrl)")
            coverImageURL = defaultCoverImageUrl
            coverImageSource = .externalApp
            selectedCoverImage = nil // Clear user-selected image
        } else if appId == nil {
            // Clear cover image when no external app is selected
            coverImageURL = nil
            coverImageSource = nil
            selectedCoverImage = nil
        }
    }

    // MARK: - Upload Cover Image
    func uploadCoverImage() async {
        guard let image = selectedCoverImage else {
            print("⚠️ [TaskRegistrationViewModel] No image selected")
            return
        }

        isUploadingImage = true

        do {
            print("📤 [TaskRegistrationViewModel] Uploading cover image...")
            let downloadURL = try await taskService.uploadCoverImage(image)
            print("✅ [TaskRegistrationViewModel] Image uploaded: \(downloadURL)")

            coverImageURL = downloadURL
            coverImageSource = .userUpload

        } catch {
            print("❌ [TaskRegistrationViewModel] Failed to upload image: \(error.localizedDescription)")
            errorMessage = "画像のアップロードに失敗しました: \(error.localizedDescription)"
            showError = true
        }

        isUploadingImage = false
    }

    // MARK: - Validation
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !url.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidURL(url) &&
        deadline > Date()
    }

    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    // MARK: - Register Task
    func registerTask() async {
        guard isFormValid else {
            errorMessage = "入力内容を確認してください"
            showError = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Upload cover image if user selected one
            if selectedCoverImage != nil && coverImageURL == nil {
                print("📤 [TaskRegistrationViewModel] Uploading user-selected cover image...")
                await uploadCoverImage()

                // Check if upload failed
                if coverImageURL == nil {
                    errorMessage = "画像のアップロードに失敗しました"
                    showError = true
                    isLoading = false
                    return
                }
            }

            // Parse bias IDs from comma-separated text
            let biasIds = biasIdsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            print("📡 [TaskRegistrationViewModel] Registering task: \(title)")
            if let appId = selectedAppId {
                print("📱 [TaskRegistrationViewModel] Selected external app: \(appId)")
            }
            if let coverImage = coverImageURL {
                print("🖼️ [TaskRegistrationViewModel] Cover image: \(coverImage)")
                print("📍 [TaskRegistrationViewModel] Cover image source: \(coverImageSource?.rawValue ?? "nil")")
            }

            let task = try await taskService.registerTask(
                title: title,
                url: url,
                deadline: deadline,
                biasIds: biasIds,
                externalAppId: selectedAppId,
                coverImage: coverImageURL,
                coverImageSource: coverImageSource
            )

            print("✅ [TaskRegistrationViewModel] Task registered successfully: \(task.id)")

            // Show success and reset form
            showSuccess = true
            resetForm()

        } catch {
            print("❌ [TaskRegistrationViewModel] Failed to register task: \(error.localizedDescription)")
            errorMessage = "タスクの登録に失敗しました: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Reset Form
    func resetForm() {
        title = ""
        url = ""
        deadline = Date().addingTimeInterval(86400)
        biasIdsText = ""
        selectedAppId = nil
        selectedCoverImage = nil
        coverImageURL = nil
        coverImageSource = nil
    }

    // MARK: - Validation Error Messages
    var titleError: String? {
        title.isEmpty ? nil : (title.trimmingCharacters(in: .whitespaces).isEmpty ? "タイトルを入力してください" : nil)
    }

    var urlError: String? {
        url.isEmpty ? nil : (isValidURL(url) ? nil : "有効なURLを入力してください")
    }

    var deadlineError: String? {
        deadline <= Date() ? "期限は現在時刻より後に設定してください" : nil
    }
}
