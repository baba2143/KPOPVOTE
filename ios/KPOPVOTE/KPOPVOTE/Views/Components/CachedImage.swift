//
//  CachedImage.swift
//  KPOPVOTE
//
//  画像キャッシュ付きの共通画像コンポーネント
//  AsyncImage の代わりに使用してパフォーマンス改善
//

import SwiftUI
import Kingfisher

/// AnyShape for conditional shape application
struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

/// キャッシュ付き画像コンポーネント
/// AsyncImage の代わりに使用することで、画像の再ダウンロードを防ぎ
/// スクロール・画面遷移時のパフォーマンスを大幅に改善
struct CachedImage: View {
    let url: String?
    var width: CGFloat = 40
    var height: CGFloat = 40
    var isCircle: Bool = true
    var cornerRadius: CGFloat = 0
    var contentMode: SwiftUI.ContentMode = .fill

    var body: some View {
        Group {
            if let urlString = url,
               let imageURL = URL(string: urlString) {
                KFImage(imageURL)
                    .resizable()
                    .placeholder {
                        placeholderView
                    }
                    .fade(duration: 0.15)
                    .cacheOriginalImage()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholderView
            }
        }
        .frame(width: width, height: height)
        .clipShape(isCircle
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: cornerRadius)))
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
    }
}

/// プロフィール画像専用のプリセット
struct CachedProfileImage: View {
    let url: String?
    var size: CGFloat = 40

    var body: some View {
        CachedImage(
            url: url,
            width: size,
            height: size,
            isCircle: true
        )
    }
}

/// サムネイル画像専用のプリセット
struct CachedThumbnailImage: View {
    let url: String?
    var width: CGFloat = 120
    var height: CGFloat = 80
    var cornerRadius: CGFloat = 8

    var body: some View {
        CachedImage(
            url: url,
            width: width,
            height: height,
            isCircle: false,
            cornerRadius: cornerRadius,
            contentMode: .fill
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CachedImage(
            url: "https://example.com/image.jpg",
            width: 100,
            height: 100,
            isCircle: true
        )

        CachedProfileImage(url: nil, size: 60)

        CachedThumbnailImage(
            url: "https://example.com/thumb.jpg",
            width: 200,
            height: 150
        )
    }
    .padding()
}
