//
//  SearchView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Search View (Instagram-style)
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    @State private var selectedTab: SearchTab = .recommended
    @State private var selectedPost: IdentifiableString?
    @State private var selectedUser: String?
    @Environment(\.dismiss) var dismiss
    
    enum SearchTab {
        case recommended
        case accounts
        case posts
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                        .padding()
                    
                    // Tab Selector
                    tabSelector
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    
                    // Content
                    ScrollView {
                        if viewModel.isLoading && searchText.isEmpty {
                            ProgressView("読み込み中...")
                                .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                .foregroundColor(Constants.Colors.textWhite)
                                .padding(.top, 40)
                        } else {
                            switch selectedTab {
                            case .recommended:
                                recommendedContent
                            case .accounts:
                                accountsContent
                            case .posts:
                                postsContent
                            }
                        }
                    }
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
            .task {
                await viewModel.loadCommunityRecommendedUsers()
            }
            .sheet(item: $selectedPost) { identifiablePost in
                NavigationStack {
                    PostDetailView(postId: identifiablePost.id)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Constants.Colors.textGray)
            
            TextField("検索", text: $searchText)
                .autocapitalization(.none)
                .onChange(of: searchText) { newValue in
                    Task {
                        await performSearch(newValue)
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Constants.Colors.textGray)
                }
            }
        }
        .padding(12)
        .background(Constants.Colors.cardDark)
        .cornerRadius(10)
    }
    
    // MARK: - Tab Selector
    @ViewBuilder
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "おすすめ", isSelected: selectedTab == .recommended) {
                selectedTab = .recommended
            }
            
            TabButton(title: "アカウント", isSelected: selectedTab == .accounts) {
                selectedTab = .accounts
            }
            
            TabButton(title: "投稿", isSelected: selectedTab == .posts) {
                selectedTab = .posts
            }
        }
        .background(Constants.Colors.cardDark)
        .cornerRadius(10)
    }
    
    // MARK: - Recommended Content
    @ViewBuilder
    private var recommendedContent: some View {
        LazyVStack(spacing: 16) {
            if viewModel.recommendedUsers.isEmpty {
                SearchEmptyStateView(
                    icon: "person.2.fill",
                    message: "おすすめユーザーがありません"
                )
                .padding(.top, 40)
            } else {
                ForEach(viewModel.recommendedUsers, id: \.id) { user in
                    UserSearchCard(user: user) {
                        selectedUser = user.id
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Accounts Content
    @ViewBuilder
    private var accountsContent: some View {
        LazyVStack(spacing: 16) {
            if searchText.isEmpty {
                SearchEmptyStateView(
                    icon: "magnifyingglass",
                    message: "ユーザー名で検索してください"
                )
                .padding(.top, 40)
            } else if viewModel.searchedUsers.isEmpty && !viewModel.isLoading {
                SearchEmptyStateView(
                    icon: "person.fill.questionmark",
                    message: "ユーザーが見つかりません"
                )
                .padding(.top, 40)
            } else {
                ForEach(viewModel.searchedUsers, id: \.id) { user in
                    UserSearchCard(user: user) {
                        selectedUser = user.id
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Posts Content
    @ViewBuilder
    private var postsContent: some View {
        LazyVStack(spacing: 16) {
            if searchText.isEmpty {
                SearchEmptyStateView(
                    icon: "magnifyingglass",
                    message: "投稿を検索してください"
                )
                .padding(.top, 40)
            } else if viewModel.searchedPosts.isEmpty && !viewModel.isLoading {
                SearchEmptyStateView(
                    icon: "doc.text.fill.magnifyingglass",
                    message: "投稿が見つかりません"
                )
                .padding(.top, 40)
            } else {
                ForEach(viewModel.searchedPosts) { post in
                    PostCardView(
                        post: post,
                        onTap: {
                            selectedPost = IdentifiableString(post.id)
                        },
                        onLike: {
                            Task {
                                await viewModel.toggleLike(postId: post.id)
                            }
                        },
                        onDelete: nil
                    )
                }
            }
        }
        .padding()
    }
    
    // MARK: - Perform Search
    private func performSearch(_ query: String) async {
        guard !query.isEmpty else {
            await viewModel.clearSearch()
            return
        }
        
        switch selectedTab {
        case .recommended:
            break // No search for recommended
        case .accounts:
            await viewModel.searchUsers(query: query)
        case .posts:
            await viewModel.searchPosts(query: query)
        }
    }
}

// MARK: - Tab Button Component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Constants.Colors.accentPink : Color.clear)
                .cornerRadius(8)
        }
    }
}

// MARK: - User Search Card Component
struct UserSearchCard: View {
    let user: CommunityRecommendedUser
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // User photo
                if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Constants.Colors.cardDark)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(Constants.Colors.textGray)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Constants.Colors.cardDark)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Constants.Colors.textGray)
                        )
                }
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)
                    
                    if let bio = user.bio {
                        Text(bio)
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                            .lineLimit(1)
                    }
                    
                    Text("\(user.followersCount) フォロワー")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                }
                
                Spacer()
                
                // Follow button placeholder
                Image(systemName: "chevron.right")
                    .foregroundColor(Constants.Colors.textGray)
            }
            .padding()
            .background(Constants.Colors.cardDark)
            .cornerRadius(12)
        }
    }
}

// MARK: - Empty State View
struct SearchEmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Constants.Colors.textGray)
            
            Text(message)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview
#Preview {
    SearchView()
}
