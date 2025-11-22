//
//  CreateCollectionView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Create Collection View (Phase 2 - Week 3)
//

import SwiftUI
import FirebaseAuth

struct CreateCollectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateCollectionViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else {
                    formContent
                }
            }
            .navigationTitle("新規コレクション")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "コレクションの作成に失敗しました")
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(selectedImage: $viewModel.coverImage)
            }
            .sheet(isPresented: $viewModel.showBiasSelectionSheet) {
                BiasSelectionSheet { selectedBiasIds in
                    Task {
                        await viewModel.shareToCommunity(biasIds: selectedBiasIds)
                        // If sharing succeeded, dismiss the create collection view
                        if !viewModel.showError {
                            dismiss()
                        }
                    }
                }
            }
            .alert("コレクションを作成しました", isPresented: $viewModel.showCommunityShareDialog) {
                Button("はい") {
                    viewModel.showBiasSelectionSheet = true
                }
                Button("いいえ") {
                    dismiss()
                }
            } message: {
                Text("コミュニティに投稿しますか？")
            }
            .overlay {
                if viewModel.isSharing {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                .scaleEffect(1.5)

                            Text("コミュニティに投稿中...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Constants.Colors.textWhite)
                        }
                        .padding(32)
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(16)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadUserTasks()
                }
            }
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView("作成中...")
                .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                .foregroundColor(Constants.Colors.textWhite)
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                            // Cover Image Section
                            CoverImageSectionView(
                                coverImage: $viewModel.coverImage,
                                onSelectImage: {
                                    viewModel.showImagePicker = true
                                }
                            )

                            // Title Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("タイトル")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textWhite)

                                TextField("コレクションのタイトル（最大50文字）", text: $viewModel.title)
                                    .textFieldStyle(UnifiedTextFieldStyle())

                                HStack {
                                    Spacer()
                                    Text("\(viewModel.title.count)/50")
                                        .font(.system(size: 12))
                                        .foregroundColor(viewModel.title.count > 50 ? .red : Constants.Colors.textGray)
                                }
                            }
                            .padding(.horizontal)

                            // Description Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("説明")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textWhite)

                                TextEditor(text: $viewModel.description)
                                    .frame(height: 120)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .background(Constants.Colors.cardDark)
                                    .cornerRadius(12)
                                    .tint(Constants.Colors.accentPink)
                                    .foregroundStyle(.white)

                                HStack {
                                    Spacer()
                                    Text("\(viewModel.description.count)/500")
                                        .font(.system(size: 12))
                                        .foregroundColor(viewModel.description.count > 500 ? .red : Constants.Colors.textGray)
                                }
                            }
                            .padding(.horizontal)

                            // Tags Input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("タグ")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textWhite)

                                TagInputView(tags: $viewModel.tags)
                            }
                            .padding(.horizontal)

                            // Task Selection
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("タスク選択")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Constants.Colors.textWhite)

                                    Spacer()

                                    Text("\(viewModel.selectedTasks.count)/50")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(viewModel.selectedTasks.count > 50 ? .red : Constants.Colors.accentPink)
                                }

                                if viewModel.userTasks.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "tray")
                                            .font(.system(size: 32))
                                            .foregroundColor(Constants.Colors.textGray)

                                        Text("タスクがありません")
                                            .foregroundColor(Constants.Colors.textGray)
                                            .font(.system(size: 14))

                                        Text("先にTASKSタブでタスクを登録してください")
                                            .foregroundColor(Constants.Colors.textGray)
                                            .font(.system(size: 12))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 32)
                                    .background(Constants.Colors.cardDark)
                                    .cornerRadius(12)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.userTasks) { task in
                                            TaskSelectionRow(
                                                task: task,
                                                isSelected: viewModel.selectedTasks.contains(where: { $0.id == task.id }),
                                                onToggle: {
                                                    viewModel.toggleTaskSelection(task)
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // Visibility Settings
                            VStack(alignment: .leading, spacing: 12) {
                                Text("公開範囲")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textWhite)

                                VStack(spacing: 0) {
                                    VisibilityOptionRow(
                                        visibility: .public,
                                        isSelected: viewModel.visibility == .public,
                                        onSelect: {
                                            viewModel.visibility = .public
                                        }
                                    )

                                    Divider()
                                        .background(Constants.Colors.textGray.opacity(0.3))

                                    VisibilityOptionRow(
                                        visibility: .followers,
                                        isSelected: viewModel.visibility == .followers,
                                        onSelect: {
                                            viewModel.visibility = .followers
                                        }
                                    )

                                    Divider()
                                        .background(Constants.Colors.textGray.opacity(0.3))

                                    VisibilityOptionRow(
                                        visibility: .private,
                                        isSelected: viewModel.visibility == .private,
                                        onSelect: {
                                            viewModel.visibility = .private
                                        }
                                    )
                                }
                                .background(Constants.Colors.cardDark)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            // Create Button
                            Button(action: {
                                Task {
                                    await viewModel.createCollection()
                                    // Dialog will be shown by viewModel.showCommunityShareDialog
                                }
                            }) {
                                Text("コレクションを作成")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        viewModel.canCreate ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [Constants.Colors.gradientPink, Constants.Colors.gradientPurple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray, Color.gray]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(12)
                            }
                            .disabled(!viewModel.canCreate)
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                        }
                        .padding(.top, 16)
                    }
    }
}

// MARK: - Cover Image Section
struct CoverImageSectionView: View {
    @Binding var coverImage: UIImage?
    let onSelectImage: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .overlay(
                        Button(action: onSelectImage) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(),
                        alignment: .bottomTrailing
                    )
            } else {
                Button(action: onSelectImage) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(Constants.Colors.textGray)

                        Text("カバー画像を追加")
                            .font(.system(size: 14))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Constants.Colors.cardDark)
                }
            }
        }
    }
}

// MARK: - Task Selection Row
struct TaskSelectionRow: View {
    let task: VoteTask
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)

                // Task Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Constants.Colors.textWhite)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        if let appName = task.externalAppName {
                            Text(appName)
                                .font(.system(size: 12))
                                .foregroundColor(Constants.Colors.textGray)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(task.formattedDeadline)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(task.isExpired ? Constants.Colors.statusExpired : Constants.Colors.textGray)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Constants.Colors.accentPink.opacity(0.1) : Constants.Colors.cardDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Constants.Colors.accentPink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Visibility Option Row
struct VisibilityOptionRow: View {
    let visibility: CollectionVisibility
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: visibility.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(visibility.displayText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(visibility.description)
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Visibility Description Extension
extension CollectionVisibility {
    var description: String {
        switch self {
        case .public:
            return "誰でも見ることができます"
        case .followers:
            return "フォロワーのみ閲覧できます"
        case .private:
            return "自分だけ閲覧できます"
        }
    }
}

// MARK: - Preview
#if DEBUG
struct CreateCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        CreateCollectionView()
            .preferredColorScheme(.dark)
    }
}
#endif
