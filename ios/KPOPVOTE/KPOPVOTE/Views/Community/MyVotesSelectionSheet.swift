//
//  MyVotesSelectionSheet.swift
//  OSHI Pick
//
//  OSHI Pick - My Votes Selection Sheet for Post Creation
//

import SwiftUI

struct MyVotesSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var myVotes: [MyVoteItem] = []
    @State private var selectedVotes: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let onVotesSelected: ([MyVoteItem]) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Content
                    if isLoading {
                        Spacer()
                        ProgressView("読み込み中...")
                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                            .foregroundColor(Constants.Colors.textWhite)
                        Spacer()
                    } else if let errorMessage = errorMessage {
                        Spacer()
                        ErrorView(message: errorMessage) {
                            Task {
                                await loadMyVotes()
                            }
                        }
                        Spacer()
                    } else if myVotes.isEmpty {
                        Spacer()
                        VStack(spacing: Constants.Spacing.medium) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 64))
                                .foregroundColor(Constants.Colors.textGray)

                            Text("投票履歴がありません")
                                .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)

                            Text("投票に参加すると、ここに履歴が表示されます")
                                .font(.system(size: Constants.Typography.bodySize))
                                .foregroundColor(Constants.Colors.textGray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Constants.Spacing.large)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(myVotes) { voteItem in
                                    MyVoteCard(
                                        voteItem: voteItem,
                                        isSelected: selectedVotes.contains(voteItem.id)
                                    ) {
                                        toggleSelection(voteItem.id)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("投票履歴を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textGray)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        let selected = myVotes.filter { selectedVotes.contains($0.id) }
                        onVotesSelected(selected)
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                    .disabled(selectedVotes.isEmpty)
                }
            }
            .task {
                await loadMyVotes()
            }
        }
    }

    // MARK: - Load My Votes
    private func loadMyVotes() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📱 [MyVotesSelectionSheet] Loading my votes...")
            myVotes = try await CommunityService.shared.fetchMyVotes()
            print("✅ [MyVotesSelectionSheet] Loaded \(myVotes.count) votes")
        } catch {
            print("❌ [MyVotesSelectionSheet] Failed to load votes: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Toggle Selection
    private func toggleSelection(_ id: String) {
        if selectedVotes.contains(id) {
            selectedVotes.remove(id)
        } else {
            selectedVotes.insert(id)
        }
    }
}

// MARK: - My Vote Card
struct MyVoteCard: View {
    let voteItem: MyVoteItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(voteItem.title)
                        .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                        .lineLimit(2)

                    if let choice = voteItem.selectedChoiceLabel {
                        Text("選択: \(choice)")
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.accentPink)
                    }

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text(timeAgoString(from: voteItem.votedAt))
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Constants.Colors.textGray)

                        // Phase 1: ポイント機能無効化
                        if FeatureFlags.pointsEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                Text("\(voteItem.pointsUsed)pt")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.yellow)
                        }
                    }
                }

                Spacer()
            }
            .padding(Constants.Spacing.medium)
            .background(
                isSelected
                    ? Constants.Colors.accentPink.opacity(0.1)
                    : Constants.Colors.cardDark
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? Constants.Colors.accentPink
                            : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time Ago String
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let seconds = Int(interval)

        if seconds < 60 {
            return "たった今"
        } else if seconds < 3600 {
            return "\(seconds / 60)分前"
        } else if seconds < 86400 {
            return "\(seconds / 3600)時間前"
        } else {
            return "\(seconds / 86400)日前"
        }
    }
}

// MARK: - Preview
#Preview {
    MyVotesSelectionSheet { votes in
        print("Selected \(votes.count) votes")
    }
}
