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
}
