//
//  PostCardView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Post Card Component
//

import SwiftUI

struct PostCardView: View {
    let post: CommunityPost
    let onTap: () -> Void
    let onLike: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            // User Header
            HStack(spacing: Constants.Spacing.small) {
                // User Avatar
                Circle()
                    .fill(Constants.Colors.accentPink.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Constants.Colors.accentPink)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user.displayName ?? "Unknown User")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(timeAgoString(from: post.createdAt))
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                }

                Spacer()

                // Delete Button (if owner)
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }
            }

            // Post Content
            Button(action: onTap) {
                postContentView
            }
            .buttonStyle(PlainButtonStyle())

            // Engagement Metrics
            HStack(spacing: Constants.Spacing.large) {
                // Like Button
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(post.isLiked ? Constants.Colors.accentPink : Constants.Colors.textGray)
                        Text("\(post.likesCount)")
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }

                // Comments
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 18))
                        .foregroundColor(Constants.Colors.textGray)
                    Text("\(post.commentsCount)")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                }

                Spacer()
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }

    // MARK: - Post Content View
    @ViewBuilder
    private var postContentView: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            switch post.type {
            case .voteShare:
                voteShareContent
            case .image:
                imageContent
            case .myVotes:
                myVotesContent
            }
        }
    }

    // MARK: - Vote Share Content
    @ViewBuilder
    private var voteShareContent: some View {
        if let voteSnapshot = post.content.voteSnapshot {
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                // Vote Card
                VStack(alignment: .leading, spacing: 8) {
                    if let coverImageUrl = voteSnapshot.coverImageUrl, let url = URL(string: coverImageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipped()
                                    .cornerRadius(8)
                            case .failure(_), .empty:
                                Rectangle()
                                    .fill(Constants.Colors.backgroundDark)
                                    .frame(height: 120)
                                    .cornerRadius(8)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    Text(voteSnapshot.title)
                        .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(voteSnapshot.description)
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                        .lineLimit(2)
                }
                .padding(Constants.Spacing.small)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Image Content
    @ViewBuilder
    private var imageContent: some View {
        if let text = post.content.text {
            Text(text)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)
                .lineSpacing(4)
        }

        if let images = post.content.images, !images.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Constants.Spacing.small) {
                    ForEach(images, id: \.self) { imageUrl in
                        if let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 200, height: 200)
                                        .clipped()
                                        .cornerRadius(12)
                                case .failure(_), .empty:
                                    Rectangle()
                                        .fill(Constants.Colors.backgroundDark)
                                        .frame(width: 200, height: 200)
                                        .cornerRadius(12)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - My Votes Content
    @ViewBuilder
    private var myVotesContent: some View {
        if let text = post.content.text {
            Text(text)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)
                .lineSpacing(4)
        }

        if let myVotes = post.content.myVotes {
            VStack(spacing: Constants.Spacing.small) {
                ForEach(myVotes.prefix(3), id: \.id) { voteItem in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(voteItem.title)
                                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textWhite)

                            if let choice = voteItem.selectedChoiceLabel {
                                Text("選択: \(choice)")
                                    .font(.system(size: Constants.Typography.captionSize))
                                    .foregroundColor(Constants.Colors.accentPink)
                            }
                        }

                        Spacer()

                        Text("\(voteItem.pointsUsed)P")
                            .font(.system(size: Constants.Typography.captionSize, weight: .bold))
                            .foregroundColor(Constants.Colors.accentBlue)
                    }
                    .padding(Constants.Spacing.small)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }

                if myVotes.count > 3 {
                    Text("+\(myVotes.count - 3)件の投票")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                }
            }
        }
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
        PostCardView(
            post: CommunityPost(
                id: "1",
                userId: "user1",
                user: User(
                    id: "user1",
                    email: "test@example.com",
                    displayName: "Test User",
                    photoURL: nil,
                    followingCount: 50,
                    followersCount: 100,
                    postsCount: 10
                ),
                type: .image,
                content: PostContent(text: "素晴らしいパフォーマンスでした！", images: nil, voteId: nil, voteSnapshot: nil, myVotes: nil),
                biasIds: [],
                isLiked: false
            ),
            onTap: {},
            onLike: {},
            onDelete: nil
        )
        .padding()

        Spacer()
    }
    .background(Constants.Colors.backgroundDark)
}
