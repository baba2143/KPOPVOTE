//
//  ProfileEditView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Profile Edit View
//

import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProfileEditViewModel()
    @StateObject private var biasViewModel = BiasViewModel()
    @State private var showBiasPicker = false
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

                    Button(action: { dismiss() }) {
                        Text("閉じる")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Constants.Colors.accentPink)
                            .cornerRadius(24)
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

                            // Bias Section
                            biasSection
                        }
                        .padding()
                    }
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
                await biasViewModel.loadIdols()
            }
            .sheet(isPresented: $showBiasPicker) {
                BiasPickerView(
                    selectedBiasIds: $viewModel.selectedBiasIds,
                    allIdols: biasViewModel.allIdols
                )
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

    // MARK: - Bias Section
    @ViewBuilder
    private var biasSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Text("推しアイドル")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()

                Button(action: {
                    showBiasPicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("追加")
                    }
                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                    .foregroundColor(Constants.Colors.accentPink)
                }
            }

            if viewModel.selectedBiasIds.isEmpty {
                Text("推しアイドルを選択してください")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Constants.Spacing.large)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.selectedBiasIds, id: \.self) { idolId in
                        if let idol = biasViewModel.allIdols.first(where: { $0.id == idolId }) {
                            BiasTag(
                                name: idol.name,
                                onRemove: {
                                    viewModel.removeBias(idolId: idolId)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - Bias Tag Component
struct BiasTag: View {
    let name: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Constants.Colors.accentPink)
        .cornerRadius(16)
    }
}

// MARK: - Bias Picker View
struct BiasPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBiasIds: [String]
    let allIdols: [IdolMaster]
    @State private var searchText = ""

    var filteredIdols: [IdolMaster] {
        if searchText.isEmpty {
            return allIdols
        }
        return allIdols.filter { idol in
            idol.name.localizedCaseInsensitiveContains(searchText) ||
            idol.groupName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedIdols: [String: [IdolMaster]] {
        Dictionary(grouping: filteredIdols, by: { $0.groupName })
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                VStack {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Constants.Colors.textGray)
                        TextField("アイドルを検索", text: $searchText)
                    }
                    .padding(12)
                    .background(Constants.Colors.cardDark)
                    .cornerRadius(12)
                    .padding()

                    // Idol List
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                            ForEach(groupedIdols.keys.sorted(), id: \.self) { groupName in
                                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                                    Text(groupName)
                                        .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                                        .foregroundColor(Constants.Colors.textWhite)
                                        .padding(.horizontal)

                                    ForEach(groupedIdols[groupName] ?? [], id: \.id) { idol in
                                        HStack {
                                            Text(idol.name)
                                                .font(.system(size: Constants.Typography.bodySize))
                                                .foregroundColor(Constants.Colors.textWhite)

                                            Spacer()

                                            if selectedBiasIds.contains(idol.id) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Constants.Colors.accentPink)
                                            }
                                        }
                                        .padding()
                                        .background(Constants.Colors.cardDark)
                                        .cornerRadius(12)
                                        .onTapGesture {
                                            if selectedBiasIds.contains(idol.id) {
                                                selectedBiasIds.removeAll { $0 == idol.id }
                                            } else {
                                                selectedBiasIds.append(idol.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("推しアイドルを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileEditView()
        .environmentObject(AuthService())
}
