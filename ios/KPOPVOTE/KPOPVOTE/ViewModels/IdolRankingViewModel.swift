//
//  IdolRankingViewModel.swift
//  KPOPVOTE
//
//  ViewModel for Idol Ranking feature
//

import Foundation
import SwiftUI

@MainActor
class IdolRankingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var rankings: [IdolRankingEntry] = []
    @Published var selectedRankingType: RankingType = .individual
    @Published var selectedPeriod: RankingPeriod = .weekly
    @Published var dailyLimit: DailyLimitResponse?

    @Published var isLoading = false
    @Published var isVoting = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showVoteSuccess = false

    // Archive properties
    @Published var availableArchives: [ArchiveListItem] = []
    @Published var selectedArchiveId: String? = nil  // nil = 今月

    // MARK: - Private Properties

    private let service = IdolRankingService.shared
    private var currentOffset = 0
    private var hasMoreData = true
    private var total = 0

    // MARK: - Computed Properties

    var remainingVotes: Int {
        dailyLimit?.remainingVotes ?? Constants.maxDailyVotes
    }

    var canVote: Bool {
        remainingVotes > 0 && !isArchiveMode
    }

    /// アーカイブモードかどうか（過去の月が選択されている）
    var isArchiveMode: Bool {
        selectedArchiveId != nil
    }

    // MARK: - Public Methods

    func loadRankings() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        showError = false  // Reset error state on new load
        currentOffset = 0
        hasMoreData = true

        do {
            let response = try await service.getRanking(
                type: selectedRankingType,
                period: selectedPeriod,
                limit: Constants.rankingPageSize,
                offset: 0
            )

            rankings = response.rankings
            total = response.total
            currentOffset = response.rankings.count
            hasMoreData = currentOffset < total
        } catch let error as IdolRankingError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    /// Load rankings without showing errors (throws instead)
    /// - Parameter refresh: If true, bypasses CDN cache for fresh data (use after voting)
    private func loadRankingsQuietly(refresh: Bool = false) async throws {
        print("🔄 [IdolRankingViewModel] loadRankingsQuietly called, refresh=\(refresh), isLoading=\(isLoading)")

        // Skip isLoading guard when refresh is true (post-vote refresh should always execute)
        if !refresh {
            guard !isLoading else {
                print("⚠️ [IdolRankingViewModel] loadRankingsQuietly skipped - already loading")
                return
            }
        }

        isLoading = true
        currentOffset = 0
        hasMoreData = true

        defer { isLoading = false }

        print("🔄 [IdolRankingViewModel] Fetching rankings with refresh=\(refresh)")
        let response = try await service.getRanking(
            type: selectedRankingType,
            period: selectedPeriod,
            limit: Constants.rankingPageSize,
            offset: 0,
            refresh: refresh
        )

        print("✅ [IdolRankingViewModel] Got \(response.rankings.count) rankings")
        rankings = response.rankings
        total = response.total
        currentOffset = response.rankings.count
        hasMoreData = currentOffset < total
    }

    func loadMoreRankings() async {
        guard !isLoading, hasMoreData else { return }

        isLoading = true

        do {
            let response = try await service.getRanking(
                type: selectedRankingType,
                period: selectedPeriod,
                limit: Constants.rankingPageSize,
                offset: currentOffset
            )

            rankings.append(contentsOf: response.rankings)
            currentOffset += response.rankings.count
            hasMoreData = currentOffset < total
        } catch let error as IdolRankingError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func loadDailyLimit() async {
        errorMessage = nil
        showError = false  // Reset error state on new load

        do {
            dailyLimit = try await service.getDailyLimit()
            print("📊 [IdolRankingViewModel] loadDailyLimit success: votesUsed=\(dailyLimit?.votesUsed ?? -1), maxVotes=\(dailyLimit?.maxVotes ?? -1), remainingVotes=\(dailyLimit?.remainingVotes ?? -1)")
        } catch let error as IdolRankingError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func vote(for entry: IdolRankingEntry) async {
        guard canVote, !isVoting else { return }

        isVoting = true
        errorMessage = nil

        do {
            let response = try await service.vote(
                entityId: entry.entityId,
                entityType: entry.entityType,
                name: entry.name,
                groupName: entry.groupName,
                imageUrl: entry.imageUrl
            )

            // Update daily limit
            let maxVotes = dailyLimit?.maxVotes ?? Constants.maxDailyVotes
            dailyLimit = DailyLimitResponse(
                votesUsed: maxVotes - response.remainingVotes,
                maxVotes: maxVotes,
                remainingVotes: response.remainingVotes,
                voteDetails: dailyLimit?.voteDetails ?? []
            )

            // Update the ranking entry's vote count locally for immediate feedback
            if let index = rankings.firstIndex(where: { $0.entityId == entry.entityId }) {
                let updatedEntry = rankings[index]
                rankings[index] = IdolRankingEntry(
                    rank: updatedEntry.rank,
                    entityId: updatedEntry.entityId,
                    entityType: updatedEntry.entityType,
                    name: updatedEntry.name,
                    groupName: updatedEntry.groupName,
                    imageUrl: updatedEntry.imageUrl,
                    weeklyVotes: updatedEntry.weeklyVotes + 1,
                    totalVotes: updatedEntry.totalVotes + 1,
                    previousRank: updatedEntry.previousRank,
                    rankChange: updatedEntry.rankChange
                )
            }

            // Re-sort rankings by weeklyVotes (descending) and recalculate ranks
            rankings.sort { $0.weeklyVotes > $1.weeklyVotes }
            rankings = rankings.enumerated().map { index, entry in
                IdolRankingEntry(
                    rank: index + 1,
                    entityId: entry.entityId,
                    entityType: entry.entityType,
                    name: entry.name,
                    groupName: entry.groupName,
                    imageUrl: entry.imageUrl,
                    weeklyVotes: entry.weeklyVotes,
                    totalVotes: entry.totalVotes,
                    previousRank: entry.previousRank,
                    rankChange: entry.rankChange
                )
            }

            showVoteSuccess = true
            print("🗳️ [IdolRankingViewModel] Vote succeeded for \(entry.name), local update and re-sort applied")
            // Note: Server refresh is intentionally NOT performed here (same as VoteDetailViewModel)
            // Local +1 update provides instant feedback. Server data will be fetched on manual refresh.
        } catch let error as IdolRankingError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isVoting = false
    }

    func voteForNewEntity(
        entityId: String,
        entityType: RankingType,
        name: String,
        groupName: String? = nil,
        imageUrl: String? = nil
    ) async {
        guard canVote, !isVoting else { return }

        isVoting = true
        errorMessage = nil

        do {
            let response = try await service.vote(
                entityId: entityId,
                entityType: entityType,
                name: name,
                groupName: groupName,
                imageUrl: imageUrl
            )

            // Update daily limit
            let maxVotes = dailyLimit?.maxVotes ?? Constants.maxDailyVotes
            dailyLimit = DailyLimitResponse(
                votesUsed: maxVotes - response.remainingVotes,
                maxVotes: maxVotes,
                remainingVotes: response.remainingVotes,
                voteDetails: dailyLimit?.voteDetails ?? []
            )

            showVoteSuccess = true
            print("🗳️ [IdolRankingViewModel] Vote succeeded for new entity \(name)")

            // For new entities, we need to refresh to show them in the list
            // Wait a moment for Firestore to complete the write
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            do {
                try await loadRankingsQuietly(refresh: true)
            } catch {
                print("[IdolRankingViewModel] Failed to refresh rankings after new entity vote: \(error)")
            }
        } catch let error as IdolRankingError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isVoting = false
    }

    func changeRankingType(_ type: RankingType) {
        guard type != selectedRankingType else { return }
        selectedRankingType = type
        Task {
            if isArchiveMode {
                await loadArchiveRankings()
            } else {
                await loadRankings()
            }
        }
    }

    func changePeriod(_ period: RankingPeriod) {
        guard period != selectedPeriod else { return }
        selectedPeriod = period

        // 週間に切り替えた場合は、アーカイブモードを解除
        if period == .weekly {
            selectedArchiveId = nil
        }

        Task {
            await loadRankings()
        }
    }

    func refresh() async {
        async let limitTask: () = loadDailyLimit()
        async let rankingsTask: () = loadRankings()
        _ = await (limitTask, rankingsTask)
    }

    // MARK: - Archive Methods

    /// 利用可能なアーカイブ（月）の一覧を取得
    func loadArchiveList() async {
        do {
            let response = try await service.getArchiveList()
            availableArchives = response.archives
        } catch let error as IdolRankingError {
            print("[IdolRankingViewModel] Failed to load archive list: \(error.errorDescription ?? "Unknown")")
            // アーカイブ一覧の取得失敗はエラー表示しない（機能は使えなくなるが、メインの機能には影響しない）
        } catch {
            print("[IdolRankingViewModel] Failed to load archive list: \(error.localizedDescription)")
        }
    }

    /// アーカイブ（月）を選択
    /// - Parameter archiveId: 選択する月のID（"2025-01"形式）、nilで今月に戻る
    func selectArchive(_ archiveId: String?) async {
        guard archiveId != selectedArchiveId else { return }
        selectedArchiveId = archiveId

        if archiveId != nil {
            await loadArchiveRankings()
        } else {
            await loadRankings()
        }
    }

    /// 選択されたアーカイブのランキングを取得
    func loadArchiveRankings() async {
        guard let archiveId = selectedArchiveId else {
            await loadRankings()
            return
        }

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        showError = false
        currentOffset = 0
        hasMoreData = true

        do {
            let response = try await service.getArchive(
                archiveId: archiveId,
                rankingType: selectedRankingType,
                limit: Constants.rankingPageSize,
                offset: 0
            )

            rankings = response.rankings
            total = response.total
            currentOffset = response.rankings.count
            hasMoreData = currentOffset < total
        } catch let error as IdolRankingError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    /// アーカイブのランキングをさらに読み込む
    func loadMoreArchiveRankings() async {
        guard let archiveId = selectedArchiveId else {
            await loadMoreRankings()
            return
        }

        guard !isLoading, hasMoreData else { return }

        isLoading = true

        do {
            let response = try await service.getArchive(
                archiveId: archiveId,
                rankingType: selectedRankingType,
                limit: Constants.rankingPageSize,
                offset: currentOffset
            )

            rankings.append(contentsOf: response.rankings)
            currentOffset += response.rankings.count
            hasMoreData = currentOffset < total
        } catch let error as IdolRankingError {
            errorMessage = error.errorDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }
}
