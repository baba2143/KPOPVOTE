//
//  BiasSettingsView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Bias Settings Screen
//

import SwiftUI

struct BiasSettingsView: View {
    @StateObject private var viewModel = BiasViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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
                        // Alphabet filter tabs
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.ALPHABET, id: \.self) { char in
                                    AlphabetTabView(
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
                        .background(Color(.systemGroupedBackground))

                        // Idol list
                        List {
                            // Selected idols section
                            if viewModel.selectedCount > 0 {
                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("選択中 (\(viewModel.selectedCount))")
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

// MARK: - Preview
struct BiasSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BiasSettingsView()
    }
}
