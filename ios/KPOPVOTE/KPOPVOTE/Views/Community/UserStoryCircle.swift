//
//  UserStoryCircle.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - User Story Circle Component
//

import SwiftUI

struct UserStoryCircle: View {
    let user: UserActivity
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Gradient ring for new posts
                if user.hasNewPost {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Constants.Colors.accentPink, Constants.Colors.accentPink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 68, height: 68)
                }
                
                // User photo
                if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Constants.Colors.cardDark)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(Constants.Colors.textGray)
                            )
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Constants.Colors.cardDark)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Constants.Colors.textGray)
                        )
                }
            }
            .onTapGesture {
                onTap()
            }
            
            // User name
            Text(user.displayName)
                .font(.system(size: 11))
                .foregroundColor(Constants.Colors.textWhite)
                .lineLimit(1)
                .frame(width: 70)
        }
    }
}

// MARK: - User Activity Model
struct UserActivity: Identifiable, Codable {
    let id: String
    let displayName: String
    let photoURL: String?
    let bio: String?
    let selectedIdols: [String]
    let followersCount: Int
    let followingCount: Int
    let postsCount: Int
    let latestPostAt: String?
    let hasNewPost: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case photoURL
        case bio
        case selectedIdols
        case followersCount
        case followingCount
        case postsCount
        case latestPostAt
        case hasNewPost
    }
}
