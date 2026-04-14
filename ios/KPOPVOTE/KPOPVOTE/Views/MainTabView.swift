//
//  MainTabView.swift
//  OSHI Pick
//
//  OSHI Pick - Main Tab Navigation
//

import SwiftUI
import UIKit

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var tabCoordinator = TabCoordinator()
    @StateObject private var idolRankingViewModel = IdolRankingViewModel()
    @State private var showCreateMenu = false
    @State private var showingTaskSheet = false
    @State private var showCreateCollection = false
    @State private var showCreatePost = false
    @State private var showIdolVote = false
    @State private var showFanCardCreate = false

    var body: some View {
        ZStack {
            // Main Tab Content
            TabView(selection: $tabCoordinator.selectedTab) {
                // Home Tab
                HomeView(selectedTab: $tabCoordinator.selectedTab)
                    .environmentObject(authService)
                    .environmentObject(tabCoordinator)
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)

                // Ranking Tab
                IdolRankingTabView()
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)

                // Votes Tab (Phase 2 - Collections)
                VotesTabView()
                    .environmentObject(tabCoordinator)
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)

                // Community Tab
                CommunityView(showCreatePost: $showCreatePost)
                    .environmentObject(authService)
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
                CustomTabBar(selectedTab: $tabCoordinator.selectedTab)
                    .padding(.bottom, 0)
            }
            .edgesIgnoringSafeArea(.bottom)

            // Floating + Button (右下)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showCreateMenu = true }) {
                        ZStack {
                            LinearGradient(
                                colors: [Constants.Colors.accentPink, Constants.Colors.gradientPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: 60, height: 60)
                            .cornerRadius(30)
                            .shadow(color: Constants.Colors.accentPink.opacity(0.5), radius: 12, x: 0, y: 4)

                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90) // タブバー(65) + safe area + margin
                }
            }
        }
        // MARK: - Rollback Point: Uncomment below to restore original confirmationDialog
        /*
        .confirmationDialog("新規作成", isPresented: $showCreateMenu, titleVisibility: .visible) {
            Button("📋 投票タスクを登録") {
                showingTaskSheet = true
            }
            Button("📦 コレクションを作成") {
                showCreateCollection = true
            }
            Button("💬 コミュニティ投稿") {
                showCreatePost = true
            }
            Button("キャンセル", role: .cancel) {}
        }
        */
        // Custom Glassmorphism Menu
        .fullScreenCover(isPresented: $showCreateMenu) {
            CreateMenuView(
                onTaskCreate: {
                    showingTaskSheet = true
                },
                onCollectionCreate: {
                    showCreateCollection = true
                },
                onPostCreate: {
                    showCreatePost = true
                },
                onIdolVote: {
                    showIdolVote = true
                },
                onFanCardCreate: {
                    showFanCardCreate = true
                }
            )
            .background(BackgroundClearView())
        }
        .fullScreenCover(isPresented: $showingTaskSheet) {
            TaskRegistrationView()
        }
        .fullScreenCover(isPresented: $showCreateCollection) {
            CreateCollectionView()
        }
        .fullScreenCover(isPresented: $showCreatePost) {
            NavigationView {
                CreatePostView()
            }
        }
        .fullScreenCover(isPresented: $showIdolVote) {
            NewIdolVoteView(viewModel: idolRankingViewModel)
        }
        .fullScreenCover(isPresented: $showFanCardCreate) {
            FanCardEditorView()
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
                    Text("参加中").tag(0)
                    Text("アーカイブ").tag(1)
                    Text("完了").tag(2)
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
                                    if selectedTab == 0 {
                                        // Active tasks - wrap in NavigationLink for editing
                                        NavigationLink(destination: TaskRegistrationView(task: task)) {
                                            TaskCard(task: task, showCompleteButton: true, onComplete: {
                                                Task {
                                                    await viewModel.completeTask(task)
                                                }
                                            }, onDelete: {
                                                Task {
                                                    await viewModel.deleteTask(task)
                                                }
                                            })
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.horizontal)
                                    } else {
                                        // Archived/Completed tasks - no navigation
                                        TaskCard(task: task, showCompleteButton: false, onComplete: {
                                            Task {
                                                await viewModel.completeTask(task)
                                            }
                                        }, onDelete: {
                                            Task {
                                                await viewModel.deleteTask(task)
                                            }
                                        })
                                        .padding(.horizontal)
                                    }
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
            .alert("完了", isPresented: $viewModel.showSuccessMessage) {
                Button("OK", role: .cancel) {
                    viewModel.showSuccessMessage = false
                }
            } message: {
                Text(viewModel.successMessageText)
            }
        }
        .navigationViewStyle(.stack) // iPad対応: 2カラムレイアウトを無効化
    }
}

// MARK: - Task Card Component
struct TaskCard: View {
    let task: VoteTask
    let showCompleteButton: Bool
    let onComplete: () -> Void
    let onDelete: () -> Void

    // Share states（新報酬設計）
    @State private var showShareSheet = false
    @State private var showShareResult = false
    @State private var shareResult: ShareTaskResponse?
    @State private var isSharing = false

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            // Cover Image
            if let coverImageUrl = task.coverImage, let url = URL(string: coverImageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                    case .failure(_), .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 120)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }

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

                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Action Buttons Row
            HStack(spacing: 12) {
                // Share Button（新報酬設計）
                if FeatureFlags.pointsEnabled {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        HStack(spacing: 4) {
                            if isSharing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14))
                                Text("共有 (+5P)")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                        }
                        .foregroundColor(Constants.Colors.accentBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Constants.Colors.accentBlue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .disabled(isSharing)
                }

                Spacer()

                // Complete Button
                if showCompleteButton && !task.isCompleted {
                    Button(action: onComplete) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("完了にする")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
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
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .sheet(isPresented: $showShareSheet) {
            ShareTaskSheet(task: task) { platform in
                await shareTask(platform: platform)
            }
        }
        .alert("共有完了", isPresented: $showShareResult) {
            Button("OK") {}
        } message: {
            if let result = shareResult {
                if result.pointsGranted > 0 {
                    Text("+\(result.pointsGranted)P獲得！（本日 \(result.dailyShareCount)/\(result.dailyLimit)回）")
                } else {
                    Text("本日の共有報酬は上限に達しました（\(result.dailyLimit)回/日）")
                }
            }
        }
    }

    // MARK: - Share Task
    private func shareTask(platform: String) async {
        isSharing = true
        do {
            let result = try await PointsService.shared.shareTask(taskId: task.id, platform: platform)
            shareResult = result
            showShareResult = true
        } catch {
            debugLog("❌ [TaskCard] Failed to share task: \(error)")
        }
        isSharing = false
    }
}

// MARK: - Share Task Sheet
struct ShareTaskSheet: View {
    let task: VoteTask
    let onShare: (String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("タスクを共有")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text("共有すると+5Pがもらえます（1日3回まで）")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)

                VStack(spacing: 16) {
                    shareButton(
                        title: "X (Twitter)",
                        icon: "message.fill",
                        color: .black,
                        platform: "twitter"
                    )

                    shareButton(
                        title: "Instagram",
                        icon: "camera.fill",
                        color: Color(red: 0.83, green: 0.18, blue: 0.47),
                        platform: "instagram"
                    )

                    shareButton(
                        title: "LINE",
                        icon: "message.fill",
                        color: Color(red: 0.0, green: 0.75, blue: 0.35),
                        platform: "line"
                    )

                    shareButton(
                        title: "その他",
                        icon: "square.and.arrow.up",
                        color: Constants.Colors.textGray,
                        platform: "other"
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.Colors.backgroundDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                }
            }
        }
    }

    @ViewBuilder
    private func shareButton(title: String, icon: String, color: Color, platform: String) -> some View {
        Button(action: {
            shareToSNS(platform: platform)
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }

    private func shareToSNS(platform: String) {
        // 二重実行防止
        guard !isProcessing else { return }
        isProcessing = true

        // 共有用テキスト
        let shareText = "\(task.title)\n\nOSHI Pickで投票タスクを管理中！ #OSHIPICK"
        let shareUrl = task.url

        switch platform {
        case "twitter":
            // テキストとURLを別々にエンコード
            guard let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let encodedUrl = shareUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                isProcessing = false
                return
            }

            // Web Intent を使用（より安定）
            if let webUrl = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)&url=\(encodedUrl)") {
                UIApplication.shared.open(webUrl)
                // ポイントAPI完了を待ってからdismiss
                Task {
                    await onShare(platform)
                    dismiss()
                }
            } else {
                isProcessing = false
            }
        case "instagram":
            // Instagram Storiesへの共有
            if let url = URL(string: "instagram-stories://share") {
                UIApplication.shared.open(url)
            }
            // ポイントAPI完了を待ってからdismiss
            Task {
                await onShare(platform)
                dismiss()
            }
        case "line":
            if let encodedText = "\(shareText) \(shareUrl)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "line://msg/text/\(encodedText)") {
                UIApplication.shared.open(url)
            }
            // ポイントAPI完了を待ってからdismiss
            Task {
                await onShare(platform)
                dismiss()
            }
        default:
            // システムのシェアシート
            let activityVC = UIActivityViewController(
                activityItems: [shareText, URL(string: shareUrl) as Any],
                applicationActivities: nil
            )
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
            // ポイントAPI完了を待ってからdismiss
            Task {
                await onShare(platform)
                dismiss()
            }
        }
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
    @State private var showNotifications = false
    @State private var showFavorites = false
    @State private var showAbout = false
    @State private var showFanCard = false
    @State private var showFollowingList = false
    @State private var showFollowersList = false
    @State private var showMessages = false
    @State private var followingCount = 0

    // 招待コード states（新報酬設計）
    @State private var showInviteCode = false
    @State private var inviteCode: String = ""
    @State private var inviteLink: String = ""
    @State private var isLoadingInviteCode = false
    @State private var showInviteCodeCopied = false
    @State private var followersCount = 0
    // 招待コード入力 states
    @State private var showEnterInviteCode = false
    @State private var manualInviteCode: String = ""
    @State private var isApplyingManualInviteCode = false
    @State private var manualInviteCodeResult: String?
    @State private var showManualInviteResult = false
    @State private var hasUsedInviteCode = UserDefaults.standard.bool(forKey: "hasUsedInviteCode")
    // Delete Account state (App Store Guideline 5.1.1(v))
    @State private var showDeleteAccountConfirm = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showDeleteError = false
    // Blocked Users (App Store Guideline 1.2)
    @State private var showBlockedUsers = false
    // Login Sheet for Guest users
    @State private var showLoginSheet = false
    // Linked Accounts (Apple/Google Sign-In)
    @State private var showLinkedAccounts = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // User Info Card
                    VStack(spacing: Constants.Spacing.medium) {
                        // Profile Image
                        profileImageView

                        // Display Name or Email
                        if let user = authService.currentUser {
                            Text(user.displayNameOrEmail)
                                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textWhite)
                        }

                        // Follow/Follower Counts
                        HStack(spacing: Constants.Spacing.large) {
                            Button {
                                showFollowingList = true
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(followingCount)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Constants.Colors.textWhite)
                                    Text("フォロー")
                                        .font(.system(size: 12))
                                        .foregroundColor(Constants.Colors.textGray)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .frame(height: 30)
                                .background(Constants.Colors.textGray.opacity(0.3))

                            Button {
                                showFollowersList = true
                            } label: {
                                VStack(spacing: 4) {
                                    Text("\(followersCount)")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Constants.Colors.textWhite)
                                    Text("フォロワー")
                                        .font(.system(size: 12))
                                        .foregroundColor(Constants.Colors.textGray)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 8)

                        // Points Display - Only show if pointsEnabled（単一ポイント制）
                        if FeatureFlags.pointsEnabled {
                            Button(action: {
                                showPointsHistory = true
                            }) {
                                VStack(spacing: Constants.Spacing.small) {
                                    // Single Point Display（単一ポイント制）
                                    if pointsViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                    } else {
                                        VStack(spacing: 8) {
                                            // Points Display
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                Text("\(pointsViewModel.points)")
                                                    .font(.system(size: 36, weight: .bold))
                                                    .foregroundColor(Constants.Colors.accentPink)
                                                Text("P")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(Constants.Colors.accentPink.opacity(0.7))
                                            }

                                            // Vote capacity (1P = 1票)
                                            Text("(\(pointsViewModel.points)票分)")
                                                .font(.system(size: 12))
                                                .foregroundColor(Constants.Colors.textGray)
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
                                        .padding(.top, 4)
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
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
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
                            // MARK: - Premium Button (Phase 2以降で実装予定)
                            /*
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
                            */

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
                                SettingsRow(icon: "person.fill", title: "プロフィール設定", color: Constants.Colors.accentBlue)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))

                            // FanCard Button
                            if authService.isAuthenticated {
                                Button {
                                    showFanCard = true
                                } label: {
                                    SettingsRow(icon: "person.text.rectangle", title: "FanCard", color: Constants.Colors.accentPink)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            }

                            Button {
                                showNotifications = true
                            } label: {
                                SettingsRow(icon: "bell.fill", title: "通知設定", color: .orange)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            Button {
                                showMessages = true
                            } label: {
                                SettingsRow(icon: "envelope.fill", title: "メッセージ", color: Constants.Colors.accentBlue)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            Button {
                                showFavorites = true
                            } label: {
                                SettingsRow(icon: "star.fill", title: "お気に入り", color: .yellow)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            // Linked Accounts (Apple/Google) - Only show for authenticated users
                            if authService.isAuthenticated {
                                Button {
                                    showLinkedAccounts = true
                                } label: {
                                    SettingsRow(icon: "link.circle.fill", title: "連携アカウント", color: Constants.Colors.primaryBlue)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            }
                            Button {
                                showBlockedUsers = true
                            } label: {
                                SettingsRow(icon: "person.slash.fill", title: "ブロックリスト", color: .red)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))

                            // 友達招待ボタン（新報酬設計）
                            if FeatureFlags.pointsEnabled && authService.isAuthenticated {
                                Button {
                                    Task {
                                        await loadInviteCode()
                                    }
                                    showInviteCode = true
                                } label: {
                                    HStack(spacing: Constants.Spacing.small) {
                                        Image(systemName: "gift.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.green)
                                            .frame(width: 40)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("友達を招待")
                                                .font(.system(size: Constants.Typography.bodySize))
                                                .foregroundColor(Constants.Colors.textWhite)
                                            Text("+50P獲得")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.green)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Constants.Colors.textGray)
                                    }
                                    .padding()
                                    .contentShape(Rectangle())
                                    .background(Color.clear)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            }

                            // 招待コードを入力ボタン（未使用の場合のみ表示）
                            if FeatureFlags.pointsEnabled && authService.isAuthenticated && !hasUsedInviteCode {
                                Button {
                                    showEnterInviteCode = true
                                } label: {
                                    HStack(spacing: Constants.Spacing.small) {
                                        Image(systemName: "ticket.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Constants.Colors.accentBlue)
                                            .frame(width: 40)

                                        Text("招待コードを入力")
                                            .font(.system(size: Constants.Typography.bodySize))
                                            .foregroundColor(Constants.Colors.textWhite)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Constants.Colors.textGray)
                                    }
                                    .padding()
                                    .contentShape(Rectangle())
                                    .background(Color.clear)
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading, 60).background(Constants.Colors.textGray.opacity(0.3))
                            }

                            Button {
                                showAbout = true
                            } label: {
                                SettingsRow(icon: "info.circle.fill", title: "アプリについて", color: Constants.Colors.textGray)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }

                    // Authentication-dependent buttons
                    if authService.isAuthenticated {
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

                        // Delete Account Button (App Store Guideline 5.1.1(v) compliance)
                        Button(action: {
                            showDeleteAccountConfirm = true
                        }) {
                            HStack {
                                if isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                } else {
                                    Image(systemName: "trash.fill")
                                }
                                Text("アカウントを削除")
                            }
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                        .disabled(isDeleting)

                        // Deletion warning text
                        Text("アカウントを削除すると、すべてのデータが完全に削除され、復元できません。")
                            .font(.system(size: 11))
                            .foregroundColor(Constants.Colors.textGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        // Login Button for Guest users
                        Button(action: {
                            showLoginSheet = true
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text("ログイン")
                            }
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Constants.Colors.accentPink)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("ログアウト確認", isPresented: $showLogoutConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    Task {
                        do {
                            try await authService.logout()
                        } catch {
                            print("ログアウトエラー: \(error.localizedDescription)")
                        }
                    }
                }
            } message: {
                Text("ログアウトしますか？")
            }
            // Delete Account Confirmation Alert (App Store Guideline 5.1.1(v))
            .alert("アカウント削除", isPresented: $showDeleteAccountConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    Task {
                        isDeleting = true
                        do {
                            try await authService.deleteAccount()
                        } catch {
                            deleteError = error.localizedDescription
                            showDeleteError = true
                        }
                        isDeleting = false
                    }
                }
            } message: {
                Text("アカウントを削除すると、すべてのデータ（投稿、いいね、フォロー関係、メッセージなど）が完全に削除され、復元できません。\n\n本当に削除しますか？")
            }
            // Delete Error Alert
            .alert("エラー", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "アカウント削除中にエラーが発生しました。")
            }
            .fullScreenCover(isPresented: $showBiasSettings) {
                BiasSettingsView()
            }
            .fullScreenCover(isPresented: $showProfileEdit) {
                ProfileEditView()
                    .environmentObject(authService)
            }
            .fullScreenCover(isPresented: $showPointsHistory) {
                PointsHistoryView()
            }
            .fullScreenCover(isPresented: $showPremium) {
                PremiumView()
            }
            .fullScreenCover(isPresented: $showNotifications) {
                NotificationsView()
            }
            .fullScreenCover(isPresented: $showFavorites) {
                FavoritesView()
            }
            .fullScreenCover(isPresented: $showMessages) {
                DMListView()
                    .environmentObject(authService)
            }
            .fullScreenCover(isPresented: $showAbout) {
                AboutView()
            }
            .fullScreenCover(isPresented: $showBlockedUsers) {
                BlockedUsersView()
            }
            .fullScreenCover(isPresented: $showFollowingList) {
                FollowListView(listType: .following)
            }
            .fullScreenCover(isPresented: $showFollowersList) {
                FollowListView(listType: .followers)
            }
            .fullScreenCover(isPresented: $showLoginSheet) {
                LoginView(authService: authService)
            }
            .fullScreenCover(isPresented: $showLinkedAccounts) {
                LinkedAccountsView(authService: authService)
                    .environmentObject(authService)
            }
            .fullScreenCover(isPresented: $showFanCard) {
                FanCardEditorView()
            }
            .sheet(isPresented: $showInviteCode) {
                InviteCodeSheet(
                    inviteCode: inviteCode,
                    inviteLink: inviteLink,
                    isLoading: isLoadingInviteCode,
                    showCopied: $showInviteCodeCopied
                )
            }
            .sheet(isPresented: $showEnterInviteCode) {
                EnterInviteCodeSheet(
                    inviteCode: $manualInviteCode,
                    isApplying: $isApplyingManualInviteCode,
                    onApply: { code in
                        await applyManualInviteCode(code)
                    }
                )
            }
            .alert("招待コード", isPresented: $showManualInviteResult) {
                Button("OK") {
                    showManualInviteResult = false
                    manualInviteCodeResult = nil
                }
            } message: {
                Text(manualInviteCodeResult ?? "")
            }
            .task {
                await loadFollowCounts()
            }
        }
        .navigationViewStyle(.stack) // iPad対応: 2カラムレイアウトを無効化
    }

    // MARK: - Load Invite Code（新報酬設計）
    private func loadInviteCode() async {
        guard inviteCode.isEmpty else { return }

        isLoadingInviteCode = true
        do {
            let response = try await PointsService.shared.generateInviteCode()
            inviteCode = response.inviteCode
            inviteLink = response.inviteLink
            debugLog("✅ [ProfileView] Invite code loaded: \(response.inviteCode)")
        } catch {
            debugLog("❌ [ProfileView] Failed to load invite code: \(error)")
        }
        isLoadingInviteCode = false
    }

    // MARK: - Apply Manual Invite Code
    private func applyManualInviteCode(_ code: String) async {
        isApplyingManualInviteCode = true
        do {
            let response = try await PointsService.shared.applyInviteCode(inviteCode: code)
            // 招待コード使用済みフラグを設定
            UserDefaults.standard.set(true, forKey: "hasUsedInviteCode")
            hasUsedInviteCode = true
            if let inviterName = response.inviterDisplayName {
                manualInviteCodeResult = "\(inviterName)さんからの招待が適用されました！"
            } else {
                manualInviteCodeResult = "招待コードが適用されました！"
            }
            showEnterInviteCode = false
            showManualInviteResult = true
            manualInviteCode = ""
            debugLog("✅ [ProfileView] Manual invite code applied successfully")
        } catch {
            manualInviteCodeResult = "招待コードの適用に失敗しました。コードを確認してください。"
            showManualInviteResult = true
            debugLog("❌ [ProfileView] Failed to apply manual invite code: \(error)")
        }
        isApplyingManualInviteCode = false
    }

    // MARK: - Load Follow Counts
    private func loadFollowCounts() async {
        // Step 1: キャッシュされた値を即座に表示（瞬時のフィードバック）
        if let user = authService.currentUser {
            followingCount = user.followingCount
            followersCount = user.followersCount
        }

        // Step 2: APIから最新データを取得して更新
        do {
            let followService = FollowService.shared
            let (following, _) = try await followService.fetchFollowing(limit: 100)
            let (followers, _) = try await followService.fetchFollowers(limit: 100)

            followingCount = following.count
            followersCount = followers.count
        } catch {
            print("Failed to load follow counts: \(error)")
            // エラー時はキャッシュ値を維持（すでに表示済み）
        }
    }

    // MARK: - Default Profile Circle
    private var defaultProfileCircle: some View {
        Circle()
            .fill(Constants.Colors.accentPink.opacity(0.3))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Constants.Colors.accentPink)
            )
    }

    // MARK: - Profile Image View
    private var profileImageView: some View {
        ProfileImageLoader(photoURL: authService.currentUser?.photoURL)
    }
}

// MARK: - Invite Code Sheet（新報酬設計）
struct InviteCodeSheet: View {
    let inviteCode: String
    let inviteLink: String
    let isLoading: Bool
    @Binding var showCopied: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green, .green.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)

                // Title and Description
                VStack(spacing: 8) {
                    Text("友達を招待しよう")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text("友達があなたの招待コードで登録すると\nあなたに50Pプレゼント！")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
                        .multilineTextAlignment(.center)
                }

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .padding(.vertical, 40)
                } else {
                    // Invite Code Display
                    VStack(spacing: 12) {
                        Text("あなたの招待コード")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Constants.Colors.textGray)

                        HStack(spacing: 12) {
                            Text(inviteCode)
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(Constants.Colors.textWhite)
                                .tracking(4)

                            Button(action: {
                                UIPasteboard.general.string = inviteCode
                                showCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopied = false
                                }
                            }) {
                                Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 20))
                                    .foregroundColor(showCopied ? .green : Constants.Colors.accentBlue)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(12)

                        if showCopied {
                            Text("コピーしました！")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 16)

                    // Share Buttons
                    VStack(spacing: 12) {
                        // Share via LINE
                        Button(action: {
                            shareToLine()
                        }) {
                            HStack {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 18))
                                Text("LINEで共有")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.0, green: 0.75, blue: 0.35))
                            .cornerRadius(12)
                        }

                        // Share via Twitter
                        Button(action: {
                            shareToTwitter()
                        }) {
                            HStack {
                                Image(systemName: "at")
                                    .font(.system(size: 18))
                                Text("X (Twitter) で共有")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .cornerRadius(12)
                        }

                        // Copy Link
                        Button(action: {
                            UIPasteboard.general.string = inviteLink
                            showCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopied = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "link")
                                    .font(.system(size: 18))
                                Text("リンクをコピー")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Constants.Colors.textWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Constants.Colors.cardDark)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.Colors.backgroundDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                }
            }
        }
    }

    private func shareToLine() {
        let shareText = "OSHI Pickで一緒に推し活しよう！招待コード「\(inviteCode)」を使って登録してね！\n\(inviteLink)"
        if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "line://msg/text/\(encodedText)") {
            UIApplication.shared.open(url)
        }
    }

    private func shareToTwitter() {
        let shareText = "OSHI Pickで一緒に推し活しよう！招待コード「\(inviteCode)」を使って登録してね！ #OSHIPICK"
        if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "twitter://post?message=\(encodedText)%20\(inviteLink)") {
            UIApplication.shared.open(url) { success in
                if !success, let webUrl = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)%20\(inviteLink)") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
}

// MARK: - Enter Invite Code Sheet（招待コード入力シート）
struct EnterInviteCodeSheet: View {
    @Binding var inviteCode: String
    @Binding var isApplying: Bool
    let onApply: (String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Constants.Colors.accentBlue, Constants.Colors.accentBlue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 80, height: 80)

                    Image(systemName: "ticket.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)

                // Title and Description
                VStack(spacing: 8) {
                    Text("招待コードを入力")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text("友達からもらった招待コードを入力すると\n友達に50Pがプレゼントされます！")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
                        .multilineTextAlignment(.center)
                }

                // Invite Code Input
                VStack(spacing: 12) {
                    TextField("招待コードを入力", text: $inviteCode)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(12)
                        .focused($isTextFieldFocused)
                        .onChange(of: inviteCode) { newValue in
                            // 大文字に変換、空白を除去
                            inviteCode = newValue.uppercased().trimmingCharacters(in: .whitespaces)
                        }

                    // Paste from Clipboard Button
                    Button(action: {
                        if let clipboardString = UIPasteboard.general.string {
                            inviteCode = clipboardString.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 14))
                            Text("クリップボードから貼り付け")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(Constants.Colors.accentBlue)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Apply Button
                Button(action: {
                    Task {
                        await onApply(inviteCode)
                    }
                }) {
                    HStack {
                        if isApplying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("招待コードを適用")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: inviteCode.count >= 6 && !isApplying
                                ? [Constants.Colors.accentPink, Constants.Colors.gradientPurple]
                                : [Color.gray, Color.gray.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(inviteCode.count < 6 || isApplying)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.Colors.backgroundDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                }
            }
            .onAppear {
                // 自動的にクリップボードをチェック
                if let clipboardString = UIPasteboard.general.string {
                    let trimmed = clipboardString.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    // 招待コードのパターン（6-10文字の英数字）
                    let inviteCodePattern = "^[A-HJ-NP-Z2-9]{6,10}$"
                    if let regex = try? NSRegularExpression(pattern: inviteCodePattern),
                       regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil {
                        inviteCode = trimmed
                    }
                }
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Profile Image Loader (Separate View for proper state management)
struct ProfileImageLoader: View {
    let photoURL: String?

    var body: some View {
        Group {
            if let urlString = photoURL,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                            .frame(width: 80, height: 80)
                            .onAppear {
                                print("🖼️ [ProfileImageLoader] LOADING... URL: \(urlString.prefix(60))...")
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipped()
                            .clipShape(Circle())
                            .onAppear {
                                print("🖼️ [ProfileImageLoader] SUCCESS! Image loaded")
                            }
                    case .failure(let error):
                        defaultCircle
                            .onAppear {
                                print("🖼️ [ProfileImageLoader] FAILED: \(error.localizedDescription)")
                            }
                    @unknown default:
                        defaultCircle
                    }
                }
                .id(urlString) // Force new AsyncImage when URL changes
            } else {
                defaultCircle
                    .onAppear {
                        print("🖼️ [ProfileImageLoader] No URL - photoURL: \(photoURL ?? "nil")")
                    }
            }
        }
        .onAppear {
            print("🖼️ [ProfileImageLoader] View appeared with URL: \(photoURL ?? "nil")")
        }
    }

    private var defaultCircle: some View {
        Circle()
            .fill(Constants.Colors.accentPink.opacity(0.3))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Constants.Colors.accentPink)
            )
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
        .contentShape(Rectangle())  // 行全体をタップ可能に
        .background(Color.clear)
    }
}

// MARK: - Background Clear View Helper
struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AuthService())
}
