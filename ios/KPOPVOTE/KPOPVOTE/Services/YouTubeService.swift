//
//  YouTubeService.swift
//  OSHI Pick
//
//  OSHI Pick - YouTube oEmbed API Service
//

import Foundation

class YouTubeService {
    static let shared = YouTubeService()

    private init() {}

    // MARK: - Video Metadata
    struct VideoMetadata {
        let videoId: String
        let title: String
        let thumbnailUrl: String
        let channelName: String?
    }

    // MARK: - oEmbed Response
    private struct OEmbedResponse: Decodable {
        let title: String
        let thumbnailUrl: String
        let authorName: String?

        enum CodingKeys: String, CodingKey {
            case title
            case thumbnailUrl = "thumbnail_url"
            case authorName = "author_name"
        }
    }

    // MARK: - Errors
    enum YouTubeError: Error, LocalizedError {
        case invalidUrl
        case networkError(Error)
        case decodingError
        case noVideoId

        var errorDescription: String? {
            switch self {
            case .invalidUrl:
                return "無効なYouTube URLです"
            case .networkError(let error):
                return "ネットワークエラー: \(error.localizedDescription)"
            case .decodingError:
                return "動画情報の解析に失敗しました"
            case .noVideoId:
                return "動画IDを取得できませんでした"
            }
        }
    }

    // MARK: - Extract Video ID
    /// YouTube URLからビデオIDを抽出
    /// Supported formats:
    /// - https://www.youtube.com/watch?v=VIDEO_ID
    /// - https://youtu.be/VIDEO_ID
    /// - https://www.youtube.com/embed/VIDEO_ID
    /// - https://m.youtube.com/watch?v=VIDEO_ID
    func extractVideoId(from urlString: String) -> String? {
        // Clean up the URL string
        let trimmedUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to parse as URL
        guard let url = URL(string: trimmedUrl) else { return nil }

        // Handle youtu.be short URLs
        if url.host?.contains("youtu.be") == true {
            let videoId = url.pathComponents.last
            return videoId?.isEmpty == false ? videoId : nil
        }

        // Handle youtube.com URLs
        if url.host?.contains("youtube.com") == true {
            // Check for /embed/ format
            if url.pathComponents.contains("embed") {
                if let embedIndex = url.pathComponents.firstIndex(of: "embed"),
                   embedIndex + 1 < url.pathComponents.count {
                    return url.pathComponents[embedIndex + 1]
                }
            }

            // Check for ?v= format
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
                if let vParam = queryItems.first(where: { $0.name == "v" })?.value {
                    return vParam
                }
            }
        }

        return nil
    }

    // MARK: - Validate URL
    /// Check if a string is a valid YouTube URL
    func isValidYouTubeUrl(_ urlString: String) -> Bool {
        return extractVideoId(from: urlString) != nil
    }

    // MARK: - Fetch Metadata
    /// oEmbed APIでメタデータ取得
    func fetchMetadata(url: String) async throws -> VideoMetadata {
        // Extract video ID first
        guard let videoId = extractVideoId(from: url) else {
            throw YouTubeError.noVideoId
        }

        // Build oEmbed API URL
        let encodedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
        let oEmbedUrlString = "https://www.youtube.com/oembed?url=\(encodedUrl)&format=json"

        guard let oEmbedUrl = URL(string: oEmbedUrlString) else {
            throw YouTubeError.invalidUrl
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: oEmbedUrl)

            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    debugLog("❌ [YouTubeService] oEmbed API returned status: \(httpResponse.statusCode)")
                    throw YouTubeError.invalidUrl
                }
            }

            // Decode response
            let decoder = JSONDecoder()
            let oEmbedResponse = try decoder.decode(OEmbedResponse.self, from: data)

            debugLog("✅ [YouTubeService] Fetched metadata for video: \(videoId)")
            debugLog("   Title: \(oEmbedResponse.title)")
            debugLog("   Channel: \(oEmbedResponse.authorName ?? "Unknown")")

            return VideoMetadata(
                videoId: videoId,
                title: oEmbedResponse.title,
                thumbnailUrl: oEmbedResponse.thumbnailUrl,
                channelName: oEmbedResponse.authorName
            )
        } catch let error as YouTubeError {
            throw error
        } catch let error as DecodingError {
            debugLog("❌ [YouTubeService] Decoding error: \(error)")
            throw YouTubeError.decodingError
        } catch {
            debugLog("❌ [YouTubeService] Network error: \(error)")
            throw YouTubeError.networkError(error)
        }
    }

    // MARK: - Get High Quality Thumbnail
    /// Get high quality thumbnail URL from video ID
    func getHighQualityThumbnailUrl(videoId: String) -> String {
        return "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg"
    }

    /// Get maximum resolution thumbnail URL from video ID
    func getMaxResThumbnailUrl(videoId: String) -> String {
        return "https://i.ytimg.com/vi/\(videoId)/maxresdefault.jpg"
    }
}
