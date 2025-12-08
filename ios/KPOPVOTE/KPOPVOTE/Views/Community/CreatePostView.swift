//
//  CreatePostView.swift
//  OSHI Pick
//
//  OSHI Pick - Create Post Sheet View
//

import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = CreatePostViewModel()
    @StateObject private var biasViewModel = BiasViewModel()
    @State private var showImagePicker = false
    @State private var showSuccessAlert = false
    @State private var showMyVotesSelection = false

    var onPostCreated: (() -> Void)?

    private var isGuest: Bool {
        AppStorageManager.shared.isGuestMode
    }

    var body: some View {
        if isGuest {
            // ゲストモード - ログイン促進画面
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 64))
                    .foregroundColor(Constants.Colors.accentPink)

                Text("ログインが必要です")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text("投稿するには\nログインしてください")
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
        } else {
            // 通常モード
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                    // Post Type Selector
                    postTypeSelector

                    // Content Input based on Type
                    switch viewModel.selectedType {
                    case .image:
                        imageInput
                    case .myVotes:
                        myVotesInput
                    case .goodsTrade:
                        goodsTradeInput
                    case .collection:
                        EmptyView() // Collections are not created from Community tab
                    }

                    // Bias Selection
                    biasSelection

                    // Submit Button
                    submitButton
                    }
                    .padding()
                }
                .dismissKeyboardOnTap()
                .keyboardDoneButton()
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
        .alert("投稿完了", isPresented: $showSuccessAlert) {
            Button("OK") {
                onPostCreated?()
                dismiss()
            }
        } message: {
            Text("投稿が正常に作成されました")
        }
        .onChange(of: viewModel.isSuccess) { isSuccess in
            if isSuccess {
                showSuccessAlert = true
            }
        }
        .sheet(isPresented: $showMyVotesSelection) {
            MyVotesSelectionSheet { selectedVotes in
                viewModel.selectMyVotes(myVotes: selectedVotes)
            }
        }
        .task {
            await biasViewModel.loadIdols()
            await biasViewModel.loadCurrentBias()
        }
        } // else
    }

    // MARK: - Post Type Selector
    @ViewBuilder
    private var postTypeSelector: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("投稿タイプ")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    PostTypeButton(
                        icon: "photo",
                        title: "画像",
                        isSelected: viewModel.selectedType == .image,
                        action: { viewModel.selectedType = .image }
                    )

                    PostTypeButton(
                        icon: "list.bullet",
                        title: "My投票",
                        isSelected: viewModel.selectedType == .myVotes,
                        action: { viewModel.selectedType = .myVotes }
                    )

                    PostTypeButton(
                        icon: "gift",
                        title: "グッズ交換",
                        isSelected: viewModel.selectedType == .goodsTrade,
                        action: { viewModel.selectedType = .goodsTrade }
                    )
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
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 120)
                .background(Constants.Colors.cardDark)
                .cornerRadius(12)
                .tint(Constants.Colors.accentPink)
                .foregroundStyle(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Constants.Colors.accentPink.opacity(0.3), lineWidth: 1)
                )

            Text("画像 (オプション)")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            if let image = viewModel.selectedImageForPost {
                // Image Preview with Change Button
                VStack(spacing: 8) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)

                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("画像を変更")
                        }
                        .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                        .foregroundColor(Constants.Colors.accentBlue)
                    }
                }
            } else {
                // Upload Button
                Button(action: {
                    showImagePicker = true
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedImageForPost)
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
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 80)
                .background(Constants.Colors.cardDark)
                .cornerRadius(12)
                .tint(Constants.Colors.accentPink)
                .foregroundStyle(.white)
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
                showMyVotesSelection = true
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

    // MARK: - Goods Trade Input
    @ViewBuilder
    private var goodsTradeInput: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.large) {
            // Trade Type Selection
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text("取引タイプ *")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                HStack(spacing: 12) {
                    TradeTypeButton(
                        title: "求む",
                        icon: "hand.raised.fill",
                        isSelected: viewModel.tradeType == "want",
                        action: { viewModel.tradeType = "want" }
                    )

                    TradeTypeButton(
                        title: "譲ります",
                        icon: "hand.thumbsup.fill",
                        isSelected: viewModel.tradeType == "offer",
                        action: { viewModel.tradeType = "offer" }
                    )
                }
            }

            // Goods Image Upload
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text("グッズ画像 *")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                if let image = viewModel.selectedGoodsImage {
                    // Image Preview with Change Button
                    VStack(spacing: 8) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)

                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("画像を変更")
                            }
                            .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                            .foregroundColor(Constants.Colors.accentBlue)
                        }
                    }
                } else {
                    // Upload Button
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text("画像を追加")
                        }
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.accentBlue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Constants.Colors.accentBlue.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }

            // Goods Name
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text("グッズ名 *")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                TextField("例: うちわ、トレカ、ペンライト", text: $viewModel.goodsName)
                    .font(.system(size: Constants.Typography.bodySize))
                    .textFieldStyle(UnifiedTextFieldStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Constants.Colors.accentPink.opacity(0.3), lineWidth: 1)
                    )
            }

            // Tags
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text("タグ *")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                TagInputView(tags: $viewModel.goodsTags)
            }

            // Condition
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text("状態")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ConditionChip(
                            title: "新品・未開封",
                            value: "new",
                            isSelected: viewModel.condition == "new",
                            action: { viewModel.condition = "new" }
                        )

                        ConditionChip(
                            title: "美品",
                            value: "excellent",
                            isSelected: viewModel.condition == "excellent",
                            action: { viewModel.condition = "excellent" }
                        )

                        ConditionChip(
                            title: "良好",
                            value: "good",
                            isSelected: viewModel.condition == "good",
                            action: { viewModel.condition = "good" }
                        )

                        ConditionChip(
                            title: "やや傷あり",
                            value: "fair",
                            isSelected: viewModel.condition == "fair",
                            action: { viewModel.condition = "fair" }
                        )
                    }
                }
            }

            // Description
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                Text("説明 (オプション)")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                TextEditor(text: $viewModel.goodsDescription)
                    .font(.system(size: Constants.Typography.bodySize))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 80)
                    .background(Constants.Colors.cardDark)
                    .cornerRadius(12)
                    .tint(Constants.Colors.accentPink)
                    .foregroundStyle(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Constants.Colors.accentPink.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $viewModel.selectedGoodsImage)
        }
    }

    // MARK: - Bias Selection
    @ViewBuilder
    private var biasSelection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Text("推し選択 *")
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)

            if !biasViewModel.selectedGroupObjects.isEmpty || !biasViewModel.selectedIdolObjects.isEmpty {
                FlowLayout(spacing: 8) {
                    // Group chips
                    ForEach(biasViewModel.selectedGroupObjects, id: \.id) { group in
                        GroupChipToggle(
                            group: group,
                            isSelected: viewModel.selectedBiasIds.contains(group.id),
                            onToggle: {
                                toggleBias(group.id)
                            }
                        )
                    }
                    // Member chips
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
                Text("推しが設定されていません")
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
            print("🔘🔘🔘 ========== BUTTON TAPPED!!! ==========")
            print("🔘 [CreatePostView] Time: \(Date())")
            print("🔘 [CreatePostView] canSubmit: \(viewModel.canSubmit)")
            print("🔘 [CreatePostView] isSubmitting: \(viewModel.isSubmitting)")
            print("🔘 [CreatePostView] selectedType: \(viewModel.selectedType.rawValue)")
            print("🔘 [CreatePostView] selectedBiasIds: \(viewModel.selectedBiasIds)")
            print("🔘 [CreatePostView] textContent: '\(viewModel.textContent)'")
            print("🔘 [CreatePostView] selectedImageForPost: \(viewModel.selectedImageForPost != nil ? "YES" : "NO")")
            print("🔘🔘🔘 ========== CALLING submitPost() ==========")

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
        .onAppear {
            print("🔘 [submitButton] onAppear - canSubmit: \(viewModel.canSubmit), isSubmitting: \(viewModel.isSubmitting)")
        }
        .onChange(of: viewModel.canSubmit) { newValue in
            print("🔘 [submitButton] canSubmit changed to: \(newValue)")
        }
        .onChange(of: viewModel.isSubmitting) { newValue in
            print("🔘 [submitButton] isSubmitting changed to: \(newValue)")
        }
    }

    // MARK: - Toggle Bias
    private func toggleBias(_ biasId: String) {
        print("🎯 [toggleBias] Before - selectedBiasIds: \(viewModel.selectedBiasIds)")
        if let index = viewModel.selectedBiasIds.firstIndex(of: biasId) {
            viewModel.selectedBiasIds.remove(at: index)
            print("🎯 [toggleBias] Removed \(biasId)")
        } else {
            viewModel.selectedBiasIds.append(biasId)
            print("🎯 [toggleBias] Added \(biasId)")
        }
        print("🎯 [toggleBias] After - selectedBiasIds: \(viewModel.selectedBiasIds)")
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
                    .frame(height: 24)
                Text(title)
                    .font(.system(size: Constants.Typography.captionSize))
            }
            .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
            .frame(width: 80)
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

// MARK: - Group Chip Toggle Component
struct GroupChipToggle: View {
    let group: GroupMaster
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Text(group.name)
                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Constants.Colors.accentPink : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

// MARK: - Trade Type Button Component
struct TradeTypeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Constants.Colors.accentPink : Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Condition Chip Component
struct ConditionChip: View {
    let title: String
    let value: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                .foregroundColor(isSelected ? .white : Constants.Colors.textGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Constants.Colors.accentBlue : Color.white.opacity(0.1))
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
