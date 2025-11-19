//
//  CommunityActivityView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Community Activity Component
//

import SwiftUI

struct CommunityActivityView: View {
    @StateObject private var viewModel = CommunityActivityViewModel()
    @EnvironmentObject var biasViewModel: BiasViewModel

    let onViewAll: () -> Void
    let onPostTap: (String) -> Void

    var body: some View {
        // Hide section if no biases selected
        if !biasViewModel.selectedIdolObjects.isEmpty {
            VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                // Section Header
                HStack {
                    Text("Community Activity")
                        .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                    Spacer()
                    Button(action: onViewAll) {
                        Text("View All")
                            .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                            .foregroundColor(Constants.Colors.accentPink)
                    }
                }

                // Content
                if viewModel.isLoading {
                    // Loading State
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        Spacer()
                    }
                    .padding(.vertical, Constants.Spacing.large)
                } else if let errorMessage = viewModel.errorMessage {
                    // Error State
                    VStack(spacing: Constants.Spacing.small) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(Constants.Colors.textGray)
                        Text(errorMessage)
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.Spacing.large)
                } else if viewModel.posts.isEmpty {
                    // Empty State
                    VStack(spacing: Constants.Spacing.small) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32))
                            .foregroundColor(Constants.Colors.textGray)
                        Text("まだ投稿がありません")
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Constants.Spacing.large)
                } else {
                    // Activity Posts
                    VStack(spacing: Constants.Spacing.medium) {
                        ForEach(viewModel.posts) { post in
                            ActivityPostItem(
                                post: post,
                                onTap: {
                                    onPostTap(post.id)
                                }
                            )
                        }
                    }
                }
            }
            .padding(Constants.Spacing.medium)
            .background(Constants.Colors.cardDark)
            .cornerRadius(16)
            .task {
                let biasIds = biasViewModel.selectedIdolObjects.map { $0.id }
                await viewModel.loadPosts(biasIds: biasIds)
            }
        }
    }
}

// MARK: - Activity Post Item Component
struct ActivityPostItem: View {
    let post: CommunityPost
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Constants.Spacing.small) {
                // Avatar
                if let photoURL = post.user.photoURL, !photoURL.isEmpty {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Constants.Colors.accentPink.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Constants.Colors.accentPink)
                            )
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Constants.Colors.accentPink.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Constants.Colors.accentPink)
                        )
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Username
                    Text(post.user.displayName ?? "Unknown User")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    // Post Content
                    if let text = post.content.text, !text.isEmpty {
                        Text(text)
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                            .lineSpacing(4)
                            .lineLimit(3)
                    }

                    // Engagement metrics
                    HStack(spacing: Constants.Spacing.medium) {
                        // Likes
                        HStack(spacing: 4) {
                            Image(systemName: (post.isLikedByCurrentUser ?? false) ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundColor((post.isLikedByCurrentUser ?? false) ? Constants.Colors.accentPink : Constants.Colors.textGray)
                            Text("\(post.likesCount)")
                                .font(.system(size: 12))
                                .foregroundColor(Constants.Colors.textGray)
                        }

                        // Comments
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 12))
                                .foregroundColor(Constants.Colors.textGray)
                            Text("\(post.commentsCount)")
                                .font(.system(size: 12))
                                .foregroundColor(Constants.Colors.textGray)
                        }

                        Spacer()

                        // Time ago
                        Text(timeAgoString(from: post.createdAt))
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
    VStack {
        CommunityActivityView(
            onViewAll: { print("View All tapped") },
            onPostTap: { postId in print("Post tapped: \(postId)") }
        )
        .environmentObject(BiasViewModel())
        .padding()

        Spacer()
    }
    .background(Constants.Colors.backgroundDark)
}
