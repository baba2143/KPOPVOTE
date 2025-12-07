//
//  PointsViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Points View Model
//

import Foundation
import SwiftUI

@MainActor
class PointsViewModel: ObservableObject {
    // Phase 1: ポイント機能無効化フラグ
    private let isPointsFeatureEnabled = false

    // マルチポイント対応
    @Published var premiumPoints: Int = 0
    @Published var regularPoints: Int = 0
    @Published var eventPoints: Int = 0
    @Published var giftPoints: Int = 0

    // 後方互換性
    @Published var points: Int = 0
    @Published var isPremium: Bool = false

    @Published var transactions: [PointTransaction] = []
    @Published var totalCount: Int = 0
    @Published var isLoading = false
    @Published var isLoadingHistory = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasMore = false

    // デイリーログインボーナス
    @Published var showDailyLoginBonus = false
    @Published var dailyLoginBonus: DailyLoginResponse?

    private let pointsService = PointsService.shared
    private let limit = 20
    private var currentOffset = 0

    // MARK: - Load Points Balance (Multi-Point)
    func loadPoints() async {
        // Phase 1: ポイント機能無効化
        guard isPointsFeatureEnabled else {
            print("ℹ️ [PointsViewModel] Points feature is disabled in Phase 1")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            print("📡 [PointsViewModel] Loading multi-point balance...")
            let balance = try await pointsService.fetchMultiPointBalance()
            premiumPoints = balance.premiumPoints
            regularPoints = balance.regularPoints
            eventPoints = balance.eventPoints ?? 0
            giftPoints = balance.giftPoints ?? 0
            isPremium = balance.isPremium

            // 後方互換性: 合計を points に設定
            points = premiumPoints + regularPoints + eventPoints + giftPoints

            print("✅ [PointsViewModel] Loaded: premium=\(premiumPoints), regular=\(regularPoints)")
        } catch {
            print("❌ [PointsViewModel] Failed to load points: \(error.localizedDescription)")
            errorMessage = "ポイント残高の取得に失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Daily Login Bonus
    func claimDailyLoginBonus() async {
        // Phase 1: ポイント機能無効化
        guard isPointsFeatureEnabled else {
            return
        }

        do {
            print("📡 [PointsViewModel] Claiming daily login bonus...")
            let bonus = try await pointsService.claimDailyLoginBonus()
            dailyLoginBonus = bonus

            // ボーナス取得後、ポイント残高を更新
            if bonus.isFirstTimeToday {
                showDailyLoginBonus = true
                await loadPoints()
                print("✅ [PointsViewModel] Daily login bonus claimed: +\(bonus.pointsGranted)P")
            } else {
                print("ℹ️ [PointsViewModel] Already claimed today")
            }
        } catch {
            print("❌ [PointsViewModel] Failed to claim daily login: \(error.localizedDescription)")
            // デイリーログインエラーは表示しない（任意機能のため）
        }
    }

    // MARK: - Load Point History
    func loadPointHistory(refresh: Bool = false) async {
        // Phase 1: ポイント機能無効化
        guard isPointsFeatureEnabled else {
            return
        }

        // Reset pagination if refreshing
        if refresh {
            currentOffset = 0
            transactions = []
        }

        // Don't load if already at the end
        if !refresh && !hasMore && currentOffset > 0 {
            return
        }

        isLoadingHistory = true
        errorMessage = nil

        do {
            print("📡 [PointsViewModel] Loading point history: offset=\(currentOffset)")
            let history = try await pointsService.fetchPointHistory(limit: limit, offset: currentOffset)

            if refresh {
                transactions = history.transactions
            } else {
                transactions.append(contentsOf: history.transactions)
            }

            totalCount = history.totalCount
            currentOffset += history.transactions.count
            hasMore = transactions.count < totalCount

            print("✅ [PointsViewModel] Loaded \(history.transactions.count) transactions, total: \(totalCount)")
        } catch {
            print("❌ [PointsViewModel] Failed to load point history: \(error.localizedDescription)")
            errorMessage = "ポイント履歴の取得に失敗しました"
            showError = true
        }

        isLoadingHistory = false
    }

    // MARK: - Load More History
    func loadMoreHistory() async {
        guard !isLoadingHistory && hasMore else { return }
        await loadPointHistory(refresh: false)
    }

    // MARK: - Refresh
    func refresh() async {
        await loadPoints()
        await loadPointHistory(refresh: true)
    }

    // MARK: - Format Points
    func formatPoints(_ points: Int) -> String {
        return "\(points)P"
    }

    // MARK: - Format Date
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
