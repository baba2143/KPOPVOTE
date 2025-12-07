//
//  FollowListView.swift
//  OSHI Pick
//
//  OSHI Pick - Follow/Follower List View
//

import SwiftUI

enum FollowListType {
    case following
    case followers

    var title: String {
        switch self {
        case .following: return "フォロー"
        case .followers: return "フォロワー"
        }
    }
}

struct FollowListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FollowListViewModel()
    let listType: FollowListType
    let userId: String?

    init(listType: FollowListType, userId: String? = nil) {
        self.listType = listType
        self.userId = userId
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.users.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                } else if viewModel.users.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: listType == .following ? "person.badge.plus" : "person.2")
                            .font(.system(size: 48))
                            .foregroundColor(Constants.Colors.textGray)
                        Text(listType == .following ? "フォロー中のユーザーがいません" : "フォロワーがいません")
                            .font(.system(size: 16))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.users, id: \.id) { user in
                                FollowUserRow(user: user)

                                Divider()
                                    .background(Constants.Colors.textGray.opacity(0.3))
                                    .padding(.leading, 72)
                            }

                            if viewModel.hasMore && !viewModel.isLoading {
                                Button(action: {
                                    Task {
                                        await viewModel.loadMore(type: listType, userId: userId)
                                    }
                                }) {
                                    Text("もっと見る")
                                        .font(.system(size: 14))
                                        .foregroundColor(Constants.Colors.accentPink)
                                        .padding()
                                }
                            }

                            if viewModel.isLoading && !viewModel.users.isEmpty {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                    .padding()
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.refresh(type: listType, userId: userId)
                    }
                }
            }
            .navigationTitle(listType.title)
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
                await viewModel.load(type: listType, userId: userId)
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
        }
    }
}

// MARK: - Follow User Row
struct FollowUserRow: View {
    let user: FollowUser

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    case .failure, .empty:
                        defaultAvatar
                    @unknown default:
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }

            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName ?? "ユーザー")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Constants.Colors.textWhite)

                // Show follower count as secondary info
                Text("\(user.followersCount) フォロワー")
                    .font(.system(size: 13))
                    .foregroundColor(Constants.Colors.textGray)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Constants.Colors.backgroundDark)
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(Constants.Colors.accentPink.opacity(0.3))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Constants.Colors.accentPink)
            )
    }
}

// MARK: - ViewModel
@MainActor
class FollowListViewModel: ObservableObject {
    @Published var users: [FollowUser] = []
    @Published var isLoading = false
    @Published var hasMore = false
    @Published var showError = false
    @Published var errorMessage: String?

    private var lastFollowId: String?
    private let followService = FollowService.shared

    func load(type: FollowListType, userId: String?) async {
        isLoading = true

        do {
            let result: ([FollowUser], Bool)

            switch type {
            case .following:
                result = try await followService.fetchFollowing(userId: userId)
            case .followers:
                result = try await followService.fetchFollowers(userId: userId)
            }

            users = result.0
            hasMore = result.1

            // Store last ID for pagination (if users exist)
            if let lastUser = users.last {
                lastFollowId = lastUser.followId
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func loadMore(type: FollowListType, userId: String?) async {
        guard !isLoading, hasMore else { return }

        isLoading = true

        do {
            let result: ([FollowUser], Bool)

            switch type {
            case .following:
                result = try await followService.fetchFollowing(userId: userId, lastFollowId: lastFollowId)
            case .followers:
                result = try await followService.fetchFollowers(userId: userId, lastFollowId: lastFollowId)
            }

            users.append(contentsOf: result.0)
            hasMore = result.1

            if let lastUser = result.0.last {
                lastFollowId = lastUser.followId
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func refresh(type: FollowListType, userId: String?) async {
        lastFollowId = nil
        await load(type: type, userId: userId)
    }
}

#Preview {
    FollowListView(listType: .following)
}
