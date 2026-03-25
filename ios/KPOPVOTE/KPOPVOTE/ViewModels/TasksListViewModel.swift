//
//  TasksListViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Tasks List ViewModel
//

import Foundation
import SwiftUI

@MainActor
class TasksListViewModel: ObservableObject {
    @Published var allTasks: [VoteTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // Success Message
    @Published var showSuccessMessage = false
    @Published var successMessageText = ""

    private let taskService = TaskService()

    // MARK: - Computed Properties
    var activeTasks: [VoteTask] {
        allTasks.filter { !$0.isCompleted && !$0.isArchived && $0.deadline > Date() }
            .sorted { $0.deadline < $1.deadline }
    }

    var archivedTasks: [VoteTask] {
        allTasks.filter { $0.isArchived || ($0.deadline < Date() && !$0.isCompleted) }
            .sorted { $0.deadline > $1.deadline } // 最新のアーカイブから
    }

    var completedTasks: [VoteTask] {
        allTasks.filter { $0.isCompleted }
            .sorted { ($0.updatedAt) > ($1.updatedAt) } // 完了日時が新しい順
    }

    // MARK: - Load All Tasks
    func loadAllTasks() async {
        isLoading = true
        errorMessage = nil

        do {
            debugLog("📡 [TasksListViewModel] Loading all tasks...")
            // isCompleted = nil で全タスク取得
            allTasks = try await taskService.getUserTasks(isCompleted: nil)
            debugLog("✅ [TasksListViewModel] Loaded \(allTasks.count) tasks")
            debugLog("   - Active: \(activeTasks.count)")
            debugLog("   - Archived: \(archivedTasks.count)")
            debugLog("   - Completed: \(completedTasks.count)")
        } catch {
            debugLog("❌ [TasksListViewModel] Failed to load tasks: \(error.localizedDescription)")
            errorMessage = "タスクの取得に失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Complete Task
    func completeTask(_ task: VoteTask) async {
        do {
            debugLog("📡 [TasksListViewModel] Marking task as completed: \(task.id)")
            let points = try await taskService.markTaskAsCompleted(taskId: task.id)

            // Reload all tasks
            await loadAllTasks()

            // Show success message
            if let points = points {
                successMessageText = "タスクを完了しました！\n\n+\(points)ポイント獲得"
            } else {
                successMessageText = "タスクを完了しました！"
            }
            showSuccessMessage = true

            debugLog("✅ [TasksListViewModel] Task completed: \(task.id)")
        } catch {
            debugLog("❌ [TasksListViewModel] Failed to complete task: \(error.localizedDescription)")
            errorMessage = "タスクの完了に失敗しました"
            showError = true
        }
    }

    // MARK: - Delete Task
    func deleteTask(_ task: VoteTask) async {
        do {
            debugLog("📡 [TasksListViewModel] Deleting task: \(task.id)")
            try await taskService.deleteTask(taskId: task.id)

            // Remove from local array immediately for better UX
            allTasks.removeAll { $0.id == task.id }
            debugLog("✅ [TasksListViewModel] Task deleted: \(task.id)")
        } catch {
            debugLog("❌ [TasksListViewModel] Failed to delete task: \(error.localizedDescription)")
            errorMessage = "タスクの削除に失敗しました"
            showError = true

            // Reload to ensure consistency
            await loadAllTasks()
        }
    }

    // MARK: - Refresh
    func refresh() async {
        await loadAllTasks()
    }
}
