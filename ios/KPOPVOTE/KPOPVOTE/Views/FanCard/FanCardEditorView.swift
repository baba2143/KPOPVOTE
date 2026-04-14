//
//  FanCardEditorView.swift
//  KPOPVOTE
//
//  FanCard Editor View
//

import SwiftUI
import PhotosUI

// MARK: - FanCard Limits
private enum FanCardLimits {
    static let maxBlocks = 20
    static let displayNameMax = 30
    static let bioMax = 200
    static let linkTitleMax = 50
    static let textContentMax = 500
}

struct FanCardEditorView: View {
    @StateObject private var viewModel = FanCardViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var showBlockPicker = false
    @State private var showPreview = false
    @State private var editingBlockIndex: Int?
    @State private var pendingEditBlockIndex: Int?

    // Image picker states
    @State private var selectedProfileItem: PhotosPickerItem?
    @State private var selectedHeaderItem: PhotosPickerItem?

    // Local state for TextField/TextEditor (workaround for SwiftUI Form bug)
    @State private var localDisplayName: String = ""
    @State private var localBio: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("読み込み中...")
                } else if viewModel.hasFanCard {
                    editFanCardForm
                        .id("edit-\(viewModel.odDisplayName)")
                } else {
                    createFanCardForm
                }
            }
            .navigationTitle(viewModel.hasFanCard ? "FanCard編集" : "FanCard作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                if viewModel.hasFanCard {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showShareSheet = true
                            } label: {
                                Label("シェア", systemImage: "square.and.arrow.up")
                            }

                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("FanCardを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    Task {
                        if await viewModel.deleteFanCard() {
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("FanCardを削除しますか？この操作は取り消せません。")
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = viewModel.shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showPreview) {
                FanCardPreviewView(viewModel: viewModel)
            }
            .sheet(isPresented: $showBlockPicker, onDismiss: {
                // Open editor for newly added block after picker is dismissed
                if let pendingIndex = pendingEditBlockIndex {
                    pendingEditBlockIndex = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        editingBlockIndex = pendingIndex
                    }
                }
            }) {
                BlockPickerView(viewModel: viewModel) { newIndex in
                    pendingEditBlockIndex = newIndex
                }
            }
            .sheet(item: Binding(
                get: { editingBlockIndex.map { BlockEditItem(index: $0) } },
                set: { editingBlockIndex = $0?.index }
            )) { item in
                if item.index < viewModel.blocks.count {
                    BlockEditorView(block: $viewModel.blocks[item.index])
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .overlay {
                if viewModel.showSuccess {
                    SuccessToast()
                        .transition(.opacity.combined(with: .scale))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    viewModel.showSuccess = false
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.showSuccess)
        }
        .task {
            await viewModel.loadFanCard()
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Create FanCard Form
    private var createFanCardForm: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FanCard ID")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("例: jimin-love", text: $viewModel.odDisplayName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onChange(of: viewModel.odDisplayName) { _ in
                                viewModel.checkOdDisplayName()
                            }

                        if viewModel.isCheckingOdDisplayName {
                            ProgressView()
                        } else if viewModel.odDisplayNameAvailable == true {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if viewModel.odDisplayNameAvailable == false {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }

                    if let error = viewModel.odDisplayNameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("URLに使用されます: fancard.app/\(viewModel.odDisplayName.isEmpty ? "your-id" : viewModel.odDisplayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("FanCard ID（後から変更できません）")
            }

            profileSection
            themeSection

            Section {
                Button {
                    showPreview = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "eye")
                        Text("プレビュー")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }

            Section {
                Button {
                    Task {
                        if await viewModel.createFanCard() {
                            // Success
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("FanCardを作成")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isSaving || viewModel.odDisplayNameAvailable != true)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
    }

    // MARK: - Edit FanCard Form
    private var editFanCardForm: some View {
        Form {
            // FanCard URL Section
            if let fanCard = viewModel.fanCard {
                Section {
                    HStack {
                        Text(FanCardService.shared.getFanCardShareURL(odDisplayName: fanCard.odDisplayName).absoluteString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        Spacer()

                        Button {
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                } header: {
                    Text("FanCard URL")
                }
            }

            profileSection
            blocksSection
            themeSection
            settingsSection

            Section {
                Button {
                    showPreview = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "eye")
                        Text("プレビュー")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.updateFanCard()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("保存")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
        .task(id: viewModel.fanCard?.odDisplayName) {
            // Initialize local state when fanCard data is loaded
            localDisplayName = viewModel.displayName
            localBio = viewModel.bio
            debugLog("📝 [FanCardEditorView] Local state initialized: displayName='\(localDisplayName)', bio='\(localBio.prefix(20))...'")
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        Section {
            // Profile Image Picker - 行全体をタップ可能に
            PhotosPicker(selection: $selectedProfileItem, matching: .images) {
                HStack {
                    Text("プロフィール画像")
                        .foregroundColor(.primary)
                    Spacer()
                    if let image = viewModel.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else if !viewModel.profileImageUrl.isEmpty,
                              let url = URL(string: viewModel.profileImageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onChange(of: selectedProfileItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.profileImage = image
                    }
                }
            }

            // Header Image Picker - 行全体をタップ可能に
            PhotosPicker(selection: $selectedHeaderItem, matching: .images) {
                HStack {
                    Text("ヘッダー画像")
                        .foregroundColor(.primary)
                    Spacer()
                    if let image = viewModel.headerImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if !viewModel.headerImageUrl.isEmpty,
                              let url = URL(string: viewModel.headerImageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .frame(width: 100, height: 50)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onChange(of: selectedHeaderItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.headerImage = image
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("表示名")
                    Spacer()
                    Text("\(localDisplayName.count)/\(FanCardLimits.displayNameMax)")
                        .font(.caption)
                        .foregroundColor(localDisplayName.count > FanCardLimits.displayNameMax ? .red : .secondary)
                }
                TextField("名前を入力", text: $localDisplayName)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                    .onChange(of: localDisplayName) { newValue in
                        // 文字数制限
                        if newValue.count > FanCardLimits.displayNameMax {
                            localDisplayName = String(newValue.prefix(FanCardLimits.displayNameMax))
                        }
                        viewModel.displayName = localDisplayName
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("自己紹介")
                    Spacer()
                    Text("\(localBio.count)/\(FanCardLimits.bioMax)")
                        .font(.caption)
                        .foregroundColor(localBio.count > FanCardLimits.bioMax ? .red : .secondary)
                }
                TextEditor(text: $localBio)
                    .frame(minHeight: 80)
                    .onChange(of: localBio) { newValue in
                        // 文字数制限
                        if newValue.count > FanCardLimits.bioMax {
                            localBio = String(newValue.prefix(FanCardLimits.bioMax))
                        }
                        viewModel.bio = localBio
                    }
            }
        } header: {
            Text("プロフィール")
        } footer: {
            Text("画像は最大5MBまでアップロードできます。")
        }
    }

    // MARK: - Blocks Section
    private var blocksSection: some View {
        Section {
            ForEach(Array(viewModel.blocks.enumerated()), id: \.element.id) { index, block in
                Button {
                    editingBlockIndex = index
                } label: {
                    BlockRowView(block: block)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.removeBlock(at: index)
                }
            }
            .onMove { source, destination in
                viewModel.moveBlock(from: source, to: destination)
            }

            if viewModel.blocks.count < FanCardLimits.maxBlocks {
                Button {
                    showBlockPicker = true
                } label: {
                    Label("ブロックを追加", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
        } header: {
            HStack {
                Text("コンテンツブロック")
                Spacer()
                Text("\(viewModel.blocks.count)/\(FanCardLimits.maxBlocks)")
                    .font(.caption)
                    .foregroundColor(viewModel.blocks.count >= FanCardLimits.maxBlocks ? .red : .secondary)
            }
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.blocks.count >= FanCardLimits.maxBlocks {
                    Text("⚠️ ブロック数が上限に達しました")
                        .foregroundColor(.red)
                }
                Text("ブロックは最大\(FanCardLimits.maxBlocks)個まで追加できます。")
            }
        }
    }

    // MARK: - Theme Section
    private var themeSection: some View {
        Section {
            Picker("テンプレート", selection: $viewModel.theme.template) {
                ForEach(FanCardTemplate.allCases, id: \.self) { template in
                    Text(template.displayName).tag(template)
                }
            }

            ColorPicker("背景色", selection: Binding(
                get: { Color(hex: viewModel.theme.backgroundColor) },
                set: { viewModel.theme.backgroundColor = $0.toHex() }
            ))

            ColorPicker("メインカラー", selection: Binding(
                get: { Color(hex: viewModel.theme.primaryColor) },
                set: { viewModel.theme.primaryColor = $0.toHex() }
            ))

            Picker("フォント", selection: $viewModel.theme.fontFamily) {
                ForEach(FanCardFontFamily.allCases, id: \.self) { font in
                    Text(font.displayName).tag(font)
                }
            }
        } header: {
            Text("テーマ")
        }
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        Section {
            Toggle("公開する", isOn: $viewModel.isPublic)
        } header: {
            Text("公開設定")
        } footer: {
            Text("非公開にすると、URLからアクセスしても表示されません。")
        }
    }
}

// MARK: - Block Row View
struct BlockRowView: View {
    let block: FanCardBlock

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !block.isVisible {
                Image(systemName: "eye.slash")
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch block.type {
        case .bias: return "heart.fill"
        case .link: return "link"
        case .mvLink: return "play.rectangle.fill"
        case .sns: return "at"
        case .text: return "text.alignleft"
        case .image: return "photo"
        }
    }

    private var title: String {
        switch block.type {
        case .bias: return "推しメンバー"
        case .link: return "リンク"
        case .mvLink: return "MV リンク"
        case .sns: return "SNS"
        case .text: return "テキスト"
        case .image: return "画像"
        }
    }

    private var subtitle: String {
        switch block.data {
        case .bias(let data):
            return data.customBias?.first?.artistName ?? "My Bias"
        case .link(let data):
            return data.title
        case .mvLink(let data):
            return data.title
        case .sns(let data):
            return "@\(data.username)"
        case .text(let data):
            return String(data.content.prefix(30))
        case .image(let data):
            return data.caption ?? "画像"
        }
    }
}

// MARK: - Block Picker View
struct BlockPickerView: View {
    @ObservedObject var viewModel: FanCardViewModel
    @Environment(\.dismiss) private var dismiss
    var onBlockAdded: ((Int) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    blockButton(type: .bias, icon: "heart.fill", title: "推しメンバー", description: "推しているアーティスト・メンバーを表示")
                    blockButton(type: .mvLink, icon: "play.rectangle.fill", title: "MVリンク", description: "YouTubeのMVをサムネイル付きで表示")
                    blockButton(type: .link, icon: "link", title: "リンク", description: "任意のURLへのリンク")
                    blockButton(type: .sns, icon: "at", title: "SNS", description: "SNSアカウントへのリンク")
                    blockButton(type: .text, icon: "text.alignleft", title: "テキスト", description: "自由なテキストを追加")
                    blockButton(type: .image, icon: "photo", title: "画像", description: "画像を追加")
                }
            }
            .navigationTitle("ブロックを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(.dark)
    }

    private func blockButton(type: FanCardBlockType, icon: String, title: String, description: String) -> some View {
        Button {
            addBlock(type: type)
            dismiss()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func addBlock(type: FanCardBlockType) {
        let id = UUID().uuidString
        let order = viewModel.blocks.count + 1

        let block: FanCardBlock
        switch type {
        case .bias:
            block = FanCardBlock(id: id, type: .bias, order: order, isVisible: true,
                                 data: .bias(BiasBlockData(showFromMyBias: true, customBias: nil)))
        case .link:
            block = FanCardBlock(id: id, type: .link, order: order, isVisible: true,
                                 data: .link(LinkBlockData(title: "", url: "")))
        case .mvLink:
            block = FanCardBlock(id: id, type: .mvLink, order: order, isVisible: true,
                                 data: .mvLink(MVLinkBlockData(title: "", youtubeUrl: "")))
        case .sns:
            block = FanCardBlock(id: id, type: .sns, order: order, isVisible: true,
                                 data: .sns(SNSBlockData(platform: .x, username: "", url: nil)))
        case .text:
            block = FanCardBlock(id: id, type: .text, order: order, isVisible: true,
                                 data: .text(TextBlockData(content: "", alignment: "center")))
        case .image:
            block = FanCardBlock(id: id, type: .image, order: order, isVisible: true,
                                 data: .image(ImageBlockData(imageUrl: "")))
        }

        let newIndex = viewModel.blocks.count
        viewModel.addBlock(block)
        onBlockAdded?(newIndex)
    }
}

// MARK: - Helper for Block Editing
struct BlockEditItem: Identifiable {
    let index: Int
    var id: Int { index }
}

// MARK: - Success Toast
struct SuccessToast: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("保存しました")
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(radius: 4)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    FanCardEditorView()
}
