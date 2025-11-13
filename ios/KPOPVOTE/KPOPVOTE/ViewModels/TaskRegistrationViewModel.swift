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
            // Parse bias IDs from comma-separated text
            let biasIds = biasIdsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            print("📡 [TaskRegistrationViewModel] Registering task: \(title)")
            if let appId = selectedAppId {
                print("📱 [TaskRegistrationViewModel] Selected external app: \(appId)")
            }

            let task = try await taskService.registerTask(
                title: title,
                url: url,
                deadline: deadline,
                biasIds: biasIds,
                externalAppId: selectedAppId
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
