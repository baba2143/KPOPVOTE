//
//  FavoritesView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Favorites View
//

import SwiftUI

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var selectedTab: FavoritesTab = .posts

    enum FavoritesTab: String, CaseIterable {
        case posts = "Posts"
        case collections = "Collections"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab Picker
                    tabPicker

                    // Content
                    TabView(selection: $selectedTab) {
                        likedPostsView
                            .tag(FavoritesTab.posts)

                        savedCollectionsView
                            .tag(FavoritesTab.collections)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
            .task {
                await viewModel.refreshAll()
            }
        }
    }

    // MARK: - Tab Picker
    @ViewBuilder
    private var tabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(FavoritesTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    // MARK: - Liked Posts View
    @ViewBuilder
    private var likedPostsView: some View {
        if viewModel.isLoadingPosts && viewModel.likedPosts.isEmpty {
            loadingView
        } else if viewModel.likedPosts.isEmpty {
            emptyStateView(
                icon: "heart.slash",
                title: "No Liked Posts",
                subtitle: "Posts you like will appear here"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Constants.Spacing.medium) {
                    ForEach(viewModel.likedPosts) { post in
                        FavoritePostCard(post: post)
                            .onAppear {
                                // Load more when last item appears
                                if post.id == viewModel.likedPosts.last?.id {
                                    Task {
                                        await viewModel.loadMoreLikedPosts()
                                    }
                                }
                            }
                    }

                    if viewModel.isLoadingPosts {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                            .padding()
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.loadLikedPosts()
            }
        }
    }

    // MARK: - Saved Collections View
    @ViewBuilder
    private var savedCollectionsView: some View {
        if viewModel.isLoadingCollections && viewModel.savedCollections.isEmpty {
            loadingView
        } else if viewModel.savedCollections.isEmpty {
            emptyStateView(
                icon: "bookmark.slash",
                title: "No Saved Collections",
                subtitle: "Collections you save will appear here"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: Constants.Spacing.medium) {
                    ForEach(viewModel.savedCollections) { collection in
                        FavoriteCollectionCard(collection: collection)
                            .onAppear {
                                // Load more when last item appears
                                if collection.id == viewModel.savedCollections.last?.id {
                                    Task {
                                        await viewModel.loadMoreSavedCollections()
                                    }
                                }
                            }
                    }

                    if viewModel.isLoadingCollections {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                            .padding()
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.loadSavedCollections()
            }
        }
    }

    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                .scaleEffect(1.5)
            Spacer()
        }
    }

    // MARK: - Empty State View
    @ViewBuilder
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: Constants.Spacing.medium) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.textGray)

            Text(title)
                .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            Text(subtitle)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Favorite Post Card
struct FavoritePostCard: View {
    let post: CommunityPost

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            // Author Info
            HStack(spacing: Constants.Spacing.small) {
                // Avatar
                if let avatarUrl = post.user.photoURL, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Constants.Colors.textGray)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Constants.Colors.textGray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.user.displayName ?? "Anonymous")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(post.formattedCreatedAt)
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                }

                Spacer()

                // Post Type Badge
                Text(post.type.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Constants.Colors.accentPink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Constants.Colors.accentPink.opacity(0.2))
                    .cornerRadius(6)
            }

            // Content Preview
            if let text = post.content.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textWhite)
                    .lineLimit(3)
            }

            // Image Preview
            if let images = post.content.images, let firstImage = images.first, let url = URL(string: firstImage) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Constants.Colors.cardDark)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipped()
                .cornerRadius(8)
            }

            // Stats
            HStack(spacing: Constants.Spacing.medium) {
                Label("\(post.likesCount)", systemImage: "heart.fill")
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(.red)

                Label("\(post.commentsCount)", systemImage: "bubble.left.fill")
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)

                Spacer()
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Favorite Collection Card
struct FavoriteCollectionCard: View {
    let collection: VoteCollection

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            // Cover Image
            if let coverUrl = collection.coverImage, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "folder.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.5))
                    )
            }

            // Title
            Text(collection.title)
                .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)
                .lineLimit(2)

            // Description
            if !collection.description.isEmpty {
                Text(collection.description)
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)
                    .lineLimit(2)
            }

            // Creator Info
            HStack(spacing: Constants.Spacing.small) {
                if let avatarUrl = collection.creatorAvatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Constants.Colors.textGray)
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Constants.Colors.textGray)
                }

                Text(collection.creatorName)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)

                Spacer()

                // Task Count
                Label("\(collection.taskCount) tasks", systemImage: "checklist")
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.accentPink)
            }

            // Stats
            HStack(spacing: Constants.Spacing.medium) {
                Label("\(collection.likeCount)", systemImage: "heart.fill")
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(.red)

                Label("\(collection.saveCount)", systemImage: "bookmark.fill")
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(.yellow)

                Spacer()
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    FavoritesView()
}
