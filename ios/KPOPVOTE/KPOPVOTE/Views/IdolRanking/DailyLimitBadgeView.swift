//
//  DailyLimitBadgeView.swift
//  KPOPVOTE
//
//  Vote points badge component - shows remaining points (voting power)
//

import SwiftUI

struct DailyLimitBadgeView: View {
    let votesUsed: Int  // 今日使った票数（参考情報として保持）
    let maxVotes: Int   // ポイント残高（投票可能数）

    /// 投票可能数（ポイント残高）
    var remainingVotes: Int {
        maxVotes  // 新システムではmaxVotes = ポイント残高
    }

    var body: some View {
        HStack(spacing: 12) {
            // Point icon
            Image(systemName: "p.circle.fill")
                .foregroundColor(Constants.Colors.accentPink)
                .font(.title3)

            // Text info
            VStack(alignment: .leading, spacing: 2) {
                Text("投票可能")
                    .font(.caption)
                    .foregroundColor(Constants.Colors.textGray)

                HStack(spacing: 4) {
                    Text("\(remainingVotes)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(remainingVotes > 0 ? Constants.Colors.accentPink : Constants.Colors.textGray)
                    Text("P")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textGray)
                }
            }

            Spacer()

            // Status indicator
            if remainingVotes > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Constants.Colors.accentPink)
                    .font(.system(size: 32))
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(Constants.Colors.textGray)
                        .font(.system(size: 28))
                    Text("ポイント不足")
                        .font(.caption2)
                        .foregroundColor(Constants.Colors.textGray)
                }
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        DailyLimitBadgeView(votesUsed: 0, maxVotes: 100)
        DailyLimitBadgeView(votesUsed: 5, maxVotes: 50)
        DailyLimitBadgeView(votesUsed: 10, maxVotes: 10)
        DailyLimitBadgeView(votesUsed: 0, maxVotes: 0)
    }
    .padding()
    .background(Color.black)
}
