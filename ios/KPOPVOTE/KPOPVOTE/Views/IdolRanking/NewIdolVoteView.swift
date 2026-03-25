//
//  NewIdolVoteView.swift
//  KPOPVOTE
//
//  View for selecting an idol or group to vote for
//

import SwiftUI

struct NewIdolVoteView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IdolRankingViewModel

    @State private var selectedTab: RankingType = .individual
    @State private var idols: [IdolMaster] = []
    @State private var groups: [GroupMaster] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var votedEntityId: String? = nil
    @State private var biasSettings: [BiasSettings] = []
    @State private var selectedChar: String = "ALL"

    private let alphabet = ["ALL"] + (65...90).map { String(UnicodeScalar($0)!) } + ["#"]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("タイプ", selection: $selectedTab) {
                    Text("アイドル").tag(RankingType.individual)
                    Text("グループ").tag(RankingType.group)
                }
                .pickerStyle(.segmented)
                .padding()

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Constants.Colors.textGray)
                    TextField("検索...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Constants.Colors.textGray)
                        }
                    }
                }
                .padding(10)
                .background(Constants.Colors.cardDark)
                .cornerRadius(10)
                .padding(.horizontal)

                // Alphabet filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(alphabet, id: \.self) { char in
                            AlphabetTabView(
                                char: char,
                                count: selectedTab == .individual
                                    ? (char == "ALL" ? idols.count : (idolAlphabetCounts[char] ?? 0))
                                    : (char == "ALL" ? groups.count : (groupAlphabetCounts[char] ?? 0)),
                                isSelected: selectedChar == char,
                                onTap: {
                                    selectedChar = char
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Constants.Colors.backgroundDark)

                // Content
                if isLoading {
                    Spacer()
                    ProgressView("読み込み中...")
                        .tint(Constants.Colors.textWhite)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(Constants.Colors.textGray)
                            .multilineTextAlignment(.center)
                        Button("再試行") {
                            Task { await loadData() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        if selectedTab == .individual {
                            ForEach(filteredIdols) { idol in
                                VoteIdolRowView(
                                    idol: idol,
                                    isVoted: votedEntityId == idol.id,
                                    onVote: { voteForIdol(idol) }
                                )
                                .disabled(!viewModel.canVote || viewModel.isVoting || votedEntityId != nil)
                                .listRowBackground(Constants.Colors.backgroundDark)
                            }
                        } else {
                            ForEach(filteredGroups) { group in
                                VoteGroupRowView(
                                    group: group,
                                    isVoted: votedEntityId == group.id,
                                    onVote: { voteForGroup(group) }
                                )
                                .disabled(!viewModel.canVote || viewModel.isVoting || votedEntityId != nil)
                                .listRowBackground(Constants.Colors.backgroundDark)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Constants.Colors.backgroundDark)
                }
            }
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("投票対象を選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("閉じる") { dismiss() })
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Computed Properties

    // アルファベット別のアイドル数をカウント
    private var idolAlphabetCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for idol in idols {
            let char = getFirstChar(idol.name)
            counts[char, default: 0] += 1
        }
        return counts
    }

    // アルファベット別のグループ数をカウント
    private var groupAlphabetCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for group in groups {
            let char = getFirstChar(group.name)
            counts[char, default: 0] += 1
        }
        return counts
    }

    // 最初の文字を取得（アルファベット以外は "#"）
    private func getFirstChar(_ name: String) -> String {
        guard let firstChar = name.first else { return "#" }
        let uppercased = String(firstChar).uppercased()
        // A-Zの範囲内かチェック
        if let scalar = uppercased.unicodeScalars.first,
           scalar.value >= 65 && scalar.value <= 90 {
            return uppercased
        }
        return "#"
    }

    private var filteredIdols: [IdolMaster] {
        var filtered: [IdolMaster] = idols

        // アルファベットフィルター適用
        if selectedChar != "ALL" {
            filtered = filtered.filter { idol in
                getFirstChar(idol.name) == selectedChar
            }
        }

        // テキスト検索フィルター適用
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { idol in
                idol.name.lowercased().contains(query) ||
                idol.groupName.lowercased().contains(query)
            }
        }

        // 推しを先頭に、それ以外は元の順序を維持
        let oshi = filtered.filter { isOshiIdol($0) }
        let others = filtered.filter { !isOshiIdol($0) }
        return oshi + others
    }

    private var filteredGroups: [GroupMaster] {
        var filtered: [GroupMaster] = groups

        // アルファベットフィルター適用
        if selectedChar != "ALL" {
            filtered = filtered.filter { group in
                getFirstChar(group.name) == selectedChar
            }
        }

        // テキスト検索フィルター適用
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            filtered = filtered.filter { group in
                group.name.lowercased().contains(query)
            }
        }

        // 推しを先頭に、それ以外は元の順序を維持
        let oshi = filtered.filter { isOshiGroup($0) }
        let others = filtered.filter { !isOshiGroup($0) }
        return oshi + others
    }

    // MARK: - Bias Check Helpers

    private func isOshiIdol(_ idol: IdolMaster) -> Bool {
        biasSettings.contains { setting in
            setting.memberIds.contains(idol.id)
        }
    }

    private func isOshiGroup(_ group: GroupMaster) -> Bool {
        biasSettings.contains { setting in
            setting.artistId == group.id
        }
    }

    // MARK: - Methods

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // 並行してデータを取得（アイドル、グループ、日次制限）
            async let fetchedIdols = IdolService.shared.fetchIdols()
            async let fetchedGroups = GroupService.shared.fetchGroups()
            async let dailyLimitTask: () = viewModel.loadDailyLimit()

            let (idolResults, groupResults, _) = try await (fetchedIdols, fetchedGroups, dailyLimitTask)
            idols = idolResults
            groups = groupResults

            // 推し設定を取得（エラーは無視して空配列のまま）
            if let bias = try? await BiasService.shared.getBias() {
                biasSettings = bias
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func voteForIdol(_ idol: IdolMaster) {
        Task {
            await viewModel.voteForNewEntity(
                entityId: idol.id,
                entityType: .individual,
                name: idol.name,
                groupName: idol.groupName,
                imageUrl: idol.imageUrl
            )
            if viewModel.showVoteSuccess {
                votedEntityId = idol.id
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            }
        }
    }

    private func voteForGroup(_ group: GroupMaster) {
        Task {
            await viewModel.voteForNewEntity(
                entityId: group.id,
                entityType: .group,
                name: group.name,
                groupName: nil,
                imageUrl: group.imageUrl
            )
            if viewModel.showVoteSuccess {
                votedEntityId = group.id
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            }
        }
    }
}

// MARK: - Idol Row View

private struct VoteIdolRowView: View {
    let idol: IdolMaster
    let isVoted: Bool
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            profileImage

            // Name and group
            VStack(alignment: .leading, spacing: 2) {
                Text(idol.name)
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textWhite)
                    .lineLimit(1)
                Text(idol.groupName)
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textGray)
                    .lineLimit(1)
            }

            Spacer()

            // Vote button
            if isVoted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("投票しました!")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(16)
            } else {
                Button(action: onVote) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                        Text("投票")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Constants.Colors.accentPink)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var profileImage: some View {
        Group {
            if let imageUrl = idol.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 44, height: 44)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        Circle()
            .fill(Constants.Colors.cardDark)
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(Constants.Colors.textGray)
            )
    }
}

// MARK: - Group Row View

private struct VoteGroupRowView: View {
    let group: GroupMaster
    let isVoted: Bool
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            profileImage

            // Name
            Text(group.name)
                .font(.headline)
                .foregroundColor(Constants.Colors.textWhite)
                .lineLimit(1)

            Spacer()

            // Vote button
            if isVoted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("投票しました!")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(16)
            } else {
                Button(action: onVote) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                        Text("投票")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Constants.Colors.accentPink)
                    .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var profileImage: some View {
        Group {
            if let imageUrl = group.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 44, height: 44)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        Circle()
            .fill(Constants.Colors.cardDark)
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.3.fill")
                    .foregroundColor(Constants.Colors.textGray)
            )
    }
}

// MARK: - Preview

#Preview {
    NewIdolVoteView(viewModel: IdolRankingViewModel())
}
