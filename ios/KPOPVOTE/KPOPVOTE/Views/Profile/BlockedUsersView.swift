//
//  BlockedUsersView.swift
//  OSHI Pick
//
//  OSHI Pick - Blocked Users View
//

import SwiftUI

struct BlockedUsersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var blockedUsers: [BlockedUser] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var userToUnblock: BlockedUser?
    @State private var showUnblockConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                } else if blockedUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("ブロックしているユーザーはいません")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(blockedUsers) { user in
                            BlockedUserRow(user: user) {
                                userToUnblock = user
                                showUnblockConfirmation = true
                            }
                            .listRowBackground(Constants.Colors.cardDark)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("ブロックリスト")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                }
            }
            .task {
                await loadBlockedUsers()
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .alert("ブロック解除", isPresented: $showUnblockConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("解除する", role: .destructive) {
                    if let user = userToUnblock {
                        Task {
                            await unblockUser(user)
                        }
                    }
                }
            } message: {
                if let user = userToUnblock {
                    Text("\(user.displayName)さんのブロックを解除しますか？")
                }
            }
        }
    }

    private func loadBlockedUsers() async {
        isLoading = true
        do {
            blockedUsers = try await BlockService.shared.getBlockedUsersList()
        } catch {
            errorMessage = "ブロックリストの読み込みに失敗しました"
            showError = true
        }
        isLoading = false
    }

    private func unblockUser(_ user: BlockedUser) async {
        do {
            try await BlockService.shared.unblockUser(userId: user.userId)
            blockedUsers.removeAll { $0.id == user.id }
        } catch {
            errorMessage = "ブロック解除に失敗しました"
            showError = true
        }
    }
}

struct BlockedUserRow: View {
    let user: BlockedUser
    let onUnblock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: user.photoURL.flatMap { URL(string: $0) }) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("ブロック日: \(formattedDate(user.blockedAt))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: onUnblock) {
                Text("解除")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray)
                    .cornerRadius(16)
            }
        }
        .padding(.vertical, 8)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

#Preview {
    BlockedUsersView()
}
