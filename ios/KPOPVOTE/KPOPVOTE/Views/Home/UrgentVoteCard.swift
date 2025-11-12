//
//  UrgentVoteCard.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Urgent Vote Card Component
//

import SwiftUI

struct UrgentVoteCard: View {
    let task: VoteTask
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            // Header with deadline badge
            HStack {
                // Deadline badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text(task.timeRemaining)
                        .font(.system(size: Constants.Typography.captionSize, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(task.isExpired ? Color.red : Constants.Colors.primaryBlue)
                .foregroundColor(.white)
                .cornerRadius(12)

                Spacer()

                // Complete button
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }

            // Task title
            Text(task.title)
                .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                .foregroundColor(Constants.Colors.textPrimary)
                .lineLimit(2)

            // Task URL
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textSecondary)
                Text(task.url)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textSecondary)
                    .lineLimit(1)
            }

            // OGP Image if available
            if let ogpImage = task.ogpImage, let imageUrl = URL(string: ogpImage) {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 120)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                        )
                }
            }

            // Deadline info
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textSecondary)
                Text(task.formattedDeadline)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textSecondary)

                Spacer()

                // Vote button
                Button(action: {
                    if let url = URL(string: task.url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("投票する")
                            .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(Constants.Colors.primaryBlue)
                }
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    let sampleTask = VoteTask(
        userId: "user123",
        title: "MAMA 2024 Best Female Group",
        url: "https://vote.mnet.com/mama",
        deadline: Date().addingTimeInterval(3600 * 8), // 8 hours from now
        biasIds: ["blackpink"]
    )

    return VStack {
        UrgentVoteCard(task: sampleTask) {
            print("Task completed")
        }
        .padding()

        Spacer()
    }
    .background(Constants.Colors.background)
}
