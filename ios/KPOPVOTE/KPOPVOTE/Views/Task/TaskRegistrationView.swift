//
//  TaskRegistrationView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Task Registration Form
//

import SwiftUI

struct TaskRegistrationView: View {
    @StateObject private var viewModel = TaskRegistrationViewModel()
    @Environment(\.dismiss) var dismiss

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

    var body: some View {
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

                    // Bias IDs Input (Optional, MVP version)
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("対象メンバー（任意）")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        TextField("例: blackpink, twice, bts（カンマ区切り）", text: $viewModel.biasIdsText)
                            .font(.system(size: Constants.Typography.bodySize))
                            .textFieldStyle(UnifiedTextFieldStyle())
                            .autocapitalization(.none)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.textGray.opacity(0.3), lineWidth: 1)
                            )

                        Text("複数のメンバーを指定する場合はカンマで区切ってください")
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
                                // TODO: Implement image picker
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
                        }

                        Text(coverImageHelpText)
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textGray)
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

                            Text(viewModel.isLoading ? "登録中..." : "タスクを登録")
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
            .background(Constants.Colors.cardDark)
            .navigationTitle("VOTE登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("VOTE登録")
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
            .alert("登録完了", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    viewModel.showSuccess = false
                    dismiss()
                }
            } message: {
                Text("タスクが正常に登録されました")
            }
            .onAppear {
                Task {
                    await viewModel.loadExternalApps()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    TaskRegistrationView()
}
