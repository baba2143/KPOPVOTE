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
        remainingVotes > 0
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
    private func loadRankingsQuietly() async throws {
        guard !isLoading else { return }

        isLoading = true
        currentOffset = 0
        hasMoreData = true

        defer { isLoading = false }

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

            // Update the ranking entry's vote count locally
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

            showVoteSuccess = true
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

            // Refresh rankings to show the new entry (don't show error if this fails)
            do {
                try await loadRankingsQuietly()
            } catch {
                // Silently ignore ranking refresh errors after successful vote
                print("[IdolRankingViewModel] Failed to refresh rankings after vote: \(error)")
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
            await loadRankings()
        }
    }

    func changePeriod(_ period: RankingPeriod) {
        guard period != selectedPeriod else { return }
        selectedPeriod = period
        Task {
            await loadRankings()
        }
    }

    func refresh() async {
        await loadDailyLimit()
        await loadRankings()
    }
}
