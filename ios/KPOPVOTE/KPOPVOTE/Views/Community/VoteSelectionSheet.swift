//
//  VoteSelectionSheet.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote Selection Sheet for Post Creation
//

import SwiftUI

struct VoteSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VoteListViewModel()

    let onVoteSelected: (InAppVote) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status Filter
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
                        VStack(spacing: Constants.Spacing.medium) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 64))
                                .foregroundColor(Constants.Colors.textGray)

                            Text("投票がありません")
                                .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.votes) { vote in
                                    VoteSelectionCard(vote: vote) {
                                        onVoteSelected(vote)
                                        dismiss()
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("投票を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textGray)
                }
            }
            .task {
                await viewModel.loadVotes()
            }
        }
    }
}

// MARK: - Vote Selection Card
struct VoteSelectionCard: View {
    let vote: InAppVote
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vote.title)
                            .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                            .foregroundColor(Constants.Colors.textWhite)
                            .lineLimit(2)

                        Text(vote.description)
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                            .lineLimit(2)
                    }

                    Spacer()

                    StatusBadge(status: vote.status)
                }

                // Info
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(vote.formattedPeriod)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(Constants.Colors.accentBlue)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                        Text("\(vote.requiredPoints)pt")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.yellow)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 11))
                        Text("\(vote.totalVotes)票")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                }
            }
            .padding(Constants.Spacing.medium)
            .background(Constants.Colors.cardDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Constants.Colors.accentPink.opacity(0.3),
                                Constants.Colors.accentBlue.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    VoteSelectionSheet { vote in
        print("Selected: \(vote.title)")
    }
}
