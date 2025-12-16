//
//  EditCollectionView.swift
//  OSHI Pick
//
//  OSHI Pick - Edit Collection View
//

import SwiftUI
import FirebaseAuth

struct EditCollectionView: View {
    let collectionId: String

    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: EditCollectionViewModel

    init(collectionId: String) {
        self.collectionId = collectionId
        _viewModel = StateObject(wrappedValue: EditCollectionViewModel(collectionId: collectionId))
    }

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
            .navigationTitle("コレクションを編集")
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
                Text(viewModel.errorMessage ?? "コレクションの更新に失敗しました")
            }
            .fullScreenCover(isPresented: $viewModel.showImagePicker) {
                ImagePicker(selectedImage: $viewModel.coverImage)
            }
            .onAppear {
                Task {
                    await viewModel.loadCollectionData()
                }
            }
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView("読み込み中...")
                .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                .foregroundColor(Constants.Colors.textWhite)
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Cover Image Section
                EditCoverImageSectionView(
                    coverImage: $viewModel.coverImage,
                    coverImageUrl: viewModel.coverImageUrl,
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

                // Update Button
                Button(action: {
                    Task {
                        let success = await viewModel.updateCollection()
                        if success {
                            dismiss()
                        }
                    }
                }) {
                    Text("コレクションを更新")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            viewModel.canUpdate ?
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
                .disabled(!viewModel.canUpdate)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .dismissKeyboardOnTap()
        .keyboardDoneButton()
    }
}

// MARK: - Edit Cover Image Section
struct EditCoverImageSectionView: View {
    @Binding var coverImage: UIImage?
    let coverImageUrl: String?
    let onSelectImage: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let image = coverImage {
                // New image selected
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
            } else if let urlString = coverImageUrl, let url = URL(string: urlString) {
                // Existing image from URL
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
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
                    case .failure(_), .empty:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                // No image
                placeholderView
            }
        }
    }

    private var placeholderView: some View {
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

// MARK: - Preview
#if DEBUG
struct EditCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        EditCollectionView(collectionId: "test_collection_id")
            .preferredColorScheme(.dark)
    }
}
#endif
