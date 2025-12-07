//
//  TaskRegistrationViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Task Registration ViewModel
//

import Foundation
import SwiftUI

@MainActor
class TaskRegistrationViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var url: String = ""
    @Published var deadline: Date = Date().addingTimeInterval(86400) // Default: 24 hours from now
    @Published var selectedMemberIds: [String] = [] // Selected member IDs
    @Published var selectedMemberNames: [String] = [] // Selected member names for display

    // External App Selection
    @Published var externalApps: [ExternalAppMaster] = []
    @Published var selectedAppId: String? = nil

    // Cover Image Selection
    @Published var selectedCoverImage: UIImage? = nil
    @Published var coverImageURL: String? = nil
    @Published var coverImageSource: CoverImageSource? = nil
    @Published var isUploadingImage = false
    @Published var showImagePicker = false
    @Published var showBiasSelection = false // For member selection sheet

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false

    // Edit Mode Properties
    @Published var isEditMode: Bool = false
    private var editingTaskId: String?

    private let taskService = TaskService()
    private let externalAppService = ExternalAppService()
    private let idolService = IdolService.shared
    private let groupService = GroupService.shared

    // MARK: - Initializer
    init(task: VoteTask? = nil) {
        if let task = task {
            // Edit mode - pre-populate with existing task data
            self.isEditMode = true
            self.editingTaskId = task.id
            self.title = task.title
            self.url = task.url
            self.deadline = task.deadline
            self.selectedMemberIds = task.biasIds
            self.selectedAppId = task.externalAppId
            self.coverImageURL = task.coverImage
            self.coverImageSource = task.coverImageSource

            // Load member names asynchronously
            Task {
                await loadMemberNames(for: task.biasIds)
            }
        }
    }

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
        print("🔍 [TaskRegistrationViewModel] handleExternalAppSelection called with appId: \(appId ?? "nil")")
        print("🔍 [TaskRegistrationViewModel] Total externalApps loaded: \(externalApps.count)")

        selectedAppId = appId

        // Auto-set cover image from external app's defaultCoverImageUrl
        if let appId = appId,
           let selectedApp = externalApps.first(where: { $0.id == appId }),
           let defaultCoverImageUrl = selectedApp.defaultCoverImageUrl,
           !defaultCoverImageUrl.isEmpty {
            print("🖼️ [TaskRegistrationViewModel] Auto-setting cover image from external app: \(defaultCoverImageUrl)")
            print("🖼️ [TaskRegistrationViewModel] Selected app: \(selectedApp.appName)")
            print("🖼️ [TaskRegistrationViewModel] defaultCoverImageUrl from selectedApp: \(selectedApp.defaultCoverImageUrl ?? "nil")")
            coverImageURL = defaultCoverImageUrl
            coverImageSource = .externalApp
            selectedCoverImage = nil // Clear user-selected image
        } else {
            print("⚠️ [TaskRegistrationViewModel] Did not set cover image. Reason:")
            if appId == nil {
                print("   - appId is nil")
            } else if externalApps.first(where: { $0.id == appId }) == nil {
                print("   - No app found with id: \(appId!)")
            } else if let app = externalApps.first(where: { $0.id == appId }) {
                print("   - App found: \(app.appName), but defaultCoverImageUrl is: \(app.defaultCoverImageUrl ?? "nil")")
            }

            // 外部アプリが選択されていない場合、
            // 外部アプリから設定された画像のみクリア（ユーザーアップロード画像は保持）
            if coverImageSource == .externalApp {
                coverImageURL = nil
                coverImageSource = nil
            }
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

    // MARK: - Register or Update Task
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

            if isEditMode, let taskId = editingTaskId {
                // Edit mode - update existing task
                print("📡 [TaskRegistrationViewModel] Updating task: \(taskId)")
                if let appId = selectedAppId {
                    print("📱 [TaskRegistrationViewModel] Selected external app: \(appId)")
                }
                if let coverImage = coverImageURL {
                    print("🖼️ [TaskRegistrationViewModel] Cover image: \(coverImage)")
                    print("📍 [TaskRegistrationViewModel] Cover image source: \(coverImageSource?.rawValue ?? "nil")")
                }

                let task = try await taskService.updateTask(
                    taskId: taskId,
                    title: title,
                    url: url,
                    deadline: deadline,
                    biasIds: selectedMemberIds,
                    externalAppId: selectedAppId,
                    coverImage: coverImageURL,
                    coverImageSource: coverImageSource
                )

                print("✅ [TaskRegistrationViewModel] Task updated successfully: \(task.id)")
            } else {
                // Create mode - register new task
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
                    biasIds: selectedMemberIds,
                    externalAppId: selectedAppId,
                    coverImage: coverImageURL,
                    coverImageSource: coverImageSource
                )

                print("✅ [TaskRegistrationViewModel] Task registered successfully: \(task.id)")
            }

            // Notify to refresh task list
            NotificationCenter.default.post(name: NSNotification.Name("taskRegisteredNotification"), object: nil)

            // Show success and reset form
            showSuccess = true
            if !isEditMode {
                resetForm()
            }

        } catch {
            print("❌ [TaskRegistrationViewModel] Failed to \(isEditMode ? "update" : "register") task: \(error.localizedDescription)")
            errorMessage = "タスクの\(isEditMode ? "更新" : "登録")に失敗しました: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Reset Form
    func resetForm() {
        title = ""
        url = ""
        deadline = Date().addingTimeInterval(86400)
        selectedMemberIds = []
        selectedMemberNames = []
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

    // MARK: - Load Member/Group Names
    func loadMemberNames(for ids: [String]) async {
        do {
            // Load both idols and groups
            async let idolsTask = idolService.fetchIdols()
            async let groupsTask = groupService.fetchGroups()

            let (allIdols, allGroups) = try await (idolsTask, groupsTask)

            let idolDict = Dictionary(uniqueKeysWithValues: allIdols.map { ($0.id, $0.name) })
            let groupDict = Dictionary(uniqueKeysWithValues: allGroups.map { ($0.id, $0.name) })

            // Try idol first, then group
            selectedMemberNames = ids.compactMap { id in
                idolDict[id] ?? groupDict[id]
            }
            print("✅ [TaskRegistrationViewModel] Loaded names for \(selectedMemberNames.count) members/groups")
        } catch {
            print("❌ [TaskRegistrationViewModel] Failed to load member/group names: \(error)")
        }
    }
}
