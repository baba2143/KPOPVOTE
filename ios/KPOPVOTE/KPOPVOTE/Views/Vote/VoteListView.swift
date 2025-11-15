//
//  VoteListView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote List Main View
//

import SwiftUI

struct VoteListView: View {
    @StateObject private var viewModel = VoteListViewModel()
    @State private var selectedVoteId: String?
    @State private var showVoteDetail = false

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Status Filter Segment
                StatusFilterView(
                    selectedStatus: viewModel.selectedStatus,
                    onStatusChange: { status in
                        Task {
                            await viewModel.changeStatusFilter(status)
                        }
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 12)

                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .foregroundColor(Constants.Colors.textWhite)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    ErrorView(message: errorMessage) {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                    Spacer()
                } else if viewModel.votes.isEmpty {
                    Spacer()
                    EmptyStateView(status: viewModel.selectedStatus)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.votes) { vote in
                                VoteCardView(vote: vote) {
                                    print("🎯 [VoteListView] VoteCard callback - vote.id: \(vote.id)")
                                    selectedVoteId = vote.id
                                    print("🎯 [VoteListView] Set selectedVoteId: \(String(describing: selectedVoteId))")
                                    showVoteDetail = true
                                    print("🎯 [VoteListView] Set showVoteDetail: \(showVoteDetail)")
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
        }
        .navigationTitle("投票")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showVoteDetail) {
            if let voteId = selectedVoteId {
                NavigationView {
                    VoteDetailView(voteId: voteId)
                        .onAppear {
                            print("📱 [VoteListView] Sheet presenting with voteId: \(voteId)")
                        }
                }
            } else {
                Text("エラー")
                    .onAppear {
                        print("⚠️ [VoteListView] Sheet triggered but selectedVoteId is nil!")
                    }
            }
        }
        .onChange(of: showVoteDetail) { newValue in
            print("📱 [VoteListView] showVoteDetail changed to: \(newValue), selectedVoteId: \(String(describing: selectedVoteId))")
        }
        .onChange(of: selectedVoteId) { newValue in
            print("📱 [VoteListView] selectedVoteId changed to: \(String(describing: newValue))")
        }
        .task {
            await viewModel.loadVotes()
        }
    }
}

// MARK: - Status Filter View
struct StatusFilterView: View {
    let selectedStatus: VoteStatus?
    let onStatusChange: (VoteStatus?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterButton(
                    icon: "square.grid.2x2",
                    title: "すべて",
                    isSelected: selectedStatus == nil,
                    action: { onStatusChange(nil) }
                )

                FilterButton(
                    icon: "clock",
                    title: "開催予定",
                    isSelected: selectedStatus == .upcoming,
                    action: { onStatusChange(.upcoming) }
                )

                FilterButton(
                    icon: "play.circle.fill",
                    title: "開催中",
                    isSelected: selectedStatus == .active,
                    action: { onStatusChange(.active) }
                )

                FilterButton(
                    icon: "checkmark.circle.fill",
                    title: "終了",
                    isSelected: selectedStatus == .ended,
                    action: { onStatusChange(.ended) }
                )
            }
        }
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            }
            .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(20)
            .shadow(
                color: isSelected ? Constants.Colors.accentPink.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Constants.Colors.statusExpired.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(Constants.Colors.statusExpired)
            }

            VStack(spacing: 8) {
                Text("エラーが発生しました")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                    Text("再試行")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Constants.Colors.accentPink.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let status: VoteStatus?

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Constants.Colors.accentPink.opacity(0.2),
                                Constants.Colors.accentBlue.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: emptyIcon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(Constants.Colors.textGray.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text(emptyMessage)
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.horizontal, 32)
    }

    private var emptyIcon: String {
        switch status {
        case .upcoming:
            return "clock.badge.questionmark"
        case .active:
            return "chart.bar.xaxis"
        case .ended:
            return "checkmark.circle"
        case nil:
            return "tray"
        }
    }

    private var emptyTitle: String {
        switch status {
        case .upcoming:
            return "開催予定なし"
        case .active:
            return "開催中の投票なし"
        case .ended:
            return "終了した投票なし"
        case nil:
            return "投票がありません"
        }
    }

    private var emptyMessage: String {
        switch status {
        case .upcoming:
            return "現在、開催予定の投票はありません\n新しい投票が追加されるのをお楽しみに！"
        case .active:
            return "現在、開催中の投票はありません\n他のフィルターをお試しください"
        case .ended:
            return "終了した投票はまだありません"
        case nil:
            return "投票が作成されていません\nしばらくお待ちください"
        }
    }
}

// MARK: - Preview
struct VoteListView_Previews: PreviewProvider {
    static var previews: some View {
        VoteListView()
    }
}
