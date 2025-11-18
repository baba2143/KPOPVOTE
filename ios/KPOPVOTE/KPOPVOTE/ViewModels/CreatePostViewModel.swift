//
//  CreatePostViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Create Post ViewModel
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
    @Published var selectedVoteId: String?
    @Published var selectedVoteSnapshot: InAppVote?
    @Published var selectedMyVotes: [MyVoteItem] = []
    @Published var selectedBiasIds: [String] = []
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var isSuccess = false

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
        switch selectedType {
        case .voteShare:
            return selectedVoteId != nil && selectedVoteSnapshot != nil && !selectedBiasIds.isEmpty
        case .image:
            return !textContent.isEmpty && !selectedBiasIds.isEmpty
        case .myVotes:
            return !selectedMyVotes.isEmpty && !selectedBiasIds.isEmpty
        case .goodsTrade:
            return selectedGoodsImage != nil &&
                   !goodsName.isEmpty &&
                   !goodsTags.isEmpty &&
                   !selectedBiasIds.isEmpty
        }
    }

    // MARK: - Create Post
    /// Submit the post
    func submitPost() async {
        guard canSubmit else {
            errorMessage = "必須項目を入力してください"
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            // Build PostContent based on type
            var content = PostContent()

            switch selectedType {
            case .voteShare:
                content.voteId = selectedVoteId
                content.voteSnapshot = selectedVoteSnapshot
            case .image:
                content.text = textContent
                content.images = selectedImageURLs.isEmpty ? nil : selectedImageURLs
            case .myVotes:
                content.myVotes = selectedMyVotes
                if !textContent.isEmpty {
                    content.text = textContent
                }
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
            }

            print("📤 [CreatePostViewModel] Creating post: type=\(selectedType.rawValue)")
            _ = try await CommunityService.shared.createPost(
                type: selectedType,
                content: content,
                biasIds: selectedBiasIds
            )

            print("✅ [CreatePostViewModel] Post created successfully")
            isSuccess = true
        } catch {
            print("❌ [CreatePostViewModel] Failed to create post: \(error)")
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    // MARK: - Select Vote
    /// Set selected vote for voteShare type
    func selectVote(vote: InAppVote) {
        selectedVoteId = vote.id
        selectedVoteSnapshot = vote
        selectedType = .voteShare

        print("🎯 [CreatePostViewModel] Selected vote: \(vote.title)")
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
        selectedVoteId = nil
        selectedVoteSnapshot = nil
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
