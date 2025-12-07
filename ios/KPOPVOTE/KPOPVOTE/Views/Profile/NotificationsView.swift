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
            .navigationTitle("Notifications")
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

                Text("Push Notifications")
                    .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)
            }

            Toggle(isOn: $viewModel.pushEnabled) {
                Text("Enable Push Notifications")
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
            Text("Notification Types")
                .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)
                .padding(.bottom, Constants.Spacing.small)

            VStack(spacing: 0) {
                NotificationToggleRow(
                    icon: "heart.fill",
                    title: "Likes",
                    subtitle: "When someone likes your content",
                    color: .red,
                    isOn: $viewModel.likesEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "bubble.left.fill",
                    title: "Comments",
                    subtitle: "When someone comments on your post",
                    color: .blue,
                    isOn: $viewModel.commentsEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "person.fill.badge.plus",
                    title: "Followers",
                    subtitle: "When someone follows you",
                    color: .purple,
                    isOn: $viewModel.followersEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "checkmark.square.fill",
                    title: "Vote Reminders",
                    subtitle: "Reminders for upcoming votes",
                    color: Constants.Colors.accentPink,
                    isOn: $viewModel.voteRemindersEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "calendar.badge.clock",
                    title: "Calendar Reminders",
                    subtitle: "Event and schedule notifications",
                    color: .orange,
                    isOn: $viewModel.calendarRemindersEnabled
                )

                Divider()
                    .padding(.leading, 60)
                    .background(Constants.Colors.textGray.opacity(0.3))

                NotificationToggleRow(
                    icon: "megaphone.fill",
                    title: "Announcements",
                    subtitle: "Important app updates and news",
                    color: .green,
                    isOn: $viewModel.announcementsEnabled
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

            Text("Notifications Disabled")
                .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            Text("Enable notifications in Settings to receive updates about votes, comments, and more.")
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)

            Button {
                viewModel.openSettings()
            } label: {
                Text("Open Settings")
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
    @Published var pushEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var likesEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var commentsEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var followersEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var voteRemindersEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var calendarRemindersEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var announcementsEnabled: Bool {
        didSet { saveSettings() }
    }

    private let defaults = UserDefaults.standard

    init() {
        // Load saved settings
        pushEnabled = defaults.bool(forKey: "notifications_push_enabled")
        likesEnabled = defaults.object(forKey: "notifications_likes") as? Bool ?? true
        commentsEnabled = defaults.object(forKey: "notifications_comments") as? Bool ?? true
        followersEnabled = defaults.object(forKey: "notifications_followers") as? Bool ?? true
        voteRemindersEnabled = defaults.object(forKey: "notifications_vote_reminders") as? Bool ?? true
        calendarRemindersEnabled = defaults.object(forKey: "notifications_calendar_reminders") as? Bool ?? true
        announcementsEnabled = defaults.object(forKey: "notifications_announcements") as? Bool ?? true
    }

    @MainActor
    func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        systemNotificationsEnabled = settings.authorizationStatus == .authorized
    }

    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func saveSettings() {
        defaults.set(pushEnabled, forKey: "notifications_push_enabled")
        defaults.set(likesEnabled, forKey: "notifications_likes")
        defaults.set(commentsEnabled, forKey: "notifications_comments")
        defaults.set(followersEnabled, forKey: "notifications_followers")
        defaults.set(voteRemindersEnabled, forKey: "notifications_vote_reminders")
        defaults.set(calendarRemindersEnabled, forKey: "notifications_calendar_reminders")
        defaults.set(announcementsEnabled, forKey: "notifications_announcements")
    }
}

#Preview {
    NotificationsView()
}
