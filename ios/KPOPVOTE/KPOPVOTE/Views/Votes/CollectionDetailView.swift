//
//  CollectionDetailView.swift
//  OSHI Pick
//
//  OSHI Pick - Collection Detail View (Phase 2)
//

import SwiftUI
import UIKit

struct CollectionDetailView: View {
    let collectionId: String
    @StateObject private var viewModel = CollectionViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tabCoordinator: TabCoordinator
    @EnvironmentObject var authService: AuthService

    @State private var showAddToTasksConfirmation = false
    @State private var addToTasksResult: AddToTasksData?

    @State private var showSingleTaskConfirmation = false
    @State private var selectedTask: VoteTaskInCollection?
    @State private var singleTaskResult: AddSingleTaskData?
    @State private var showSingleTaskSuccess = false

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var showReportSheet = false

    private var isGuest: Bool {
        AppStorageManager.shared.isGuestMode
    }

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            if isGuest {
                // ゲストモード - ログイン促進画面
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 64))
                        .foregroundColor(Constants.Colors.accentPink)

                    Text("ログインが必要です")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text("コレクションの詳細を見るには\nログインしてください")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        Button(action: {
                            dismiss()
                            authService.exitGuestMode()
                        }) {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("ログイン・新規登録")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Constants.Colors.accentPink)
                            .cornerRadius(24)
                        }
                        .padding(.horizontal, 32)

                        Button(action: { dismiss() }) {
                            Text("閉じる")
                                .font(.system(size: 14))
                                .foregroundColor(Constants.Colors.textGray)
                        }
                    }
                }
                .padding()
            } else if viewModel.isLoading && viewModel.currentCollection == nil {
                VStack {
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .foregroundColor(Constants.Colors.textWhite)
                    Text("CollectionID: \(collectionId)")
                        .foregroundColor(Constants.Colors.textGray)
                        .font(.system(size: 12))
                        .padding(.top, 8)
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
                        print("🔄 [CollectionDetailView] Retry button tapped for: \(collectionId)")
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

                                        // Haptic feedback for success
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)

                                        showAddToTasksConfirmation = true
                                    }
                                }
                            }
                        )
                        .padding(.horizontal)

                        // Tasks Section
                        CollectionTasksListView(
                            tasks: collection.tasks,
                            onTaskTap: { task in
                                selectedTask = task
                                showSingleTaskConfirmation = true
                            }
                        )
                        .padding(.horizontal)

                        // Creator Info Section
                        CreatorInfoView(
                            collection: collection,
                            isOwner: viewModel.isOwner,
                            isFollowingCreator: viewModel.isFollowingCreator,
                            onToggleFollow: {
                                Task {
                                    await viewModel.toggleFollowCreator()
                                }
                            }
                        )
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if let collection = viewModel.currentCollection {
                    Menu {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("共有", systemImage: "square.and.arrow.up")
                        }

                        if viewModel.isOwner {
                            Button(action: {
                                showEditSheet = true
                            }) {
                                Label("編集", systemImage: "pencil")
                            }

                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                            }) {
                                Label("削除", systemImage: "trash")
                            }
                        } else {
                            Button(role: .destructive, action: {
                                showReportSheet = true
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
            Button("TASKSで確認", role: .none) {
                // Dismiss sheet first, then navigate to TASKS tab
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    tabCoordinator.navigateToTasks()
                }
            }
            Button("閉じる", role: .cancel) { }
        } message: {
            if let result = addToTasksResult {
                Text("\(result.addedCount)個のタスクを追加しました\n（\(result.skippedCount)個は既に登録済みのためスキップ）")
            }
        }
        .alert("タスクを追加", isPresented: $showSingleTaskConfirmation) {
            Button("追加", role: .none) {
                Task {
                    guard let task = selectedTask else { return }
                    if let result = await viewModel.addSingleTask(
                        collectionId: collectionId,
                        task: task
                    ) {
                        singleTaskResult = result

                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)

                        showSingleTaskSuccess = true
                    }
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            if let task = selectedTask {
                Text("「\(task.title)」をTASKSに追加しますか？")
            }
        }
        .alert("タスク追加完了", isPresented: $showSingleTaskSuccess) {
            Button("TASKSで確認", role: .none) {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    tabCoordinator.navigateToTasks()
                }
            }
            Button("閉じる", role: .cancel) { }
        } message: {
            if let result = singleTaskResult {
                if result.alreadyAdded {
                    Text("このタスクは既に追加されています")
                } else {
                    Text("TASKSに追加しました。TASKSで確認しますか？")
                }
            }
        }
        .fullScreenCover(isPresented: $showEditSheet) {
            Group {
                if let collection = viewModel.currentCollection {
                    EditCollectionView(collectionId: collection.id)
                        .onDisappear {
                            // Reload collection data after edit
                            Task {
                                await viewModel.loadCollectionDetail(collectionId: collectionId)
                            }
                        }
                }
            }
        }
        .alert("コレクションを削除", isPresented: $showDeleteConfirmation) {
            Button("削除", role: .destructive) {
                // Optimistic UI - dismiss immediately
                dismiss()

                // Delete in background
                Task {
                    let success = await viewModel.deleteCollection(collectionId: collectionId)
                    if !success {
                        // Error is handled by viewModel (errorMessage is set)
                        debugLog("⚠️ [CollectionDetailView] Collection deletion failed in background")
                    }
                }
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("このコレクションを削除してもよろしいですか？この操作は取り消せません。")
        }
        .fullScreenCover(isPresented: $showShareSheet) {
            Group {
                if let collection = viewModel.currentCollection {
                    ShareSheet(activityItems: [
                        "「\(collection.title)」をチェック！\n\(collection.description)\n\n#KPOPVOTE",
                        URL(string: "https://kpopvote.app/collections/\(collection.id)")!
                    ])
                }
            }
        }
        .fullScreenCover(isPresented: $showReportSheet) {
            Group {
                if let collection = viewModel.currentCollection {
                    ReportCollectionView(collectionId: collection.id, collectionTitle: collection.title, creatorId: collection.creatorId)
                }
            }
        }
        .onAppear {
            print("📱 [CollectionDetailView] onAppear - collectionId: \(collectionId)")
            Task {
                print("📱 [CollectionDetailView] Starting to load collection detail...")
                await viewModel.loadCollectionDetail(collectionId: collectionId)
                print("📱 [CollectionDetailView] Finished loading. currentCollection: \(viewModel.currentCollection?.title ?? "nil"), error: \(viewModel.errorMessage ?? "none")")
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
struct CollectionTasksListView: View {
    let tasks: [VoteTaskInCollection]
    let onTaskTap: (VoteTaskInCollection) -> Void

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
                            .onTapGesture {
                                onTaskTap(task)
                            }
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
    let isOwner: Bool
    let isFollowingCreator: Bool
    let onToggleFollow: () -> Void

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

                // Follow button (only show if not owner)
                if !isOwner {
                    Button(action: onToggleFollow) {
                        HStack(spacing: 4) {
                            Image(systemName: isFollowingCreator ? "person.badge.minus" : "person.badge.plus")
                                .font(.system(size: 14))
                            Text(isFollowingCreator ? "フォロー中" : "フォロー")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(isFollowingCreator ? Constants.Colors.textGray : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isFollowingCreator ? Constants.Colors.cardDark : Constants.Colors.accentPink)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isFollowingCreator ? Constants.Colors.textGray : Color.clear, lineWidth: 1)
                        )
                    }
                }
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

// ShareSheet moved to Utilities/ShareSheet.swift

// MARK: - Report Collection View
struct ReportCollectionView: View {
    let collectionId: String
    let collectionTitle: String
    let creatorId: String
    @Environment(\.dismiss) var dismiss

    @State private var selectedReason: ReportReason?
    @State private var additionalComment: String = ""
    @State private var blockUser = false
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false

    enum ReportReason: String, CaseIterable {
        case spam = "スパム・宣伝"
        case inappropriate = "不適切なコンテンツ"
        case copyright = "著作権侵害"
        case harassment = "嫌がらせ・誹謗中傷"
        case other = "その他"

        var description: String {
            return self.rawValue
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("「\(collectionTitle)」を報告")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Constants.Colors.textWhite)
                            .padding(.top, 16)

                        // Reason Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("報告理由を選択")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Constants.Colors.textWhite)

                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                ReportReasonRow(
                                    reason: reason,
                                    isSelected: selectedReason == reason,
                                    onTap: { selectedReason = reason }
                                )
                            }
                        }

                        // Additional Comment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("追加コメント（任意）")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Constants.Colors.textWhite)

                            TextEditor(text: $additionalComment)
                                .frame(height: 100)
                                .padding(8)
                                .background(Constants.Colors.cardDark)
                                .cornerRadius(8)
                                .foregroundColor(Constants.Colors.textWhite)
                        }

                        // Block User Option
                        if !creatorId.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $blockUser) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundColor(.red)
                                        Text("このユーザーをブロック")
                                            .foregroundColor(Constants.Colors.textWhite)
                                    }
                                }
                                .tint(.red)

                                Text("ブロックすると、このユーザーのコンテンツが表示されなくなります")
                                    .font(.system(size: 12))
                                    .foregroundColor(Constants.Colors.textGray)
                            }
                        }

                        // Submit Button
                        Button(action: submitReport) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("報告する")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedReason != nil ? Color.red : Constants.Colors.textGray)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(selectedReason == nil || isSubmitting)

                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .dismissKeyboardOnTap()
                .keyboardDoneButton()
            }
            .navigationTitle("報告")
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
            .alert("報告を送信しました", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("ご報告いただきありがとうございます。内容を確認の上、適切に対応いたします。")
            }
        }
    }

    private func submitReport() {
        guard let reason = selectedReason else { return }

        isSubmitting = true

        // Submit report to Firestore
        Task {
            do {
                try await ReportService.shared.submitReport(
                    collectionId: collectionId,
                    reason: reason.rawValue,
                    comment: additionalComment
                )

                // Block user if requested
                if blockUser && !creatorId.isEmpty {
                    try await BlockService.shared.blockUser(userId: creatorId)
                    // Post notification to refresh feeds
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("UserBlocked"),
                            object: nil,
                            userInfo: ["userId": creatorId]
                        )
                    }
                }

                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // Handle error (could show an alert)
                    print("❌ [ReportCollectionView] Failed to submit report: \(error)")
                }
            }
        }
    }
}

struct ReportReasonRow: View {
    let reason: ReportCollectionView.ReportReason
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(reason.description)
                    .font(.system(size: 16))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)
            }
            .padding(16)
            .background(Constants.Colors.cardDark)
            .cornerRadius(8)
        }
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
