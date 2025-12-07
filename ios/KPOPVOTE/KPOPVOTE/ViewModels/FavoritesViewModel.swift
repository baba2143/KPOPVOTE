//
//  FavoritesViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Favorites ViewModel
//

import Foundation
import Combine

@MainActor
class FavoritesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var likedPosts: [CommunityPost] = []
    @Published var savedCollections: [VoteCollection] = []
    @Published var isLoadingPosts = false
    @Published var isLoadingCollections = false
    @Published var errorMessage: String?

    // MARK: - Pagination
    @Published var hasMorePosts = false
    @Published var hasMoreCollections = false
    private var lastPostId: String?
    private var currentCollectionPage = 1

    // MARK: - Load Liked Posts
    func loadLikedPosts() async {
        isLoadingPosts = true
        errorMessage = nil
        lastPostId = nil

        do {
            print("📱 [FavoritesViewModel] Loading liked posts")
            let result = try await CommunityService.shared.fetchLikedPosts(limit: 20, lastPostId: nil)
            likedPosts = result.posts
            hasMorePosts = result.hasMore
            lastPostId = likedPosts.last?.id
            print("✅ [FavoritesViewModel] Loaded \(likedPosts.count) liked posts")
        } catch {
            print("❌ [FavoritesViewModel] Failed to load liked posts: \(error)")
            // API may not exist yet, show empty state gracefully
            likedPosts = []
            hasMorePosts = false
        }

        isLoadingPosts = false
    }

    // MARK: - Load More Liked Posts
    func loadMoreLikedPosts() async {
        guard hasMorePosts, !isLoadingPosts, let lastPostId = lastPostId else { return }

        isLoadingPosts = true

        do {
            print("📱 [FavoritesViewModel] Loading more liked posts after: \(lastPostId)")
            let result = try await CommunityService.shared.fetchLikedPosts(limit: 20, lastPostId: lastPostId)
            likedPosts.append(contentsOf: result.posts)
            hasMorePosts = result.hasMore
            self.lastPostId = likedPosts.last?.id
            print("✅ [FavoritesViewModel] Loaded \(result.posts.count) more liked posts")
        } catch {
            print("❌ [FavoritesViewModel] Failed to load more liked posts: \(error)")
        }

        isLoadingPosts = false
    }

    // MARK: - Load Saved Collections
    func loadSavedCollections() async {
        isLoadingCollections = true
        errorMessage = nil
        currentCollectionPage = 1

        do {
            print("📱 [FavoritesViewModel] Loading saved collections")
            let result = try await CollectionService.shared.getSavedCollections(page: 1, limit: 20)
            savedCollections = result.data.collections
            hasMoreCollections = result.data.pagination.hasNext
            print("✅ [FavoritesViewModel] Loaded \(savedCollections.count) saved collections")
        } catch {
            print("❌ [FavoritesViewModel] Failed to load saved collections: \(error)")
            savedCollections = []
            hasMoreCollections = false
        }

        isLoadingCollections = false
    }

    // MARK: - Load More Saved Collections
    func loadMoreSavedCollections() async {
        guard hasMoreCollections, !isLoadingCollections else { return }

        isLoadingCollections = true
        currentCollectionPage += 1

        do {
            print("📱 [FavoritesViewModel] Loading more saved collections page: \(currentCollectionPage)")
            let result = try await CollectionService.shared.getSavedCollections(page: currentCollectionPage, limit: 20)
            savedCollections.append(contentsOf: result.data.collections)
            hasMoreCollections = result.data.pagination.hasNext
            print("✅ [FavoritesViewModel] Loaded \(result.data.collections.count) more saved collections")
        } catch {
            print("❌ [FavoritesViewModel] Failed to load more saved collections: \(error)")
            currentCollectionPage -= 1
        }

        isLoadingCollections = false
    }

    // MARK: - Refresh All
    func refreshAll() async {
        await loadLikedPosts()
        await loadSavedCollections()
    }
}
