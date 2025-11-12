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

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .environmentObject(authService)
                .tabItem {
                    Label("ホーム", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            // Votes Tab (Placeholder)
            VotesListView()
                .tabItem {
                    Label("投票", systemImage: selectedTab == 1 ? "list.bullet.circle.fill" : "list.bullet.circle")
                }
                .tag(1)

            // Tasks Tab (Placeholder)
            TasksListView()
                .tabItem {
                    Label("タスク", systemImage: selectedTab == 2 ? "checkmark.circle.fill" : "checkmark.circle")
                }
                .tag(2)

            // Profile Tab (Placeholder)
            ProfileView()
                .environmentObject(authService)
                .tabItem {
                    Label("プロフィール", systemImage: selectedTab == 3 ? "person.fill" : "person")
                }
                .tag(3)
        }
        .accentColor(Constants.Colors.primaryBlue)
    }
}

// MARK: - Placeholder Views (実装予定)

struct VotesListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "list.bullet.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.primaryBlue)

                Text("投票一覧")
                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textPrimary)

                Text("実装予定")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textSecondary)
            }
            .navigationTitle("投票")
        }
    }
}

struct TasksListView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.primaryBlue)

                Text("タスク管理")
                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textPrimary)

                Text("実装予定")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textSecondary)
            }
            .navigationTitle("タスク")
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
                            .foregroundColor(Constants.Colors.primaryBlue)

                        // User Email
                        if let email = authService.currentUser?.email {
                            Text(email)
                                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textPrimary)
                        }

                        // Points Display
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("\(authService.currentUser?.points ?? 0) ポイント")
                                .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                                .foregroundColor(Constants.Colors.textPrimary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(20)
                    }
                    .padding()
                    .background(Constants.Colors.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                    // Settings Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("設定")
                            .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                            .foregroundColor(Constants.Colors.textPrimary)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            SettingsRow(icon: "person.fill", title: "アカウント設定", color: .blue)
                            Divider().padding(.leading, 60)
                            SettingsRow(icon: "bell.fill", title: "通知設定", color: .orange)
                            Divider().padding(.leading, 60)
                            SettingsRow(icon: "heart.fill", title: "推し管理", color: .pink)
                            Divider().padding(.leading, 60)
                            SettingsRow(icon: "info.circle.fill", title: "アプリ情報", color: .gray)
                        }
                        .background(Constants.Colors.cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
            .background(Constants.Colors.background)
            .navigationTitle("プロフィール")
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
                .foregroundColor(Constants.Colors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textSecondary)
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
