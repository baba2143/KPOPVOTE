//
//  CommunityActivityViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Community Activity ViewModel
//

import Foundation
import SwiftUI

@MainActor
class CommunityActivityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let communityService = CommunityService.shared
    private let maxPostsToShow = 3

    // MARK: - Load Posts
    /// Load community posts for the user's selected biases
    /// - Parameter biasIds: Array of bias IDs to fetch posts for
    func loadPosts(biasIds: [String]) async {
        guard !biasIds.isEmpty else {
            // No biases selected - clear posts
            posts = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            print("📱 [CommunityActivityViewModel] Loading posts for \(biasIds.count) biases")

            // Fetch posts for each bias in parallel
            let results = await withTaskGroup(of: (biasId: String, posts: [CommunityPost]).self) { group in
                for biasId in biasIds {
                    group.addTask {
                        do {
                            let (posts, _) = try await self.communityService.fetchPosts(
                                type: "bias",
                                biasId: biasId,
                                limit: 5
                            )
                            return (biasId: biasId, posts: posts)
                        } catch {
                            print("❌ [CommunityActivityViewModel] Failed to load posts for bias \(biasId): \(error)")
                            return (biasId: biasId, posts: [])
                        }
                    }
                }

                var allResults: [(biasId: String, posts: [CommunityPost])] = []
                for await result in group {
                    allResults.append(result)
                }
                return allResults
            }

            // Combine all posts from all biases
            let allPosts = results.flatMap { $0.posts }

            // Sort by creation date (newest first)
            let sortedPosts = allPosts.sorted { post1, post2 in
                return post1.createdAt > post2.createdAt
            }

            // Take top N posts
            posts = Array(sortedPosts.prefix(maxPostsToShow))

            print("✅ [CommunityActivityViewModel] Loaded \(posts.count) posts from \(allPosts.count) total")

        } catch {
            print("❌ [CommunityActivityViewModel] Error loading posts: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Refresh
    /// Refresh posts for the given bias IDs
    func refresh(biasIds: [String]) async {
        await loadPosts(biasIds: biasIds)
    }
}
