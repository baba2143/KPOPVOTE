//
//  CreatePostViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Create Post ViewModel
//

import Foundation
import UIKit
import Combine

@MainActor
class CreatePostViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedType: PostType = .image
    @Published var textContent: String = ""
    @Published var selectedImageURLs: [String] = []
    @Published var selectedVoteIds: [String] = []
    @Published var selectedVoteSnapshots: [InAppVote] = []
    @Published var selectedMyVotes: [MyVoteItem] = []
    @Published var selectedBiasIds: [String] = []
    @Published var isSubmitting = false
    @Published var errorMessage: String? {
        didSet {
            if let error = errorMessage {
                debugLog("❌ [errorMessage] Set to: \(error)")
            } else {
                debugLog("✅ [errorMessage] Cleared")
            }
        }
    }
    @Published var isSuccess = false

    // Image Post Properties
    @Published var selectedImageForPost: UIImage?

    // Goods Trade Properties
    @Published var selectedGoodsImage: UIImage?
    @Published var goodsName: String = ""
    @Published var goodsTags: [String] = []
    @Published var tradeType: String = "want" // "want" or "offer"
    @Published var condition: String? // "new", "excellent", "good", "fair"
    @Published var goodsDescription: String = ""

    // Music Video Properties
    @Published var youtubeUrl: String = ""
    @Published var fetchedVideoMetadata: YouTubeService.VideoMetadata?
    @Published var isFetchingMetadata = false
    @Published var metadataError: String?

    // MARK: - Estimated Points (新報酬設計)
    /// 投稿タイプに応じた獲得ポイントの予測値
    var estimatedPoints: Int {
        switch selectedType {
        case .musicVideo:
            return 5  // post_mv
        case .image:
            return 3  // post_image
        case .goodsTrade:
            return 5  // post_goods_exchange
        case .collection:
            return 10 // collection_create
        case .myVotes:
            return 2  // post_text (投票結果投稿)
        }
    }

    // MARK: - Validation
    /// Check if current post can be submitted
    var canSubmit: Bool {
        let result: Bool
        switch selectedType {
        case .image:
            let hasText = !textContent.isEmpty
            let hasBias = !selectedBiasIds.isEmpty
            result = hasText && hasBias
        case .myVotes:
            result = !selectedMyVotes.isEmpty && !selectedBiasIds.isEmpty
        case .goodsTrade:
            result = selectedGoodsImage != nil &&
                   !goodsName.isEmpty &&
                   !goodsTags.isEmpty &&
                   !selectedBiasIds.isEmpty
        case .collection:
            result = false // Collections cannot be created from Community tab
        case .musicVideo:
            result = fetchedVideoMetadata != nil && !selectedBiasIds.isEmpty
        }
        return result
    }

    // MARK: - Create Post
    /// Submit the post
    func submitPost() async {
        debugLog("🚀🚀🚀 ========== submitPost() CALLED! ==========")
        debugLog("🚀 [submitPost] Time: \(Date())")
        debugLog("🚀 [submitPost] canSubmit: \(canSubmit)")
        debugLog("🚀 [submitPost] selectedType: \(selectedType.rawValue)")

        guard canSubmit else {
            debugLog("❌ [submitPost] GUARD FAILED - canSubmit is false")
            errorMessage = "必須項目を入力してください"
            return
        }

        // 重複呼び出し防止
        guard !isSubmitting else {
            debugLog("⚠️ [submitPost] Already submitting, ignoring duplicate call")
            return
        }

        debugLog("✅ [submitPost] Guard passed, continuing...")

        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil

        do {
            // Build PostContent based on type
            var content = PostContent()

            debugLog("📝 [CreatePostViewModel] Building post content - type: \(selectedType.rawValue)")
            debugLog("📝 [CreatePostViewModel] Selected biasIds: \(selectedBiasIds)")

            switch selectedType {
            case .image:
                content.text = textContent
                debugLog("📝 [CreatePostViewModel] Image post - text length: \(textContent.count) characters")

                // Upload image if selected
                if let image = selectedImageForPost {
                    debugLog("📤 [CreatePostViewModel] Uploading post image... (size: \(image.size.width)x\(image.size.height))")
                    let imageUrl = try await ImageUploadService.shared.uploadGoodsImage(image)
                    debugLog("✅ [CreatePostViewModel] Image uploaded: \(imageUrl) (length: \(imageUrl.count) chars)")
                    content.images = [imageUrl]
                } else {
                    content.images = nil
                    debugLog("📝 [CreatePostViewModel] No image selected")
                }
            case .myVotes:
                content.myVotes = selectedMyVotes
                if !textContent.isEmpty {
                    content.text = textContent
                }
                debugLog("📝 [CreatePostViewModel] My votes - count: \(selectedMyVotes.count)")
            case .goodsTrade:
                // Upload goods image first
                guard let image = selectedGoodsImage else {
                    errorMessage = "画像を選択してください"
                    isSubmitting = false
                    return
                }

                debugLog("📤 [CreatePostViewModel] Uploading goods image...")
                let imageUrl = try await ImageUploadService.shared.uploadGoodsImage(image)
                debugLog("✅ [CreatePostViewModel] Image uploaded: \(imageUrl)")

                // Get idol info from first selected bias
                guard let firstBiasId = selectedBiasIds.first else {
                    errorMessage = "アイドルを選択してください"
                    isSubmitting = false
                    return
                }

                // Get idol info from IdolGroupLookupService
                await IdolGroupLookupService.shared.loadIfNeeded()
                let idolName: String
                let groupName: String

                if let idol = IdolGroupLookupService.shared.findIdol(byId: firstBiasId) {
                    // Found as idol
                    idolName = idol.name
                    groupName = idol.groupName
                    debugLog("📝 [CreatePostViewModel] Found idol: \(idolName) from \(groupName)")
                } else if let group = IdolGroupLookupService.shared.findGroup(byId: firstBiasId) {
                    // Found as group (use group name for both)
                    idolName = group.name
                    groupName = group.name
                    debugLog("📝 [CreatePostViewModel] Found group: \(groupName)")
                } else {
                    // Fallback: use biasId as name (not ideal but prevents empty values)
                    idolName = firstBiasId
                    groupName = ""
                    debugLog("⚠️ [CreatePostViewModel] Could not find idol/group for ID: \(firstBiasId), using ID as name")
                }

                let goodsTrade = GoodsTradeContent(
                    idolId: firstBiasId,
                    idolName: idolName,
                    groupName: groupName,
                    goodsImageUrl: imageUrl,
                    goodsTags: goodsTags,
                    goodsName: goodsName,
                    tradeType: tradeType,
                    condition: condition,
                    description: goodsDescription.isEmpty ? nil : goodsDescription,
                    status: "available"
                )
                content.goodsTrade = goodsTrade
            case .collection:
                // Collections are not created from Community tab
                errorMessage = "コレクションはVOTESタブから作成してください"
                isSubmitting = false
                return
            case .musicVideo:
                guard let metadata = fetchedVideoMetadata else {
                    errorMessage = "YouTube動画情報を取得してください"
                    isSubmitting = false
                    return
                }

                let musicVideoContent = MusicVideoContent(
                    youtubeVideoId: metadata.videoId,
                    youtubeUrl: youtubeUrl,
                    title: metadata.title,
                    thumbnailUrl: metadata.thumbnailUrl,
                    channelName: metadata.channelName
                )
                content.musicVideo = musicVideoContent
                if !textContent.isEmpty {
                    content.text = textContent
                }
                debugLog("📝 [CreatePostViewModel] Music video - videoId: \(metadata.videoId), title: \(metadata.title)")
            }

            debugLog("📤 [CreatePostViewModel] Creating post: type=\(selectedType.rawValue), biasIds count: \(selectedBiasIds.count)")

            // Log content summary
            if let text = content.text {
                debugLog("📝 [CreatePostViewModel] Content text: \(text.prefix(50))... (total: \(text.count) chars)")
            }
            if let images = content.images {
                debugLog("📝 [CreatePostViewModel] Content images: \(images.count) URLs")
                images.forEach { debugLog("   - URL: \($0.prefix(100))... (length: \($0.count))") }
            }
            if let goodsTrade = content.goodsTrade {
                debugLog("📝 [CreatePostViewModel] Content goodsTrade: \(goodsTrade.goodsName)")
            }

            _ = try await CommunityService.shared.createPost(
                type: selectedType,
                content: content,
                biasIds: selectedBiasIds
            )

            debugLog("✅ [CreatePostViewModel] Post created successfully")
            isSuccess = true
        } catch {
            debugLog("❌ [CreatePostViewModel] Failed to create post: \(error)")
            debugLog("❌ [CreatePostViewModel] Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                debugLog("❌ [CreatePostViewModel] Error domain: \(nsError.domain), code: \(nsError.code)")
                debugLog("❌ [CreatePostViewModel] Error userInfo: \(nsError.userInfo)")
            }
            errorMessage = "投稿に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Select My Votes
    /// Set my votes for myVotes type
    func selectMyVotes(myVotes: [MyVoteItem]) {
        selectedMyVotes = myVotes
        selectedType = .myVotes

        debugLog("🎯 [CreatePostViewModel] Selected \(myVotes.count) my votes")
    }

    // MARK: - Reset
    /// Reset form to initial state
    func reset() {
        selectedType = .image
        textContent = ""
        selectedImageURLs = []
        selectedImageForPost = nil
        selectedVoteIds = []
        selectedVoteSnapshots = []
        selectedMyVotes = []
        selectedBiasIds = []
        selectedGoodsImage = nil
        goodsName = ""
        goodsTags = []
        tradeType = "want"
        condition = nil
        goodsDescription = ""
        youtubeUrl = ""
        fetchedVideoMetadata = nil
        isFetchingMetadata = false
        metadataError = nil
        isSubmitting = false
        errorMessage = nil
        isSuccess = false
    }

    // MARK: - Clear Error
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Fetch YouTube Metadata
    /// Fetch metadata from YouTube URL using oEmbed API
    func fetchYouTubeMetadata() async {
        let url = youtubeUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else {
            fetchedVideoMetadata = nil
            metadataError = nil
            return
        }

        // Check if URL is valid
        guard YouTubeService.shared.isValidYouTubeUrl(url) else {
            fetchedVideoMetadata = nil
            metadataError = "有効なYouTube URLを入力してください"
            return
        }

        isFetchingMetadata = true
        metadataError = nil

        do {
            let metadata = try await YouTubeService.shared.fetchMetadata(url: url)
            fetchedVideoMetadata = metadata
            metadataError = nil
            debugLog("✅ [CreatePostViewModel] Fetched YouTube metadata: \(metadata.title)")
        } catch {
            fetchedVideoMetadata = nil
            metadataError = "動画情報の取得に失敗しました"
            debugLog("❌ [CreatePostViewModel] Failed to fetch YouTube metadata: \(error)")
        }

        isFetchingMetadata = false
    }

    // MARK: - Clear YouTube Metadata
    /// Clear fetched YouTube metadata
    func clearYouTubeMetadata() {
        youtubeUrl = ""
        fetchedVideoMetadata = nil
        metadataError = nil
    }
}
