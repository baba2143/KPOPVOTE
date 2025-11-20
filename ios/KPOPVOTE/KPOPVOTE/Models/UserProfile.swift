//
//  UserProfile.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - User Profile Model
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let displayName: String
    let photoURL: String?
    let bio: String?
    let selectedIdols: [String]
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let isFollowing: Bool
    let isFollowedBy: Bool
    let posts: [CommunityPost]
}

struct UserProfileResponse: Codable {
    let success: Bool
    let data: UserProfile
}
