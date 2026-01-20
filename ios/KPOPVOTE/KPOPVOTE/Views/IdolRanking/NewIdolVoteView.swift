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
                        .foregroundColor(.gray)
                    TextField("検索...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // Content
                if isLoading {
                    Spacer()
                    ProgressView("読み込み中...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
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
                                VoteIdolRowView(idol: idol) {
                                    voteForIdol(idol)
                                }
                                .disabled(!viewModel.canVote || viewModel.isVoting)
                            }
                        } else {
                            ForEach(filteredGroups) { group in
                                VoteGroupRowView(group: group) {
                                    voteForGroup(group)
                                }
                                .disabled(!viewModel.canVote || viewModel.isVoting)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("投票対象を選択")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("閉じる") { dismiss() })
            .task {
                await loadData()
            }
            .onChange(of: viewModel.showVoteSuccess) { success in
                if success {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredIdols: [IdolMaster] {
        if searchText.isEmpty {
            return idols
        }
        let query = searchText.lowercased()
        return idols.filter { idol in
            idol.name.lowercased().contains(query) ||
            idol.groupName.lowercased().contains(query)
        }
    }

    private var filteredGroups: [GroupMaster] {
        if searchText.isEmpty {
            return groups
        }
        let query = searchText.lowercased()
        return groups.filter { group in
            group.name.lowercased().contains(query)
        }
    }

    // MARK: - Methods

    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchedIdols = IdolService.shared.fetchIdols()
            async let fetchedGroups = GroupService.shared.fetchGroups()

            let (idolResults, groupResults) = try await (fetchedIdols, fetchedGroups)
            idols = idolResults
            groups = groupResults
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
        }
    }
}

// MARK: - Idol Row View

private struct VoteIdolRowView: View {
    let idol: IdolMaster
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            profileImage

            // Name and group
            VStack(alignment: .leading, spacing: 2) {
                Text(idol.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(idol.groupName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Vote button
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
                .background(Color.pink)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
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
            .fill(Color.gray.opacity(0.3))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Group Row View

private struct VoteGroupRowView: View {
    let group: GroupMaster
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            profileImage

            // Name
            Text(group.name)
                .font(.headline)
                .lineLimit(1)

            Spacer()

            // Vote button
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
                .background(Color.pink)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
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
            .fill(Color.gray.opacity(0.3))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "person.3.fill")
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Preview

#Preview {
    NewIdolVoteView(viewModel: IdolRankingViewModel())
}
