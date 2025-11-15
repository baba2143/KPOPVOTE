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
        VStack(spacing: 0) {
            // Cover Image with gradient overlay and content
            ZStack(alignment: .topLeading) {
                // Background Image
                if let coverImage = task.coverImage, let imageUrl = URL(string: coverImage) {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 220)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Constants.Colors.gradientBlue, Constants.Colors.gradientPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 220)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }
                } else {
                    // Fallback gradient background
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Constants.Colors.gradientBlue, Constants.Colors.gradientPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 220)
                }

                // Dark gradient overlay
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.black.opacity(0.3), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)

                // Content on top of image
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    // External App Badge
                    if let iconUrl = task.externalAppIconUrl, let appName = task.externalAppName {
                        HStack(spacing: 6) {
                            if let url = URL(string: iconUrl) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .cornerRadius(4)
                                    case .failure(_), .empty:
                                        Image(systemName: "app.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }

                            Text(appName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(6)
                    }

                    // Urgent badge
                    HStack(spacing: 4) {
                        Text("投票タイトル：")
                            .font(.system(size: 12, weight: .bold))
                        Text(task.title)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Constants.Colors.statusUrgent)
                    .cornerRadius(6)

                    Spacer()

                    // Time remaining badge
                    HStack(spacing: 4) {
                        Text("終了まで")
                            .font(.system(size: 12, weight: .semibold))
                        Text(task.timeRemaining)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Constants.Colors.statusUrgent)
                    .cornerRadius(8)
                }
                .padding(Constants.Spacing.medium)
                .frame(height: 220, alignment: .topLeading)
            }

            // Bottom section with Vote button
            VStack(spacing: Constants.Spacing.small) {
                // Vote Now button
                Button(action: {
                    if let url = URL(string: task.url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Vote Now")
                        .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(Constants.Spacing.medium)
            .background(Constants.Colors.cardDark)
        }
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
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
