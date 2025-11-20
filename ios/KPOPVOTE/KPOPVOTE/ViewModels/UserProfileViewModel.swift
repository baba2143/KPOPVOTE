//
//  UserProfileViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - User Profile ViewModel
//

import Foundation

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadProfile(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await CommunityService.shared.getUserProfile(userId: userId)
            print("✅ [UserProfileViewModel] Loaded profile for: \(profile?.displayName ?? "")")
        } catch {
            errorMessage = "プロフィールの読み込みに失敗しました"
            print("❌ [UserProfileViewModel] Error loading profile: \(error)")
        }

        isLoading = false
    }

    func toggleFollow() async {
        guard let profile = profile else { return }

        do {
            if profile.isFollowing {
                try await FollowService.shared.unfollowUser(userId: profile.id)
                // Update local state
                self.profile = UserProfile(
                    id: profile.id,
                    displayName: profile.displayName,
                    photoURL: profile.photoURL,
                    bio: profile.bio,
                    selectedIdols: profile.selectedIdols,
                    followersCount: profile.followersCount - 1,
                    followingCount: profile.followingCount,
                    postsCount: profile.postsCount,
                    isFollowing: false,
                    isFollowedBy: profile.isFollowedBy,
                    posts: profile.posts
                )
                print("✅ [UserProfileViewModel] Unfollowed user")
            } else {
                _ = try await FollowService.shared.followUser(userId: profile.id)
                // Update local state
                self.profile = UserProfile(
                    id: profile.id,
                    displayName: profile.displayName,
                    photoURL: profile.photoURL,
                    bio: profile.bio,
                    selectedIdols: profile.selectedIdols,
                    followersCount: profile.followersCount + 1,
                    followingCount: profile.followingCount,
                    postsCount: profile.postsCount,
                    isFollowing: true,
                    isFollowedBy: profile.isFollowedBy,
                    posts: profile.posts
                )
                print("✅ [UserProfileViewModel] Followed user")
            }
        } catch {
            errorMessage = "フォロー操作に失敗しました"
            print("❌ [UserProfileViewModel] Follow error: \(error)")
        }
    }
}
