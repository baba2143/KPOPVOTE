//
//  BiasSelectionSheet.swift
//  OSHI Pick
//
//  OSHI Pick - Bias Selection Sheet for Community Sharing
//

import SwiftUI

struct BiasSelectionSheet: View {
    @StateObject private var viewModel = BiasViewModel()
    @Environment(\.dismiss) private var dismiss
    let onComplete: ([String]) -> Void

    // Selection mode: 0 = Group, 1 = Member
    @State private var selectionMode = 0

    // Total selected count (groups + members)
    private var totalSelectedCount: Int {
        viewModel.selectedGroups.count + viewModel.selectedIdols.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                // Loading state
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        Text("読み込み中...")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textGray)
                    }
                } else {
                    // Main content
                    VStack(spacing: 0) {
                        // Selected count header
                        if totalSelectedCount > 0 {
                            HStack {
                                Text("選択中: \(totalSelectedCount)件")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Constants.Colors.accentPink)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Constants.Colors.cardDark)
                        }

                        // Group / Member selector
                        Picker("", selection: $selectionMode) {
                            Text("グループ").tag(0)
                            Text("メンバー").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Constants.Colors.textGray)

                            TextField(selectionMode == 0 ? "グループ名で検索" : "アイドル名・グループ名で検索", text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                                .foregroundColor(Constants.Colors.textWhite)
                                .autocorrectionDisabled()

                            if !viewModel.searchText.isEmpty {
                                Button(action: { viewModel.searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Constants.Colors.textGray)
                                }
                            }
                        }
                        .padding(10)
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                        // Content based on selection mode
                        if selectionMode == 0 {
                            // Group list
                            groupListView
                        } else {
                            // Member list (existing implementation)
                            memberListView
                        }
                    }
                }
            }
            .navigationTitle("推しを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        // Combine group IDs and member IDs
                        let selectedIds = Array(viewModel.selectedGroups) + Array(viewModel.selectedIdols)
                        onComplete(selectedIds)
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                    .disabled(totalSelectedCount == 0)
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadIdols()
                }
            }
        }
    }

    // MARK: - Group List View
    @ViewBuilder
    private var groupListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filteredGroups, id: \.id) { group in
                    BiasGroupRow(
                        group: group,
                        isSelected: viewModel.isGroupSelected(group),
                        onTap: {
                            viewModel.toggleGroup(group)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Member List View
    @ViewBuilder
    private var memberListView: some View {
        VStack(spacing: 0) {
            // Alphabet filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.ALPHABET, id: \.self) { char in
                        AlphabetTabButton(
                            char: char,
                            count: char == "ALL" ? viewModel.allIdols.count : (viewModel.alphabetCounts[char] ?? 0),
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
            .background(Constants.Colors.backgroundDark.opacity(0.5))

            // Idol list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.groupNames, id: \.self) { groupName in
                        VStack(alignment: .leading, spacing: 12) {
                            // Group header
                            HStack {
                                Text(groupName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Constants.Colors.textWhite)

                                Spacer()

                                Text("\(viewModel.groupedIdols[groupName]?.count ?? 0)人")
                                    .font(.system(size: 14))
                                    .foregroundColor(Constants.Colors.textGray)
                            }
                            .padding(.horizontal, 16)

                            // Idols in group
                            VStack(spacing: 8) {
                                ForEach(viewModel.groupedIdols[groupName] ?? []) { idol in
                                    IdolSelectionRow(
                                        idol: idol,
                                        isSelected: viewModel.isSelected(idol),
                                        onTap: {
                                            viewModel.toggleIdol(idol)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - Bias Group Row (for BiasSelectionSheet)
struct BiasGroupRow: View {
    let group: GroupMaster
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)

                // Group info
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text("グループ")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
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

// MARK: - Alphabet Tab Button
struct AlphabetTabButton: View {
    let char: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(char)
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? Constants.Colors.textWhite : Constants.Colors.textGray)

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)
                }
            }
            .frame(minWidth: 40)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                isSelected ?
                LinearGradient(
                    gradient: Gradient(colors: [Constants.Colors.gradientPink, Constants.Colors.gradientPurple]),
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [Constants.Colors.cardDark, Constants.Colors.cardDark]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Idol Selection Row
struct IdolSelectionRow: View {
    let idol: IdolMaster
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray)

                // Idol info
                VStack(alignment: .leading, spacing: 4) {
                    Text(idol.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(idol.groupName)
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
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

// MARK: - Preview
#if DEBUG
struct BiasSelectionSheet_Previews: PreviewProvider {
    static var previews: some View {
        BiasSelectionSheet { selectedIds in
            print("Selected IDs: \(selectedIds)")
        }
        .preferredColorScheme(.dark)
    }
}
#endif
