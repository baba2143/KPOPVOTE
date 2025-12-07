//
//  CommunityView.swift
//  OSHI Pick
//
//  OSHI Pick - Community Timeline Main View
//

import SwiftUI
import FirebaseAuth

// MARK: - Community Content Type
enum CommunityContentType: String, CaseIterable {
    case posts = "posts"
    case calendar = "calendar"

    var displayName: String {
        switch self {
        case .posts:
            return "投稿"
        case .calendar:
            return "カレンダー"
        }
    }

    var icon: String {
        switch self {
        case .posts:
            return "bubble.left.and.bubble.right"
        case .calendar:
            return "calendar"
        }
    }
}

struct CommunityView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var biasViewModel = BiasViewModel()
    @StateObject private var activityViewModel = SearchViewModel()
    @State private var selectedPost: IdentifiableString?
    @State private var showLoginPrompt = false
    @State private var showDeleteSuccess = false
    @State private var showSearch = false
    @State private var selectedUser: IdentifiableString?
    @State private var contentType: CommunityContentType = .posts
    @Binding var showCreatePost: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top-level content type selector (Posts | Calendar)
                    contentTypeSelector
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Show content based on selected type
                    if contentType == .posts {
                        postsContent
                    } else {
                        calendarContent
                    }
                }
            }
            .navigationTitle("コミュニティ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Search button
                        Button(action: {
                            if authService.isGuest {
                                showLoginPrompt = true
                            } else {
                                showSearch = true
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(Constants.Colors.textWhite)
                        }

                        // Search button
                        Button(action: {
                            showSearch = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(Constants.Colors.textWhite)
                        }
                    }
                }
            }
            .sheet(item: $selectedPost) { identifiablePost in
                NavigationStack {
                    PostDetailView(postId: identifiablePost.id)
                        .onAppear {
                            print("🔶 [CommunityView] Sheet appeared with postId: \(identifiablePost.id)")
                        }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                NavigationView {
                    CreatePostView {
                        // Reload timeline when post is created
                        Task {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                SearchView()
            }
            .sheet(item: $selectedUser) { identifiable in
                NavigationView {
                    UserProfileView(userId: identifiable.id)
                }
            }
            .task {
                // Parallel execution: Independent API calls
                await withTaskGroup(of: Void.self) { group in
                    group.addTask { await biasViewModel.loadIdols() }
                    group.addTask { await biasViewModel.loadCurrentBias() }
                    group.addTask { await viewModel.loadPosts() }
                    group.addTask { await activityViewModel.loadFollowingActivity() }
                }

                // Conditional load (depends on activity result)
                if activityViewModel.followingActivity.isEmpty {
                    await activityViewModel.loadCommunityRecommendedUsers()
                }
            }
            .alert("削除完了", isPresented: $showDeleteSuccess) {
                Button("OK") {}
            } message: {
                Text("投稿を削除しました")
            }
            .onChange(of: viewModel.deleteSuccess) { newValue in
                if newValue {
                    showDeleteSuccess = true
                    viewModel.deleteSuccess = false // Reset
                }
            }
            .overlay(
                Group {
                    if showLoginPrompt {
                        LoginPromptView(isPresented: $showLoginPrompt, featureName: "投稿作成")
                    }
                }
            )
        }
    }

    // MARK: - Content Type Selector (Posts | Calendar)
    @ViewBuilder
    private var contentTypeSelector: some View {
        HStack(spacing: 0) {
            ForEach(CommunityContentType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        contentType = type
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.system(size: 14))
                        Text(type.displayName)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(contentType == type ? .white : Constants.Colors.textGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        contentType == type ?
                        LinearGradient(
                            colors: [Constants.Colors.gradientPink, Constants.Colors.gradientPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) : nil
                    )
                }
            }
        }
        .background(Constants.Colors.cardDark)
        .cornerRadius(25)
    }

    // MARK: - Posts Content
    @ViewBuilder
    private var postsContent: some View {
        VStack(spacing: 0) {
            // User Story Bar
            if !activityViewModel.followingActivity.isEmpty {
                UserStoryBar(users: activityViewModel.followingActivity) { user in
                    selectedUser = IdentifiableString(user.id)
                }
            } else if !activityViewModel.recommendedUsers.isEmpty {
                UserStoryBar(users: convertRecommendedToActivity(activityViewModel.recommendedUsers)) { user in
                    selectedUser = IdentifiableString(user.id)
                }
            }

            // Timeline Type Selector
            timelineSelector
                .padding(.horizontal)
                .padding(.vertical, 12)

            // Posts List
            if viewModel.isLoading && viewModel.posts.isEmpty {
                Spacer()
                ProgressView("読み込み中...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                    .foregroundColor(Constants.Colors.textWhite)
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                Spacer()
                ErrorView(message: errorMessage) {
                    Task {
                        await viewModel.refresh()
                    }
                }
                Spacer()
            } else if viewModel.posts.isEmpty {
                Spacer()
                VStack(spacing: Constants.Spacing.medium) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 64))
                        .foregroundColor(Constants.Colors.textGray)

                    Text("投稿がありません")
                        .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(viewModel.timelineType == "following" ? "フォローしているユーザーの投稿がここに表示されます" : "この推しの投稿がありません")
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.textGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.Spacing.large)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.posts) { post in
                            PostCardView(
                                post: post,
                                onTap: {
                                    print("🔷 [CommunityView] Post tapped: \(post.id)")
                                    selectedPost = IdentifiableString(post.id)
                                    print("🔷 [CommunityView] selectedPost set to: \(post.id)")
                                },
                                onLike: {
                                    if authService.isGuest {
                                        showLoginPrompt = true
                                    } else {
                                        Task {
                                            await viewModel.toggleLike(postId: post.id)
                                        }
                                    }
                                },
                                onDelete: isPostOwner(post) ? {
                                    Task {
                                        await viewModel.deletePost(postId: post.id)
                                    }
                                } : nil
                            )

                            // Load more trigger
                            if post.id == viewModel.posts.last?.id && viewModel.hasMore {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMorePosts()
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
    }

    // MARK: - Calendar Content
    @ViewBuilder
    private var calendarContent: some View {
        VStack(spacing: 0) {
            // Bias selector for calendar
            if biasViewModel.selectedIdolObjects.isEmpty {
                // No bias selected - show prompt
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(Constants.Colors.textGray)

                    Text("推しを選択してください")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("カレンダーを表示するには、マイページで推しを設定してください")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                // Bias tabs for calendar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(biasViewModel.selectedIdolObjects, id: \.id) { idol in
                            CalendarBiasTab(
                                name: idol.name,
                                isSelected: selectedCalendarBiasId == idol.id
                            ) {
                                selectedCalendarBiasId = idol.id
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                // Calendar container for selected bias
                if let biasId = selectedCalendarBiasId,
                   let idol = biasViewModel.selectedIdolObjects.first(where: { $0.id == biasId }) {
                    CalendarContainerView(artistId: biasId, artistName: idol.name)
                } else if let firstIdol = biasViewModel.selectedIdolObjects.first {
                    CalendarContainerView(artistId: firstIdol.id, artistName: firstIdol.name)
                        .onAppear {
                            selectedCalendarBiasId = firstIdol.id
                        }
                }
            }
        }
    }

    // MARK: - Timeline Selector
    @ViewBuilder
    private var timelineSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Following Timeline Button
                TimelineTypeButton(
                    title: "フォロー中",
                    isSelected: viewModel.timelineType == "following",
                    action: {
                        Task {
                            await viewModel.changeTimelineType("following")
                        }
                    }
                )

                // Bias Timeline Buttons - Show all with horizontal scroll
                ForEach(biasViewModel.selectedIdolObjects, id: \.id) { idol in
                    TimelineTypeButton(
                        title: idol.name,
                        isSelected: viewModel.timelineType == "bias" && viewModel.selectedBiasId == idol.id,
                        action: {
                            Task {
                                await viewModel.changeTimelineType("bias", biasId: idol.id)
                            }
                        }
                    )
                }
            }
        }
    }

    // Selected bias for calendar
    @State private var selectedCalendarBiasId: String?

    // MARK: - Check Post Owner
    private func isPostOwner(_ post: CommunityPost) -> Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return post.userId == currentUser.uid
    }

    // MARK: - Convert Recommended to Activity
    private func convertRecommendedToActivity(_ users: [CommunityRecommendedUser]) -> [UserActivity] {
        return users.map { user in
            UserActivity(
                id: user.id,
                displayName: user.displayName,
                photoURL: user.photoURL,
                bio: user.bio,
                selectedIdols: user.selectedIdols,
                followersCount: user.followersCount,
                followingCount: user.followingCount,
                postsCount: user.postsCount,
                latestPostAt: nil,
                hasNewPost: false
            )
        }
    }
}

// MARK: - Timeline Type Button Component
struct TimelineTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Constants.Colors.accentPink : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Identifiable String Wrapper
struct IdentifiableString: Identifiable {
    let id: String

    init(_ string: String) {
        self.id = string
    }
}

// MARK: - Calendar Bias Tab
struct CalendarBiasTab: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [Constants.Colors.gradientPink, Constants.Colors.gradientPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : nil
                )
                .background(isSelected ? nil : Constants.Colors.cardDark)
                .cornerRadius(20)
        }
    }
}

// MARK: - Preview
#Preview {
    CommunityView(showCreatePost: .constant(false))
        .environmentObject(AuthService())
}
