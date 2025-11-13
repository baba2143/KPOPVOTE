//
//  TasksListViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Tasks List ViewModel
//

import Foundation
import SwiftUI

@MainActor
class TasksListViewModel: ObservableObject {
    @Published var allTasks: [VoteTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

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
            print("📡 [TasksListViewModel] Loading all tasks...")
            // isCompleted = nil で全タスク取得
            allTasks = try await taskService.getUserTasks(isCompleted: nil)
            print("✅ [TasksListViewModel] Loaded \(allTasks.count) tasks")
            print("   - Active: \(activeTasks.count)")
            print("   - Archived: \(archivedTasks.count)")
            print("   - Completed: \(completedTasks.count)")
        } catch {
            print("❌ [TasksListViewModel] Failed to load tasks: \(error.localizedDescription)")
            errorMessage = "タスクの取得に失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Complete Task
    func completeTask(_ task: VoteTask) async {
        do {
            print("📡 [TasksListViewModel] Marking task as completed: \(task.id)")
            try await taskService.markTaskAsCompleted(taskId: task.id)

            // Reload all tasks
            await loadAllTasks()
            print("✅ [TasksListViewModel] Task completed: \(task.id)")
        } catch {
            print("❌ [TasksListViewModel] Failed to complete task: \(error.localizedDescription)")
            errorMessage = "タスクの完了に失敗しました"
            showError = true
        }
    }

    // MARK: - Refresh
    func refresh() async {
        await loadAllTasks()
    }
}
