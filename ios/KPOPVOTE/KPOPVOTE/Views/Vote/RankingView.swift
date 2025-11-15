//
//  RankingView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote Ranking Component
//

import SwiftUI

struct RankingView: View {
    let ranking: VoteRanking

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("投票結果")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()

                Text("総投票数: \(ranking.totalVotes)")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
            }

            // Ranking list
            VStack(spacing: 12) {
                ForEach(Array(ranking.ranking.enumerated()), id: \.element.id) { index, item in
                    RankingItemView(
                        rank: index + 1,
                        item: item,
                        isTopRank: index == 0
                    )
                }
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Ranking Item View
struct RankingItemView: View {
    let rank: Int
    let item: RankingItem
    let isTopRank: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label and vote count
            HStack(alignment: .center) {
                // Rank badge
                RankBadge(rank: rank, isTopRank: isTopRank)

                // Choice label
                Text(item.label)
                    .font(.system(size: 16, weight: isTopRank ? .bold : .medium))
                    .foregroundColor(Constants.Colors.textWhite)
                    .lineLimit(1)

                Spacer()

                // Vote count and percentage
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(item.voteCount)票")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(String(format: "%.1f%%", item.percentage))
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)
                }
            }

            // Progress bar
            ProgressBar(percentage: item.percentage, isTopRank: isTopRank)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTopRank ? Constants.Colors.accentPink.opacity(0.1) : Color.white.opacity(0.05))
        )
    }
}

// MARK: - Rank Badge
struct RankBadge: View {
    let rank: Int
    let isTopRank: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)

            if rank <= 3 {
                // Medal icon for top 3
                Image(systemName: medalIcon)
                    .font(.system(size: 16))
                    .foregroundColor(medalColor)
            } else {
                // Number for others
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)
            }
        }
    }

    private var backgroundColor: Color {
        switch rank {
        case 1:
            return Color(hex: "FFD700").opacity(0.3) // Gold
        case 2:
            return Color(hex: "C0C0C0").opacity(0.3) // Silver
        case 3:
            return Color(hex: "CD7F32").opacity(0.3) // Bronze
        default:
            return Color.white.opacity(0.1)
        }
    }

    private var medalIcon: String {
        switch rank {
        case 1:
            return "crown.fill"
        case 2:
            return "medal.fill"
        case 3:
            return "medal.fill"
        default:
            return ""
        }
    }

    private var medalColor: Color {
        switch rank {
        case 1:
            return Color(hex: "FFD700") // Gold
        case 2:
            return Color(hex: "C0C0C0") // Silver
        case 3:
            return Color(hex: "CD7F32") // Bronze
        default:
            return .white
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let percentage: Double
    let isTopRank: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: progressColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                    .animation(.easeInOut(duration: 0.5), value: percentage)
            }
        }
        .frame(height: 8)
    }

    private var progressColors: [Color] {
        if isTopRank {
            return [Constants.Colors.gradientPink, Constants.Colors.gradientPurple]
        } else {
            return [Constants.Colors.accentBlue, Constants.Colors.accentBlue.opacity(0.6)]
        }
    }
}

// MARK: - Preview
struct RankingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            RankingView(
                ranking: VoteRanking(
                    voteId: "1",
                    title: "K-POP ダンス対決",
                    totalVotes: 125,
                    ranking: [
                        RankingItem(id: "1", label: "BTS - Jungkook", voteCount: 50, percentage: 40.0),
                        RankingItem(id: "2", label: "BLACKPINK - Lisa", voteCount: 35, percentage: 28.0),
                        RankingItem(id: "3", label: "TWICE - Momo", voteCount: 25, percentage: 20.0),
                        RankingItem(id: "4", label: "Stray Kids - Lee Know", voteCount: 15, percentage: 12.0)
                    ]
                )
            )
        }
        .padding()
        .background(Constants.Colors.backgroundDark)
        .previewLayout(.sizeThatFits)
    }
}
