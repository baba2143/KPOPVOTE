//
//  DMConversationView.swift
//  OSHI Pick
//
//  OSHI Pick - DM Conversation View
//

import SwiftUI

struct DMConversationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DMConversationViewModel
    @FocusState private var isInputFocused: Bool

    // Report states
    @State private var showReportUserSheet = false
    @State private var showReportMessageSheet = false
    @State private var messageToReport: DirectMessage?

    init(conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: DMConversationViewModel(conversation: conversation))
    }

    init(recipientId: String, recipientName: String?, recipientPhotoURL: String?) {
        _viewModel = StateObject(wrappedValue: DMConversationViewModel(
            recipientId: recipientId,
            recipientName: recipientName,
            recipientPhotoURL: recipientPhotoURL
        ))
    }

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                messagesScrollView

                // Input area
                messageInputArea
            }
        }
        .navigationTitle(viewModel.participantName ?? "メッセージ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showReportUserSheet = true
                    } label: {
                        Label("ユーザーを通報", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }
        }
        .task {
            await viewModel.loadMessages()
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showReportUserSheet) {
            DMReportView(
                reportType: .user,
                conversationId: viewModel.conversationId,
                reporteeId: viewModel.participantId,
                reporteeName: viewModel.participantName,
                message: nil
            )
        }
        .fullScreenCover(isPresented: $showReportMessageSheet) {
            Group {
                if let message = messageToReport {
                    DMReportView(
                        reportType: .message,
                        conversationId: viewModel.conversationId,
                        reporteeId: message.senderId,
                        reporteeName: viewModel.participantName,
                        message: message
                    )
                }
            }
        }
    }

    // MARK: - Messages Scroll View
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Load more trigger at top
                    if viewModel.hasMore {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreMessages()
                                }
                            }
                    }

                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isOwnMessage: viewModel.isOwnMessage(message),
                            onReport: {
                                messageToReport = message
                                showReportMessageSheet = true
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .onChange(of: viewModel.messages.count) { _ in
                // Scroll to bottom when new messages are added
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                // Scroll to bottom on appear
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Message Input Area
    private var messageInputArea: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("メッセージを入力", text: $viewModel.inputText, axis: .vertical)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Constants.Colors.cardDark)
                .cornerRadius(20)
                .foregroundColor(Constants.Colors.textWhite)
                .focused($isInputFocused)
                .lineLimit(1...5)

            // Send button
            Button(action: {
                Task {
                    await viewModel.sendMessage()
                }
            }) {
                if viewModel.isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Constants.Colors.textGray
                            : Constants.Colors.accentPink
                        )
                        .clipShape(Circle())
                }
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Constants.Colors.backgroundDark)
    }
}

// MARK: - Message Bubble View
struct MessageBubbleView: View {
    let message: DirectMessage
    let isOwnMessage: Bool
    let onReport: () -> Void

    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer(minLength: 60)
            }

            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                // Text content
                if let text = message.text, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .foregroundColor(isOwnMessage ? .white : Constants.Colors.textWhite)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            isOwnMessage
                            ? LinearGradient(
                                colors: [Constants.Colors.gradientPink, Constants.Colors.gradientPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Constants.Colors.cardDark, Constants.Colors.cardDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)
                }

                // Image content
                if let imageURL = message.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(Constants.Colors.textGray)
                                .frame(width: 100, height: 100)
                                .background(Constants.Colors.cardDark)
                                .cornerRadius(12)
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }

                // Time
                Text(formatTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(Constants.Colors.textGray)
            }
            .contextMenu {
                // Only show report option for other user's messages
                if !isOwnMessage {
                    Button(role: .destructive) {
                        onReport()
                    } label: {
                        Label("メッセージを通報", systemImage: "exclamationmark.triangle")
                    }
                }
            }

            if !isOwnMessage {
                Spacer(minLength: 60)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        DMConversationView(
            recipientId: "user123",
            recipientName: "テストユーザー",
            recipientPhotoURL: nil
        )
    }
}
