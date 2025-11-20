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

    var body: some View {
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
    }

    // MARK: - Profile Image Section
    @ViewBuilder
    private var profileImageSection: some View {
        VStack(spacing: Constants.Spacing.small) {
            // Profile Icon
            Image(systemName: "person.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(Constants.Colors.accentPink)

            // TODO: Image picker will be added in future
            Text("プロフィール画像")
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(Constants.Colors.textGray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
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
                .foregroundColor(Constants.Colors.textWhite)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
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
                    .foregroundColor(Constants.Colors.textWhite)
                    .padding(8)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
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
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
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
