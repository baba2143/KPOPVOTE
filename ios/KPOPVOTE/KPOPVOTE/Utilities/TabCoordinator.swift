//
//  TabCoordinator.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Tab Navigation Coordinator (Phase 2 Week 4)
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
        case votes = 1     // Collections/Votes
        case center = 2    // Center button (not a real tab)
        case store = 3     // Store
        case community = 4 // Community
        case profile = 5   // Profile
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

    /// Navigate to Votes/Collections tab
    func navigateToVotes() {
        navigate(to: .votes)
    }

    /// Navigate to Store tab
    func navigateToStore() {
        navigate(to: .store)
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
