//
//  CommunityView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Community Timeline Main View
//

import SwiftUI
import FirebaseAuth

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @StateObject private var biasViewModel = BiasViewModel()
    @State private var selectedPostId: String?
    @State private var showPostDetail = false
    @State private var showCreatePost = false

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Timeline Type Selector
                    timelineSelector
                        .padding(.horizontal)
                        .padding(.vertical, 12)

                    // Content
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

                            Text(viewModel.timelineType == "following" ? "フォローしているユーザーの投稿がここに表示されます" : "このBiasの投稿がありません")
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
                                            selectedPostId = post.id
                                            showPostDetail = true
                                        },
                                        onLike: {
                                            Task {
                                                await viewModel.toggleLike(postId: post.id)
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
            .navigationTitle("コミュニティ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreatePost = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Constants.Colors.accentPink)
                    }
                }
            }
            .sheet(isPresented: $showPostDetail) {
                if let postId = selectedPostId {
                    NavigationView {
                        PostDetailView(postId: postId)
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                NavigationView {
                    CreatePostView()
                }
            }
            .task {
                await biasViewModel.loadIdols()
                await biasViewModel.loadCurrentBias()
                await viewModel.loadPosts()
            }
        }
    }

    // MARK: - Timeline Selector
    @ViewBuilder
    private var timelineSelector: some View {
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

            // Bias Timeline Buttons
            ForEach(Array(biasViewModel.selectedIdolObjects.prefix(3)), id: \.id) { idol in
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

            if biasViewModel.selectedIdols.count > 3 {
                Text("+\(biasViewModel.selectedIdols.count - 3)")
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)
            }
        }
    }

    // MARK: - Check Post Owner
    private func isPostOwner(_ post: CommunityPost) -> Bool {
        guard let currentUser = Auth.auth().currentUser else { return false }
        return post.userId == currentUser.uid
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

// MARK: - Preview
#Preview {
    CommunityView()
}
