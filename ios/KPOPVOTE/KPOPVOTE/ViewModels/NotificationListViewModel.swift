//
//  NotificationListViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Notification List View Model
//

import Foundation
import Combine

@MainActor
class NotificationListViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMore: Bool = true
    @Published var errorMessage: String? = nil
    @Published var showingUnreadOnly: Bool = false

    private let notificationService = NotificationService.shared
    private var lastNotificationId: String? = nil
    private let pageSize: Int = 20

    // Task management to prevent duplicate requests
    private var loadTask: Task<Void, Never>?
    private var loadMoreTask: Task<Void, Never>?

    // MARK: - Initial Load
    func loadNotifications() async {
        // Cancel existing load task
        loadTask?.cancel()

        guard !isLoading else { return }

        loadTask = Task {
            isLoading = true
            errorMessage = nil
            lastNotificationId = nil

            do {
                // Check if cancelled
                try Task.checkCancellation()

                let result = try await notificationService.fetchNotifications(
                    unreadOnly: showingUnreadOnly,
                    limit: pageSize,
                    lastNotificationId: nil
                )

                // Check again after async operation
                try Task.checkCancellation()

                notifications = result.notifications
                hasMore = result.hasMore
                unreadCount = result.unreadCount

                if let lastNotification = result.notifications.last {
                    lastNotificationId = lastNotification.id
                }

                debugLog("✅ [NotificationListViewModel] Loaded \(result.notifications.count) notifications, unread: \(result.unreadCount)")
            } catch is CancellationError {
                debugLog("⚠️ [NotificationListViewModel] Load cancelled")
            } catch {
                errorMessage = "通知の取得に失敗しました"
                debugLog("❌ [NotificationListViewModel] Failed to load notifications: \(error)")
            }

            isLoading = false
            loadTask = nil
        }

        await loadTask?.value
    }

    // MARK: - Load More (Pagination)
    func loadMoreNotifications() async {
        // Cancel existing load more task
        loadMoreTask?.cancel()

        guard !isLoadingMore && hasMore && !isLoading else { return }

        loadMoreTask = Task {
            isLoadingMore = true

            do {
                try Task.checkCancellation()

                let result = try await notificationService.fetchNotifications(
                    unreadOnly: showingUnreadOnly,
                    limit: pageSize,
                    lastNotificationId: lastNotificationId
                )

                try Task.checkCancellation()

                notifications.append(contentsOf: result.notifications)
                hasMore = result.hasMore
                unreadCount = result.unreadCount

                if let lastNotification = result.notifications.last {
                    lastNotificationId = lastNotification.id
                }

                debugLog("✅ [NotificationListViewModel] Loaded \(result.notifications.count) more notifications")
            } catch is CancellationError {
                debugLog("⚠️ [NotificationListViewModel] Load more cancelled")
            } catch {
                errorMessage = "通知の取得に失敗しました"
                debugLog("❌ [NotificationListViewModel] Failed to load more notifications: \(error)")
            }

            isLoadingMore = false
            loadMoreTask = nil
        }

        await loadMoreTask?.value
    }

    // MARK: - Mark as Read
    func markAsRead(notification: AppNotification) async {
        guard !notification.isRead else { return }

        do {
            try await notificationService.markAsRead(notificationId: notification.id)

            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
                unreadCount = max(0, unreadCount - 1)
            }

            debugLog("✅ [NotificationListViewModel] Marked notification as read: \(notification.id)")
        } catch {
            errorMessage = "既読マークに失敗しました"
            debugLog("❌ [NotificationListViewModel] Failed to mark as read: \(error)")
        }
    }

    // MARK: - Mark All as Read
    func markAllAsRead() async {
        guard unreadCount > 0 else { return }

        do {
            let count = try await notificationService.markAllAsRead()

            // Update local state
            for index in notifications.indices {
                notifications[index].isRead = true
            }
            unreadCount = 0

            debugLog("✅ [NotificationListViewModel] Marked \(count) notifications as read")
        } catch {
            errorMessage = "一括既読マークに失敗しました"
            debugLog("❌ [NotificationListViewModel] Failed to mark all as read: \(error)")
        }
    }

    // MARK: - Toggle Filter
    func toggleUnreadFilter() async {
        showingUnreadOnly.toggle()
        await loadNotifications()
    }

    // MARK: - Refresh
    func refresh() async {
        await loadNotifications()
    }
}
