//
//  HomeViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Home View Model
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
            debugLog("👤 [HomeViewModel] Guest mode - skipping active tasks")
            activeTasks = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            debugLog("📡 [HomeViewModel] Loading active tasks...")
            activeTasks = try await taskService.getActiveTasks()
            debugLog("✅ [HomeViewModel] Loaded \(activeTasks.count) active tasks")
        } catch is CancellationError {
            // Swift concurrency cancellation
            debugLog("⏸️ [HomeViewModel] Task loading cancelled (view transition)")
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession cancellation
            debugLog("⏸️ [HomeViewModel] URLSession cancelled (view transition)")
        } catch {
            debugLog("❌ [HomeViewModel] Failed to load active tasks: \(error.localizedDescription)")
            errorMessage = "アクティブタスクの取得に失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Complete Task
    func completeTask(_ task: VoteTask) async {
        do {
            debugLog("📡 [HomeViewModel] Marking task as completed: \(task.id)")
            try await taskService.markTaskAsCompleted(taskId: task.id)

            // Remove from active tasks
            activeTasks.removeAll { $0.id == task.id }
            debugLog("✅ [HomeViewModel] Task completed: \(task.id)")
        } catch is CancellationError {
            debugLog("⏸️ [HomeViewModel] Task completion cancelled (view transition)")
        } catch let urlError as URLError where urlError.code == .cancelled {
            debugLog("⏸️ [HomeViewModel] URLSession cancelled (view transition)")
        } catch {
            debugLog("❌ [HomeViewModel] Failed to complete task: \(error.localizedDescription)")
            errorMessage = "タスクの完了に失敗しました"
            showError = true
        }
    }

    // MARK: - Load Featured Votes
    func loadFeaturedVotes() async {
        isLoadingVotes = true

        do {
            debugLog("📡 [HomeViewModel] Loading featured votes...")
            featuredVotes = try await voteService.fetchFeaturedVotes()
            debugLog("✅ [HomeViewModel] Loaded \(featuredVotes.count) featured votes")
        } catch is CancellationError {
            debugLog("⏸️ [HomeViewModel] Featured votes loading cancelled (view transition)")
        } catch let urlError as URLError where urlError.code == .cancelled {
            debugLog("⏸️ [HomeViewModel] URLSession cancelled (view transition)")
        } catch {
            debugLog("❌ [HomeViewModel] Failed to load featured votes: \(error.localizedDescription)")
            // Don't show error for featured votes failure
        }

        isLoadingVotes = false
    }

    // MARK: - Refresh
    func refresh() async {
        // Run both loads in parallel for faster refresh
        async let tasksResult: () = loadActiveTasks()
        async let votesResult: () = loadFeaturedVotes()
        _ = await (tasksResult, votesResult)
    }
}
