//
//  PostEditView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Post Edit View
//

import SwiftUI
import FirebaseAuth

struct PostEditView: View {
    @Environment(\.dismiss) var dismiss

    let post: CommunityPost
    let onPostUpdated: (CommunityPost) -> Void

    @State private var editedText: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(post: CommunityPost, onPostUpdated: @escaping (CommunityPost) -> Void) {
        self.post = post
        self.onPostUpdated = onPostUpdated
        _editedText = State(initialValue: post.content.text ?? "")
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: Constants.Spacing.large) {
                    // Text Editor
                    VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                        Text("投稿内容")
                            .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textGray)

                        TextEditor(text: $editedText)
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                            .padding(Constants.Spacing.medium)
                            .background(Constants.Colors.cardDark)
                            .cornerRadius(12)
                            .tint(Constants.Colors.accentPink)
                            .onAppear {
                                UITextView.appearance().textColor = UIColor(Constants.Colors.textWhite)
                            }
                    }

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(Constants.Spacing.large)

                // Loading Overlay
                if isSaving {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("投稿を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textWhite)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            await savePost()
                        }
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                    .disabled(isSaving || editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Save Post
    private func savePost() async {
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else {
            errorMessage = "投稿内容を入力してください"
            return
        }

        // Check if text has actually changed
        if trimmedText == (post.content.text ?? "") {
            dismiss()
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            // Update content with new text
            var updatedContent = post.content
            updatedContent.text = trimmedText

            let updatedPost = try await CommunityService.shared.updatePost(
                postId: post.id,
                content: updatedContent
            )

            print("✅ [PostEditView] Post updated successfully")

            // Call the callback with updated post
            onPostUpdated(updatedPost)

            dismiss()
        } catch let error as CommunityError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "投稿の更新に失敗しました"
        }

        isSaving = false
    }
}
