//
//  DailyLimitBadgeView.swift
//  KPOPVOTE
//
//  Daily vote limit badge component
//

import SwiftUI

struct DailyLimitBadgeView: View {
    let votesUsed: Int
    let maxVotes: Int  // 互換性のため保持（使用しない）

    var body: some View {
        HStack(spacing: 12) {
            // Vote icon
            Image(systemName: "heart.fill")
                .foregroundColor(Constants.Colors.accentPink)
                .font(.title3)

            // Text info
            VStack(alignment: .leading, spacing: 2) {
                Text("本日の投票数")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textGray)

                HStack(spacing: 4) {
                    Text("\(votesUsed)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Constants.Colors.accentPink)
                    Text("票")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textGray)
                }
            }

            Spacer()

            // Vote count indicator (上限撤廃後はシンプルなアイコン表示)
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Constants.Colors.accentPink)
                .font(.system(size: 32))
        }
        .padding()
        .background(Constants.Colors.cardDark)
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
