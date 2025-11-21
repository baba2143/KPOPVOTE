//
//  CustomTabBar.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Custom Tab Bar with Floating Center Button
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onCenterTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            TabBarItem(
                iconName: selectedTab == 0 ? "house.fill" : "house",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            // Votes Tab
            TabBarItem(
                iconName: selectedTab == 1 ? "chart.bar.fill" : "chart.bar",
                title: "Votes",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            // Center Button (Floating +)
            ZStack {
                // Spacer for tab bar
                Color.clear
                    .frame(width: 70, height: 50)

                // Floating button
                Button(action: onCenterTap) {
                    ZStack {
                        // Gradient background
                        LinearGradient(
                            colors: [Constants.Colors.accentPink, Constants.Colors.gradientPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 60, height: 60)
                        .cornerRadius(30)
                        .shadow(
                            color: Constants.Colors.accentPink.opacity(0.5),
                            radius: 12,
                            x: 0,
                            y: 4
                        )

                        // Plus icon
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: -20) // Float above tab bar
            }

            // Store Tab
            TabBarItem(
                iconName: selectedTab == 3 ? "cart.fill" : "cart",
                title: "Store",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }

            // Community Tab
            TabBarItem(
                iconName: selectedTab == 4 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right",
                title: "Community",
                isSelected: selectedTab == 4
            ) {
                selectedTab = 4
            }

            // Profile Tab
            TabBarItem(
                iconName: selectedTab == 5 ? "person.fill" : "person",
                title: "Profile",
                isSelected: selectedTab == 5
            ) {
                selectedTab = 5
            }
        }
        .frame(height: 50)
        .background(Constants.Colors.cardDark)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Constants.Colors.textGray.opacity(0.2)),
            alignment: .top
        )
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let iconName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)

                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(0)) {
            print("Center button tapped")
        }
    }
    .background(Constants.Colors.backgroundDark)
}
