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
                print("❌ [errorMessage] Set to: \(error)")
            } else {
                print("✅ [errorMessage] Cleared")
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
            print("✅ [canSubmit] image - hasText: \(hasText) ('\(textContent)'), hasBias: \(hasBias) (\(selectedBiasIds)), result: \(result)")
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
        print("🚀🚀🚀 ========== submitPost() CALLED! ==========")
        print("🚀 [submitPost] Time: \(Date())")
        print("🚀 [submitPost] canSubmit: \(canSubmit)")
        print("🚀 [submitPost] selectedType: \(selectedType.rawValue)")

        guard canSubmit else {
            print("❌ [submitPost] GUARD FAILED - canSubmit is false")
            errorMessage = "必須項目を入力してください"
            return
        }

        print("✅ [submitPost] Guard passed, continuing...")

        isSubmitting = true
        errorMessage = nil

        do {
            // Build PostContent based on type
            var content = PostContent()

            print("📝 [CreatePostViewModel] Building post content - type: \(selectedType.rawValue)")
            print("📝 [CreatePostViewModel] Selected biasIds: \(selectedBiasIds)")

            switch selectedType {
            case .image:
                content.text = textContent
                print("📝 [CreatePostViewModel] Image post - text length: \(textContent.count) characters")

                // Upload image if selected
                if let image = selectedImageForPost {
                    print("📤 [CreatePostViewModel] Uploading post image... (size: \(image.size.width)x\(image.size.height))")
                    let imageUrl = try await ImageUploadService.shared.uploadGoodsImage(image)
                    print("✅ [CreatePostViewModel] Image uploaded: \(imageUrl) (length: \(imageUrl.count) chars)")
                    content.images = [imageUrl]
                } else {
                    content.images = nil
                    print("📝 [CreatePostViewModel] No image selected")
                }
            case .myVotes:
                content.myVotes = selectedMyVotes
                if !textContent.isEmpty {
                    content.text = textContent
                }
                print("📝 [CreatePostViewModel] My votes - count: \(selectedMyVotes.count)")
            case .goodsTrade:
                // Upload goods image first
                guard let image = selectedGoodsImage else {
                    errorMessage = "画像を選択してください"
                    isSubmitting = false
                    return
                }

                print("📤 [CreatePostViewModel] Uploading goods image...")
                let imageUrl = try await ImageUploadService.shared.uploadGoodsImage(image)
                print("✅ [CreatePostViewModel] Image uploaded: \(imageUrl)")

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

            print("📤 [CreatePostViewModel] Creating post: type=\(selectedType.rawValue), biasIds count: \(selectedBiasIds.count)")

            // Log content summary
            if let text = content.text {
                print("📝 [CreatePostViewModel] Content text: \(text.prefix(50))... (total: \(text.count) chars)")
            }
            if let images = content.images {
                print("📝 [CreatePostViewModel] Content images: \(images.count) URLs")
                images.forEach { print("   - URL: \($0.prefix(100))... (length: \($0.count))") }
            }
            if let goodsTrade = content.goodsTrade {
                print("📝 [CreatePostViewModel] Content goodsTrade: \(goodsTrade.goodsName)")
            }

            _ = try await CommunityService.shared.createPost(
                type: selectedType,
                content: content,
                biasIds: selectedBiasIds
            )

            print("✅ [CreatePostViewModel] Post created successfully")
            isSuccess = true
        } catch {
            print("❌ [CreatePostViewModel] Failed to create post: \(error)")
            print("❌ [CreatePostViewModel] Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ [CreatePostViewModel] Error domain: \(nsError.domain), code: \(nsError.code)")
                print("❌ [CreatePostViewModel] Error userInfo: \(nsError.userInfo)")
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

        print("🎯 [CreatePostViewModel] Selected \(myVotes.count) my votes")
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
