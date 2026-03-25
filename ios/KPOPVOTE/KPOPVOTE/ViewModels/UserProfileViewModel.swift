//
//  UserProfileViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - User Profile ViewModel
//

import Foundation

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isTogglingFollow = false

    func loadProfile(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await CommunityService.shared.getUserProfile(userId: userId)
            debugLog("✅ [UserProfileViewModel] Loaded profile for: \(profile?.displayName ?? "")")
        } catch {
            errorMessage = "プロフィールの読み込みに失敗しました"
            debugLog("❌ [UserProfileViewModel] Error loading profile: \(error)")
        }

        isLoading = false
    }

    func toggleFollow() async {
        guard let profile = profile else { return }

        // 重複呼び出し防止
        guard !isTogglingFollow else {
            debugLog("⚠️ [UserProfileViewModel] Already toggling follow, ignoring duplicate call")
            return
        }

        isTogglingFollow = true
        defer { isTogglingFollow = false }

        do {
            if profile.isFollowing {
                try await FollowService.shared.unfollowUser(userId: profile.id)
                // Update local state - direct property update
                self.profile?.isFollowing = false
                self.profile?.followersCount -= 1
                debugLog("✅ [UserProfileViewModel] Unfollowed user")
            } else {
                _ = try await FollowService.shared.followUser(userId: profile.id)
                // Update local state - direct property update
                self.profile?.isFollowing = true
                self.profile?.followersCount += 1
                debugLog("✅ [UserProfileViewModel] Followed user")
            }
        } catch {
            errorMessage = "フォロー操作に失敗しました"
            debugLog("❌ [UserProfileViewModel] Follow error: \(error)")
        }
    }
}
