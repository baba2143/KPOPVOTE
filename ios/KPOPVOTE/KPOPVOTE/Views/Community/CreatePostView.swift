//
//  CreatePostView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Create Post Sheet View
//

import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    @StateObject private var biasViewModel = BiasViewModel()

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    // Post Type Selector
                    postTypeSelector

                    // Content Input based on Type
                    switch viewModel.selectedType {
                    case .voteShare:
                        voteShareInput
                    case .image:
                        imageInput
                    case .myVotes:
                        myVotesInput
                    }

                    // Bias Selection
                    biasSelection

                    // Submit Button
                    submitButton
                }
                .padding()
            }
        }
        .navigationTitle("新規投稿")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    dismiss()
                }
                .foregroundColor(Constants.Colors.textGray)
            }
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
        .onChange(of: viewModel.isSuccess) { isSuccess in
            if isSuccess {
                dismiss()
            }
        }
        .task {
            await biasViewModel.loadIdols()
            await biasViewModel.loadCurrentBias()
        }
    }

    // MARK: - Post Type Selector
    @ViewBuilder
    private var postTypeSelector: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("投稿タイプ")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            HStack(spacing: 12) {
                PostTypeButton(
                    icon: "photo",
                    title: "画像",
                    isSelected: viewModel.selectedType == .image,
                    action: { viewModel.selectedType = .image }
                )

                PostTypeButton(
                    icon: "chart.bar",
                    title: "投票シェア",
                    isSelected: viewModel.selectedType == .voteShare,
                    action: { viewModel.selectedType = .voteShare }
                )

                PostTypeButton(
                    icon: "list.bullet",
                    title: "My投票",
                    isSelected: viewModel.selectedType == .myVotes,
                    action: { viewModel.selectedType = .myVotes }
                )
            }
        }
    }

    // MARK: - Vote Share Input
    @ViewBuilder
    private var voteShareInput: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("投票を選択")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            if let voteSnapshot = viewModel.selectedVoteSnapshot {
                // Selected Vote Display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(voteSnapshot.title)
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        Text(voteSnapshot.description)
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button("変更") {
                        // TODO: Open vote selection sheet
                    }
                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                    .foregroundColor(Constants.Colors.accentPink)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            } else {
                // Select Vote Button
                Button(action: {
                    // TODO: Open vote selection sheet
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("投票を選択")
                    }
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.accentPink)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Image Input
    @ViewBuilder
    private var imageInput: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("テキスト")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            TextEditor(text: $viewModel.textContent)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)
                .padding(8)
                .frame(minHeight: 120)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Constants.Colors.accentPink.opacity(0.3), lineWidth: 1)
                )

            Text("画像 (オプション)")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            Button(action: {
                // TODO: Open image picker
            }) {
                HStack {
                    Image(systemName: "photo")
                    Text("画像を追加")
                }
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.accentBlue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - My Votes Input
    @ViewBuilder
    private var myVotesInput: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("テキスト (オプション)")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            TextEditor(text: $viewModel.textContent)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)
                .padding(8)
                .frame(minHeight: 80)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Constants.Colors.accentPink.opacity(0.3), lineWidth: 1)
                )

            Text("投票履歴を選択")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            if !viewModel.selectedMyVotes.isEmpty {
                VStack(spacing: 8) {
                    ForEach(viewModel.selectedMyVotes, id: \.id) { voteItem in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(voteItem.title)
                                    .font(.system(size: Constants.Typography.bodySize))
                                    .foregroundColor(Constants.Colors.textWhite)

                                if let choice = voteItem.selectedChoiceLabel {
                                    Text("選択: \(choice)")
                                        .font(.system(size: Constants.Typography.captionSize))
                                        .foregroundColor(Constants.Colors.accentPink)
                                }
                            }
                            Spacer()
                            Text("\(voteItem.pointsUsed)P")
                                .font(.system(size: Constants.Typography.captionSize, weight: .bold))
                                .foregroundColor(Constants.Colors.accentBlue)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            }

            Button(action: {
                // TODO: Open my votes selection sheet
            }) {
                HStack {
                    Image(systemName: viewModel.selectedMyVotes.isEmpty ? "plus.circle" : "pencil.circle")
                    Text(viewModel.selectedMyVotes.isEmpty ? "投票履歴を選択" : "変更")
                }
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.accentPink)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Bias Selection
    @ViewBuilder
    private var biasSelection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("Bias選択 *")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            if !biasViewModel.selectedIdolObjects.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(biasViewModel.selectedIdolObjects, id: \.id) { idol in
                        BiasChipToggle(
                            idol: idol,
                            isSelected: viewModel.selectedBiasIds.contains(idol.id),
                            onToggle: {
                                toggleBias(idol.id)
                            }
                        )
                    }
                }
            } else {
                Text("Biasが設定されていません")
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Submit Button
    @ViewBuilder
    private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.submitPost()
            }
        }) {
            HStack {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("投稿する")
                        .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canSubmit ? Constants.Colors.accentPink : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSubmit || viewModel.isSubmitting)
    }

    // MARK: - Toggle Bias
    private func toggleBias(_ biasId: String) {
        if let index = viewModel.selectedBiasIds.firstIndex(of: biasId) {
            viewModel.selectedBiasIds.remove(at: index)
        } else {
            viewModel.selectedBiasIds.append(biasId)
        }
    }
}

// MARK: - Post Type Button Component
struct PostTypeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: Constants.Typography.captionSize))
            }
            .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Constants.Colors.accentPink : Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Bias Chip Toggle Component
struct BiasChipToggle: View {
    let idol: IdolMaster
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(idol.name)
                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Constants.Colors.accentPink : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Flow Layout Helper
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        CreatePostView()
    }
}
