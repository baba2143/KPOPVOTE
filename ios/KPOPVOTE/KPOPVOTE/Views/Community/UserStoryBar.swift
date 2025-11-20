//
//  UserStoryBar.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - User Story Horizontal Bar
//

import SwiftUI

struct UserStoryBar: View {
    let users: [UserActivity]
    let onUserTap: (UserActivity) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(users) { user in
                    UserStoryCircle(user: user) {
                        onUserTap(user)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 100)
    }
}
