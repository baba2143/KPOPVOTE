//
//  IdolRankingHintBanner.swift
//  KPOPVOTE
//
//  Hint banner to guide users to the "+" button for voting on idols not in the list
//

import SwiftUI

struct IdolRankingHintBanner: View {
    let onTap: () -> Void
    let onDismiss: () -> Void
    @AppStorage("hasSeenIdolRankingHint") private var hasSeenHint = false

    var body: some View {
        if !hasSeenHint {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.subheadline)

                    Text("推しが見つからない？タップして検索")
                        .font(.subheadline)
                        .foregroundColor(Constants.Colors.textWhite)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            hasSeenHint = true
                        }
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Constants.Colors.textGray)
                            .font(.subheadline)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(12)
                .background(Constants.Colors.cardDark)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Constants.Colors.accentBlue.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            .padding(.top, 8)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Constants.Colors.backgroundDark
            .ignoresSafeArea()

        VStack {
            IdolRankingHintBanner(
                onTap: { print("Tapped banner") },
                onDismiss: { print("Dismissed banner") }
            )
            Spacer()
        }
    }
}
