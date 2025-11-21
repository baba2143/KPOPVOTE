//
//  CollectionDetailView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Collection Detail View (Phase 2)
//

import SwiftUI

struct CollectionDetailView: View {
    let collectionId: String
    @StateObject private var viewModel = CollectionViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var showAddToTasksConfirmation = false
    @State private var addToTasksResult: AddToTasksData?

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.currentCollection == nil {
                VStack {
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .foregroundColor(Constants.Colors.textWhite)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(Constants.Colors.textGray)

                    Text(errorMessage)
                        .foregroundColor(Constants.Colors.textGray)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)

                    Button(action: {
                        Task {
                            await viewModel.loadCollectionDetail(collectionId: collectionId)
                        }
                    }) {
                        Text("再試行")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Constants.Colors.accentPink)
                            .cornerRadius(24)
                    }
                }
                .padding()
            } else if let collection = viewModel.currentCollection {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Section
                        CollectionHeaderView(
                            collection: collection,
                            isSaved: viewModel.isSaved,
                            isOwner: viewModel.isOwner
                        )

                        // Action Buttons
                        ActionButtonsView(
                            collection: collection,
                            isSaved: viewModel.isSaved,
                            onSaveToggle: {
                                Task {
                                    let success = await viewModel.toggleSaveCollection(collectionId: collection.id)
                                    if success {
                                        // Haptic feedback
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                    }
                                }
                            },
                            onAddToTasks: {
                                Task {
                                    if let result = await viewModel.addCollectionToTasks(collectionId: collection.id) {
                                        addToTasksResult = result
                                        showAddToTasksConfirmation = true

                                        // Haptic feedback
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)
                                    }
                                }
                            }
                        )
                        .padding(.horizontal)

                        // Tasks Section
                        TasksListView(tasks: collection.tasks)
                            .padding(.horizontal)

                        // Creator Info Section
                        CreatorInfoView(collection: collection)
                            .padding(.horizontal)

                        // Stats Section
                        StatsView(collection: collection)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await viewModel.loadCollectionDetail(collectionId: collectionId)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let collection = viewModel.currentCollection {
                    Menu {
                        Button(action: {
                            // TODO: Share functionality
                        }) {
                            Label("共有", systemImage: "square.and.arrow.up")
                        }

                        if viewModel.isOwner {
                            Button(action: {
                                // TODO: Edit functionality (Week 3)
                            }) {
                                Label("編集", systemImage: "pencil")
                            }

                            Button(role: .destructive, action: {
                                // TODO: Delete functionality
                            }) {
                                Label("削除", systemImage: "trash")
                            }
                        } else {
                            Button(role: .destructive, action: {
                                // TODO: Report functionality
                            }) {
                                Label("報告", systemImage: "exclamationmark.triangle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
        }
        .alert("タスク追加完了", isPresented: $showAddToTasksConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            if let result = addToTasksResult {
                Text("\(result.addedCount)個のタスクを追加しました\n（\(result.skippedCount)個は既に登録済みのためスキップ）")
            }
        }
        .onAppear {
            Task {
                await viewModel.loadCollectionDetail(collectionId: collectionId)
            }
        }
    }
}

// MARK: - Collection Header View
struct CollectionHeaderView: View {
    let collection: VoteCollection
    let isSaved: Bool
    let isOwner: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cover Image
            if let coverUrl = collection.coverImage {
                AsyncImage(url: URL(string: coverUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Constants.Colors.cardDark)
                        .overlay(
                            ProgressView()
                                .tint(Constants.Colors.accentPink)
                        )
                }
                .frame(height: 200)
                .clipped()
            }

            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(collection.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                // Description
                Text(collection.description)
                    .font(.system(size: 16))
                    .foregroundColor(Constants.Colors.textGray)
                    .lineSpacing(4)

                // Tags
                if !collection.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(collection.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Constants.Colors.accentBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Constants.Colors.accentBlue.opacity(0.15))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }

                // Visibility Badge
                HStack(spacing: 4) {
                    Image(systemName: collection.visibility.icon)
                        .font(.system(size: 12))

                    Text(collection.visibility.displayText)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(Constants.Colors.textGray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Constants.Colors.cardDark)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    let collection: VoteCollection
    let isSaved: Bool
    let onSaveToggle: () -> Void
    let onAddToTasks: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Save/Unsave Button
            Button(action: onSaveToggle) {
                HStack(spacing: 8) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .semibold))

                    Text(isSaved ? "保存済み" : "保存")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSaved ? Constants.Colors.accentBlue : Constants.Colors.accentPink)
                .cornerRadius(12)
            }

            // Add to Tasks Button
            Button(action: onAddToTasks) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 16, weight: .semibold))

                    Text("TASKSに追加")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Constants.Colors.gradientPink, Constants.Colors.gradientPurple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Tasks List View
struct TasksListView: View {
    let tasks: [VoteTaskInCollection]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundColor(Constants.Colors.accentPink)
                    .font(.system(size: 16))

                Text("含まれるタスク（\(tasks.count)個）")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()
            }

            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(Constants.Colors.textGray)

                    Text("タスクがありません")
                        .foregroundColor(Constants.Colors.textGray)
                        .font(.system(size: 14))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(tasks.sorted(by: { $0.orderIndex < $1.orderIndex })) { task in
                        CollectionTaskCardView(task: task)
                    }
                }
            }
        }
    }
}

// MARK: - Collection Task Card View
struct CollectionTaskCardView: View {
    let task: VoteTaskInCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // App Icon
                if let iconUrl = task.externalAppIconUrl {
                    AsyncImage(url: URL(string: iconUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "app.fill")
                            .resizable()
                    }
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(Constants.Colors.textGray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)
                        .lineLimit(2)

                    // App Name
                    if let appName = task.externalAppName {
                        Text(appName)
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }

                Spacer()
            }

            // Deadline
            HStack(spacing: 4) {
                Image(systemName: task.isExpired ? "clock.fill" : "clock")
                    .font(.system(size: 12))

                Text(task.isExpired ? "期限切れ" : "残り\(task.timeRemaining)")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(task.isExpired ? Constants.Colors.statusExpired : Constants.Colors.textGray)
        }
        .padding(16)
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Creator Info View
struct CreatorInfoView: View {
    let collection: VoteCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("作成者")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)

            HStack(spacing: 12) {
                // Creator Avatar
                if let avatarUrl = collection.creatorAvatarUrl {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(Constants.Colors.textGray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.creatorName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(formatDate(collection.createdAt) + "に作成")
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)
                }

                Spacer()

                // TODO: Follow button
            }
            .padding(16)
            .background(Constants.Colors.cardDark)
            .cornerRadius(12)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Stats View
struct StatsView: View {
    let collection: VoteCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("統計")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)

            HStack(spacing: 0) {
                StatItemView(
                    icon: "bookmark.fill",
                    value: "\(collection.saveCount)",
                    label: "保存"
                )

                Divider()
                    .background(Constants.Colors.textGray.opacity(0.3))
                    .frame(height: 40)

                StatItemView(
                    icon: "heart.fill",
                    value: "\(collection.likeCount)",
                    label: "いいね"
                )

                Divider()
                    .background(Constants.Colors.textGray.opacity(0.3))
                    .frame(height: 40)

                StatItemView(
                    icon: "eye.fill",
                    value: "\(collection.viewCount)",
                    label: "閲覧"
                )

                Divider()
                    .background(Constants.Colors.textGray.opacity(0.3))
                    .frame(height: 40)

                StatItemView(
                    icon: "message.fill",
                    value: "\(collection.commentCount)",
                    label: "コメント"
                )
            }
            .padding(16)
            .background(Constants.Colors.cardDark)
            .cornerRadius(12)
        }
    }
}

struct StatItemView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.accentPink)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Constants.Colors.textGray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#if DEBUG
struct CollectionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CollectionDetailView(collectionId: "coll_preview")
        }
        .preferredColorScheme(.dark)
    }
}
#endif
