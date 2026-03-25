//
//  UserProfile.swift
//  OSHI Pick
//
//  OSHI Pick - User Profile Model
//

import Foundation

struct UserProfile: Identifiable, Codable {
    let id: String
    let displayName: String
    let photoURL: String?
    let bio: String?
    let selectedIdols: [String]
    var followersCount: Int
    let followingCount: Int
    let postsCount: Int
    var isFollowing: Bool
    let isFollowedBy: Bool
    let posts: [CommunityPost]
}

struct UserProfileResponse: Codable {
    let success: Bool
    let data: UserProfile
}
