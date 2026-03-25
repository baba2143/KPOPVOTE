//
//  YouTubePlayerView.swift
//  OSHI Pick
//
//  OSHI Pick - YouTube Player Component using WKWebView
//

import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String
    var autoplay: Bool = false

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = autoplay ? [] : .all

        // JavaScript明示的有効化（エラー153対策）
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // バンドルIDからリファラーURLを生成（Error 153対策の核心）
        // 参考: https://tech.yappli.io/entry/webview-show-youtube
        let bundleId = Bundle.main.bundleIdentifier ?? "com.example.app"
        let referrer = "https://\(bundleId)".lowercased()
        guard let referrerUrl = URL(string: referrer) else { return }

        // YouTube embed URLを構築
        var urlComponents = URLComponents(string: "https://www.youtube.com/embed/\(videoId)")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "rel", value: "0"),
            URLQueryItem(name: "modestbranding", value: "1"),
            URLQueryItem(name: "enablejsapi", value: "1"),
            URLQueryItem(name: "fs", value: "1"),
        ]

        if autoplay {
            queryItems.append(URLQueryItem(name: "autoplay", value: "1"))
        }

        urlComponents.queryItems = queryItems

        guard let embedUrl = urlComponents.url else { return }

        // iframe HTMLを生成してloadHTMLStringで読み込み
        // baseURLを設定することでRefererヘッダーが正しく送信される
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; }
                html, body { width: 100%; height: 100%; background: #000; }
                iframe { width: 100%; height: 100%; border: none; }
            </style>
        </head>
        <body>
            <iframe
                src="\(embedUrl.absoluteString)"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: referrerUrl)
    }
}

// MARK: - YouTube Thumbnail View
struct YouTubeThumbnailView: View {
    let videoId: String
    let thumbnailUrl: String?
    var onPlay: (() -> Void)?

    var body: some View {
        ZStack {
            // Thumbnail Image
            if let thumbnailUrl = thumbnailUrl, let url = URL(string: thumbnailUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    case .failure(_), .empty:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                // Fallback to YouTube thumbnail URL
                AsyncImage(url: URL(string: YouTubeService.shared.getHighQualityThumbnailUrl(videoId: videoId))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                    case .failure(_), .empty:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            }

            // Play Button Overlay
            if let onPlay = onPlay {
                Button(action: onPlay) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 68, height: 68)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                        Image(systemName: "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .offset(x: 2) // Slight offset for visual centering
                    }
                }
            } else {
                // Static play button (no action)
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 68, height: 68)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                    Image(systemName: "play.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .offset(x: 2)
                }
            }
        }
    }

    @ViewBuilder
    private var placeholderView: some View {
        Rectangle()
            .fill(Constants.Colors.backgroundDark)
            .aspectRatio(16/9, contentMode: .fill)
            .overlay(
                Image(systemName: "play.rectangle")
                    .font(.system(size: 40))
                    .foregroundColor(Constants.Colors.textGray)
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        YouTubePlayerView(videoId: "dQw4w9WgXcQ")
            .frame(height: 220)
            .cornerRadius(12)

        YouTubeThumbnailView(
            videoId: "dQw4w9WgXcQ",
            thumbnailUrl: nil,
            onPlay: { print("Play tapped") }
        )
        .frame(height: 200)
        .cornerRadius(12)
    }
    .padding()
    .background(Color.black)
}
