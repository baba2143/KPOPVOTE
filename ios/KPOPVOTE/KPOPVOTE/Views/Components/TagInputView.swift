//
//  TagInputView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Tag Input Component
//

import SwiftUI

struct TagInputView: View {
    @Binding var tags: [String]
    @State private var inputText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            // 入力済みタグ表示
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChipView(tag: tag) {
                            tags.removeAll { $0 == tag }
                        }
                    }
                }
                .padding(.bottom, Constants.Spacing.small)
            }

            // タグ入力欄
            HStack(spacing: Constants.Spacing.small) {
                TextField("タグを入力（例: うちわ、トレカ）", text: $inputText)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    .foregroundColor(Constants.Colors.textWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Constants.Colors.accentPink.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit {
                        addTag()
                    }

                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(inputText.isEmpty ? Constants.Colors.textGray : Constants.Colors.accentPink)
                }
                .disabled(inputText.isEmpty)
            }
        }
    }

    private func addTag() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            inputText = ""
        }
    }
}

// MARK: - Tag Chip View
struct TagChipView: View {
    let tag: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(tag)
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Constants.Colors.accentPink)
        .cornerRadius(16)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        TagInputView(tags: .constant(["うちわ", "ペンライト", "トレカ"]))
            .padding()

        Spacer()
    }
    .background(Constants.Colors.backgroundDark)
}
