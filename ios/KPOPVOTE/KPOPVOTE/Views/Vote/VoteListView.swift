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
        NavigationView {
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
                                        selectedVoteId = vote.id
                                        showVoteDetail = true
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
                    VoteDetailView(voteId: voteId)
                }
            }
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
        HStack(spacing: 8) {
            FilterButton(
                title: "すべて",
                isSelected: selectedStatus == nil,
                action: { onStatusChange(nil) }
            )

            FilterButton(
                title: "開催予定",
                isSelected: selectedStatus == .upcoming,
                action: { onStatusChange(.upcoming) }
            )

            FilterButton(
                title: "開催中",
                isSelected: selectedStatus == .active,
                action: { onStatusChange(.active) }
            )

            FilterButton(
                title: "終了",
                isSelected: selectedStatus == .ended,
                action: { onStatusChange(.ended) }
            )
        }
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Constants.Colors.accentPink : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Constants.Colors.statusExpired)

            Text(message)
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("再試行") {
                onRetry()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Constants.Colors.accentPink)
            .cornerRadius(8)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let status: VoteStatus?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 64))
                .foregroundColor(Constants.Colors.textGray.opacity(0.5))

            Text(emptyMessage)
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var emptyMessage: String {
        switch status {
        case .upcoming:
            return "開催予定の投票はありません"
        case .active:
            return "開催中の投票はありません"
        case .ended:
            return "終了した投票はありません"
        case nil:
            return "投票がありません"
        }
    }
}

// MARK: - Preview
struct VoteListView_Previews: PreviewProvider {
    static var previews: some View {
        VoteListView()
    }
}
