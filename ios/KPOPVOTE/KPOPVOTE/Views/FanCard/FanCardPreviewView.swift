//
//  FanCardPreviewView.swift
//  KPOPVOTE
//
//  FanCard Preview using WKWebView
//

import SwiftUI
import WebKit

struct FanCardPreviewView: View {
    @ObservedObject var viewModel: FanCardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if let url = previewURL {
                    FanCardWebView(url: url, isLoading: $isLoading, loadError: $loadError)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("プレビューURLを生成できませんでした")
                            .font(.headline)
                        Text("FanCardデータを確認してください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("プレビューを読み込み中...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.9))
                }

                if let error = loadError {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("読み込みエラー")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("プレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Generate preview URL with Base64-encoded FanCard data
    private var previewURL: URL? {
        // Create preview data structure
        let previewData = FanCardPreviewData(
            odDisplayName: viewModel.odDisplayName,
            displayName: viewModel.displayName,
            bio: viewModel.bio,
            profileImageUrl: viewModel.profileImage != nil ? "" : viewModel.profileImageUrl,
            headerImageUrl: viewModel.headerImage != nil ? "" : viewModel.headerImageUrl,
            theme: viewModel.theme,
            blocks: viewModel.blocks.filter { isBlockValid($0) },
            isPublic: viewModel.isPublic
        )

        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(previewData)

            // Base64 URL-safe encode (replace + with -, / with _, remove =)
            let base64String = jsonData.base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")

            guard let encodedData = base64String.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                debugLog("❌ [FanCardPreview] Failed to URL encode base64 data")
                return nil
            }

            let urlString = "https://oshipick.com/preview?data=\(encodedData)"
            debugLog("ℹ️ [FanCardPreview] URL length: \(urlString.count)")
            debugLog("ℹ️ [FanCardPreview] URL: \(urlString.prefix(500))...")

            return URL(string: urlString)
        } catch {
            debugLog("❌ [FanCardPreview] Failed to encode FanCard: \(error)")
            return nil
        }
    }

    /// Check if a block has valid data for preview
    private func isBlockValid(_ block: FanCardBlock) -> Bool {
        switch block.data {
        case .bias:
            return true
        case .link(let data):
            return !data.url.isEmpty
        case .mvLink(let data):
            return !data.youtubeUrl.isEmpty
        case .sns(let data):
            return !data.username.isEmpty
        case .text(let data):
            return !data.content.isEmpty
        case .image(let data):
            return !data.imageUrl.isEmpty
        }
    }
}

// MARK: - Preview Data Structure
/// Simplified FanCard structure for preview (matches web/fancard PreviewFanCard interface)
struct FanCardPreviewData: Codable {
    let odDisplayName: String
    let displayName: String
    let bio: String
    let profileImageUrl: String
    let headerImageUrl: String
    let theme: FanCardTheme
    let blocks: [FanCardBlock]
    let isPublic: Bool
}

// MARK: - WKWebView Wrapper
struct FanCardWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var loadError: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Enable JavaScript
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.backgroundColor = .systemBackground
        webView.isOpaque = true

        // Allow pull to refresh
        webView.scrollView.bounces = true

        // Load URL immediately on creation
        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Do not reload - URL is loaded once in makeUIView
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: FanCardWebView

        init(_ parent: FanCardWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.loadError = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadError = error.localizedDescription
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadError = error.localizedDescription
            }
        }
    }
}

#Preview {
    FanCardPreviewView(viewModel: FanCardViewModel())
}
