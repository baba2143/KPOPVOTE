//
//  VoteDetailViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Vote Detail ViewModel
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

    // Multiple vote support
    @Published var voteCount: Int = 1
    @Published var maxVoteCount: Int = 1
    @Published var pointsToBeUsed: Int = 0
    @Published var premiumPoints: Int = 0
    @Published var regularPoints: Int = 0

    // Point selection mode (🔴/🔵 選択)
    @Published var selectedPointMode: PointSelectionMode = .auto
    @Published var premiumPointsToBeUsed: Int = 0
    @Published var regularPointsToBeUsed: Int = 0
    @Published var pointSelectionError: String?

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

        guard let vote = vote else {
            errorMessage = "投票情報の取得に失敗しました"
            return
        }

        isExecuting = true
        errorMessage = nil
        successMessage = nil

        do {
            debugLog("📱 [VoteDetailViewModel] Executing vote: \(voteId), choice: \(choiceId)")

            // Phase 1: ポイント機能無効化時は "none" を送信
            let pointSelectionValue = FeatureFlags.pointsEnabled ? selectedPointMode.rawValue : "none"

            let result = try await VoteService.shared.executeVote(
                voteId: voteId,
                choiceId: choiceId,
                voteCount: voteCount,
                pointSelection: pointSelectionValue
            )

            // 🔴 hasVoted = true は削除 → 再投票可能に
            // Phase 1: ポイント消費なしの場合は簡略メッセージ
            if FeatureFlags.pointsEnabled {
                // Show point breakdown in success message
                var pointsDetail = ""
                if result.premiumPointsDeducted > 0 && result.regularPointsDeducted > 0 {
                    pointsDetail = "\(result.premiumPointsDeducted)pt🔴 + \(result.regularPointsDeducted)pt🔵"
                } else if result.premiumPointsDeducted > 0 {
                    pointsDetail = "\(result.premiumPointsDeducted)pt🔴"
                } else {
                    pointsDetail = "\(result.regularPointsDeducted)pt🔵"
                }
                successMessage = "投票が完了しました（\(result.voteCount)票、\(pointsDetail)消費）"
            } else {
                successMessage = "投票が完了しました（\(result.voteCount)票）"
            }

            debugLog("✅ [VoteDetailViewModel] Vote executed successfully")

            // ローカル更新（即座にUI反映）- IdolRankingViewModelと同様のパターン
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

    /// 投票成功後にローカルの票数を即座に更新（IdolRankingViewModelと同様のパターン）
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

        // voteを更新（totalVotes、userDailyVotes、userDailyRemainingも更新）
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

    // MARK: - Multiple Vote Support

    /// Update points (should be called from View with PointsViewModel data)
    func updatePoints(premium: Int, regular: Int) {
        premiumPoints = premium
        regularPoints = regular

        // 初期投票数を最低投票数に設定
        if let minCount = vote?.restrictions?.minVoteCount, voteCount < minCount {
            voteCount = minCount
        }

        calculateMaxVoteCount()
        calculatePointsToBeUsed()
    }

    /// Calculate maximum vote count based on points, mode and restrictions
    func calculateMaxVoteCount() {
        guard let vote = vote else {
            maxVoteCount = 1
            return
        }

        let restrictions = vote.restrictions
        let premiumCost = restrictions?.premiumPointsPerVote ?? vote.requiredPoints
        let regularCost = restrictions?.regularPointsPerVote ?? vote.requiredPoints

        // Calculate max votes based on selected mode
        var maxFromPoints = 0

        switch selectedPointMode {
        case .auto:
            // Auto: Use both premium and regular
            if premiumCost > 0 {
                let premiumVotes = premiumPoints / premiumCost
                let regularVotes = regularCost > 0 ? regularPoints / regularCost : 0
                maxFromPoints = premiumVotes + regularVotes
            } else {
                maxFromPoints = Int.max
            }

        case .premium:
            // Premium only
            if premiumCost > 0 {
                maxFromPoints = premiumPoints / premiumCost
            } else {
                maxFromPoints = Int.max
            }

        case .regular:
            // Regular only
            if regularCost > 0 {
                maxFromPoints = regularPoints / regularCost
            } else {
                maxFromPoints = Int.max
            }
        }

        // Apply restrictions
        let minCount = restrictions?.minVoteCount ?? 1
        var maxCount = restrictions?.maxVoteCount ?? maxFromPoints

        // Limit by available points
        maxCount = min(maxCount, maxFromPoints)

        // Ensure at least 0 (not minCount, to allow UI to show error)
        maxVoteCount = max(0, maxCount)

        // Adjust current vote count if it exceeds new max
        if voteCount > maxVoteCount && maxVoteCount > 0 {
            voteCount = maxVoteCount
        } else if maxVoteCount == 0 {
            voteCount = 1  // Keep at 1 to show error
        }
    }

    /// Calculate points to be used for current vote count
    func calculatePointsToBeUsed() {
        guard let vote = vote else {
            pointsToBeUsed = 0
            premiumPointsToBeUsed = 0
            regularPointsToBeUsed = 0
            pointSelectionError = nil
            return
        }

        let restrictions = vote.restrictions
        let premiumCost = restrictions?.premiumPointsPerVote ?? vote.requiredPoints
        let regularCost = restrictions?.regularPointsPerVote ?? vote.requiredPoints

        pointSelectionError = nil

        switch selectedPointMode {
        case .auto:
            // Auto selection: Premium first, then regular
            let premiumUsed = min(voteCount * premiumCost, premiumPoints)
            let premiumVotes = premiumCost > 0 ? premiumUsed / premiumCost : 0
            let remainingVotes = voteCount - premiumVotes
            let regularUsed = remainingVotes * regularCost

            premiumPointsToBeUsed = premiumUsed
            regularPointsToBeUsed = regularUsed
            pointsToBeUsed = premiumUsed + regularUsed

            // Validate total points
            if (premiumUsed + regularUsed) > (premiumPoints + regularPoints) {
                pointSelectionError = "ポイントが不足しています"
            }

        case .premium:
            // Premium only
            let requiredPremium = voteCount * premiumCost
            premiumPointsToBeUsed = requiredPremium
            regularPointsToBeUsed = 0
            pointsToBeUsed = requiredPremium

            if requiredPremium > premiumPoints {
                pointSelectionError = "🔴 赤ポイントが不足しています（必要: \(requiredPremium)P）"
            }

        case .regular:
            // Regular only
            let requiredRegular = voteCount * regularCost
            premiumPointsToBeUsed = 0
            regularPointsToBeUsed = requiredRegular
            pointsToBeUsed = requiredRegular

            if requiredRegular > regularPoints {
                pointSelectionError = "🔵 青ポイントが不足しています（必要: \(requiredRegular)P）"
            }
        }
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

    /// Update point selection mode
    func updatePointMode(_ mode: PointSelectionMode) {
        selectedPointMode = mode
        calculateMaxVoteCount()
        calculatePointsToBeUsed()
        debugLog("📱 [VoteDetailViewModel] Point mode changed to: \(mode.rawValue)")
    }

    /// Check if current mode can vote with current settings
    var canVoteWithCurrentMode: Bool {
        return pointSelectionError == nil && voteCount > 0
    }

    /// Get formatted point usage string
    var formattedPointUsage: String {
        switch selectedPointMode {
        case .auto:
            if premiumPointsToBeUsed > 0 && regularPointsToBeUsed > 0 {
                return "\(premiumPointsToBeUsed)pt(🔴) + \(regularPointsToBeUsed)pt(🔵) = \(pointsToBeUsed)pt"
            } else if premiumPointsToBeUsed > 0 {
                return "\(premiumPointsToBeUsed)pt(🔴)"
            } else {
                return "\(regularPointsToBeUsed)pt(🔵)"
            }
        case .premium:
            return "\(premiumPointsToBeUsed)pt(🔴)"
        case .regular:
            return "\(regularPointsToBeUsed)pt(🔵)"
        }
    }
}
