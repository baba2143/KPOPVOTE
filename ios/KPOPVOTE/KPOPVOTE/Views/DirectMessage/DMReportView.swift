//
//  DMReportView.swift
//  OSHI Pick
//
//  OSHI Pick - DM Report View
//

import SwiftUI

struct DMReportView: View {
    @Environment(\.dismiss) private var dismiss

    let reportType: DMReportType
    let conversationId: String
    let reporteeId: String
    let reporteeName: String?
    let message: DirectMessage?  // Only for message reports

    @State private var reason: String = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""

    private var isValid: Bool {
        !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                        // Header
                        headerSection

                        // Message preview (for message reports)
                        if reportType == .message, let message = message {
                            messagePreviewSection(message: message)
                        }

                        // Reason input
                        reasonInputSection

                        // Submit button
                        submitButton
                    }
                    .padding()
                }
                .dismissKeyboardOnTap()
                .keyboardDoneButton()
            }
            .navigationTitle("報告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textGray)
                }
            }
            .alert("報告が完了しました", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("ご報告ありがとうございます。内容を確認し、適切に対応いたします。")
            }
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .disabled(isSubmitting)
        }
    }

    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 24))

                Text(reportType == .message ? "メッセージを報告" : "ユーザーを報告")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)
            }

            if let name = reporteeName {
                Text("対象: \(name)")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
            }
        }
    }

    // MARK: - Message Preview Section
    @ViewBuilder
    private func messagePreviewSection(message: DirectMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("報告対象のメッセージ")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.Colors.textGray)

            VStack(alignment: .leading, spacing: 4) {
                if let text = message.text {
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textWhite)
                        .padding(12)
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(12)
                }

                if message.imageURL != nil {
                    Text("[画像]")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
                        .italic()
                }
            }
        }
    }

    // MARK: - Reason Input Section
    @ViewBuilder
    private var reasonInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("報告理由")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.Colors.textGray)

            Text("問題の詳細をお知らせください")
                .font(.system(size: 12))
                .foregroundColor(Constants.Colors.textGray.opacity(0.7))

            TextEditor(text: $reason)
                .scrollContentBackground(.hidden)
                .background(Constants.Colors.cardDark)
                .foregroundColor(Constants.Colors.textWhite)
                .font(.system(size: 15))
                .frame(minHeight: 150)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Constants.Colors.textGray.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if reason.isEmpty {
                            Text("例：不適切な内容、スパム、嫌がらせなど")
                                .font(.system(size: 15))
                                .foregroundColor(Constants.Colors.textGray.opacity(0.5))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }

    // MARK: - Submit Button
    @ViewBuilder
    private var submitButton: some View {
        Button(action: submitReport) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("報告する")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isValid ? Color.red : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isValid || isSubmitting)
        .padding(.top, Constants.Spacing.medium)
    }

    // MARK: - Submit Report
    private func submitReport() {
        guard isValid else { return }

        isSubmitting = true

        Task {
            do {
                if reportType == .message, let message = message {
                    try await DMReportService.shared.reportMessage(
                        conversationId: conversationId,
                        messageId: message.id,
                        messageContent: message.text ?? "[画像]",
                        reporteeId: reporteeId,
                        reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } else {
                    try await DMReportService.shared.reportUser(
                        conversationId: conversationId,
                        reporteeId: reporteeId,
                        reason: reason.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }

                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    DMReportView(
        reportType: .user,
        conversationId: "test_conversation",
        reporteeId: "test_user",
        reporteeName: "テストユーザー",
        message: nil
    )
}
