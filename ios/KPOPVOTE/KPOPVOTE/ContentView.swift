//
//  ContentView.swift
//  OSHI Pick
//
//  Created by MAKOTO BABA on R 7/11/12.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedSocialLinking") private var hasCompletedSocialLinking = false
    @State private var deepLinkVoteId: String?
    @State private var showDeepLinkVote = false
    @State private var deepLinkInviteCode: String?
    @State private var showInviteCodeAlert = false
    @State private var inviteAlertMessage = ""
    @State private var isApplyingInviteCode = false
    // Clipboard invite code detection
    @State private var clipboardInviteCode: String?
    @State private var showClipboardInviteConfirm = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // 初回起動 - チュートリアル表示
                TutorialView()
                    .environmentObject(authService)
            } else if authService.isAuthenticated && !hasCompletedSocialLinking {
                // 認証済みだがソーシャル連携未完了 - socialLinking画面表示
                ZStack {
                    Constants.Colors.backgroundDark
                        .ignoresSafeArea()
                    TutorialSocialLinkingView(
                        authService: authService,
                        onComplete: {
                            // onComplete内でフラグ設定済み
                        }
                    )
                }
            } else if authService.isAuthenticated {
                // 認証済み - メイン画面
                MainTabView()
                    .environmentObject(authService)
            } else if authService.isGuest {
                // ゲストモード - メイン画面（機能制限あり）
                MainTabView()
                    .environmentObject(authService)
            } else {
                // 未認証 - ログイン画面
                LoginView(authService: authService)
            }
        }
        .onReceive(deepLinkManager.$pendingVoteId) { voteId in
            if let voteId = voteId {
                print("🔗 [ContentView] Deep link vote received: \(voteId)")
                deepLinkVoteId = voteId
                showDeepLinkVote = true
                deepLinkManager.clearPendingVote()
            }
        }
        .onReceive(deepLinkManager.$pendingInviteCode) { inviteCode in
            if let inviteCode = inviteCode {
                print("🔗 [ContentView] Deep link invite code received: \(inviteCode)")
                deepLinkInviteCode = inviteCode
                deepLinkManager.clearPendingInviteCode()
                // 認証済みの場合のみ招待コードを適用
                if authService.isAuthenticated {
                    applyInviteCodeFromDeepLink(inviteCode)
                } else {
                    // 未認証の場合はログイン後に適用するためにコードを保持
                    UserDefaults.standard.set(inviteCode, forKey: "pendingInviteCode")
                    inviteAlertMessage = "ログイン後に招待コードが自動で適用されます"
                    showInviteCodeAlert = true
                }
            }
        }
        .fullScreenCover(isPresented: $showDeepLinkVote) {
            if let voteId = deepLinkVoteId {
                VoteDetailView(voteId: voteId)
            }
        }
        .alert("招待コード", isPresented: $showInviteCodeAlert) {
            Button("OK") {
                showInviteCodeAlert = false
            }
        } message: {
            Text(inviteAlertMessage)
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            // ログイン完了時に保留中の招待コードを適用
            if isAuthenticated {
                if let pendingCode = UserDefaults.standard.string(forKey: "pendingInviteCode") {
                    UserDefaults.standard.removeObject(forKey: "pendingInviteCode")
                    applyInviteCodeFromDeepLink(pendingCode)
                } else {
                    // クリップボードに招待コードがあるかチェック
                    checkClipboardForInviteCode()
                }
            }
        }
        .alert("招待コードを発見", isPresented: $showClipboardInviteConfirm) {
            Button("適用する") {
                if let code = clipboardInviteCode {
                    applyInviteCodeFromDeepLink(code)
                }
                clipboardInviteCode = nil
            }
            Button("キャンセル", role: .cancel) {
                clipboardInviteCode = nil
            }
        } message: {
            Text("クリップボードに招待コード「\(clipboardInviteCode ?? "")」が見つかりました。適用しますか？")
        }
    }

    // MARK: - Private Methods

    /// クリップボードに招待コードがあるかチェック
    private func checkClipboardForInviteCode() {
        // すでに招待コードを使用済みかチェック（UserDefaultsでフラグ管理）
        if UserDefaults.standard.bool(forKey: "hasUsedInviteCode") {
            return
        }

        // クリップボードの内容を取得
        guard let clipboardString = UIPasteboard.general.string else { return }
        let trimmed = clipboardString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // 招待コードのパターンチェック（6-10文字の英数字、I/L/O/0/1を除く）
        let inviteCodePattern = "^[A-HJ-NP-Z2-9]{6,10}$"
        if let regex = try? NSRegularExpression(pattern: inviteCodePattern),
           regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) != nil {
            print("📋 [ContentView] Found invite code in clipboard: \(trimmed)")
            clipboardInviteCode = trimmed
            showClipboardInviteConfirm = true
        }
    }

    /// Deep Linkから受け取った招待コードを適用
    private func applyInviteCodeFromDeepLink(_ inviteCode: String) {
        guard !isApplyingInviteCode else { return }
        isApplyingInviteCode = true

        Task {
            do {
                let response = try await PointsService.shared.applyInviteCode(inviteCode: inviteCode)
                await MainActor.run {
                    isApplyingInviteCode = false
                    // 招待コード使用済みフラグを設定
                    UserDefaults.standard.set(true, forKey: "hasUsedInviteCode")
                    if let inviterName = response.inviterDisplayName {
                        inviteAlertMessage = "\(inviterName)さんからの招待が適用されました！"
                    } else {
                        inviteAlertMessage = "招待コードが適用されました！"
                    }
                    showInviteCodeAlert = true
                }
            } catch {
                await MainActor.run {
                    isApplyingInviteCode = false
                    print("❌ [ContentView] Failed to apply invite code: \(error.localizedDescription)")
                    inviteAlertMessage = "招待コードの適用に失敗しました"
                    showInviteCodeAlert = true
                }
            }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var biasViewModel = BiasViewModel()
    @StateObject private var pointsViewModel = PointsViewModel()
    @Binding var selectedTab: Int
    @State private var showLogoutConfirm = false
    @State private var selectedVoteId: String?
    @State private var showVoteDetail = false
    @State private var selectedPostId: IdentifiableString?
    @State private var showPointsHistory = false
    @State private var showNotifications = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Active Tasks Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        HStack {
                            Text("参加中の推し投票")
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

                        // Tasks Pending Badge - Tappable
                        if !viewModel.activeTasks.isEmpty {
                            NavigationLink(destination: TasksListView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Constants.Colors.statusUrgent)

                                    Text("\(viewModel.activeTasks.count)個のタスクがあります。")
                                        .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                        .foregroundColor(Constants.Colors.statusUrgent)

                                    Spacer()

                                    Text("一覧を見る")
                                        .font(.system(size: 12))
                                        .foregroundColor(Constants.Colors.accentBlue)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10))
                                        .foregroundColor(Constants.Colors.accentBlue)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Constants.Colors.statusUrgent.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }

                    // Featured Votes Slider
                    if viewModel.isLoadingVotes {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(Constants.Colors.accentPink)
                                .padding()
                            Spacer()
                        }
                        .frame(height: 180)
                    } else if !viewModel.featuredVotes.isEmpty {
                        FeaturedVoteSlider(votes: viewModel.featuredVotes) { vote in
                            print("🎯 [ContentView] FeaturedVoteSlider callback - vote.id: \(vote.id)")
                            selectedVoteId = vote.id
                            print("🎯 [ContentView] Set selectedVoteId: \(vote.id)")
                            showVoteDetail = true
                            print("🎯 [ContentView] Set showVoteDetail: true")
                        }
                        .padding(.horizontal)
                    } else {
                        // Fallback to static banner if no featured votes
                        AppExclusiveVoteBanner()
                            .padding(.horizontal)
                    }

                    // Community Activity Section
                    CommunityActivityView(
                        onViewAll: {
                            selectedTab = 3 // Switch to Community Tab
                        },
                        onPostTap: { postId in
                            selectedPostId = IdentifiableString(postId)
                        }
                    )
                    .environmentObject(biasViewModel)
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .background(Constants.Colors.backgroundDark)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("oshi_pick_header_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 56)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Single Point Display Button（単一ポイント制）
                        if FeatureFlags.pointsEnabled {
                            Button(action: {
                                showPointsHistory = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(Constants.Colors.accentPink)
                                    if pointsViewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.6)
                                    } else {
                                        Text("\(pointsViewModel.points)P")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                        }

                        // Store Button (Phase 1: 非表示)
                        if FeatureFlags.storeEnabled {
                            NavigationLink(destination: StoreView()) {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Constants.Colors.textWhite)
                            }
                        }

                        // Notification Button
                        Button(action: {
                            showNotifications = true
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
            }
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .fullScreenCover(item: $selectedPostId) { identifiablePost in
                NavigationStack {
                    PostDetailView(postId: identifiablePost.id)
                }
            }
            .task {
                // ポイント読み込みを独立タスクとして開始（他のAPIと完全並列）
                let pointsTask = Task {
                    if FeatureFlags.pointsEnabled {
                        await pointsViewModel.loadPoints()
                    }
                }

                // 他のAPI呼び出しを並列実行
                async let tasks: () = viewModel.loadActiveTasks()
                async let votes: () = viewModel.loadFeaturedVotes()
                async let biasData: () = biasViewModel.loadIdols()  // 内部でloadCurrentBias()も呼ぶ

                _ = await (tasks, votes, biasData)
                await pointsTask.value

                // loadCurrentBias()は削除（loadIdols→loadData内で既に実行済み）
            }
            // Phase 1: ポイント履歴画面無効化
            .fullScreenCover(isPresented: FeatureFlags.pointsEnabled ? $showPointsHistory : .constant(false)) {
                PointsHistoryView()
            }
            .fullScreenCover(isPresented: $showVoteDetail) {
                Group {
                    if let voteId = selectedVoteId {
                        VoteDetailView(voteId: voteId)
                    }
                }
            }
            .fullScreenCover(isPresented: $showNotifications) {
                NotificationListView()
            }
            .onChange(of: showVoteDetail) { newValue in
                print("📱 [ContentView] showVoteDetail changed to: \(newValue), selectedVoteId: \(selectedVoteId ?? "nil")")
                if newValue {
                    if let voteId = selectedVoteId {
                        print("📱 [ContentView] Sheet will present VoteDetailView with voteId: \(voteId)")
                    } else {
                        print("⚠️ [ContentView] showVoteDetail is true but selectedVoteId is nil!")
                    }
                }
            }
            .onChange(of: selectedVoteId) { newValue in
                print("📱 [ContentView] selectedVoteId changed to: \(newValue ?? "nil")")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("taskRegisteredNotification"))) { _ in
                Task {
                    await viewModel.loadActiveTasks()
                }
            }
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
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
        }
        .navigationViewStyle(.stack) // iPad対応: 2カラムレイアウトを無効化
    }
}

// MARK: - APP EXCLUSIVE VOTE Banner
struct AppExclusiveVoteBanner: View {
    @State private var showVoteList = false

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
            showVoteList = true
        }
        .fullScreenCover(isPresented: $showVoteList) {
            VoteListView()
        }
    }
}

#Preview {
    ContentView()
}
