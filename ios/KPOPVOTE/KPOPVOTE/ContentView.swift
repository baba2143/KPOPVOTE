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
                    // User Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("こんにちは")
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(Constants.Colors.textSecondary)

                            if let email = authService.currentUser?.email {
                                Text(email.components(separatedBy: "@").first ?? email)
                                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                    .foregroundColor(Constants.Colors.textPrimary)
                            }
                        }

                        Spacer()

                        // Points Badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                            Text("\(authService.currentUser?.points ?? 0)")
                                .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                                .foregroundColor(Constants.Colors.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Urgent Tasks Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                            Text("緊急VOTE")
                                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal)

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        } else if viewModel.urgentTasks.isEmpty {
                            VStack(spacing: Constants.Spacing.small) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.green)
                                Text("緊急タスクはありません")
                                    .font(.system(size: Constants.Typography.bodySize))
                                    .foregroundColor(Constants.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Constants.Spacing.medium) {
                                    ForEach(viewModel.urgentTasks) { task in
                                        UrgentVoteCard(task: task) {
                                            Task {
                                                await viewModel.completeTask(task)
                                            }
                                        }
                                        .frame(width: 300)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Community Activity Section
                    CommunityActivityView()
                        .padding(.horizontal)

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
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Constants.Colors.background)
            .navigationTitle("K-VOTE COLLECTOR")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Constants.Colors.primaryBlue)
                    }
                }
            }
            .task {
                await viewModel.loadUrgentTasks()
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

#Preview {
    ContentView()
}
