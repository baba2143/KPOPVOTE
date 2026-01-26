//
//  IdolRankingTabView.swift
//  KPOPVOTE
//
//  Main view for Idol Ranking feature
//

import SwiftUI

struct IdolRankingTabView: View {
    @StateObject private var viewModel = IdolRankingViewModel()
    @State private var showVoteSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with segments and daily limit
                headerSection

                // Ranking list
                IdolRankingListView(viewModel: viewModel)
            }
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("アイドルランキング")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showVoteSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(viewModel.canVote ? Constants.Colors.accentBlue : Constants.Colors.textGray)
                    }
                    .disabled(!viewModel.canVote)
                }
            }
            .task {
                await viewModel.refresh()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
            }
            .alert("投票完了", isPresented: $viewModel.showVoteSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("投票しました！残り\(viewModel.remainingVotes)票")
            }
            .sheet(isPresented: $showVoteSheet) {
                NewIdolVoteView(viewModel: viewModel)
            }
        }
        .background(Constants.Colors.backgroundDark)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Ranking type picker (Individual / Group)
            Picker("ランキングタイプ", selection: Binding(
                get: { viewModel.selectedRankingType },
                set: { viewModel.changeRankingType($0) }
            )) {
                ForEach(RankingType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Period picker (Weekly / All Time)
            Picker("期間", selection: Binding(
                get: { viewModel.selectedPeriod },
                set: { viewModel.changePeriod($0) }
            )) {
                ForEach(RankingPeriod.allCases, id: \.self) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Daily limit badge
            DailyLimitBadgeView(
                votesUsed: viewModel.dailyLimit?.votesUsed ?? 0,
                maxVotes: viewModel.dailyLimit?.maxVotes ?? 5
            )
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Constants.Colors.backgroundDark)
    }
}

// MARK: - Preview

#Preview {
    IdolRankingTabView()
}
