//
//  CommunityViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Community Timeline ViewModel
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class CommunityViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var posts: [CommunityPost] = []
    @Published var timelineType: String = "following" // "following" or "bias"
    @Published var selectedBiasId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = false
    @Published var deleteSuccess = false

    // MARK: - Private Properties
    private var lastPostId: String?

    // MARK: - Load Posts
    /// Load posts with timeline type
    func loadPosts() async {
        // ゲストモードの場合はスキップ
        guard Auth.auth().currentUser != nil else {
            debugLog("👤 [CommunityViewModel] Guest mode - skipping posts")
            posts = []
            isLoading = false
            return
        }

        isLoading = true
        errorMessage = nil
        lastPostId = nil

        do {
            debugLog("📱 [CommunityViewModel] Loading posts: type=\(timelineType), biasId=\(selectedBiasId ?? "nil")")
            let result = try await CommunityService.shared.fetchPosts(
                type: timelineType,
                biasId: selectedBiasId,
                limit: 20,
                lastPostId: nil
            )
            posts = result.posts
            hasMore = result.hasMore
            lastPostId = posts.last?.id
            debugLog("✅ [CommunityViewModel] Loaded \(posts.count) posts, hasMore: \(hasMore)")
        } catch {
            debugLog("❌ [CommunityViewModel] Failed to load posts: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load More Posts (Pagination)
    /// Load next page of posts
    func loadMorePosts() async {
        guard hasMore, !isLoading, let lastPostId = lastPostId else { return }

        isLoading = true

        do {
            debugLog("📱 [CommunityViewModel] Loading more posts after: \(lastPostId)")
            let result = try await CommunityService.shared.fetchPosts(
                type: timelineType,
                biasId: selectedBiasId,
                limit: 20,
                lastPostId: lastPostId
            )
            posts.append(contentsOf: result.posts)
            hasMore = result.hasMore
            self.lastPostId = posts.last?.id
            debugLog("✅ [CommunityViewModel] Loaded \(result.posts.count) more posts, total: \(posts.count)")
        } catch {
            debugLog("❌ [CommunityViewModel] Failed to load more posts: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Change Timeline Type
    /// Change timeline type and reload
    func changeTimelineType(_ type: String, biasId: String? = nil) async {
        timelineType = type
        selectedBiasId = biasId
        await loadPosts()
    }

    // MARK: - Refresh
    /// Refresh posts
    func refresh() async {
        await loadPosts()
    }

    // MARK: - Like Post
    /// Toggle like for a post
    func toggleLike(postId: String) async {
        do {
            debugLog("💗 [CommunityViewModel] Toggling like for post: \(postId)")
            let result = try await CommunityService.shared.likePost(postId: postId)

            // Update local post state
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].isLiked = (result.action == "liked")
                posts[index].likesCount = result.likesCount
            }

            debugLog("✅ [CommunityViewModel] Like toggled: \(result.action)")
        } catch {
            debugLog("❌ [CommunityViewModel] Failed to toggle like: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete Post
    /// Delete a post
    func deletePost(postId: String) async {
        do {
            debugLog("🗑️ [CommunityViewModel] Deleting post: \(postId)")
            try await CommunityService.shared.deletePost(postId: postId)

            // Remove from local array
            posts.removeAll { $0.id == postId }

            debugLog("✅ [CommunityViewModel] Post deleted")
            deleteSuccess = true
        } catch {
            debugLog("❌ [CommunityViewModel] Failed to delete post: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Clear Error
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Handle User Blocked (Apple Requirement)
    /// Instantly remove blocked user's posts from feed
    /// This satisfies Apple's requirement: "should remove it from the user's feed instantly"
    func onUserBlocked(blockedUserId: String) {
        debugLog("🚫 [CommunityViewModel] Removing posts from blocked user: \(blockedUserId)")
        let beforeCount = posts.count
        posts.removeAll { $0.userId == blockedUserId }
        let removedCount = beforeCount - posts.count
        debugLog("✅ [CommunityViewModel] Removed \(removedCount) posts from blocked user")
    }

    // MARK: - Filter Blocked Users
    /// Filter out posts from blocked users
    func filterBlockedUsers() {
        let blockedIds = BlockService.shared.blockedUserIds
        guard !blockedIds.isEmpty else { return }

        debugLog("🔍 [CommunityViewModel] Filtering posts from \(blockedIds.count) blocked users")
        let beforeCount = posts.count
        posts = posts.filter { !blockedIds.contains($0.userId) }
        let removedCount = beforeCount - posts.count
        debugLog("✅ [CommunityViewModel] Filtered \(removedCount) posts from blocked users")
    }
}
