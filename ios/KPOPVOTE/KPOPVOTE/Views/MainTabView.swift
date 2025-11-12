//
//  MainTabView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Main Tab Navigation
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    @State private var showingTaskSheet = false

    var body: some View {
        ZStack {
            // Main Tab Content
            TabView(selection: $selectedTab) {
                // Home Tab
                HomeView()
                    .environmentObject(authService)
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)

                // Votes Tab (Placeholder)
                VotesListView()
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)

                // Center Button Placeholder (Empty, handled by custom tab bar)
                Color.clear
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)

                // Tasks Tab (Placeholder)
                TasksListView()
                    .tag(3)
                    .toolbar(.hidden, for: .tabBar)

                // Profile Tab
                ProfileView()
                    .environmentObject(authService)
                    .tag(4)
                    .toolbar(.hidden, for: .tabBar)
            }

            // Custom Tab Bar (Overlay)
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab) {
                    showingTaskSheet = true
                }
                .padding(.bottom, 0)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $showingTaskSheet) {
            TaskRegistrationView()
        }
    }
}

// MARK: - Placeholder Views (実装予定)

struct VotesListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "chart.bar")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.accentPink)

                Text("Votes")
                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text("Coming Soon")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("Votes")
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct TasksListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.accentPink)

                Text("Tasks")
                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text("Coming Soon")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("Tasks")
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // User Info Card
                    VStack(spacing: Constants.Spacing.medium) {
                        // Profile Icon
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Constants.Colors.accentPink)

                        // User Email
                        if let email = authService.currentUser?.email {
                            Text(email)
                                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textWhite)
                        }

                        // Points Display
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(authService.currentUser?.points ?? 0) Points")
                                .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(20)
                    }
                    .padding()
                    .background(Constants.Colors.cardDark)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

                    // Settings Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Settings")
                            .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                            .foregroundColor(Constants.Colors.textWhite)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            SettingsRow(icon: "person.fill", title: "Account", color: Constants.Colors.accentBlue)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            SettingsRow(icon: "heart.fill", title: "Favorites", color: Constants.Colors.accentPink)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            SettingsRow(icon: "info.circle.fill", title: "About", color: Constants.Colors.textGray)
                        }
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }

                    // Logout Button
                    Button(action: {
                        showLogoutConfirm = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("ログアウト")
                        }
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("Profile")
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("ログアウト確認", isPresented: $showLogoutConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    do {
                        try authService.logout()
                    } catch {
                        print("ログアウトエラー: \(error.localizedDescription)")
                    }
                }
            } message: {
                Text("ログアウトしますか？")
            }
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: Constants.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40)

            Text(title)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textGray)
        }
        .padding()
        .background(Color.clear)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AuthService())
}
