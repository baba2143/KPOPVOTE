//
//  IdolRankingEntryView.swift
//  KPOPVOTE
//
//  Single ranking entry row component
//

import SwiftUI

struct IdolRankingEntryView: View {
    let entry: IdolRankingEntry
    let canVote: Bool
    let isVoting: Bool
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            rankView

            // Profile image
            profileImage

            // Name and group
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.headline)
                    .lineLimit(1)

                if let groupName = entry.groupName, !groupName.isEmpty {
                    Text(groupName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Vote count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.votes.formatted())")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("票")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Vote button
            voteButton
        }
        .padding(.vertical, 4)
    }

    private var rankView: some View {
        Group {
            if entry.rank <= 3 {
                Text(entry.rankMedal)
                    .font(.title2)
                    .frame(width: 40)
            } else {
                Text("\(entry.rank)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(width: 40)
            }
        }
    }

    private var profileImage: some View {
        Group {
            if let imageUrl = entry.imageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
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
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: entry.entityType == .group ? "person.3.fill" : "person.fill")
                    .foregroundColor(.gray)
            )
    }

    private var voteButton: some View {
        Button(action: onVote) {
            if isVoting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(canVote ? .pink : .gray)
                    .frame(width: 44, height: 44)
            }
        }
        .disabled(!canVote || isVoting)
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        IdolRankingEntryView(
            entry: IdolRankingEntry(
                rank: 1,
                entityId: "1",
                entityType: .individual,
                name: "カリナ",
                groupName: "aespa",
                imageUrl: nil,
                weeklyVotes: 1234,
                totalVotes: 5678,
                previousRank: 2,
                rankChange: 1
            ),
            canVote: true,
            isVoting: false,
            onVote: {}
        )

        IdolRankingEntryView(
            entry: IdolRankingEntry(
                rank: 2,
                entityId: "2",
                entityType: .group,
                name: "NewJeans",
                groupName: nil,
                imageUrl: nil,
                weeklyVotes: 987,
                totalVotes: 4321,
                previousRank: 1,
                rankChange: -1
            ),
            canVote: true,
            isVoting: false,
            onVote: {}
        )

        IdolRankingEntryView(
            entry: IdolRankingEntry(
                rank: 4,
                entityId: "4",
                entityType: .individual,
                name: "ウィンター",
                groupName: "aespa",
                imageUrl: nil,
                weeklyVotes: 456,
                totalVotes: 2345,
                previousRank: nil,
                rankChange: nil
            ),
            canVote: false,
            isVoting: false,
            onVote: {}
        )
    }
    .padding()
}
