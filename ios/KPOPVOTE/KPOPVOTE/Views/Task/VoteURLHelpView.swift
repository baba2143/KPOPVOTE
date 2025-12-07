//
//  VoteURLHelpView.swift
//  KPOPVOTE
//
//  投票URLの取得方法を説明するヘルプビュー
//

import SwiftUI

struct VoteURLHelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    Text("投票URLの取得方法")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                        .padding(.top)

                    // Step 1
                    stepView(
                        number: 1,
                        title: "投票ページからXへ共有",
                        description: "各アプリの投票ページから共有ボタンをタップし、Xで共有する",
                        imageName: "vote_help_step1"
                    )

                    // Step 2
                    stepView(
                        number: 2,
                        title: "XのツイートからURLを長押し",
                        description: "投稿されたツイート内のURL部分を長押しする",
                        imageName: "vote_help_step2"
                    )

                    // Step 3
                    stepView(
                        number: 3,
                        title: "リンクをコピーして貼り付け",
                        description: "「リンクをコピー」を選択し、投票URLに貼り付ける",
                        imageName: "vote_help_step3"
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
            }
            .background(Constants.Colors.backgroundDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func stepView(number: Int, title: String, description: String, imageName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step number and title
            HStack(spacing: 12) {
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Constants.Colors.accentPink)
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)
            }

            // Description
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textGray)
                .padding(.leading, 40)

            // Image
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 400)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Constants.Colors.cardDark, lineWidth: 1)
                )
                .padding(.top, 8)
        }
    }
}

#Preview {
    VoteURLHelpView()
}
