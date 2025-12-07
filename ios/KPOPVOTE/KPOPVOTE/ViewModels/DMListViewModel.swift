//
//  DMListViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - DM List ViewModel
//

import Foundation
import Combine

@MainActor
class DMListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalUnreadCount: Int = 0

    // MARK: - Pagination
    @Published var hasMore = false
    private var lastConversationId: String?

    // MARK: - Load Conversations
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        lastConversationId = nil

        do {
            print("📱 [DMListViewModel] Loading conversations")
            let result = try await DirectMessageService.shared.fetchConversations(limit: 20, lastConversationId: nil)
            conversations = result.conversations
            hasMore = result.hasMore
            totalUnreadCount = result.totalUnreadCount
            lastConversationId = conversations.last?.id
            print("✅ [DMListViewModel] Loaded \(conversations.count) conversations, unread: \(totalUnreadCount)")
        } catch {
            print("❌ [DMListViewModel] Failed to load conversations: \(error)")
            errorMessage = error.localizedDescription
            conversations = []
            hasMore = false
        }

        isLoading = false
    }

    // MARK: - Load More Conversations
    func loadMoreConversations() async {
        guard hasMore, !isLoading, let lastConversationId = lastConversationId else { return }

        isLoading = true

        do {
            print("📱 [DMListViewModel] Loading more conversations after: \(lastConversationId)")
            let result = try await DirectMessageService.shared.fetchConversations(limit: 20, lastConversationId: lastConversationId)
            conversations.append(contentsOf: result.conversations)
            hasMore = result.hasMore
            self.lastConversationId = conversations.last?.id
            print("✅ [DMListViewModel] Loaded \(result.conversations.count) more conversations")
        } catch {
            print("❌ [DMListViewModel] Failed to load more conversations: \(error)")
        }

        isLoading = false
    }

    // MARK: - Refresh
    func refresh() async {
        await loadConversations()
    }

    // MARK: - Update Conversation After Read
    func markConversationAsRead(conversationId: String) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            let conversation = conversations[index]
            // Create updated conversation with zero unread
            let updatedConversation = Conversation(
                id: conversation.id,
                participantId: conversation.participantId,
                participantName: conversation.participantName,
                participantPhotoURL: conversation.participantPhotoURL,
                lastMessage: conversation.lastMessage,
                lastMessageAt: conversation.lastMessageAt,
                unreadCount: 0,
                updatedAt: conversation.updatedAt
            )
            conversations[index] = updatedConversation
            // Update total unread count
            totalUnreadCount = max(0, totalUnreadCount - conversation.unreadCount)
        }
    }
}
