//
//  VoteDetailViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote Detail ViewModel
//

import Foundation
import Combine

@MainActor
class VoteDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var vote: InAppVote?
    @Published var ranking: VoteRanking?
    @Published var selectedChoiceId: String?
    @Published var isLoading = true
    @Published var isExecuting = false
    @Published var hasVoted = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Properties
    let voteId: String

    // MARK: - Initializer
    init(voteId: String) {
        self.voteId = voteId
        print("🎬 [VoteDetailViewModel] Initialized with voteId: \(voteId)")
    }

    // MARK: - Computed Properties
    var canVote: Bool {
        guard let vote = vote else { return false }
        return vote.isActive && !hasVoted && selectedChoiceId != nil
    }

    var selectedChoice: VoteChoice? {
        guard let choiceId = selectedChoiceId,
              let vote = vote else { return nil }
        return vote.choices.first { $0.id == choiceId }
    }

    // MARK: - Methods

    /// Load vote detail and ranking
    func loadDetail() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📱 [VoteDetailViewModel] Loading vote detail: \(voteId)")

            // Load vote detail
            vote = try await VoteService.shared.fetchVoteDetail(voteId: voteId)
            print("✅ [VoteDetailViewModel] Loaded vote detail")

            // Load ranking
            await loadRanking()
        } catch {
            print("❌ [VoteDetailViewModel] Failed to load detail: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load ranking
    func loadRanking() async {
        do {
            print("📱 [VoteDetailViewModel] Loading ranking: \(voteId)")
            ranking = try await VoteService.shared.fetchRanking(voteId: voteId)
            print("✅ [VoteDetailViewModel] Loaded ranking")
        } catch {
            print("❌ [VoteDetailViewModel] Failed to load ranking: \(error)")
            // Don't show error for ranking failure
        }
    }

    /// Select choice
    func selectChoice(_ choiceId: String) {
        selectedChoiceId = choiceId
        print("📱 [VoteDetailViewModel] Selected choice: \(choiceId)")
    }

    /// Execute vote
    func executeVote() async {
        guard let choiceId = selectedChoiceId else {
            errorMessage = "選択肢を選んでください"
            return
        }

        guard let vote = vote else {
            errorMessage = "投票情報の取得に失敗しました"
            return
        }

        isExecuting = true
        errorMessage = nil
        successMessage = nil

        do {
            print("📱 [VoteDetailViewModel] Executing vote: \(voteId), choice: \(choiceId)")

            let result = try await VoteService.shared.executeVote(
                voteId: voteId,
                choiceId: choiceId
            )

            hasVoted = true
            successMessage = "投票が完了しました（\(result.pointsDeducted)pt消費）"

            print("✅ [VoteDetailViewModel] Vote executed successfully")

            // Reload ranking to show updated results
            await loadRanking()

        } catch let error as VoteError {
            print("❌ [VoteDetailViewModel] Vote execution failed: \(error)")
            errorMessage = error.localizedDescription
        } catch {
            print("❌ [VoteDetailViewModel] Unexpected error: \(error)")
            errorMessage = "投票に失敗しました"
        }

        isExecuting = false
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Clear success message
    func clearSuccess() {
        successMessage = nil
    }

    /// Refresh all data
    func refresh() async {
        await loadDetail()
    }
}
