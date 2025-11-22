//
//  BiasSelectionSheet.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Bias Selection Sheet for Community Sharing
//

import SwiftUI

struct BiasSelectionSheet: View {
    @StateObject private var viewModel = BiasViewModel()
    @Environment(\.dismiss) private var dismiss
    let onComplete: ([String]) -> Void

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
                        Text("アイドル一覧を読み込んでいます...")
                            .font(.caption)
                            .foregroundColor(Constants.Colors.textGray)
                    }
                } else {
                    // Main content
                    VStack(spacing: 0) {
                        // Selected count header
                        if viewModel.selectedCount > 0 {
                            HStack {
                                Text("選択中: \(viewModel.selectedCount)人")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Constants.Colors.accentPink)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Constants.Colors.cardDark)
                        }

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
                        let selectedIds = Array(viewModel.selectedIdols)
                        onComplete(selectedIds)
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                    .disabled(viewModel.selectedCount == 0)
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
