//
//  PointsViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Points View Model
//  単一ポイント制（2024/02 移行）
//

import Foundation
import SwiftUI

@MainActor
class PointsViewModel: ObservableObject {
    // ポイント機能有効化フラグ（新報酬設計で有効化）
    private let isPointsFeatureEnabled = true

    // 単一ポイント
    @Published var points: Int = 0

    @Published var transactions: [PointTransaction] = []
    @Published var totalCount: Int = 0
    @Published var isLoading = true  // 起動時からローディング表示して「0P」一瞬表示を防止
    @Published var isLoadingHistory = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasMore = false

    private let pointsService = PointsService.shared
    private let limit = 20
    private var currentOffset = 0

    // MARK: - Load Points Balance (単一ポイント)
    func loadPoints() async {
        guard isPointsFeatureEnabled else {
            debugLog("ℹ️ [PointsViewModel] Points feature is disabled")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            debugLog("📡 [PointsViewModel] Loading point balance...")
            let balance = try await pointsService.fetchPointBalance()
            points = balance.points
            debugLog("✅ [PointsViewModel] Loaded: points=\(points)")
        } catch {
            debugLog("❌ [PointsViewModel] Failed to load points: \(error.localizedDescription)")
            errorMessage = "ポイント残高の取得に失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Load Point History
    func loadPointHistory(refresh: Bool = false) async {
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
            debugLog("📡 [PointsViewModel] Loading point history: offset=\(currentOffset)")
            let history = try await pointsService.fetchPointHistory(limit: limit, offset: currentOffset)

            if refresh {
                transactions = history.transactions
            } else {
                transactions.append(contentsOf: history.transactions)
            }

            totalCount = history.totalCount
            currentOffset += history.transactions.count
            // hasMoreの判定: limit件取得できた場合はまだデータがある可能性がある
            // (totalCountが-1の場合でも正しく動作する)
            hasMore = history.transactions.count == limit

            debugLog("✅ [PointsViewModel] Loaded \(history.transactions.count) transactions, total: \(totalCount)")
        } catch {
            debugLog("❌ [PointsViewModel] Failed to load point history: \(error.localizedDescription)")
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

    // MARK: - Calculate Votes (1P = 1票)
    func calculateVotesAvailable() -> Int {
        return points
    }
}
