//
//  HomeViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Home View Model
//

import Foundation
import SwiftUI
import FirebaseAuth

@MainActor
class HomeViewModel: ObservableObject {
    @Published var activeTasks: [VoteTask] = []
    @Published var featuredVotes: [InAppVote] = []
    @Published var isLoading = false
    @Published var isLoadingVotes = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let taskService = TaskService()
    private let voteService = VoteService.shared

    // MARK: - Load Active Tasks
    func loadActiveTasks() async {
        // ゲストモードの場合はスキップ
        guard Auth.auth().currentUser != nil else {
            print("👤 [HomeViewModel] Guest mode - skipping active tasks")
            activeTasks = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            print("📡 [HomeViewModel] Loading active tasks...")
            activeTasks = try await taskService.getActiveTasks()
            print("✅ [HomeViewModel] Loaded \(activeTasks.count) active tasks")
        } catch {
            print("❌ [HomeViewModel] Failed to load active tasks: \(error.localizedDescription)")
            errorMessage = "アクティブタスクの取得に失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Complete Task
    func completeTask(_ task: VoteTask) async {
        do {
            print("📡 [HomeViewModel] Marking task as completed: \(task.id)")
            try await taskService.markTaskAsCompleted(taskId: task.id)

            // Remove from active tasks
            activeTasks.removeAll { $0.id == task.id }
            print("✅ [HomeViewModel] Task completed: \(task.id)")
        } catch {
            print("❌ [HomeViewModel] Failed to complete task: \(error.localizedDescription)")
            errorMessage = "タスクの完了に失敗しました"
            showError = true
        }
    }

    // MARK: - Load Featured Votes
    func loadFeaturedVotes() async {
        isLoadingVotes = true

        do {
            print("📡 [HomeViewModel] Loading featured votes...")
            featuredVotes = try await voteService.fetchFeaturedVotes()
            print("✅ [HomeViewModel] Loaded \(featuredVotes.count) featured votes")
        } catch {
            print("❌ [HomeViewModel] Failed to load featured votes: \(error.localizedDescription)")
            // Don't show error for featured votes failure
        }

        isLoadingVotes = false
    }

    // MARK: - Refresh
    func refresh() async {
        await loadActiveTasks()
        await loadFeaturedVotes()
    }
}
