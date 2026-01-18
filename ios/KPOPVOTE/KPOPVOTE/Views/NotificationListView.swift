//
//  NotificationListView.swift
//  OSHI Pick
//
//  OSHI Pick - Notification List View
//

import SwiftUI

struct NotificationListView: View {
    @StateObject private var viewModel = NotificationListViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Filter and Actions Bar
                filterBar

                // Notification List
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    loadingView
                } else if viewModel.notifications.isEmpty {
                    emptyView
                } else {
                    notificationListView
                }
            }
        }
        .task {
            await viewModel.loadNotifications()
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil), presenting: viewModel.errorMessage) { _ in
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Constants.Colors.textWhite)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text("通知")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)

            Spacer()

            // Unread count badge
            ZStack {
                if viewModel.unreadCount > 0 {
                    Text("\(viewModel.unreadCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Constants.Colors.statusUrgent)
                        .clipShape(Capsule())
                } else {
                    Color.clear
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Constants.Colors.backgroundDark)
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        HStack(spacing: 12) {
            // Unread filter button
            Button(action: {
                Task {
                    await viewModel.toggleUnreadFilter()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.showingUnreadOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16))
                    Text(viewModel.showingUnreadOnly ? "未読のみ" : "すべて")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(viewModel.showingUnreadOnly ? Constants.Colors.accentPink : Constants.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    viewModel.showingUnreadOnly ?
                    Constants.Colors.accentPink.opacity(0.15) :
                    Constants.Colors.cardDark
                )
                .clipShape(Capsule())
            }

            Spacer()

            // Mark all as read button
            if viewModel.unreadCount > 0 {
                Button(action: {
                    Task {
                        await viewModel.markAllAsRead()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("すべて既読")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Constants.Colors.accentBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Constants.Colors.accentBlue.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Constants.Colors.backgroundDark)
    }

    // MARK: - Notification List
    private var notificationListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.notifications) { notification in
                    NotificationRow(notification: notification) {
                        Task {
                            await viewModel.markAsRead(notification: notification)
                        }
                    }
                    .onAppear {
                        // Load more when reaching the last item
                        if notification.id == viewModel.notifications.last?.id {
                            Task {
                                await viewModel.loadMoreNotifications()
                            }
                        }
                    }
                }

                // Loading more indicator
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Constants.Colors.accentPink)
                            .padding()
                        Spacer()
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Constants.Colors.accentPink)
                .scaleEffect(1.2)
            Text("読み込み中...")
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(Constants.Colors.textSecondary)
            Text(viewModel.showingUnreadOnly ? "未読の通知はありません" : "通知はありません")
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 40, height: 40)

                    Image(systemName: notification.type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(notification.displayTitle)
                            .font(.system(size: 15, weight: notification.isRead ? .regular : .semibold))
                            .foregroundColor(Constants.Colors.textWhite)
                            .lineLimit(2)

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(Constants.Colors.accentPink)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(notification.body)
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textSecondary)
                        .lineLimit(2)

                    Text(notification.formattedCreatedAt)
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(notification.isRead ? Constants.Colors.backgroundDark : Constants.Colors.cardDark.opacity(0.5))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var iconBackgroundColor: Color {
        switch notification.type {
        case .follow:
            return Color.purple
        case .like:
            return Color.red
        case .comment:
            return Color.blue
        case .mention:
            return Color.cyan
        case .vote:
            return Color.pink
        case .system:
            return Color.green
        }
    }
}

// MARK: - Preview
struct NotificationListView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationListView()
    }
}
