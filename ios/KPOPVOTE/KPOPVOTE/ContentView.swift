//
//  ContentView.swift
//  KPOPVOTE
//
//  Created by MAKOTO BABA on R 7/11/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // メイン画面（タブナビゲーション）
                MainTabView()
                    .environmentObject(authService)
            } else {
                // ログイン画面
                LoginView(authService: authService)
            }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Active Tasks Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Text("My VOTE Dashboard")
                                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)
                            Spacer()
                        }
                        .padding(.horizontal)

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(Constants.Colors.accentPink)
                                    .padding()
                                Spacer()
                            }
                        } else if viewModel.activeTasks.isEmpty {
                            VStack(spacing: Constants.Spacing.small) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                Text("進行中のタスクはありません")
                                    .font(.system(size: Constants.Typography.bodySize))
                                    .foregroundColor(Constants.Colors.textGray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Constants.Spacing.medium) {
                                    ForEach(viewModel.activeTasks) { task in
                                        UrgentVoteCard(task: task) {
                                            Task {
                                                await viewModel.completeTask(task)
                                            }
                                        }
                                        .frame(width: 340)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Tasks Pending Badge
                        if !viewModel.activeTasks.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Constants.Colors.statusUrgent)
                                Text("\(viewModel.activeTasks.count) Tasks Pending")
                                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                    .foregroundColor(Constants.Colors.statusUrgent)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Community Activity Section
                    CommunityActivityView()
                        .padding(.horizontal)

                    // APP EXCLUSIVE VOTE Banner
                    AppExclusiveVoteBanner()
                        .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .refreshable {
                await viewModel.loadActiveTasks()
            }
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("K-VOTE COLLECTOR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("K-VOTE COLLECTOR")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Navigate to notifications
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Constants.Colors.textWhite)

                            // Notification badge
                            Circle()
                                .fill(Constants.Colors.statusUrgent)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -4)
                        }
                    }
                }
            }
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await viewModel.loadActiveTasks()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("taskRegisteredNotification"))) { _ in
                Task {
                    await viewModel.loadActiveTasks()
                }
            }
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

// MARK: - APP EXCLUSIVE VOTE Banner
struct AppExclusiveVoteBanner: View {
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Constants.Colors.gradientPurple,
                    Constants.Colors.accentPink,
                    Constants.Colors.accentBlue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 180)
            .cornerRadius(20)

            // Abstract wave pattern overlay
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    path.move(to: CGPoint(x: 0, y: height * 0.7))
                    path.addQuadCurve(
                        to: CGPoint(x: width, y: height * 0.5),
                        control: CGPoint(x: width * 0.5, y: height * 0.3)
                    )
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.1))
            }
            .frame(height: 180)
            .cornerRadius(20)

            // Content
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text("APP EXCLUSIVE VOTE")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Vote for the next chart-chosen song cover!")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .padding(Constants.Spacing.large)
            .frame(height: 180, alignment: .topLeading)
        }
        .frame(height: 180)
        .onTapGesture {
            // Navigate to exclusive vote
        }
    }
}

#Preview {
    ContentView()
}
