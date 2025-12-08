//
//  BiasSettingsView.swift
//  OSHI Pick
//
//  OSHI Pick - Bias Settings Screen
//

import SwiftUI

struct BiasSettingsView: View {
    @StateObject private var viewModel = BiasViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

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
                        .foregroundColor(.blue)

                    Text("ログインが必要です")
                        .font(.system(size: 20, weight: .bold))

                    Text("推しを設定するには\nログインしてください")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
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
                            .background(Color.blue)
                            .cornerRadius(24)
                        }
                        .padding(.horizontal, 32)

                        Button(action: { dismiss() }) {
                            Text("閉じる")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()
                .navigationTitle("推し設定")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            dismiss()
                        }
                    }
                }
            }
        } else {
            // 通常モード
            NavigationView {
            ZStack {
                // Loading state
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("アイドル一覧を読み込んでいます...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Main content
                    VStack(spacing: 0) {
                        // Selection mode picker
                        Picker("選択モード", selection: $viewModel.selectionMode) {
                            ForEach(BiasSelectionMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)

                            TextField(
                                viewModel.selectionMode == .group ? "グループ名で検索" : "アイドル名・グループ名で検索",
                                text: $viewModel.searchText
                            )
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled()

                            if !viewModel.searchText.isEmpty {
                                Button(action: { viewModel.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)

                        // Alphabet filter tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.ALPHABET, id: \.self) { char in
                                    AlphabetTabView(
                                        char: char,
                                        count: viewModel.selectionMode == .group
                                            ? (char == "ALL" ? viewModel.allGroups.count : (viewModel.groupAlphabetCounts[char] ?? 0))
                                            : (char == "ALL" ? viewModel.allIdols.count : (viewModel.alphabetCounts[char] ?? 0)),
                                        isSelected: viewModel.selectedChar == char,
                                        onTap: {
                                            viewModel.selectedChar = char
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color(.systemGroupedBackground))

                        // List content based on mode
                        if viewModel.selectionMode == .group {
                            // Group list
                            List {
                                // Selected groups section
                                if viewModel.selectedGroups.count > 0 {
                                    Section {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("選択中 (\(viewModel.selectedGroups.count))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            GroupChipView(
                                                selectedGroups: viewModel.selectedGroupObjects,
                                                onRemove: { group in
                                                    viewModel.toggleGroup(group)
                                                }
                                            )
                                        }
                                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                    }
                                }

                                // Group list
                                Section {
                                    ForEach(viewModel.filteredGroupsByAlphabet) { group in
                                        GroupRowView(
                                            group: group,
                                            isSelected: viewModel.isGroupSelected(group),
                                            onTap: {
                                                viewModel.toggleGroup(group)
                                            }
                                        )
                                    }
                                } header: {
                                    Text("グループ一覧 (\(viewModel.filteredGroupsByAlphabet.count))")
                                }
                            }
                            .listStyle(.insetGrouped)
                        } else {
                            // Idol list (existing implementation)
                            List {
                                // Selected idols section
                                if viewModel.selectedIdols.count > 0 {
                                    Section {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("選択中 (\(viewModel.selectedIdols.count))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            BiasChipView(
                                                selectedIdols: viewModel.selectedIdolObjects,
                                                onRemove: { idol in
                                                    viewModel.toggleIdol(idol)
                                                }
                                            )
                                        }
                                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                    }
                                }

                                // Grouped idol list
                                ForEach(viewModel.groupNames, id: \.self) { groupName in
                                    Section {
                                        ForEach(viewModel.groupedIdols[groupName] ?? []) { idol in
                                            IdolRowView(
                                                idol: idol,
                                                isSelected: viewModel.isSelected(idol),
                                                onTap: {
                                                    viewModel.toggleIdol(idol)
                                                }
                                            )
                                        }
                                    } header: {
                                        Text("\(groupName) (\(viewModel.groupedIdols[groupName]?.count ?? 0))")
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                    .dismissKeyboardOnTap()
                    .keyboardDoneButton()
                }
            }
            .navigationTitle("推し設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.saveBias()
                            if viewModel.errorMessage == nil {
                                // Success - dismiss after short delay
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("保存")
                                .bold()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .task {
                await viewModel.loadIdols()
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("成功", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.clearSuccess()
                }
            } message: {
                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                }
            }
        }
        } // else
    }
}

// MARK: - Alphabet Tab View
struct AlphabetTabView: View {
    let char: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(char)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : (count > 0 ? .blue : .gray))

                if count > 0 && !isSelected {
                    Text("\(count)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 36, minHeight: 36)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : (count > 0 ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3)), lineWidth: 1)
            )
        }
        .disabled(count == 0 && char != "ALL")
        .opacity(count == 0 && char != "ALL" ? 0.5 : 1.0)
    }
}

// MARK: - Idol Row View
struct IdolRowView: View {
    let idol: IdolMaster
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)

                // Idol image
                AsyncImage(url: URL(string: idol.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(idol.name.prefix(1))
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                // Idol name
                VStack(alignment: .leading, spacing: 2) {
                    Text(idol.name)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(idol.groupName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Group Row View
struct GroupRowView: View {
    let group: GroupMaster
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)

                // Group image
                AsyncImage(url: URL(string: group.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .overlay(
                            Text(group.name.prefix(1))
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                // Group name
                Text(group.name)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Group Chip View
struct GroupChipView: View {
    let selectedGroups: [GroupMaster]
    let onRemove: (GroupMaster) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedGroups) { group in
                    HStack(spacing: 4) {
                        // Group image
                        AsyncImage(url: URL(string: group.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())

                        Text(group.name)
                            .font(.caption)
                            .lineLimit(1)

                        Button(action: { onRemove(group) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                }
            }
        }
    }
}

// MARK: - Preview
struct BiasSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BiasSettingsView()
    }
}
