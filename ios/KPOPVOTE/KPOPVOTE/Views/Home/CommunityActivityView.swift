//
//  CommunityActivityView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Community Activity Component
//

import SwiftUI

struct CommunityActivityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            // Section Header
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Constants.Colors.primaryBlue)
                Text("コミュニティ活動")
                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textPrimary)
                Spacer()
            }

            // Activity Items
            VStack(spacing: Constants.Spacing.small) {
                ActivityItem(
                    icon: "trophy.fill",
                    iconColor: .orange,
                    title: "今週のTOP投票者",
                    subtitle: "3,421票を獲得"
                )

                ActivityItem(
                    icon: "flame.fill",
                    iconColor: .red,
                    title: "連続投票中",
                    subtitle: "7日間継続中"
                )

                ActivityItem(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .green,
                    title: "コミュニティ貢献度",
                    subtitle: "レベル 12"
                )
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Activity Item Component
struct ActivityItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: Constants.Spacing.small) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textPrimary)

                Text(subtitle)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textSecondary)
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .padding(Constants.Spacing.small)
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        CommunityActivityView()
            .padding()

        Spacer()
    }
    .background(Constants.Colors.background)
}
