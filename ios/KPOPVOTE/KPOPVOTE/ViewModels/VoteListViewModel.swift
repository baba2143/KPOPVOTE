//
//  VoteListViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote List ViewModel
//

import Foundation
import Combine

@MainActor
class VoteListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var votes: [InAppVote] = []
    @Published var selectedStatus: VoteStatus? = .active
    @Published var isLoading = false
    @Published var errorMessage: String?

    // User Tasks
    @Published var userTasks: [VoteTask] = []
    @Published var selectedTaskFilter: TaskFilter = .active
    @Published var isLoadingTasks = false

    private let taskService = TaskService()

    // MARK: - Task Filter Enum
    enum TaskFilter {
        case active
        case archived
        case completed
    }

    // MARK: - Computed Properties
    var activeVotes: [InAppVote] {
        votes.filter { $0.status == .active }
    }

    var upcomingVotes: [InAppVote] {
        votes.filter { $0.status == .upcoming }
    }

    var endedVotes: [InAppVote] {
        votes.filter { $0.status == .ended }
    }

    var activeTasks: [VoteTask] {
        userTasks.filter { !$0.isCompleted && !$0.isArchived && !$0.isExpired }
    }

    var archivedTasks: [VoteTask] {
        userTasks.filter { $0.isArchived || $0.isExpired }
    }

    var completedTasks: [VoteTask] {
        userTasks.filter { $0.isCompleted }
    }

    var filteredTasks: [VoteTask] {
        switch selectedTaskFilter {
        case .active:
            return activeTasks
        case .archived:
            return archivedTasks
        case .completed:
            return completedTasks
        }
    }

    // MARK: - Methods

    /// Load votes with optional status filter
    func loadVotes() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📱 [VoteListViewModel] Loading votes with status: \(selectedStatus?.rawValue ?? "all")")
            votes = try await VoteService.shared.fetchVotes(status: selectedStatus)
            print("✅ [VoteListViewModel] Loaded \(votes.count) votes")
        } catch {
            print("❌ [VoteListViewModel] Failed to load votes: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Change status filter and reload
    func changeStatusFilter(_ status: VoteStatus?) async {
        selectedStatus = status
        await loadVotes()
    }

    /// Refresh votes
    func refresh() async {
        await loadVotes()
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Task Methods

    /// Load user tasks
    func loadUserTasks() async {
        isLoadingTasks = true

        do {
            print("📱 [VoteListViewModel] Loading user tasks...")
            userTasks = try await taskService.getUserTasks()
            print("✅ [VoteListViewModel] Loaded \(userTasks.count) tasks")
        } catch {
            print("❌ [VoteListViewModel] Failed to load tasks: \(error)")
            // Don't show error for tasks, just log it
        }

        isLoadingTasks = false
    }

    /// Change task filter
    func changeTaskFilter(_ filter: TaskFilter) {
        selectedTaskFilter = filter
    }

    /// Complete a task
    func completeTask(_ task: VoteTask) async {
        do {
            try await taskService.markTaskAsCompleted(taskId: task.id)
            await loadUserTasks()
        } catch {
            print("❌ [VoteListViewModel] Failed to complete task: \(error)")
            errorMessage = "タスクの完了処理に失敗しました"
        }
    }

    /// Refresh all data
    func refreshAll() async {
        await loadVotes()
        await loadUserTasks()
    }
}
