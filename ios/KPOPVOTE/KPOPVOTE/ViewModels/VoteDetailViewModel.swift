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

    // Multiple vote support
    @Published var voteCount: Int = 1
    @Published var maxVoteCount: Int = 1
    @Published var pointsToBeUsed: Int = 0
    @Published var premiumPoints: Int = 0
    @Published var regularPoints: Int = 0

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
                choiceId: choiceId,
                voteCount: voteCount
            )

            hasVoted = true
            successMessage = "投票が完了しました（\(result.voteCount)票、\(result.pointsDeducted)pt消費）"

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

    // MARK: - Multiple Vote Support

    /// Update points (should be called from View with PointsViewModel data)
    func updatePoints(premium: Int, regular: Int) {
        premiumPoints = premium
        regularPoints = regular
        calculateMaxVoteCount()
        calculatePointsToBeUsed()
    }

    /// Calculate maximum vote count based on points and restrictions
    func calculateMaxVoteCount() {
        guard let vote = vote,
              let restrictions = vote.restrictions else {
            maxVoteCount = 1
            return
        }

        let premiumCost = restrictions.premiumPointsPerVote ?? vote.requiredPoints
        let regularCost = restrictions.regularPointsPerVote ?? vote.requiredPoints

        // Calculate max votes from points
        var maxFromPoints = 0
        if premiumCost > 0 {
            let premiumVotes = premiumPoints / premiumCost
            let regularVotes = regularPoints / regularCost
            maxFromPoints = premiumVotes + regularVotes
        } else {
            maxFromPoints = Int.max
        }

        // Apply restrictions
        let minCount = restrictions.minVoteCount ?? 1
        var maxCount = restrictions.maxVoteCount ?? maxFromPoints

        // Limit by available points
        maxCount = min(maxCount, maxFromPoints)

        // Ensure at least minCount
        maxVoteCount = max(minCount, maxCount)
    }

    /// Calculate points to be used for current vote count
    func calculatePointsToBeUsed() {
        guard let vote = vote,
              let restrictions = vote.restrictions else {
            pointsToBeUsed = vote?.requiredPoints ?? 0
            return
        }

        let premiumCost = restrictions.premiumPointsPerVote ?? vote.requiredPoints
        let regularCost = restrictions.regularPointsPerVote ?? vote.requiredPoints

        // Auto selection: Premium first, then regular
        let premiumUsed = min(voteCount * premiumCost, premiumPoints)
        let premiumVotes = premiumUsed / premiumCost
        let remainingVotes = voteCount - premiumVotes
        let regularUsed = remainingVotes * regularCost

        pointsToBeUsed = premiumUsed + regularUsed
    }

    /// Set vote count to maximum
    func voteAll() {
        voteCount = maxVoteCount
        calculatePointsToBeUsed()
    }

    /// Update vote count (called when user changes stepper)
    func updateVoteCount(_ newCount: Int) {
        guard let restrictions = vote?.restrictions else {
            voteCount = 1
            return
        }

        let minCount = restrictions.minVoteCount ?? 1
        voteCount = max(minCount, min(newCount, maxVoteCount))
        calculatePointsToBeUsed()
    }
}
