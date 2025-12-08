//
//  ProfileEditView.swift
//  OSHI Pick
//
//  OSHI Pick - Profile Edit View
//

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProfileEditViewModel()
    @State private var showImagePicker = false

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

                    Text("プロフィールを編集するには\nログインしてください")
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
                .navigationTitle("プロフィール編集")
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
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                if viewModel.isSaving {
                    ProgressView("保存中...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .foregroundColor(Constants.Colors.textWhite)
                } else {
                    ScrollView {
                        VStack(spacing: Constants.Spacing.large) {
                            // Profile Image Section
                            profileImageSection

                            // Display Name Section
                            displayNameSection

                            // Bio Section
                            bioSection
                        }
                        .padding()
                    }
                    .dismissKeyboardOnTap()
                    .keyboardDoneButton()
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            if let updatedUser = await viewModel.saveProfile() {
                                // Update AuthService with new user data
                                await authService.updateCurrentUser(updatedUser)
                                dismiss()
                            }
                        }
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                    .fontWeight(.semibold)
                    .disabled(!viewModel.hasChanges() || viewModel.isSaving)
                }
            }
            .task {
                if let user = authService.currentUser {
                    viewModel.loadCurrentProfile(user: user)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedImage)
            }
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        } // else
    }

    // MARK: - Profile Image Section
    @ViewBuilder
    private var profileImageSection: some View {
        VStack(spacing: Constants.Spacing.small) {
            // Profile Image
            ZStack {
                if let selectedImage = viewModel.selectedImage {
                    // Show selected image
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let photoURL = viewModel.currentPhotoURL,
                          let url = URL(string: photoURL) {
                    // Show current profile image from URL
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 100, height: 100)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        case .failure:
                            defaultProfileIcon
                        @unknown default:
                            defaultProfileIcon
                        }
                    }
                } else {
                    // Default icon
                    defaultProfileIcon
                }

                // Camera overlay
                Circle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                    .opacity(0.7)
            }
            .onTapGesture {
                showImagePicker = true
            }

            Text("タップして変更")
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(Constants.Colors.textGray)

            if viewModel.isUploadingImage {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("画像をアップロード中...")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                }
            } else if viewModel.selectedImage != nil {
                HStack(spacing: 8) {
                    Image(systemName: "photo.circle.fill")
                        .foregroundColor(.blue)
                    Text("画像を選択しました")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }

    private var defaultProfileIcon: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 100))
            .foregroundColor(Constants.Colors.accentPink)
    }

    // MARK: - Display Name Section
    @ViewBuilder
    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("表示名")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            TextField("表示名を入力", text: $viewModel.displayName)
                .font(.system(size: Constants.Typography.bodySize))
                .textFieldStyle(UnifiedTextFieldStyle())
                .autocorrectionDisabled()

            if let error = viewModel.displayNameError {
                Text(error)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(.red)
            }

            Text("\(viewModel.displayName.count)/30文字")
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(Constants.Colors.textGray)
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }

    // MARK: - Bio Section
    @ViewBuilder
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("自己紹介")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            ZStack(alignment: .topLeading) {
                if viewModel.bio.isEmpty {
                    Text("自己紹介を入力してください（任意）")
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.textGray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                }

                TextEditor(text: $viewModel.bio)
                    .font(.system(size: Constants.Typography.bodySize))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 100)
                    .background(Constants.Colors.cardDark)
                    .cornerRadius(12)
                    .tint(Constants.Colors.accentPink)
                    .foregroundStyle(.white)
            }

            if let error = viewModel.bioError {
                Text(error)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(.red)
            }

            Text("\(viewModel.bio.count)/150文字")
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(Constants.Colors.textGray)
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    ProfileEditView()
        .environmentObject(AuthService())
}
