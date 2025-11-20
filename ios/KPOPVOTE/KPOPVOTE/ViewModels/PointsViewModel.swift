//
//  PointsViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Points View Model
//

import Foundation
import SwiftUI

@MainActor
class PointsViewModel: ObservableObject {
    @Published var points: Int = 0
    @Published var isPremium: Bool = false
    @Published var transactions: [PointTransaction] = []
    @Published var totalCount: Int = 0
    @Published var isLoading = false
    @Published var isLoadingHistory = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var hasMore = false

    private let pointsService = PointsService.shared
    private let limit = 20
    private var currentOffset = 0

    // MARK: - Load Points Balance
    func loadPoints() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📡 [PointsViewModel] Loading points balance...")
            let balance = try await pointsService.fetchPoints()
            points = balance.points
            isPremium = balance.isPremium
            print("✅ [PointsViewModel] Loaded points: \(points), isPremium: \(isPremium)")
        } catch {
            print("❌ [PointsViewModel] Failed to load points: \(error.localizedDescription)")
            errorMessage = "ポイント残高の取得に失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Load Point History
    func loadPointHistory(refresh: Bool = false) async {
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
