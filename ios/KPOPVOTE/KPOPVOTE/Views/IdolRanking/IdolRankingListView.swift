//
//  IdolRankingListView.swift
//  KPOPVOTE
//
//  Ranking list component
//

import SwiftUI

struct IdolRankingListView: View {
    @ObservedObject var viewModel: IdolRankingViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.rankings.isEmpty {
                loadingView
            } else if viewModel.rankings.isEmpty {
                emptyView
            } else {
                rankingList
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(.circular)
            Text("読み込み中...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("ランキングデータがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("最初の投票をしてランキングを開始しましょう！")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private var rankingList: some View {
        List {
            ForEach(viewModel.rankings) { entry in
                IdolRankingEntryView(
                    entry: entry,
                    canVote: viewModel.canVote,
                    isVoting: viewModel.isVoting
                ) {
                    Task {
                        await viewModel.vote(for: entry)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // Load more indicator
            if viewModel.rankings.count > 0 {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .onAppear {
                    Task {
                        await viewModel.loadMoreRankings()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    IdolRankingListView(viewModel: IdolRankingViewModel())
}
