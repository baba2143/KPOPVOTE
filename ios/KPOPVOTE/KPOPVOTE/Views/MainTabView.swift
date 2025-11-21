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
                HomeView(selectedTab: $selectedTab)
                    .environmentObject(authService)
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)

                // Votes Tab (Phase 2 - Collections)
                VotesTabView()
                .tag(1)
                .toolbar(.hidden, for: .tabBar)

                // Center Button Placeholder (Empty, handled by custom tab bar)
                Color.clear
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)

                // Store Tab
                StoreView()
                    .tag(3)
                    .toolbar(.hidden, for: .tabBar)

                // Community Tab
                CommunityView()
                    .tag(4)
                    .toolbar(.hidden, for: .tabBar)

                // Profile Tab
                ProfileView()
                    .environmentObject(authService)
                    .tag(5)
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

// MARK: - Tasks List View

struct TasksListView: View {
    @StateObject private var viewModel = TasksListViewModel()
    @State private var selectedTab = 0 // 0: Active, 1: Archived, 2: Completed

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Filter", selection: $selectedTab) {
                    Text("Active").tag(0)
                    Text("Archived").tag(1)
                    Text("Completed").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Constants.Colors.backgroundDark)

                // Task List
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(Constants.Colors.accentPink)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    let tasks = selectedTab == 0 ? viewModel.activeTasks :
                                selectedTab == 1 ? viewModel.archivedTasks :
                                viewModel.completedTasks

                    if tasks.isEmpty {
                        VStack(spacing: Constants.Spacing.small) {
                            Spacer()
                            Image(systemName: selectedTab == 0 ? "checkmark.circle" :
                                              selectedTab == 1 ? "archivebox" :
                                              "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Constants.Colors.textGray)

                            Text(selectedTab == 0 ? "アクティブなタスクはありません" :
                                 selectedTab == 1 ? "アーカイブされたタスクはありません" :
                                 "完了したタスクはありません")
                                .font(.system(size: Constants.Typography.bodySize))
                                .foregroundColor(Constants.Colors.textGray)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: Constants.Spacing.medium) {
                                ForEach(tasks) { task in
                                    TaskCard(task: task, showCompleteButton: selectedTab == 0) {
                                        Task {
                                            await viewModel.completeTask(task)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable {
                            await viewModel.refresh()
                        }
                    }
                }
            }
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tasks")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await viewModel.loadAllTasks()
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
        }
    }
}

// MARK: - Task Card Component
struct TaskCard: View {
    let task: VoteTask
    let showCompleteButton: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            // External App Badge
            if let iconUrl = task.externalAppIconUrl, let appName = task.externalAppName {
                HStack(spacing: 6) {
                    if let url = URL(string: iconUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .cornerRadius(4)
                            case .failure(_), .empty:
                                Image(systemName: "app.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Constants.Colors.textGray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    Text(appName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Constants.Colors.textGray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Constants.Colors.backgroundDark)
                .cornerRadius(6)
            }

            // Title
            Text(task.title)
                .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)
                .lineLimit(2)

            // URL
            if let url = URL(string: task.url) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 12))
                        Text(task.url)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                    .foregroundColor(Constants.Colors.accentBlue)
                }
            }

            // Deadline & Status
            HStack(spacing: Constants.Spacing.small) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(task.formattedDeadline)
                        .font(.system(size: 12))
                }
                .foregroundColor(task.isExpired ? .red : Constants.Colors.textGray)

                Spacer()

                if task.isCompleted {
                    Text("完了")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                } else if task.isArchived || task.isExpired {
                    Text("アーカイブ")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                } else {
                    Text(task.timeRemaining)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Constants.Colors.accentPink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Constants.Colors.accentPink.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            // Complete Button
            if showCompleteButton && !task.isCompleted {
                Button(action: onComplete) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("完了にする")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var pointsViewModel = PointsViewModel()
    @State private var showLogoutConfirm = false
    @State private var showBiasSettings = false
    @State private var showProfileEdit = false
    @State private var showPointsHistory = false
    @State private var showPremium = false

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

                        // Display Name or Email
                        if let user = authService.currentUser {
                            Text(user.displayNameOrEmail)
                                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textWhite)
                        }

                        // Points Display - Tappable Card
                        Button(action: {
                            showPointsHistory = true
                        }) {
                            VStack(spacing: Constants.Spacing.small) {
                                // Premium Badge
                                if pointsViewModel.isPremium {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 12))
                                        Text("プレミアム会員")
                                            .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                    }
                                    .foregroundColor(.yellow)
                                }

                                // Points Amount
                                if pointsViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                } else {
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.yellow)
                                        Text("\(pointsViewModel.points)")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(Constants.Colors.textWhite)
                                        Text("P")
                                            .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                                            .foregroundColor(Constants.Colors.accentPink)
                                    }

                                    // View History Link
                                    HStack(spacing: 4) {
                                        Text("履歴を見る")
                                            .font(.system(size: Constants.Typography.captionSize))
                                            .foregroundColor(Constants.Colors.accentBlue)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 10))
                                            .foregroundColor(Constants.Colors.accentBlue)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Constants.Spacing.medium)
                            .padding(.horizontal, Constants.Spacing.large)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Constants.Colors.gradientPink.opacity(0.15),
                                        Constants.Colors.gradientBlue.opacity(0.15)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Constants.Colors.cardDark)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .task {
                        await pointsViewModel.loadPoints()
                    }

                    // Settings Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("Settings")
                            .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                            .foregroundColor(Constants.Colors.textWhite)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            // Premium Button
                            Button {
                                showPremium = true
                            } label: {
                                HStack(spacing: Constants.Spacing.small) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.yellow)
                                        .frame(width: 40)

                                    Text("プレミアム会員")
                                        .font(.system(size: Constants.Typography.bodySize))
                                        .foregroundColor(Constants.Colors.textWhite)

                                    if pointsViewModel.isPremium {
                                        Text("有効")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.2))
                                            .cornerRadius(6)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Constants.Colors.textGray)
                                }
                                .padding()
                                .background(Color.clear)
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))

                            // Bias Settings Button
                            Button {
                                showBiasSettings = true
                            } label: {
                                SettingsRow(icon: "heart.fill", title: "推し設定", color: Constants.Colors.accentPink)
                            }
                            .buttonStyle(.plain)

                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            Button {
                                showProfileEdit = true
                            } label: {
                                SettingsRow(icon: "person.fill", title: "Account", color: Constants.Colors.accentBlue)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            SettingsRow(icon: "star.fill", title: "Favorites", color: .yellow)
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
            .sheet(isPresented: $showBiasSettings) {
                BiasSettingsView()
            }
            .sheet(isPresented: $showProfileEdit) {
                ProfileEditView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showPointsHistory) {
                PointsHistoryView()
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
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
