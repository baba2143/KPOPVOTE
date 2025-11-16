//
//  PostDetailView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Post Detail View
//

import SwiftUI
import FirebaseAuth

struct PostDetailView: View {
    let postId: String
    @Environment(\.dismiss) private var dismiss
    @State private var post: CommunityPost?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            if isLoading {
                ProgressView("読み込み中...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                    .foregroundColor(Constants.Colors.textWhite)
            } else if let errorMessage = errorMessage {
                ErrorView(message: errorMessage) {
                    Task {
                        await loadPost()
                    }
                }
            } else if let post = post {
                ScrollView {
                    VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                        // User Header
                        userHeader(post: post)

                        // Post Content
                        postContent(post: post)

                        // Engagement Section
                        engagementSection(post: post)

                        Divider()
                            .background(Color.white.opacity(0.1))

                        // Comments Section (Placeholder)
                        commentsSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("投稿詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let post = post, isPostOwner(post) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            showDeleteConfirm = true
                        }) {
                            Label("削除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
        }
        .alert("投稿を削除", isPresented: $showDeleteConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                Task {
                    await deletePost()
                }
            }
        } message: {
            Text("この投稿を削除してもよろしいですか？")
        }
        .task {
            await loadPost()
        }
    }

    // MARK: - User Header
    @ViewBuilder
    private func userHeader(post: CommunityPost) -> some View {
        HStack(spacing: Constants.Spacing.small) {
            // User Avatar
            Circle()
                .fill(Constants.Colors.accentPink.opacity(0.3))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Constants.Colors.accentPink)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(post.user.displayName ?? "Unknown User")
                    .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                        Text("\(post.user.followersCount)")
                            .font(.system(size: Constants.Typography.captionSize))
                    }
                    .foregroundColor(Constants.Colors.textGray)

                    Text("・")
                        .foregroundColor(Constants.Colors.textGray)

                    Text(timeAgoString(from: post.createdAt))
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                }
            }

            Spacer()
        }
    }

    // MARK: - Post Content
    @ViewBuilder
    private func postContent(post: CommunityPost) -> some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            switch post.type {
            case .voteShare:
                voteShareContent(post: post)
            case .image:
                imageContent(post: post)
            case .myVotes:
                myVotesContent(post: post)
            }
        }
    }

    // MARK: - Vote Share Content
    @ViewBuilder
    private func voteShareContent(post: CommunityPost) -> some View {
        if let voteSnapshot = post.content.voteSnapshot {
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                // Vote Card
                VStack(alignment: .leading, spacing: 12) {
                    if let coverImageUrl = voteSnapshot.coverImageUrl, let url = URL(string: coverImageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxHeight: 300)
                                    .clipped()
                                    .cornerRadius(12)
                            case .failure(_), .empty:
                                Rectangle()
                                    .fill(Constants.Colors.backgroundDark)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    Text(voteSnapshot.title)
                        .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(voteSnapshot.description)
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.textGray)
                        .lineSpacing(4)

                    // Vote Stats
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 14))
                            Text("\(voteSnapshot.totalVotes)票")
                                .font(.system(size: Constants.Typography.captionSize))
                        }
                        .foregroundColor(Constants.Colors.textGray)

                        HStack(spacing: 4) {
                            Image(systemName: "flame")
                                .font(.system(size: 14))
                            Text("\(voteSnapshot.requiredPoints)P")
                                .font(.system(size: Constants.Typography.captionSize))
                        }
                        .foregroundColor(Constants.Colors.accentBlue)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
            }
        }
    }

    // MARK: - Image Content
    @ViewBuilder
    private func imageContent(post: CommunityPost) -> some View {
        if let text = post.content.text {
            Text(text)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)
                .lineSpacing(6)
        }

        if let images = post.content.images, !images.isEmpty {
            VStack(spacing: Constants.Spacing.small) {
                ForEach(images, id: \.self) { imageUrl in
                    if let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(12)
                            case .failure(_), .empty:
                                Rectangle()
                                    .fill(Constants.Colors.backgroundDark)
                                    .frame(height: 200)
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

    // MARK: - My Votes Content
    @ViewBuilder
    private func myVotesContent(post: CommunityPost) -> some View {
        if let text = post.content.text {
            Text(text)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)
                .lineSpacing(6)
        }

        if let myVotes = post.content.myVotes {
            VStack(spacing: Constants.Spacing.small) {
                ForEach(myVotes, id: \.id) { voteItem in
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(voteItem.title)
                                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textWhite)

                            if let choice = voteItem.selectedChoiceLabel {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text(choice)
                                        .font(.system(size: Constants.Typography.captionSize))
                                }
                                .foregroundColor(Constants.Colors.accentPink)
                            }

                            Text(timeAgoString(from: voteItem.votedAt))
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(Constants.Colors.textGray)
                        }

                        Spacer()

                        Text("\(voteItem.pointsUsed)P")
                            .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                            .foregroundColor(Constants.Colors.accentBlue)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Engagement Section
    @ViewBuilder
    private func engagementSection(post: CommunityPost) -> some View {
        VStack(spacing: Constants.Spacing.medium) {
            // Engagement Stats
            HStack(spacing: Constants.Spacing.large) {
                Text("\(post.likesCount)いいね")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)

                Text("\(post.commentsCount)コメント")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)

                Spacer()
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Action Buttons
            HStack(spacing: 0) {
                Button(action: {
                    Task {
                        await toggleLike()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 22))
                        Text("いいね")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    }
                    .foregroundColor(post.isLiked ? Constants.Colors.accentPink : Constants.Colors.textGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Button(action: {
                    // TODO: Focus on comment input
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 22))
                        Text("コメント")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    }
                    .foregroundColor(Constants.Colors.textGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Comments Section
    @ViewBuilder
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
            Text("コメント")
                .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)

            Text("コメント機能は今後実装予定です")
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, Constants.Spacing.large)
        }
    }

    // MARK: - Load Post
    private func loadPost() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📱 [PostDetailView] Loading post: \(postId)")
            post = try await CommunityService.shared.fetchPost(postId: postId)
            print("✅ [PostDetailView] Post loaded successfully")
        } catch {
            print("❌ [PostDetailView] Failed to load post: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Toggle Like
    private func toggleLike() async {
        guard var currentPost = post else { return }

        do {
            print("💗 [PostDetailView] Toggling like for post: \(postId)")
            let result = try await CommunityService.shared.likePost(postId: postId)

            // Update local state
            currentPost.isLiked = (result.action == "liked")
            currentPost.likesCount = result.likesCount
            post = currentPost

            print("✅ [PostDetailView] Like toggled: \(result.action)")
        } catch {
            print("❌ [PostDetailView] Failed to toggle like: \(error)")
        }
    }

    // MARK: - Delete Post
    private func deletePost() async {
        do {
            print("🗑️ [PostDetailView] Deleting post: \(postId)")
            try await CommunityService.shared.deletePost(postId: postId)
            print("✅ [PostDetailView] Post deleted successfully")
            dismiss()
        } catch {
            print("❌ [PostDetailView] Failed to delete post: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Check Post Owner
    private func isPostOwner(_ post: CommunityPost) -> Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return post.userId == currentUser.uid
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
    NavigationView {
        PostDetailView(postId: "test-post-id")
    }
}
