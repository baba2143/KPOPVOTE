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
                Text("Community Activity")
                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)
                Spacer()
                Button(action: {
                    // Navigate to full community activity
                }) {
                    Text("View All")
                        .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                        .foregroundColor(Constants.Colors.accentPink)
                }
            }

            // Activity Posts
            VStack(spacing: Constants.Spacing.medium) {
                ActivityPostItem(
                    avatarColor: .pink,
                    username: "K-Pop Fan",
                    message: "Amazing performance today! Did everyone see the ",
                    highlightedText: "new choreography",
                    remainingText: " for the comeback stage? Absolutely breathtaking!",
                    likes: 1200,
                    comments: 345,
                    timeAgo: "2 hours ago"
                )

                ActivityPostItem(
                    avatarColor: .purple,
                    username: "Vote Master",
                    message: "Just a reminder to keep streaming the ",
                    highlightedText: "new music video",
                    remainingText: ". We're so close to our goal for the first 24 hours! Let's do this 💪",
                    likes: 892,
                    comments: 102,
                    timeAgo: "5 hours ago"
                )
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - Activity Post Item Component
struct ActivityPostItem: View {
    let avatarColor: Color
    let username: String
    let message: String
    let highlightedText: String
    let remainingText: String
    let likes: Int
    let comments: Int
    let timeAgo: String

    var body: some View {
        HStack(alignment: .top, spacing: Constants.Spacing.small) {
            // Avatar
            Circle()
                .fill(avatarColor.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(avatarColor)
                )

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Username
                Text(username)
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                // Message with highlighted text
                Group {
                    Text(message)
                        .foregroundColor(Constants.Colors.textGray) +
                    Text(highlightedText)
                        .foregroundColor(Constants.Colors.accentPink)
                        .bold() +
                    Text(remainingText)
                        .foregroundColor(Constants.Colors.textGray)
                }
                .font(.system(size: Constants.Typography.captionSize))
                .lineSpacing(4)

                // Engagement metrics
                HStack(spacing: Constants.Spacing.medium) {
                    // Likes
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
                        Text("\(likes)")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
                    }

                    // Comments
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
                        Text("\(comments)")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
                    }

                    Spacer()

                    // Time ago
                    Text(timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(Constants.Colors.textGray)
                }
                .padding(.top, 4)
            }
        }
        .padding(Constants.Spacing.small)
        .background(Color.white.opacity(0.05))
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
    .background(Constants.Colors.backgroundDark)
}
