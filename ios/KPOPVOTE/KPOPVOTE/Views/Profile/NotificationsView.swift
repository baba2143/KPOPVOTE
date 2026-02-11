//
//  NotificationsView.swift
//  OSHI Pick
//
//  OSHI Pick - Notification Settings View
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NotificationsViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.large) {
                        // Main Push Notification Toggle
                        mainToggleSection

                        // Notification Types Section
                        if viewModel.pushEnabled {
                            notificationTypesSection
                        }

                        // Permission Warning
                        if !viewModel.systemNotificationsEnabled {
                            permissionWarningSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("通知設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
            .task {
                await viewModel.checkNotificationPermission()
            }
        }
    }

    // MARK: - Main Toggle Section
    @ViewBuilder
    private var mainToggleSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack(spacing: Constants.Spacing.small) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Constants.Colors.accentPink)

                Text("プッシュ通知")
                    .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)
            }

            Toggle(isOn: $viewModel.pushEnabled) {
                Text("プッシュ通知を有効にする")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textWhite)
            }
            .tint(Constants.Colors.accentPink)
            .padding()
            .background(Constants.Colors.cardDark)
            .cornerRadius(12)
            .onChange(of: viewModel.pushEnabled) { newValue in
                if newValue && !viewModel.systemNotificationsEnabled {
                    viewModel.openSettings()
                }
            }
        }
    }

    // MARK: - Notification Types Section
    @ViewBuilder
    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("通知の種類")
                .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)
                .padding(.bottom, Constants.Spacing.small)

            VStack(spacing: 0) {
                NotificationToggleRow(
                    icon: "heart.fill",
                    title: "いいね",
                    subtitle: "あなたのコンテンツにいいねがついたとき",
                    color: .red,
                    isOn: $viewModel.likesEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "bubble.left.fill",
                    title: "コメント",
                    subtitle: "あなたの投稿にコメントがついたとき",
                    color: .blue,
                    isOn: $viewModel.commentsEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "at",
                    title: "メンション",
                    subtitle: "コメントであなたがメンションされたとき",
                    color: .cyan,
                    isOn: $viewModel.mentionsEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "person.fill.badge.plus",
                    title: "フォロワー",
                    subtitle: "誰かにフォローされたとき",
                    color: .purple,
                    isOn: $viewModel.followersEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "bell.badge.fill",
                    title: "新着投稿",
                    subtitle: "フォロー中のユーザーが投稿したとき",
                    color: .indigo,
                    isOn: $viewModel.newPostsEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "checkmark.square.fill",
                    title: "投票リマインダー",
                    subtitle: "投票予定のリマインダー",
                    color: Constants.Colors.accentPink,
                    isOn: $viewModel.voteRemindersEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "calendar.badge.clock",
                    title: "カレンダーリマインダー",
                    subtitle: "イベントやスケジュールの通知",
                    color: .orange,
                    isOn: $viewModel.calendarRemindersEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "megaphone.fill",
                    title: "お知らせ",
                    subtitle: "アプリの重要なお知らせ",
                    color: .green,
                    isOn: $viewModel.announcementsEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "envelope.fill",
                    title: "メッセージ",
                    subtitle: "メッセージを受信したとき",
                    color: .pink,
                    isOn: $viewModel.directMessagesEnabled
                )
            }
            .background(Constants.Colors.cardDark)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Permission Warning Section
    @ViewBuilder
    private var permissionWarningSection: some View {
        VStack(spacing: Constants.Spacing.medium) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("通知が無効です")
                .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            Text("設定から通知を有効にすると、投票やコメントなどの更新を受け取れます。")
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)

            Button {
                viewModel.openSettings()
            } label: {
                Text("設定を開く")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Constants.Spacing.large)
                    .padding(.vertical, Constants.Spacing.medium)
                    .background(Constants.Colors.accentPink)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - Notification Toggle Row Component
struct NotificationToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Constants.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textWhite)

                Text(subtitle)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Constants.Colors.accentPink)
                .labelsHidden()
        }
        .padding()
    }
}

// MARK: - Notifications ViewModel
class NotificationsViewModel: ObservableObject {
    @Published var systemNotificationsEnabled = false
    @Published var isLoading = false
    @Published var pushEnabled = true {
        didSet { if !isLoading { saveSettings(key: "pushEnabled", value: pushEnabled) } }
    }
    @Published var likesEnabled = true {
        didSet { if !isLoading { saveSettings(key: "likes", value: likesEnabled) } }
    }
    @Published var commentsEnabled = true {
        didSet { if !isLoading { saveSettings(key: "comments", value: commentsEnabled) } }
    }
    @Published var mentionsEnabled = true {
        didSet { if !isLoading { saveSettings(key: "mentions", value: mentionsEnabled) } }
    }
    @Published var followersEnabled = true {
        didSet { if !isLoading { saveSettings(key: "followers", value: followersEnabled) } }
    }
    @Published var newPostsEnabled = true {
        didSet { if !isLoading { saveSettings(key: "newPosts", value: newPostsEnabled) } }
    }
    @Published var voteRemindersEnabled = true {
        didSet { if !isLoading { saveSettings(key: "voteReminders", value: voteRemindersEnabled) } }
    }
    @Published var calendarRemindersEnabled = true {
        didSet { if !isLoading { saveSettings(key: "calendarReminders", value: calendarRemindersEnabled) } }
    }
    @Published var announcementsEnabled = true {
        didSet { if !isLoading { saveSettings(key: "announcements", value: announcementsEnabled) } }
    }
    @Published var directMessagesEnabled = true {
        didSet { if !isLoading { saveSettings(key: "directMessages", value: directMessagesEnabled) } }
    }

    private let notificationService = NotificationService.shared

    @MainActor
    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let settings = try await notificationService.fetchNotificationSettings()
            debugLog("✅ [NotificationsViewModel] Loaded settings from API")

            // Update all settings without triggering didSet
            pushEnabled = settings.pushEnabled
            likesEnabled = settings.likes
            commentsEnabled = settings.comments
            mentionsEnabled = settings.mentions
            followersEnabled = settings.followers
            newPostsEnabled = settings.newPosts
            voteRemindersEnabled = settings.voteReminders
            calendarRemindersEnabled = settings.calendarReminders
            announcementsEnabled = settings.announcements
            directMessagesEnabled = settings.directMessages
        } catch {
            debugLog("❌ [NotificationsViewModel] Failed to load settings: \(error.localizedDescription)")
        }
    }

    @MainActor
    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        systemNotificationsEnabled = settings.authorizationStatus == .authorized

        // Load settings from API on first load
        await loadSettings()
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func saveSettings(key: String, value: Bool) {
        Task {
            do {
                try await notificationService.updateNotificationSettings(settings: [key: value])
                debugLog("✅ [NotificationsViewModel] Saved \(key) = \(value)")
            } catch {
                debugLog("❌ [NotificationsViewModel] Failed to save \(key): \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NotificationsView()
}
