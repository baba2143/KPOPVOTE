//
//  TaskRegistrationView.swift
//  OSHI Pick
//
//  OSHI Pick - Task Registration Form
//

import SwiftUI

struct TaskRegistrationView: View {
    @ObservedObject var viewModel: TaskRegistrationViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var showVoteURLHelp = false

    init(task: VoteTask? = nil) {
        self.viewModel = TaskRegistrationViewModel(task: task)
    }

    // MARK: - Computed Properties
    private var buttonGradient: LinearGradient {
        viewModel.isFormValid ?
            LinearGradient(
                colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                startPoint: .leading,
                endPoint: .trailing
            ) :
            LinearGradient(
                colors: [Constants.Colors.textGray, Constants.Colors.textGray],
                startPoint: .leading,
                endPoint: .trailing
            )
    }

    private var coverImageHelpText: String {
        if viewModel.selectedAppId != nil && viewModel.coverImageURL != nil && viewModel.coverImageSource == .externalApp {
            return "選択した投票サイトの推奨画像が使用されます"
        } else {
            return "投票サイトを選択すると推奨画像が自動設定されます"
        }
    }

    private var isGuest: Bool {
        AppStorageManager.shared.isGuestMode
    }

    var body: some View {
        if isGuest {
            // ゲストモード - ログイン促進画面
            NavigationView {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 64))
                        .foregroundColor(Constants.Colors.accentPink)

                    Text("ログインが必要です")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text("VOTEを登録するには\nログインしてください")
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

                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Constants.Colors.backgroundDark)
                .navigationTitle("VOTE登録")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            dismiss()
                        }
                        .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
        } else {
            // 通常モード
            NavigationView {
                ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Title Input
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("タスクタイトル")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        TextField("例: MAMA 2024 投票", text: $viewModel.title)
                            .font(.system(size: Constants.Typography.bodySize))
                            .textFieldStyle(UnifiedTextFieldStyle())
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.accentPink.opacity(0.3), lineWidth: 1)
                            )

                        if let error = viewModel.titleError {
                            Text(error)
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(.red)
                        }
                    }

                    // URL Input
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("投票URL")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        TextField("https://vote.example.com", text: $viewModel.url)
                            .font(.system(size: Constants.Typography.bodySize))
                            .textFieldStyle(UnifiedTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.URL)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.accentBlue.opacity(0.3), lineWidth: 1)
                            )

                        if let error = viewModel.urlError {
                            Text(error)
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(.red)
                        }

                        Button(action: { showVoteURLHelp = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "questionmark.circle")
                                Text("アプリの投票URLの取得方法")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(Constants.Colors.accentBlue)
                        }
                    }
                    .sheet(isPresented: $showVoteURLHelp) {
                        VoteURLHelpView()
                    }

                    // Deadline Picker
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("投票期限")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        DatePicker(
                            "",
                            selection: $viewModel.deadline,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(Constants.Colors.accentPink)
                        .colorScheme(.dark)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                        .environment(\.calendar, Calendar(identifier: .japanese))
                        .padding()
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Constants.Colors.gradientPurple.opacity(0.3), lineWidth: 1)
                        )

                        if let error = viewModel.deadlineError {
                            Text(error)
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(.red)
                        }
                    }

                    // External App Picker
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("投票サイト（任意）")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        Picker("投票サイトを選択", selection: $viewModel.selectedAppId) {
                            Text("なし").tag(nil as String?)
                            ForEach(viewModel.externalApps) { app in
                                Text(app.appName).tag(app.id as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                        .background(Constants.Colors.cardDark)
                        .foregroundColor(Constants.Colors.textWhite)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Constants.Colors.accentBlue.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: viewModel.selectedAppId) { newValue in
                            viewModel.handleExternalAppSelection(newValue)
                        }

                        Text("投票サイトを選択すると、タスク一覧にアイコンが表示されます")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
                    }

                    // Member Selection (Optional)
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("対象メンバー（任意）")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        // Selected members chips
                        if !viewModel.selectedMemberNames.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(viewModel.selectedMemberNames.enumerated()), id: \.offset) { index, name in
                                        HStack(spacing: 6) {
                                            Text(name)
                                                .font(.system(size: 14))
                                                .foregroundColor(Constants.Colors.textWhite)

                                            Button(action: {
                                                viewModel.selectedMemberNames.remove(at: index)
                                                viewModel.selectedMemberIds.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundColor(Constants.Colors.textGray)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Constants.Colors.accentPink.opacity(0.2))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Constants.Colors.accentPink, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }

                        // Add member button
                        Button(action: {
                            viewModel.showBiasSelection = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("メンバーを選択")
                                    .font(.system(size: Constants.Typography.bodySize))
                            }
                            .foregroundColor(Constants.Colors.accentBlue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Constants.Colors.cardDark)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.accentBlue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .sheet(isPresented: $viewModel.showBiasSelection) {
                            BiasSelectionSheet { selectedIds in
                                // Get idol names from IDs
                                Task {
                                    viewModel.selectedMemberIds = selectedIds
                                    await viewModel.loadMemberNames(for: selectedIds)
                                }
                            }
                        }

                        Text("推し設定から対象メンバーを選択できます")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
                    }

                    // Cover Image Section
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("カバー画像（任意）")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        // Show default cover image from external app or user-selected image
                        if let coverImageURL = viewModel.coverImageURL {
                            // Display URL-based image (from external app or uploaded)
                            AsyncImage(url: URL(string: coverImageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Constants.Colors.accentBlue.opacity(0.3), lineWidth: 1)
                                        )
                                case .failure(_):
                                    Text("画像の読み込みに失敗しました")
                                        .foregroundColor(.red)
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    EmptyView()
                                }
                            }

                            HStack {
                                if let source = viewModel.coverImageSource {
                                    Text(source == .externalApp ? "推奨画像を使用" : "カスタム画像を使用")
                                        .font(.system(size: 12))
                                        .foregroundColor(Constants.Colors.textGray)
                                }
                                Spacer()
                                if viewModel.coverImageSource == .userUpload {
                                    Button(action: {
                                        viewModel.coverImageURL = nil
                                        viewModel.coverImageSource = nil
                                        viewModel.selectedCoverImage = nil
                                    }) {
                                        Text("削除")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        } else {
                            // Placeholder for image selection
                            Button(action: {
                                viewModel.showImagePicker = true
                            }) {
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(Constants.Colors.textGray)
                                    Text("カバー画像を選択")
                                        .font(.system(size: Constants.Typography.bodySize))
                                        .foregroundColor(Constants.Colors.textGray)
                                }
                                .frame(maxWidth: .infinity, maxHeight: 150)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .sheet(isPresented: $viewModel.showImagePicker) {
                                ImagePicker(selectedImage: $viewModel.selectedCoverImage)
                                    .onDisappear {
                                        if viewModel.selectedCoverImage != nil {
                                            Task {
                                                await viewModel.uploadCoverImage()
                                            }
                                        }
                                    }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(coverImageHelpText)
                                .font(.system(size: 12))
                                .foregroundColor(Constants.Colors.textGray)

                            if viewModel.coverImageURL == nil {
                                Text("推奨サイズ: 800×600px（アスペクト比 4:3）")
                                    .font(.system(size: 11))
                                    .foregroundColor(Constants.Colors.textGray.opacity(0.8))
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Register Button
                    Button(action: {
                        Task {
                            await viewModel.registerTask()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }

                            Text(viewModel.isLoading ? (viewModel.isEditMode ? "更新中..." : "登録中...") : (viewModel.isEditMode ? "タスクを更新" : "タスクを登録"))
                                .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(buttonGradient)
                        .cornerRadius(16)
                        .shadow(
                            color: viewModel.isFormValid ? Constants.Colors.accentPink.opacity(0.4) : .clear,
                            radius: 12,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
                .padding()
            }
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .background(Constants.Colors.cardDark)
            .navigationTitle(viewModel.isEditMode ? "VOTE編集" : "VOTE登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.isEditMode ? "VOTE編集" : "VOTE登録")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                }
            }
            .toolbarBackground(Constants.Colors.cardDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
            .alert(viewModel.isEditMode ? "更新完了" : "登録完了", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    viewModel.showSuccess = false
                    dismiss()
                }
            } message: {
                Text(viewModel.isEditMode ? "タスクが正常に更新されました" : "タスクが正常に登録されました")
            }
            .onAppear {
                Task {
                    await viewModel.loadExternalApps()
                }
            }
        }
        } // else
    }
}

// MARK: - Preview
#Preview {
    TaskRegistrationView()
}
