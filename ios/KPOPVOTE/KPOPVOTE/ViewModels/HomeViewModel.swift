//
//  HomeViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Home View Model
//

import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var urgentTasks: [VoteTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let taskService = TaskService()

    // MARK: - Load Urgent Tasks
    func loadUrgentTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📡 [HomeViewModel] Loading urgent tasks...")
            urgentTasks = try await taskService.getUrgentTasks()
            print("✅ [HomeViewModel] Loaded \(urgentTasks.count) urgent tasks")
        } catch {
            print("❌ [HomeViewModel] Failed to load urgent tasks: \(error.localizedDescription)")
            errorMessage = "緊急タスクの取得に失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Complete Task
    func completeTask(_ task: VoteTask) async {
        do {
            print("📡 [HomeViewModel] Marking task as completed: \(task.id)")
            try await taskService.markTaskAsCompleted(taskId: task.id)

            // Remove from urgent tasks
            urgentTasks.removeAll { $0.id == task.id }
            print("✅ [HomeViewModel] Task completed: \(task.id)")
        } catch {
            print("❌ [HomeViewModel] Failed to complete task: \(error.localizedDescription)")
            errorMessage = "タスクの完了に失敗しました"
            showError = true
        }
    }

    // MARK: - Refresh
    func refresh() async {
        await loadUrgentTasks()
    }
}
