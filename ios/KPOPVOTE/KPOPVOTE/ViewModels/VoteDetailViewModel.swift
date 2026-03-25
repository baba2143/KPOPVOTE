//
//  VoteDetailViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Vote Detail ViewModel
//  単一ポイント制（2024/02 移行）
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
    @Published var showVoteSuccess = false

    // Multiple vote support (単一ポイント制)
    @Published var voteCount: Int = 1
    @Published var maxVoteCount: Int = 1
    @Published var pointsToBeUsed: Int = 0
    @Published var points: Int = 0  // 単一ポイント

    // MARK: - Properties
    let voteId: String
    let lookupService = IdolGroupLookupService.shared

    // MARK: - Initializer
    init(voteId: String) {
        self.voteId = voteId
        debugLog("🎬 [VoteDetailViewModel] Initialized with voteId: \(voteId)")
    }

    // MARK: - Computed Properties

    /// 残り投票数（日次上限がある場合のみ）
    var remainingVotes: Int? {
        vote?.userDailyRemaining
    }

    /// 日次投票上限があるか
    var hasDailyLimit: Bool {
        vote?.restrictions?.dailyVoteLimitPerUser != nil
    }

    /// 日次投票上限
    var dailyVoteLimit: Int? {
        vote?.restrictions?.dailyVoteLimitPerUser
    }

    var canVote: Bool {
        guard let vote = vote else { return false }
        // 日次上限がある場合、残り投票数が0なら投票不可
        if let remaining = vote.userDailyRemaining, remaining <= 0 {
            return false
        }
        return vote.isActive && !hasVoted && selectedChoiceId != nil && minVoteCountError == nil
    }

    /// 最低投票数バリデーションエラー
    var minVoteCountError: String? {
        guard let restrictions = vote?.restrictions,
              let minCount = restrictions.minVoteCount else {
            return nil
        }
        if voteCount < minCount {
            return "投票は最低\(minCount)票以上必要です"
        }
        return nil
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

        // Lookupサービスを並列ロード
        async let lookupLoad: () = lookupService.loadIfNeeded()

        do {
            debugLog("📱 [VoteDetailViewModel] Loading vote detail: \(voteId)")

            // Load vote detail and ranking in parallel
            async let voteDetail = VoteService.shared.fetchVoteDetail(voteId: voteId)
            // ランキングは失敗しても画面表示に影響しないよう、エラーを握りつぶす
            let rankingTask = Task { () -> VoteRanking? in
                do {
                    return try await VoteService.shared.fetchRanking(voteId: self.voteId)
                } catch {
                    debugLog("❌ [VoteDetailViewModel] Failed to load ranking: \(error)")
                    return nil
                }
            }

            // Wait for both to complete
            vote = try await voteDetail
            debugLog("✅ [VoteDetailViewModel] Loaded vote detail")
            debugLog("📊 [VoteDetailViewModel] dailyLimit: limit=\(vote?.restrictions?.dailyVoteLimitPerUser ?? -1), userDailyVotes=\(vote?.userDailyVotes ?? -1), userDailyRemaining=\(vote?.userDailyRemaining ?? -1)")

            ranking = await rankingTask.value
            if ranking != nil {
                debugLog("✅ [VoteDetailViewModel] Loaded ranking")
            }

            await lookupLoad  // Lookup完了を待つ
        } catch {
            debugLog("❌ [VoteDetailViewModel] Failed to load detail: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load ranking
    func loadRanking() async {
        do {
            debugLog("📱 [VoteDetailViewModel] Loading ranking: \(voteId)")
            ranking = try await VoteService.shared.fetchRanking(voteId: voteId)
            debugLog("✅ [VoteDetailViewModel] Loaded ranking")
        } catch {
            debugLog("❌ [VoteDetailViewModel] Failed to load ranking: \(error)")
            // Don't show error for ranking failure
        }
    }

    /// Select choice
    func selectChoice(_ choiceId: String) {
        selectedChoiceId = choiceId
        debugLog("📱 [VoteDetailViewModel] Selected choice: \(choiceId)")
    }

    /// Execute vote
    func executeVote() async {
        guard let choiceId = selectedChoiceId else {
            errorMessage = "選択肢を選んでください"
            return
        }

        guard vote != nil else {
            errorMessage = "投票情報の取得に失敗しました"
            return
        }

        isExecuting = true
        errorMessage = nil
        successMessage = nil

        do {
            debugLog("📱 [VoteDetailViewModel] Executing vote: \(voteId), choice: \(choiceId)")

            let result = try await VoteService.shared.executeVote(
                voteId: voteId,
                choiceId: choiceId,
                voteCount: voteCount,
                pointSelection: "none"  // 単一ポイント制: ポイント選択不要
            )

            // ポイント消費メッセージ（単一ポイント制）
            if FeatureFlags.pointsEnabled {
                successMessage = "投票が完了しました（\(result.voteCount)票、\(pointsToBeUsed)P消費）"
            } else {
                successMessage = "投票が完了しました（\(result.voteCount)票）"
            }

            debugLog("✅ [VoteDetailViewModel] Vote executed successfully")

            // ローカル更新（即座にUI反映）
            updateLocalVoteCount(choiceId: choiceId, addedVotes: result.voteCount, result: result)

            showVoteSuccess = true

        } catch let error as VoteError {
            debugLog("❌ [VoteDetailViewModel] Vote execution failed: \(error)")
            errorMessage = error.localizedDescription
        } catch {
            debugLog("❌ [VoteDetailViewModel] Unexpected error: \(error)")
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

    /// 投票成功後にローカルの票数を即座に更新
    private func updateLocalVoteCount(choiceId: String, addedVotes: Int, result: VoteExecuteResult) {
        guard let currentVote = vote else { return }

        // choicesを更新
        let updatedChoices = currentVote.choices.map { choice -> VoteChoice in
            if choice.id == choiceId {
                return VoteChoice(
                    id: choice.id,
                    label: choice.label,
                    voteCount: choice.voteCount + addedVotes,
                    idolId: choice.idolId,
                    imageUrl: choice.imageUrl,
                    groupName: choice.groupName,
                    groupId: choice.groupId
                )
            }
            return choice
        }

        // voteを更新
        vote = InAppVote(
            id: currentVote.id,
            title: currentVote.title,
            description: currentVote.description,
            choices: updatedChoices,
            startDate: currentVote.startDate,
            endDate: currentVote.endDate,
            requiredPoints: currentVote.requiredPoints,
            status: currentVote.status,
            totalVotes: currentVote.totalVotes + addedVotes,
            coverImageUrl: currentVote.coverImageUrl,
            isFeatured: currentVote.isFeatured,
            restrictions: currentVote.restrictions,
            createdAt: currentVote.createdAt,
            updatedAt: currentVote.updatedAt,
            userDailyVotes: result.userDailyVotes ?? currentVote.userDailyVotes,
            userDailyRemaining: result.userDailyRemaining ?? currentVote.userDailyRemaining
        )

        debugLog("📊 [VoteDetailViewModel] API result: userDailyVotes=\(result.userDailyVotes ?? -1), userDailyRemaining=\(result.userDailyRemaining ?? -1)")
        debugLog("📊 [VoteDetailViewModel] Local vote count updated: choice \(choiceId) +\(addedVotes), remaining=\(result.userDailyRemaining ?? -1)")
    }

    /// Refresh all data
    func refresh() async {
        await loadDetail()
    }

    // MARK: - Multiple Vote Support (単一ポイント制)

    /// Update points (単一ポイント)
    func updatePoints(_ availablePoints: Int) {
        points = availablePoints

        // 初期投票数を最低投票数に設定
        if let minCount = vote?.restrictions?.minVoteCount, voteCount < minCount {
            voteCount = minCount
        }

        calculateMaxVoteCount()
        calculatePointsToBeUsed()
    }

    /// Calculate maximum vote count based on points and restrictions (1P = 1票)
    func calculateMaxVoteCount() {
        guard let vote = vote else {
            maxVoteCount = 1
            return
        }

        let restrictions = vote.restrictions
        let pointsPerVote = restrictions?.pointsPerVote ?? vote.requiredPoints

        // 1P = 1票の計算
        var maxFromPoints = 0
        if pointsPerVote > 0 {
            maxFromPoints = points / pointsPerVote
        } else {
            maxFromPoints = Int.max
        }

        // Apply restrictions
        var maxCount = restrictions?.maxVoteCount ?? maxFromPoints

        // Limit by available points
        maxCount = min(maxCount, maxFromPoints)

        // Ensure at least 0
        maxVoteCount = max(0, maxCount)

        // Adjust current vote count if it exceeds new max
        if voteCount > maxVoteCount && maxVoteCount > 0 {
            voteCount = maxVoteCount
        } else if maxVoteCount == 0 {
            voteCount = 1  // Keep at 1 to show error
        }
    }

    /// Calculate points to be used for current vote count (1P = 1票)
    func calculatePointsToBeUsed() {
        guard let vote = vote else {
            pointsToBeUsed = 0
            return
        }

        let restrictions = vote.restrictions
        let pointsPerVote = restrictions?.pointsPerVote ?? vote.requiredPoints

        pointsToBeUsed = voteCount * pointsPerVote
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

    /// Check if can vote with current settings
    var canVoteWithCurrentPoints: Bool {
        return pointsToBeUsed <= points && voteCount > 0
    }

    /// Get formatted point usage string (単一ポイント)
    var formattedPointUsage: String {
        return "\(pointsToBeUsed)P"
    }
}
