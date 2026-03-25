//
//  SameBiasUsersView.swift
//  OSHI Pick
//
//  OSHI Pick - Same Bias Users View
//  Shows users who added the same bias in the past 24 hours
//

import SwiftUI

struct SameBiasUsersView: View {
    let biasId: String
    let biasType: String
    let biasName: String

    @StateObject private var viewModel = SameBiasUsersViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedUserId: String?
    @State private var showUserProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .foregroundColor(Constants.Colors.textWhite)
                } else if viewModel.users.isEmpty {
                    emptyStateView
                } else {
                    userListView
                }
            }
            .navigationTitle("新しい\(biasName)ファン")
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
                await viewModel.loadUsers(biasId: biasId, biasType: biasType)
            }
            .sheet(isPresented: $showUserProfile) {
                if let userId = selectedUserId {
                    NavigationStack {
                        UserProfileView(userId: userId)
                    }
                }
            }
        }
    }

    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Constants.Spacing.medium) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.textGray)

            Text("新しいファンはいません")
                .font(.system(size: Constants.Typography.headlineSize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            Text("過去24時間以内に\(biasName)を推しに追加したユーザーはいません")
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: - User List View
    @ViewBuilder
    private var userListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    HStack(spacing: Constants.Spacing.small) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)

                        Text("過去24時間で\(viewModel.users.count)人が参加")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, Constants.Spacing.medium)
                }

                // User List
                ForEach(viewModel.users) { user in
                    SameBiasUserRow(user: user) {
                        selectedUserId = user.userId
                        showUserProfile = true
                    }

                    Divider()
                        .background(Constants.Colors.textGray.opacity(0.3))
                        .padding(.leading, 80)
                }
            }
        }
    }
}

// MARK: - User Row Component
struct SameBiasUserRow: View {
    let user: SameBiasUser
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Constants.Spacing.medium) {
                // Profile Image
                AsyncImage(url: user.photoURL.flatMap { URL(string: $0) }) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(Constants.Colors.textGray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())

                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName ?? "匿名ユーザー")
                        .font(.system(size: Constants.Typography.bodySize, weight: .medium))
                        .foregroundColor(Constants.Colors.textWhite)

                    if let date = user.addedAtDate {
                        Text(formatRelativeTime(from: date))
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
            }
            .padding(.horizontal)
            .padding(.vertical, Constants.Spacing.medium)
        }
        .background(Constants.Colors.backgroundDark)
    }

    private func formatRelativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - View Model
class SameBiasUsersViewModel: ObservableObject {
    @Published var users: [SameBiasUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SameBiasService.shared

    @MainActor
    func loadUsers(biasId: String, biasType: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await service.fetchSameBiasUsers(biasId: biasId, biasType: biasType)
            users = result.users
            debugLog("✅ [SameBiasUsersViewModel] Loaded \(users.count) users")
        } catch {
            errorMessage = error.localizedDescription
            debugLog("❌ [SameBiasUsersViewModel] Error: \(error.localizedDescription)")
        }

        isLoading = false
    }
}

#Preview {
    SameBiasUsersView(biasId: "test123", biasType: "group", biasName: "BTS")
}
