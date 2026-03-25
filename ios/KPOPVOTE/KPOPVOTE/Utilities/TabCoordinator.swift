//
//  TabCoordinator.swift
//  OSHI Pick
//
//  OSHI Pick - Tab Navigation Coordinator (5 tabs)
//

import SwiftUI
import Combine

/// Tab Coordinator - Manages tab navigation across the app
@MainActor
class TabCoordinator: ObservableObject {
    /// Currently selected tab index
    @Published var selectedTab: Int = 0

    /// Tab indices for easy reference
    enum Tab: Int {
        case home = 0      // TASKS tab (inside HomeView)
        case ranking = 1   // Ranking
        case votes = 2     // Collections/Votes
        case community = 3 // Community
        case profile = 4   // Profile
    }

    /// Navigate to specific tab
    /// - Parameter tab: Target tab
    func navigate(to tab: Tab) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.easeInOut(duration: 0.3)) {
            selectedTab = tab.rawValue
        }
    }

    /// Navigate to TASKS tab (Home tab)
    func navigateToTasks() {
        navigate(to: .home)
    }

    /// Navigate to Ranking tab
    func navigateToRanking() {
        navigate(to: .ranking)
    }

    /// Navigate to Votes/Collections tab
    func navigateToVotes() {
        navigate(to: .votes)
    }

    /// Navigate to Community tab
    func navigateToCommunity() {
        navigate(to: .community)
    }

    /// Navigate to Profile tab
    func navigateToProfile() {
        navigate(to: .profile)
    }
}
