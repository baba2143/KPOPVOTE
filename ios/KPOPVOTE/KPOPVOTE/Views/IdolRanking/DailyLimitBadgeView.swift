//
//  DailyLimitBadgeView.swift
//  KPOPVOTE
//
//  Daily vote limit badge component
//

import SwiftUI

struct DailyLimitBadgeView: View {
    let votesUsed: Int
    let maxVotes: Int

    var remainingVotes: Int {
        max(0, maxVotes - votesUsed)
    }

    var progressValue: Double {
        guard maxVotes > 0 else { return 0 }
        return Double(votesUsed) / Double(maxVotes)
    }

    var badgeColor: Color {
        if remainingVotes == 0 {
            return .gray
        } else if remainingVotes <= 2 {
            return .orange
        } else {
            return .green
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Vote icon
            Image(systemName: "heart.fill")
                .foregroundColor(.pink)
                .font(.title3)

            // Text info
            VStack(alignment: .leading, spacing: 2) {
                Text("本日の残り投票数")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("\(remainingVotes)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(badgeColor)
                    Text("/ \(maxVotes)票")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: 1 - progressValue)
                    .stroke(badgeColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text("\(remainingVotes)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(badgeColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DailyLimitBadgeView(votesUsed: 0, maxVotes: 5)
        DailyLimitBadgeView(votesUsed: 2, maxVotes: 5)
        DailyLimitBadgeView(votesUsed: 4, maxVotes: 5)
        DailyLimitBadgeView(votesUsed: 5, maxVotes: 5)
    }
    .padding()
}
