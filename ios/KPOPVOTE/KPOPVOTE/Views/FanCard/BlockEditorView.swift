//
//  BlockEditorView.swift
//  KPOPVOTE
//
//  Block Editor Views for FanCard
//

import SwiftUI
import PhotosUI

// MARK: - Block Limits
private enum BlockLimits {
    static let linkTitleMax = 50
    static let textContentMax = 500
}

// MARK: - Block Editor Router
struct BlockEditorView: View {
    @Binding var block: FanCardBlock
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch block.data {
                case .bias(let data):
                    BiasBlockEditorView(block: $block, data: data)
                case .link(let data):
                    LinkBlockEditorView(block: $block, data: data)
                case .mvLink(let data):
                    MVLinkBlockEditorView(block: $block, data: data)
                case .sns(let data):
                    SNSBlockEditorView(block: $block, data: data)
                case .text(let data):
                    TextBlockEditorView(block: $block, data: data)
                case .image(let data):
                    ImageBlockEditorView(block: $block, data: data)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
    }
}

// MARK: - Bias Block Editor
struct BiasBlockEditorView: View {
    @Binding var block: FanCardBlock
    let data: BiasBlockData

    @State private var showFromMyBias: Bool
    @State private var isVisible: Bool
    @State private var customBiasList: [BiasBlockData.CustomBias]

    // For adding custom bias
    @State private var newArtistName: String = ""
    @State private var newMemberName: String = ""

    init(block: Binding<FanCardBlock>, data: BiasBlockData) {
        self._block = block
        self.data = data
        self._showFromMyBias = State(initialValue: data.showFromMyBias)
        self._isVisible = State(initialValue: block.wrappedValue.isVisible)
        self._customBiasList = State(initialValue: data.customBias ?? [])
    }

    var body: some View {
        Form {
            Section {
                Toggle("My Biasから自動取得", isOn: $showFromMyBias)
                    .onChange(of: showFromMyBias) { newValue in
                        updateBlock()
                    }
            } header: {
                Text("推しメンバー設定")
            } footer: {
                Text("オンにすると、あなたのMy Biasに登録されているアーティストが自動的に表示されます。")
            }

            // Custom bias section (shown when My Bias is OFF)
            if !showFromMyBias {
                Section {
                    ForEach(customBiasList) { bias in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(bias.artistName)
                                    .font(.subheadline)
                                if let memberName = bias.memberName, !memberName.isEmpty {
                                    Text(memberName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        customBiasList.remove(atOffsets: indexSet)
                        updateBlock()
                    }

                    // Add new custom bias
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("アーティスト名", text: $newArtistName)
                        TextField("メンバー名（任意）", text: $newMemberName)
                        Button {
                            addCustomBias()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("追加")
                            }
                        }
                        .disabled(newArtistName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("カスタム推し")
                } footer: {
                    Text("My Biasを使わない場合、手動で推しを追加できます。")
                }
            }

            Section {
                Toggle("表示する", isOn: $isVisible)
                    .onChange(of: isVisible) { newValue in
                        block.isVisible = newValue
                    }
            } header: {
                Text("表示設定")
            }
        }
        .navigationTitle("推しメンバー")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
    }

    private func addCustomBias() {
        let artistName = newArtistName.trimmingCharacters(in: .whitespaces)
        guard !artistName.isEmpty else { return }

        let memberName = newMemberName.trimmingCharacters(in: .whitespaces)

        let newBias = BiasBlockData.CustomBias(
            artistId: UUID().uuidString,
            artistName: artistName,
            memberId: memberName.isEmpty ? nil : UUID().uuidString,
            memberName: memberName.isEmpty ? nil : memberName,
            imageUrl: nil
        )

        customBiasList.append(newBias)
        newArtistName = ""
        newMemberName = ""
        updateBlock()
    }

    private func updateBlock() {
        block.data = .bias(BiasBlockData(
            showFromMyBias: showFromMyBias,
            customBias: customBiasList.isEmpty ? nil : customBiasList
        ))
    }
}

// MARK: - Link Block Editor
struct LinkBlockEditorView: View {
    @Binding var block: FanCardBlock
    let data: LinkBlockData

    @State private var title: String
    @State private var url: String
    @State private var iconUrl: String
    @State private var backgroundColor: String
    @State private var isVisible: Bool

    init(block: Binding<FanCardBlock>, data: LinkBlockData) {
        self._block = block
        self.data = data
        self._title = State(initialValue: data.title)
        self._url = State(initialValue: data.url)
        self._iconUrl = State(initialValue: data.iconUrl ?? "")
        self._backgroundColor = State(initialValue: data.backgroundColor ?? "#3B82F6")
        self._isVisible = State(initialValue: block.wrappedValue.isVisible)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("タイトル")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(title.count)/\(BlockLimits.linkTitleMax)")
                            .font(.caption)
                            .foregroundColor(title.count > BlockLimits.linkTitleMax ? .red : .secondary)
                    }
                    TextField("タイトルを入力", text: $title)
                        .onChange(of: title) { newValue in
                            if newValue.count > BlockLimits.linkTitleMax {
                                title = String(newValue.prefix(BlockLimits.linkTitleMax))
                            }
                            updateBlock()
                        }
                }

                TextField("URL", text: $url)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .onChange(of: url) { newValue in
                        updateBlock()
                    }
            } header: {
                Text("リンク設定")
            }

            Section {
                ColorPicker("ボタン色", selection: Binding(
                    get: { Color(hex: backgroundColor) },
                    set: { newColor in
                        backgroundColor = newColor.toHex()
                        updateBlock()
                    }
                ))

                TextField("アイコンURL（任意）", text: $iconUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .onChange(of: iconUrl) { newValue in
                        updateBlock()
                    }
            } header: {
                Text("デザイン")
            }

            Section {
                Toggle("表示する", isOn: $isVisible)
                    .onChange(of: isVisible) { newValue in
                        block.isVisible = newValue
                    }
            } header: {
                Text("表示設定")
            }
        }
        .navigationTitle("リンク")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
    }

    private func updateBlock() {
        block.data = .link(LinkBlockData(
            title: title,
            url: url,
            iconUrl: iconUrl.isEmpty ? nil : iconUrl,
            backgroundColor: backgroundColor
        ))
    }
}

// MARK: - MV Link Block Editor
struct MVLinkBlockEditorView: View {
    @Binding var block: FanCardBlock
    let data: MVLinkBlockData

    @State private var title: String
    @State private var youtubeUrl: String
    @State private var artistName: String
    @State private var isVisible: Bool

    init(block: Binding<FanCardBlock>, data: MVLinkBlockData) {
        self._block = block
        self.data = data
        self._title = State(initialValue: data.title)
        self._youtubeUrl = State(initialValue: data.youtubeUrl)
        self._artistName = State(initialValue: data.artistName ?? "")
        self._isVisible = State(initialValue: block.wrappedValue.isVisible)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("タイトル")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(title.count)/\(BlockLimits.linkTitleMax)")
                            .font(.caption)
                            .foregroundColor(title.count > BlockLimits.linkTitleMax ? .red : .secondary)
                    }
                    TextField("MV名を入力", text: $title)
                        .onChange(of: title) { newValue in
                            if newValue.count > BlockLimits.linkTitleMax {
                                title = String(newValue.prefix(BlockLimits.linkTitleMax))
                            }
                            updateBlock()
                        }
                }

                TextField("YouTube URL", text: $youtubeUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .onChange(of: youtubeUrl) { newValue in
                        updateBlock()
                    }

                TextField("アーティスト名（任意）", text: $artistName)
                    .onChange(of: artistName) { newValue in
                        updateBlock()
                    }
            } header: {
                Text("MV設定")
            } footer: {
                Text("YouTubeのMV URLを入力してください。サムネイルは自動的に取得されます。")
            }

            Section {
                Toggle("表示する", isOn: $isVisible)
                    .onChange(of: isVisible) { newValue in
                        block.isVisible = newValue
                    }
            } header: {
                Text("表示設定")
            }
        }
        .navigationTitle("MVリンク")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
    }

    private func updateBlock() {
        // Extract video ID and generate thumbnail
        let thumbnailUrl = extractThumbnailUrl(from: youtubeUrl)

        block.data = .mvLink(MVLinkBlockData(
            title: title,
            youtubeUrl: youtubeUrl,
            thumbnailUrl: thumbnailUrl,
            artistName: artistName.isEmpty ? nil : artistName
        ))
    }

    private func extractThumbnailUrl(from url: String) -> String? {
        // Extract video ID from various YouTube URL formats
        let patterns = [
            "(?:youtube\\.com/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com/embed/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                let videoId = String(url[range])
                return "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"
            }
        }

        return nil
    }
}

// MARK: - SNS Block Editor
struct SNSBlockEditorView: View {
    @Binding var block: FanCardBlock
    let data: SNSBlockData

    @State private var platform: SNSPlatform
    @State private var username: String
    @State private var isVisible: Bool

    init(block: Binding<FanCardBlock>, data: SNSBlockData) {
        self._block = block
        self.data = data
        self._platform = State(initialValue: data.platform)
        self._username = State(initialValue: data.username)
        self._isVisible = State(initialValue: block.wrappedValue.isVisible)
    }

    var body: some View {
        Form {
            Section {
                Picker("プラットフォーム", selection: $platform) {
                    ForEach(SNSPlatform.allCases, id: \.self) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .onChange(of: platform) { _ in
                    updateBlock()
                }

                HStack {
                    Text("@")
                        .foregroundColor(.secondary)
                    TextField("ユーザー名", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: username) { _ in
                            updateBlock()
                        }
                }
            } header: {
                Text("SNS設定")
            }

            Section {
                Toggle("表示する", isOn: $isVisible)
                    .onChange(of: isVisible) { newValue in
                        block.isVisible = newValue
                    }
            } header: {
                Text("表示設定")
            }
        }
        .navigationTitle("SNS")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
    }

    private func updateBlock() {
        let url = generateSNSUrl(platform: platform, username: username)
        block.data = .sns(SNSBlockData(
            platform: platform,
            username: username,
            url: url
        ))
    }

    private func generateSNSUrl(platform: SNSPlatform, username: String) -> String {
        let cleanUsername = username.replacingOccurrences(of: "@", with: "")
        switch platform {
        case .x:
            return "https://twitter.com/\(cleanUsername)"
        case .instagram:
            return "https://instagram.com/\(cleanUsername)"
        case .tiktok:
            return "https://tiktok.com/@\(cleanUsername)"
        case .youtube:
            return "https://youtube.com/@\(cleanUsername)"
        case .threads:
            return "https://threads.net/@\(cleanUsername)"
        case .other:
            return ""
        }
    }
}

// MARK: - Text Block Editor
struct TextBlockEditorView: View {
    @Binding var block: FanCardBlock
    let data: TextBlockData

    @State private var content: String
    @State private var alignment: String
    @State private var isVisible: Bool

    init(block: Binding<FanCardBlock>, data: TextBlockData) {
        self._block = block
        self.data = data
        self._content = State(initialValue: data.content)
        self._alignment = State(initialValue: data.alignment)
        self._isVisible = State(initialValue: block.wrappedValue.isVisible)
    }

    var body: some View {
        Form {
            Section {
                TextEditor(text: $content)
                    .frame(minHeight: 120)
                    .onChange(of: content) { newValue in
                        if newValue.count > BlockLimits.textContentMax {
                            content = String(newValue.prefix(BlockLimits.textContentMax))
                        }
                        updateBlock()
                    }
            } header: {
                HStack {
                    Text("テキスト")
                    Spacer()
                    Text("\(content.count)/\(BlockLimits.textContentMax)")
                        .font(.caption)
                        .foregroundColor(content.count > BlockLimits.textContentMax ? .red : .secondary)
                }
            } footer: {
                Text("最大\(BlockLimits.textContentMax)文字まで入力できます。")
            }

            Section {
                Picker("配置", selection: $alignment) {
                    Text("左揃え").tag("left")
                    Text("中央").tag("center")
                    Text("右揃え").tag("right")
                }
                .pickerStyle(.segmented)
                .onChange(of: alignment) { _ in
                    updateBlock()
                }
            } header: {
                Text("配置")
            }

            Section {
                Toggle("表示する", isOn: $isVisible)
                    .onChange(of: isVisible) { newValue in
                        block.isVisible = newValue
                    }
            } header: {
                Text("表示設定")
            }
        }
        .navigationTitle("テキスト")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
    }

    private func updateBlock() {
        block.data = .text(TextBlockData(
            content: content,
            alignment: alignment
        ))
    }
}

// MARK: - Image Block Editor
struct ImageBlockEditorView: View {
    @Binding var block: FanCardBlock
    let data: ImageBlockData

    @State private var imageUrl: String
    @State private var caption: String
    @State private var linkUrl: String
    @State private var isVisible: Bool

    // Photo picker states
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading: Bool = false
    @State private var uploadError: String?

    init(block: Binding<FanCardBlock>, data: ImageBlockData) {
        self._block = block
        self.data = data
        self._imageUrl = State(initialValue: data.imageUrl)
        self._caption = State(initialValue: data.caption ?? "")
        self._linkUrl = State(initialValue: data.linkUrl ?? "")
        self._isVisible = State(initialValue: block.wrappedValue.isVisible)
    }

    var body: some View {
        Form {
            Section {
                // Photo picker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(.accentColor)
                        Text("写真を選択")
                            .foregroundColor(.primary)
                        Spacer()
                        if isUploading {
                            ProgressView()
                        }
                    }
                }
                .disabled(isUploading)
                .onChange(of: selectedItem) { item in
                    Task {
                        await loadAndUploadImage(item: item)
                    }
                }

                if let error = uploadError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } header: {
                Text("画像を選択")
            }

            // Preview section
            if let image = selectedImage {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                } header: {
                    Text("プレビュー")
                }
            } else if !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                Section {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(maxHeight: 200)
                } header: {
                    Text("プレビュー")
                }
            }

            Section {
                TextField("キャプション（任意）", text: $caption)
                    .onChange(of: caption) { _ in
                        updateBlock()
                    }

                TextField("リンクURL（任意）", text: $linkUrl)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .onChange(of: linkUrl) { _ in
                        updateBlock()
                    }
            } header: {
                Text("オプション")
            }

            Section {
                Toggle("表示する", isOn: $isVisible)
                    .onChange(of: isVisible) { newValue in
                        block.isVisible = newValue
                    }
            } header: {
                Text("表示設定")
            }
        }
        .navigationTitle("画像")
        .scrollDismissesKeyboard(.interactively)
        .keyboardDoneButton()
    }

    private func loadAndUploadImage(item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isUploading = true
        uploadError = nil

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                uploadError = "画像の読み込みに失敗しました"
                isUploading = false
                return
            }

            selectedImage = image

            // Upload image
            let uploadedUrl = try await ImageUploadService.shared.uploadGoodsImage(image)
            imageUrl = uploadedUrl
            updateBlock()

            debugLog("✅ [ImageBlockEditor] Image uploaded: \(uploadedUrl)")
        } catch {
            uploadError = "アップロードに失敗しました: \(error.localizedDescription)"
            debugLog("❌ [ImageBlockEditor] Upload error: \(error)")
        }

        isUploading = false
    }

    private func updateBlock() {
        block.data = .image(ImageBlockData(
            imageUrl: imageUrl,
            caption: caption.isEmpty ? nil : caption,
            linkUrl: linkUrl.isEmpty ? nil : linkUrl
        ))
    }
}
