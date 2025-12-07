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

    // MARK: - Validation
    /// Check if current post can be submitted
    var canSubmit: Bool {
        let result: Bool
        switch selectedType {
        case .image:
            let hasText = !textContent.isEmpty
            let hasBias = !selectedBiasIds.isEmpty
            result = hasText && hasBias
            debugLog("✅ [canSubmit] image - hasText: \(hasText) ('\(textContent)'), hasBias: \(hasBias) (\(selectedBiasIds)), result: \(result)")
        case .myVotes:
            result = !selectedMyVotes.isEmpty && !selectedBiasIds.isEmpty
        case .goodsTrade:
            result = selectedGoodsImage != nil &&
                   !goodsName.isEmpty &&
                   !goodsTags.isEmpty &&
                   !selectedBiasIds.isEmpty
        case .collection:
            result = false // Collections cannot be created from Community tab
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

        debugLog("✅ [submitPost] Guard passed, continuing...")

        isSubmitting = true
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

                // Need to get idol info - assuming we have access to BiasViewModel or similar
                // For now, we'll use placeholder values
                let goodsTrade = GoodsTradeContent(
                    idolId: firstBiasId,
                    idolName: "", // Will be filled from biasViewModel
                    groupName: "", // Will be filled from biasViewModel
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

        isSubmitting = false
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
        isSubmitting = false
        errorMessage = nil
        isSuccess = false
    }

    // MARK: - Clear Error
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
