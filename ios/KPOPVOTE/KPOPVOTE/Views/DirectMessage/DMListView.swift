//
//  DMListView.swift
//  OSHI Pick
//
//  OSHI Pick - DM List View
//

import SwiftUI

struct DMListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = DMListViewModel()
    @State private var selectedConversation: Conversation?
    @State private var showLoginPrompt = false

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                if authService.isGuest {
                    guestView
                } else if viewModel.isLoading && viewModel.conversations.isEmpty {
                    loadingView
                } else if viewModel.conversations.isEmpty {
                    emptyView
                } else {
                    conversationsList
                }
            }
            .navigationTitle("メッセージ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                if !authService.isGuest {
                    await viewModel.loadConversations()
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .fullScreenCover(item: $selectedConversation) { conversation in
                NavigationStack {
                    DMConversationView(conversation: conversation)
                        .onDisappear {
                            // Update unread count when returning
                            viewModel.markConversationAsRead(conversationId: conversation.id)
                        }
                }
            }
            .overlay(
                Group {
                    if showLoginPrompt {
                        LoginPromptView(isPresented: $showLoginPrompt, featureName: "メッセージ")
                    }
                }
            )
        }
    }

    // MARK: - Guest View
    private var guestView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.textGray)

            Text("メッセージ機能を利用するには\nログインが必要です")
                .font(.subheadline)
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)

            Button(action: {
                showLoginPrompt = true
            }) {
                Text("ログイン")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(
                        LinearGradient(
                            colors: [Constants.Colors.gradientPink, Constants.Colors.gradientBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(22)
            }
        }
        .padding()
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("読み込み中...")
                .font(.caption)
                .foregroundColor(Constants.Colors.textGray)
                .padding(.top, 8)
        }
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.textGray)

            Text("メッセージはありません")
                .font(.headline)
                .foregroundColor(Constants.Colors.textWhite)

            Text("相互フォローしているユーザーと\nメッセージを送り合えます")
                .font(.subheadline)
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Conversations List
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.conversations) { conversation in
                    ConversationRowView(conversation: conversation)
                        .onTapGesture {
                            selectedConversation = conversation
                        }

                    Divider()
                        .background(Constants.Colors.textGray.opacity(0.3))
                }

                // Load more trigger
                if viewModel.hasMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .onAppear {
                            Task {
                                await viewModel.loadMoreConversations()
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Conversation Row View
struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: conversation.participantPhotoURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(Constants.Colors.textGray)
                @unknown default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(Constants.Colors.textGray)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // Name and time
                HStack {
                    Text(conversation.participantName ?? "ユーザー")
                        .font(.headline)
                        .foregroundColor(Constants.Colors.textWhite)
                        .lineLimit(1)

                    Spacer()

                    if let lastMessageAt = conversation.lastMessageAt {
                        Text(formatDate(lastMessageAt))
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }

                // Last message and unread badge
                HStack {
                    Text(conversation.lastMessage ?? "")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textGray)
                        .lineLimit(1)

                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Constants.Colors.accentPink)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Constants.Colors.backgroundDark)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Identifiable Extension for Conversation
extension Conversation: Hashable {
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    DMListView()
        .environmentObject(AuthService())
}
