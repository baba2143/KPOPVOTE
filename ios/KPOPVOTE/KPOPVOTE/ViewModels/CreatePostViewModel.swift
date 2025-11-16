//
//  CreatePostViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Create Post ViewModel
//

import Foundation
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
