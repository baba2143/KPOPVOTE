//
//  SearchViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Search ViewModel
//

import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var recommendedUsers: [CommunityRecommendedUser] = []
    @Published var searchedUsers: [CommunityRecommendedUser] = []
    @Published var searchedPosts: [CommunityPost] = []
    @Published var followingActivity: [UserActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Load Recommended Users
    func loadCommunityRecommendedUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📱 [SearchViewModel] Loading recommended users")
            recommendedUsers = try await CommunityService.shared.getRecommendedUsers(limit: 20)
            print("✅ [SearchViewModel] Loaded \(recommendedUsers.count) recommended users")
        } catch {
            print("❌ [SearchViewModel] Failed to load recommended users: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Load Following Activity
    func loadFollowingActivity() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📱 [SearchViewModel] Loading following activity")
            followingActivity = try await CommunityService.shared.getFollowingActivity(limit: 20)
            print("✅ [SearchViewModel] Loaded \(followingActivity.count) following users")
        } catch {
            print("❌ [SearchViewModel] Failed to load following activity: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Search Users
    func searchUsers(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📱 [SearchViewModel] Searching users: \(query)")
            searchedUsers = try await CommunityService.shared.searchUsers(query: query, limit: 20)
            print("✅ [SearchViewModel] Found \(searchedUsers.count) users")
        } catch {
            print("❌ [SearchViewModel] Failed to search users: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Search Posts
    func searchPosts(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📱 [SearchViewModel] Searching posts: \(query)")
            searchedPosts = try await CommunityService.shared.searchPosts(query: query, limit: 20)
            print("✅ [SearchViewModel] Found \(searchedPosts.count) posts")
        } catch {
            print("❌ [SearchViewModel] Failed to search posts: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Clear Search
    func clearSearch() async {
        searchedUsers = []
        searchedPosts = []
    }
    
    // MARK: - Toggle Like
    func toggleLike(postId: String) async {
        do {
            print("💗 [SearchViewModel] Toggling like for post: \(postId)")
            let result = try await CommunityService.shared.likePost(postId: postId)
            
            // Update local post state
            if let index = searchedPosts.firstIndex(where: { $0.id == postId }) {
                searchedPosts[index].isLiked = (result.action == "liked")
                searchedPosts[index].likesCount = result.likesCount
            }
            
            print("✅ [SearchViewModel] Like toggled: \(result.action)")
        } catch {
            print("❌ [SearchViewModel] Failed to toggle like: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Clear Error
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Recommended User Model
struct CommunityRecommendedUser: Identifiable, Codable {
    let id: String
    let displayName: String
    let photoURL: String?
    let bio: String?
    let selectedIdols: [String]
    let sharedIdols: [String]?
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case photoURL
        case bio
        case selectedIdols
        case sharedIdols
        case followersCount
        case followingCount
        case postsCount
    }
}
