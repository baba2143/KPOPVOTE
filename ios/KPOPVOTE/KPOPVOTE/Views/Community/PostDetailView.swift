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
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false

    // Comment states
    @State private var comments: [Comment] = []
    @State private var isLoadingComments = false
    @State private var commentText = ""
    @State private var isSendingComment = false
    @State private var commentError: String?

    init(postId: String) {
        self.postId = postId
        print("🔵 [PostDetailView] INIT with postId: \(postId)")
    }

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
            // Close button (always visible)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }

            // Delete button (owner only)
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
            print("🟢 [PostDetailView] .task executed for postId: \(postId)")
            await loadPost()
            await loadComments()
        }
        .onAppear {
            print("🟡 [PostDetailView] onAppear called for postId: \(postId)")
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
            case .goodsTrade:
                goodsTradeContent(post: post)
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

    // MARK: - Goods Trade Content
    @ViewBuilder
    private func goodsTradeContent(post: CommunityPost) -> some View {
        if let goodsTrade = post.content.goodsTrade {
            VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                // Trade Type and Status Badges
                HStack(spacing: 8) {
                    // Trade Type Badge
                    HStack(spacing: 4) {
                        Image(systemName: goodsTrade.tradeType == "want" ? "hand.raised.fill" : "hand.thumbsup.fill")
                            .font(.system(size: 14))
                        Text(goodsTrade.tradeType == "want" ? "求む" : "譲ります")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(goodsTrade.tradeType == "want" ? Constants.Colors.accentPink : Constants.Colors.accentBlue)
                    .cornerRadius(20)

                    // Status Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusColor(goodsTrade.status))
                            .frame(width: 8, height: 8)
                        Text(statusText(goodsTrade.status))
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(20)

                    Spacer()
                }

                // Goods Image
                if let url = URL(string: goodsTrade.goodsImageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(16)
                        case .failure(_), .empty:
                            Rectangle()
                                .fill(Constants.Colors.backgroundDark)
                                .frame(height: 300)
                                .cornerRadius(16)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 60))
                                        .foregroundColor(Constants.Colors.textGray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                // Goods Info
                VStack(alignment: .leading, spacing: 12) {
                    // Goods Name
                    Text(goodsTrade.goodsName)
                        .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    // Idol Info
                    if !goodsTrade.idolName.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                            Text(goodsTrade.idolName)
                            if !goodsTrade.groupName.isEmpty {
                                Text("(\(goodsTrade.groupName))")
                            }
                        }
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.textGray)
                    }

                    // Condition
                    if let condition = goodsTrade.condition {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                            Text("状態: \(conditionText(condition))")
                        }
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.textWhite)
                    }

                    // Tags
                    if !goodsTrade.goodsTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(goodsTrade.goodsTags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: Constants.Typography.bodySize))
                                        .foregroundColor(Constants.Colors.accentPink)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Constants.Colors.accentPink.opacity(0.2))
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }

                    // Description
                    if let description = goodsTrade.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("説明")
                                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textGray)

                            Text(description)
                                .font(.system(size: Constants.Typography.bodySize))
                                .foregroundColor(Constants.Colors.textWhite)
                                .lineSpacing(6)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions for Goods Trade
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "available":
            return .green
        case "reserved":
            return .orange
        case "completed":
            return .gray
        default:
            return .gray
        }
    }

    private func statusText(_ status: String) -> String {
        switch status {
        case "available":
            return "募集中"
        case "reserved":
            return "予約済"
        case "completed":
            return "完了"
        default:
            return status
        }
    }

    private func conditionText(_ condition: String) -> String {
        switch condition {
        case "new":
            return "新品・未開封"
        case "excellent":
            return "美品"
        case "good":
            return "良好"
        case "fair":
            return "やや傷あり"
        default:
            return condition
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
            // Header
            HStack {
                Text("コメント")
                    .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()

                Text("\(comments.count)")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)
            }

            // Comment Input
            HStack(alignment: .top, spacing: Constants.Spacing.small) {
                TextField("コメントを入力...", text: $commentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textWhite)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .lineLimit(3...6)
                    .disabled(isSendingComment)

                Button(action: {
                    Task {
                        await sendComment()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Constants.Colors.textGray : Constants.Colors.accentPink)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingComment)
            }

            // Error message
            if let commentError = commentError {
                Text(commentError)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
            }

            // Loading state
            if isLoadingComments {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                    Spacer()
                }
                .padding(.vertical, Constants.Spacing.medium)
            }

            // Comments list
            if !comments.isEmpty {
                VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                    ForEach(comments) { comment in
                        CommentRow(
                            comment: comment,
                            postAuthorId: post?.userId ?? "",
                            onDelete: {
                                Task {
                                    await deleteCommentAction(commentId: comment.id)
                                }
                            }
                        )
                    }
                }
            } else if !isLoadingComments {
                Text("まだコメントがありません")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Constants.Spacing.large)
            }
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

    // MARK: - Load Comments
    private func loadComments() async {
        isLoadingComments = true
        commentError = nil

        do {
            print("💬 [PostDetailView] Loading comments for post: \(postId)")
            let result = try await CommunityService.shared.fetchComments(postId: postId, limit: 50)
            comments = result.comments
            print("✅ [PostDetailView] Loaded \(comments.count) comments")
        } catch {
            print("❌ [PostDetailView] Failed to load comments: \(error)")
            commentError = "コメントの読み込みに失敗しました"
        }

        isLoadingComments = false
    }

    // MARK: - Send Comment
    private func sendComment() async {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSendingComment = true
        commentError = nil

        do {
            print("💬 [PostDetailView] Sending comment: \(text)")
            let result = try await CommunityService.shared.createComment(postId: postId, text: text)

            // Clear input
            commentText = ""

            // Update post's comment count
            if var currentPost = post {
                currentPost.commentsCount = result.commentsCount
                post = currentPost
            }

            // Reload comments to show the new one
            await loadComments()

            print("✅ [PostDetailView] Comment sent successfully: \(result.commentId)")
        } catch {
            print("❌ [PostDetailView] Failed to send comment: \(error)")

            // Show specific error message
            if let communityError = error as? CommunityError {
                commentError = communityError.errorDescription
            } else {
                commentError = "コメントの送信に失敗しました"
            }
        }

        isSendingComment = false
    }

    // MARK: - Delete Comment
    private func deleteCommentAction(commentId: String) async {
        do {
            print("🗑️ [PostDetailView] Deleting comment: \(commentId)")
            try await CommunityService.shared.deleteComment(commentId: commentId)

            // Remove from local list
            comments.removeAll { $0.id == commentId }

            // Update post's comment count
            if var currentPost = post {
                currentPost.commentsCount = max(0, currentPost.commentsCount - 1)
                post = currentPost
            }

            print("✅ [PostDetailView] Comment deleted successfully")
        } catch {
            print("❌ [PostDetailView] Failed to delete comment: \(error)")
            commentError = "コメントの削除に失敗しました"
        }
    }
}

// MARK: - Comment Row Component
struct CommentRow: View {
    let comment: Comment
    let postAuthorId: String
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Constants.Spacing.small) {
            // Avatar
            if let photoURL = comment.user.photoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Constants.Colors.accentPink.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Constants.Colors.accentPink)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Constants.Colors.accentPink.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Constants.Colors.accentPink)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.displayName ?? "Unknown User")
                        .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(timeAgoString(from: comment.createdAt))
                        .font(.system(size: 11))
                        .foregroundColor(Constants.Colors.textGray)

                    Spacer()

                    // Delete button (show if current user is comment author or post author)
                    if canDeleteComment() {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.red.opacity(0.8))
                        }
                    }
                }

                Text(comment.text)
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textWhite)
                    .lineSpacing(4)
            }
        }
        .padding(Constants.Spacing.small)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }

    private func canDeleteComment() -> Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return comment.userId == currentUser.uid || postAuthorId == currentUser.uid
    }

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
