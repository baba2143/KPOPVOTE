//
//  UserProfileView.swift
//  OSHI Pick
//
//  OSHI Pick - User Profile View
//

import SwiftUI

struct UserProfileView: View {
    let userId: String
    @StateObject private var viewModel = UserProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDMConversation = false

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
            } else if let profile = viewModel.profile {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        profileHeader(profile)

                        // Stats
                        statsRow(profile)

                        // Follow Button
                        followButton(profile)

                        // Bias
                        biasSection(profile)

                        // Posts Grid
                        postsSection(profile)
                    }
                    .padding()
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
            await viewModel.loadProfile(userId: userId)
        }
        .sheet(isPresented: $showDMConversation) {
            if let profile = viewModel.profile {
                NavigationStack {
                    DMConversationView(
                        recipientId: userId,
                        recipientName: profile.displayName,
                        recipientPhotoURL: profile.photoURL
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 12) {
            AsyncImage(url: profile.photoURL.flatMap { URL(string: $0) }) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())

            Text(profile.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if let bio = profile.bio {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private func statsRow(_ profile: UserProfile) -> some View {
        HStack(spacing: 40) {
            statItem(title: "投稿", count: profile.postsCount)
            statItem(title: "フォロワー", count: profile.followersCount)
            statItem(title: "フォロー中", count: profile.followingCount)
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func statItem(title: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    @ViewBuilder
    private func followButton(_ profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            // Follow Button
            Button {
                Task {
                    await viewModel.toggleFollow()
                }
            } label: {
                Text(profile.isFollowing ? "フォロー中" : "フォロー")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(profile.isFollowing ? Color.gray : Constants.Colors.accentPink)
                    .cornerRadius(8)
            }

            // DM Button (show only for mutual follows)
            if profile.isFollowing && profile.isFollowedBy {
                Button {
                    showDMConversation = true
                } label: {
                    Image(systemName: "envelope.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Constants.Colors.accentBlue)
                        .cornerRadius(8)
                }
            }
        }
    }

    @ViewBuilder
    private func biasSection(_ profile: UserProfile) -> some View {
        if !profile.selectedIdols.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("推しアイドル")
                    .font(.headline)
                    .foregroundColor(.white)

                FlowLayout(spacing: 8) {
                    ForEach(profile.selectedIdols, id: \.self) { idol in
                        Text(idol)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Constants.Colors.accentPink.opacity(0.2))
                            .foregroundColor(Constants.Colors.accentPink)
                            .cornerRadius(16)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func postsSection(_ profile: UserProfile) -> some View {
        if !profile.posts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("投稿 (\(profile.posts.count))")
                    .font(.headline)
                    .foregroundColor(.white)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                    ForEach(profile.posts) { post in
                        PostThumbnail(post: post)
                    }
                }
            }
        }
    }
}

struct PostThumbnail: View {
    let post: CommunityPost

    var body: some View {
        Rectangle()
            .fill(Constants.Colors.cardDark)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Image(systemName: postIcon)
                    .foregroundColor(.white.opacity(0.6))
            )
    }

    private var postIcon: String {
        switch post.type {
        case .image:
            return "photo"
        case .collection:
            return "rectangle.stack"
        case .myVotes:
            return "checkmark.circle.fill"
        case .goodsTrade:
            return "shippingbox.fill"
        }
    }
}
