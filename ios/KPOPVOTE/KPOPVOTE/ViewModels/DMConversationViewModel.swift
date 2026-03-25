//
//  DMConversationViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - DM Conversation ViewModel
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class DMConversationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [DirectMessage] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var inputText: String = ""

    // MARK: - Pagination
    @Published var hasMore = false
    private var lastMessageId: String?

    // MARK: - Conversation Info
    let conversationId: String
    let participantId: String
    let participantName: String?
    let participantPhotoURL: String?

    // MARK: - Current User
    var currentUserId: String {
        Auth.auth().currentUser?.uid ?? ""
    }

    // MARK: - Initializer
    init(conversationId: String, participantId: String, participantName: String?, participantPhotoURL: String?) {
        self.conversationId = conversationId
        self.participantId = participantId
        self.participantName = participantName
        self.participantPhotoURL = participantPhotoURL
    }

    // MARK: - Convenience Initializer from Conversation
    convenience init(conversation: Conversation) {
        self.init(
            conversationId: conversation.id,
            participantId: conversation.participantId,
            participantName: conversation.participantName,
            participantPhotoURL: conversation.participantPhotoURL
        )
    }

    // MARK: - Convenience Initializer for New Conversation
    convenience init(recipientId: String, recipientName: String?, recipientPhotoURL: String?) {
        // Generate conversation ID (will be created by backend if doesn't exist)
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let sorted = [currentUserId, recipientId].sorted()
        let conversationId = "\(sorted[0])_\(sorted[1])"

        self.init(
            conversationId: conversationId,
            participantId: recipientId,
            participantName: recipientName,
            participantPhotoURL: recipientPhotoURL
        )
    }

    // MARK: - Load Messages
    func loadMessages() async {
        isLoading = true
        errorMessage = nil
        lastMessageId = nil

        do {
            debugLog("📱 [DMConversationViewModel] Loading messages for: \(conversationId)")
            let result = try await DirectMessageService.shared.fetchMessages(conversationId: conversationId, limit: 50, lastMessageId: nil)
            // Messages come newest first, reverse for display (oldest at top)
            messages = result.messages.reversed()
            hasMore = result.hasMore
            lastMessageId = result.messages.last?.id
            debugLog("✅ [DMConversationViewModel] Loaded \(messages.count) messages")

            // Mark as read
            try? await DirectMessageService.shared.markAsRead(conversationId: conversationId)
        } catch DirectMessageError.conversationNotFound {
            // New conversation - no messages yet, this is normal
            debugLog("ℹ️ [DMConversationViewModel] New conversation, no messages yet")
            messages = []
            hasMore = false
            // Don't set errorMessage - this is expected for new conversations
        } catch {
            debugLog("❌ [DMConversationViewModel] Failed to load messages: \(error)")
            errorMessage = error.localizedDescription
            messages = []
            hasMore = false
        }

        isLoading = false
    }

    // MARK: - Load More Messages (Older)
    func loadMoreMessages() async {
        guard hasMore, !isLoading, let lastMessageId = lastMessageId else { return }

        isLoading = true

        do {
            debugLog("📱 [DMConversationViewModel] Loading more messages before: \(lastMessageId)")
            let result = try await DirectMessageService.shared.fetchMessages(conversationId: conversationId, limit: 50, lastMessageId: lastMessageId)
            // Insert older messages at the beginning
            let olderMessages = result.messages.reversed()
            messages.insert(contentsOf: olderMessages, at: 0)
            hasMore = result.hasMore
            self.lastMessageId = result.messages.last?.id
            debugLog("✅ [DMConversationViewModel] Loaded \(result.messages.count) more messages")
        } catch {
            debugLog("❌ [DMConversationViewModel] Failed to load more messages: \(error)")
        }

        isLoading = false
    }

    // MARK: - Send Message
    func sendMessage() async {
        // 重複呼び出し防止
        guard !isSending else {
            debugLog("⚠️ [DMConversationViewModel] Already sending message, ignoring duplicate call")
            return
        }

        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        defer { isSending = false }
        errorMessage = nil
        let messageToSend = text
        inputText = "" // Clear immediately for better UX

        do {
            debugLog("📱 [DMConversationViewModel] Sending message to: \(participantId)")
            let result = try await DirectMessageService.shared.sendMessage(recipientId: participantId, text: messageToSend)

            // Create optimistic message for immediate display
            let newMessage = DirectMessage(
                id: result.messageId,
                conversationId: result.conversationId,
                senderId: currentUserId,
                senderName: nil,
                senderPhotoURL: nil,
                text: messageToSend,
                imageURL: nil,
                isRead: false,
                createdAt: Date()
            )
            messages.append(newMessage)
            debugLog("✅ [DMConversationViewModel] Message sent: \(result.messageId)")
        } catch DirectMessageError.mutualFollowRequired {
            debugLog("❌ [DMConversationViewModel] Mutual follow required")
            errorMessage = "相互フォローのユーザーにのみDMを送信できます"
            inputText = messageToSend // Restore text on error
        } catch {
            debugLog("❌ [DMConversationViewModel] Failed to send message: \(error)")
            errorMessage = error.localizedDescription
            inputText = messageToSend // Restore text on error
        }
    }

    // MARK: - Send Image Message
    func sendImageMessage(imageURL: String) async {
        // 重複呼び出し防止
        guard !isSending else {
            debugLog("⚠️ [DMConversationViewModel] Already sending image, ignoring duplicate call")
            return
        }

        isSending = true
        defer { isSending = false }
        errorMessage = nil

        do {
            debugLog("📱 [DMConversationViewModel] Sending image to: \(participantId)")
            let result = try await DirectMessageService.shared.sendMessage(recipientId: participantId, imageURL: imageURL)

            // Create optimistic message for immediate display
            let newMessage = DirectMessage(
                id: result.messageId,
                conversationId: result.conversationId,
                senderId: currentUserId,
                senderName: nil,
                senderPhotoURL: nil,
                text: nil,
                imageURL: imageURL,
                isRead: false,
                createdAt: Date()
            )
            messages.append(newMessage)
            debugLog("✅ [DMConversationViewModel] Image sent: \(result.messageId)")
        } catch DirectMessageError.mutualFollowRequired {
            debugLog("❌ [DMConversationViewModel] Mutual follow required")
            errorMessage = "相互フォローのユーザーにのみDMを送信できます"
        } catch {
            debugLog("❌ [DMConversationViewModel] Failed to send image: \(error)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh
    func refresh() async {
        await loadMessages()
    }

    // MARK: - Check if message is from current user
    func isOwnMessage(_ message: DirectMessage) -> Bool {
        message.senderId == currentUserId
    }
}
