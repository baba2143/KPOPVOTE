//
//  PointsHistoryView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Points History View
//

import SwiftUI

struct PointsHistoryView: View {
    @StateObject private var viewModel = PointsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: PointHistoryFilter = .all

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.medium) {
                        // Dual Points Balance Card
                        DualPointsBalanceCard(
                            premiumPoints: viewModel.premiumPoints,
                            regularPoints: viewModel.regularPoints
                        )
                        .padding(.horizontal, Constants.Spacing.medium)

                        // Transaction History
                        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                            // Header with filter
                            HStack {
                                Text("ポイント履歴")
                                    .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                                    .foregroundColor(Constants.Colors.textWhite)
                                Spacer()
                            }
                            .padding(.horizontal, Constants.Spacing.medium)

                            // Filter buttons
                            PointHistoryFilterBar(selectedFilter: $selectedFilter)
                                .padding(.horizontal, Constants.Spacing.medium)

                            if viewModel.isLoadingHistory && viewModel.transactions.isEmpty {
                                // Loading State
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                    Spacer()
                                }
                                .padding(.vertical, Constants.Spacing.large)
                            } else if let errorMessage = viewModel.errorMessage, viewModel.transactions.isEmpty {
                                // Error State
                                VStack(spacing: Constants.Spacing.small) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 32))
                                        .foregroundColor(Constants.Colors.textGray)
                                    Text(errorMessage)
                                        .font(.system(size: Constants.Typography.captionSize))
                                        .foregroundColor(Constants.Colors.textGray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Constants.Spacing.large)
                            } else if viewModel.transactions.isEmpty {
                                // Empty State
                                VStack(spacing: Constants.Spacing.small) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 32))
                                        .foregroundColor(Constants.Colors.textGray)
                                    Text("ポイント履歴がありません")
                                        .font(.system(size: Constants.Typography.captionSize))
                                        .foregroundColor(Constants.Colors.textGray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Constants.Spacing.large)
                            } else {
                                // Transaction List
                                LazyVStack(spacing: 0) {
                                    ForEach(filteredTransactions) { transaction in
                                        TransactionRow(transaction: transaction, showPointType: true)
                                        if transaction.id != viewModel.transactions.last?.id {
                                            Divider()
                                                .background(Constants.Colors.textGray.opacity(0.2))
                                                .padding(.leading, 60)
                                        }
                                    }

                                    // Load More Button
                                    if viewModel.hasMore {
                                        Button(action: {
                                            Task {
                                                await viewModel.loadMoreHistory()
                                            }
                                        }) {
                                            HStack {
                                                if viewModel.isLoadingHistory {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                                } else {
                                                    Text("さらに読み込む")
                                                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                                        .foregroundColor(Constants.Colors.accentPink)
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, Constants.Spacing.medium)
                                        }
                                        .disabled(viewModel.isLoadingHistory)
                                    }
                                }
                                .background(Constants.Colors.cardDark)
                                .cornerRadius(16)
                                .padding(.horizontal, Constants.Spacing.medium)
                            }
                        }
                    }
                    .padding(.top, Constants.Spacing.medium)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationTitle("ポイント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
            }
            .task {
                await viewModel.refresh()
            }
        }
    }

    // Filtered transactions based on selected filter
    private var filteredTransactions: [PointTransaction] {
        switch selectedFilter {
        case .all:
            return viewModel.transactions
        case .premium:
            return viewModel.transactions.filter { $0.pointType == "premium" }
        case .regular:
            return viewModel.transactions.filter { $0.pointType == "regular" }
        }
    }
}

// MARK: - Points Balance Card
struct PointsBalanceCard: View {
    let points: Int
    let isPremium: Bool
    let isLoading: Bool

    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            // Premium Badge
            if isPremium {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("プレミアム会員")
                        .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                        .foregroundColor(.yellow)
                }
            }

            // Points Display
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
            } else {
                VStack(spacing: 4) {
                    Text("保有ポイント")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                    Text("\(points)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                    + Text("P")
                        .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                        .foregroundColor(Constants.Colors.accentPink)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Spacing.large)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Constants.Colors.gradientPink.opacity(0.2),
                    Constants.Colors.gradientBlue.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Constants.Colors.cardDark)
        .cornerRadius(20)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: PointTransaction
    var showPointType: Bool = false

    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            // Icon
            ZStack {
                Circle()
                    .fill(transaction.isPositive ? Constants.Colors.accentPink.opacity(0.2) : Constants.Colors.textGray.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: transaction.icon)
                    .font(.system(size: 20))
                    .foregroundColor(transaction.isPositive ? Constants.Colors.accentPink : Constants.Colors.textGray)
            }

            // Transaction Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(transaction.typeDisplayName)
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)
                    // Point type badge
                    if showPointType, let icon = transaction.pointTypeIcon {
                        Text(icon)
                            .font(.system(size: 12))
                    }
                }
                Text(transaction.reason)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)
                    .lineLimit(1)
                Text(formatDate(transaction.date))
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)
            }

            Spacer()

            // Points with type color
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Text("\(transaction.isPositive ? "+" : "")\(transaction.points)")
                        .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                        .foregroundColor(pointsColor)
                    Text("P")
                        .font(.system(size: Constants.Typography.captionSize, weight: .bold))
                        .foregroundColor(pointsColor)
                }
                // Show point type name
                if showPointType, let typeName = transaction.pointTypeDisplayName {
                    Text(typeName)
                        .font(.system(size: 10))
                        .foregroundColor(transaction.pointTypeColor ?? Constants.Colors.textGray)
                }
            }
        }
        .padding(.horizontal, Constants.Spacing.medium)
        .padding(.vertical, Constants.Spacing.small)
    }

    private var pointsColor: Color {
        if let typeColor = transaction.pointTypeColor {
            return typeColor
        }
        return transaction.isPositive ? Constants.Colors.accentPink : Constants.Colors.textGray
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Point History Filter
enum PointHistoryFilter: String, CaseIterable {
    case all = "all"
    case premium = "premium"
    case regular = "regular"

    var displayName: String {
        switch self {
        case .all: return "すべて"
        case .premium: return "Premium"
        case .regular: return "Regular"
        }
    }

    var icon: String {
        switch self {
        case .all: return ""
        case .premium: return "🔴"
        case .regular: return "🔵"
        }
    }
}

// MARK: - Point History Filter Bar
struct PointHistoryFilterBar: View {
    @Binding var selectedFilter: PointHistoryFilter

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PointHistoryFilter.allCases, id: \.self) { filter in
                PointHistoryFilterButton(
                    filter: filter,
                    isSelected: selectedFilter == filter,
                    onTap: { selectedFilter = filter }
                )
            }
            Spacer()
        }
    }
}

// MARK: - Point History Filter Button
struct PointHistoryFilterButton: View {
    let filter: PointHistoryFilter
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if !filter.icon.isEmpty {
                    Text(filter.icon)
                        .font(.system(size: 12))
                }
                Text(filter.displayName)
                    .font(.system(size: Constants.Typography.captionSize, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? Constants.Colors.textWhite : Constants.Colors.textGray)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Constants.Colors.accentPink : Constants.Colors.cardDark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Constants.Colors.textGray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    PointsHistoryView()
}
