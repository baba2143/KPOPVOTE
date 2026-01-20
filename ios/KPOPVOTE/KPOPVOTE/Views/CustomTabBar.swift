//
//  CustomTabBar.swift
//  OSHI Pick
//
//  OSHI Pick - Custom Tab Bar (5 tabs)
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 0) {
        HStack(spacing: 0) {
            // Home Tab
            TabBarItem(
                iconName: selectedTab == 0 ? "house.fill" : "house",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            // Ranking Tab
            TabBarItem(
                iconName: selectedTab == 1 ? "crown.fill" : "crown",
                title: "Ranking",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            // Votes Tab
            TabBarItem(
                iconName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar",
                title: "Votes",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }

            // Community Tab
            TabBarItem(
                iconName: selectedTab == 3 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right",
                title: "Community",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }

            // Profile Tab
            TabBarItem(
                iconName: selectedTab == 4 ? "person.fill" : "person",
                title: "Mypage",
                isSelected: selectedTab == 4
            ) {
                selectedTab = 4
            }
        }
        .frame(height: 65)
        .background(Constants.Colors.cardDark)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Constants.Colors.textGray.opacity(0.2)),
            alignment: .top
        )
        }
        // Safe area bottom padding for home indicator
        .background(
            GeometryReader { geometry in
                Constants.Colors.cardDark
                    .frame(height: geometry.safeAreaInsets.bottom)
                    .offset(y: 65)
            }
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
            VStack(spacing: 5) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 65)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(0))
    }
    .background(Constants.Colors.backgroundDark)
}
