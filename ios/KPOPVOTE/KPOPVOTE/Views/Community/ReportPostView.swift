//
//  ReportPostView.swift
//  KPOPVOTE
//
//  Report community post view
//

import SwiftUI

struct ReportPostView: View {
    let postId: String
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String = ""
    @State private var additionalComment: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let reasons = [
        "スパム",
        "不適切なコンテンツ",
        "嫌がらせ・誹謗中傷",
        "なりすまし",
        "著作権侵害",
        "その他"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                        // Header
                        Text("この投稿を通報する理由を選択してください")
                            .font(.system(size: Constants.Typography.bodySize))
                            .foregroundColor(Constants.Colors.textGray)
                            .padding(.top, Constants.Spacing.medium)

                        // Reason Selection
                        VStack(spacing: Constants.Spacing.small) {
                            ForEach(reasons, id: \.self) { reason in
                                Button(action: {
                                    selectedReason = reason
                                }) {
                                    HStack {
                                        Text(reason)
                                            .font(.system(size: Constants.Typography.bodySize))
                                            .foregroundColor(Constants.Colors.textWhite)

                                        Spacer()

                                        if selectedReason == reason {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Constants.Colors.accentPink)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(Constants.Colors.textGray)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedReason == reason ? Constants.Colors.accentPink.opacity(0.15) : Color.white.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedReason == reason ? Constants.Colors.accentPink : Color.clear, lineWidth: 1)
                                    )
                                }
                            }
                        }

                        // Additional Comment (optional)
                        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                            Text("詳細（任意）")
                                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textGray)

                            ZStack(alignment: .topLeading) {
                                if additionalComment.isEmpty {
                                    Text("追加の詳細があれば入力してください...")
                                        .font(.system(size: Constants.Typography.bodySize))
                                        .foregroundColor(Constants.Colors.textGray.opacity(0.5))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                }

                                TextEditor(text: $additionalComment)
                                    .font(.system(size: Constants.Typography.bodySize))
                                    .scrollContentBackground(.hidden)
                                    .padding(8)
                                    .frame(minHeight: 100)
                                    .background(Constants.Colors.cardDark)
                                    .cornerRadius(12)
                                    .tint(Constants.Colors.accentPink)
                                    .foregroundStyle(.white)
                            }
                        }

                        // Error message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                        }

                        // Submit Button
                        Button(action: {
                            Task {
                                await submitReport()
                            }
                        }) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("通報する")
                                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedReason.isEmpty ? Constants.Colors.textGray : Constants.Colors.accentPink)
                            )
                        }
                        .disabled(selectedReason.isEmpty || isSubmitting)
                        .padding(.top, Constants.Spacing.medium)

                        Spacer()
                    }
                    .padding()
                }
                .dismissKeyboardOnTap()
                .keyboardDoneButton()
            }
            .navigationTitle("投稿を通報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
        }
    }

    private func submitReport() async {
        guard !selectedReason.isEmpty else { return }

        isSubmitting = true
        errorMessage = nil

        let reason: String
        if selectedReason == "その他" && !additionalComment.isEmpty {
            reason = "その他: \(additionalComment)"
        } else if !additionalComment.isEmpty {
            reason = "\(selectedReason) - \(additionalComment)"
        } else {
            reason = selectedReason
        }

        do {
            try await ReportService.shared.reportCommunityPost(postId: postId, reason: reason)
            dismiss()
            onComplete()
        } catch {
            debugLog("❌ [ReportPostView] Failed to submit report: \(error)")
            errorMessage = "通報の送信に失敗しました。もう一度お試しください。"
        }

        isSubmitting = false
    }
}

#Preview {
    ReportPostView(postId: "test-post-id") {
        print("Report completed")
    }
}
