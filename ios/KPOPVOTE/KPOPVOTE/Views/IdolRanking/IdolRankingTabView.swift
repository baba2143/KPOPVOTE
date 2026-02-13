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
    @State private var showArchivePicker = false

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
                await viewModel.loadArchiveList()
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
            .sheet(isPresented: $showVoteSheet, onDismiss: {
                Task {
                    await viewModel.refresh()
                }
            }) {
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

            // Archive picker (only shown when allTime is selected)
            if viewModel.selectedPeriod == .allTime {
                archivePickerSection
            }

            // Daily limit badge (hidden in archive mode)
            if !viewModel.isArchiveMode {
                DailyLimitBadgeView(
                    votesUsed: viewModel.dailyLimit?.votesUsed ?? 5,  // データなしなら使用済みとして表示
                    maxVotes: viewModel.dailyLimit?.maxVotes ?? 5
                )
                .padding(.horizontal)
            } else {
                // Archive mode indicator
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(Constants.Colors.accentBlue)
                    Text("過去のランキング（読み取り専用）")
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textGray)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Constants.Colors.backgroundDark)
    }

    private var archivePickerSection: some View {
        Menu {
            // 「今月」オプション
            Button(action: {
                Task {
                    await viewModel.selectArchive(nil)
                }
            }) {
                HStack {
                    Text(currentMonthLabel)
                    if viewModel.selectedArchiveId == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            // 過去の月（降順）
            ForEach(viewModel.availableArchives) { archive in
                Button(action: {
                    Task {
                        await viewModel.selectArchive(archive.id)
                    }
                }) {
                    HStack {
                        Text(archive.label)
                        if viewModel.selectedArchiveId == archive.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Constants.Colors.accentBlue)
                Text(selectedArchiveLabel)
                    .foregroundColor(Constants.Colors.textWhite)
                Image(systemName: "chevron.down")
                    .foregroundColor(Constants.Colors.textGray)
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Constants.Colors.cardDark)
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }

    /// 現在の月のラベル（例：「今月（2025年2月）」）
    private var currentMonthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return "今月（\(formatter.string(from: Date()))）"
    }

    /// 選択されているアーカイブのラベル
    private var selectedArchiveLabel: String {
        if let archiveId = viewModel.selectedArchiveId,
           let archive = viewModel.availableArchives.first(where: { $0.id == archiveId }) {
            return archive.label
        }
        return currentMonthLabel
    }
}

// MARK: - Preview

#Preview {
    IdolRankingTabView()
}
