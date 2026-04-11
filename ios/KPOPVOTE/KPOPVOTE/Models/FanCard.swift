//
//  FanCard.swift
//  KPOPVOTE
//
//  FanCard data models
//

import Foundation

// MARK: - FanCard Theme
enum FanCardTemplate: String, Codable, CaseIterable {
    case `default` = "default"
    case cute = "cute"
    case cool = "cool"
    case elegant = "elegant"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .default: return "デフォルト"
        case .cute: return "キュート"
        case .cool: return "クール"
        case .elegant: return "エレガント"
        case .dark: return "ダーク"
        }
    }
}

enum FanCardFontFamily: String, Codable, CaseIterable {
    case `default` = "default"
    case rounded = "rounded"
    case serif = "serif"

    var displayName: String {
        switch self {
        case .default: return "デフォルト"
        case .rounded: return "丸ゴシック"
        case .serif: return "明朝体"
        }
    }
}

struct FanCardTheme: Codable {
    var template: FanCardTemplate
    var backgroundColor: String
    var primaryColor: String
    var fontFamily: FanCardFontFamily

    static let `default` = FanCardTheme(
        template: .default,
        backgroundColor: "#ffffff",
        primaryColor: "#8b5cf6",
        fontFamily: .default
    )
}

// MARK: - FanCard Blocks
enum FanCardBlockType: String, Codable {
    case bias = "bias"
    case link = "link"
    case mvLink = "mvLink"
    case sns = "sns"
    case text = "text"
    case image = "image"
}

enum SNSPlatform: String, Codable, CaseIterable {
    case x = "x"
    case instagram = "instagram"
    case tiktok = "tiktok"
    case youtube = "youtube"
    case threads = "threads"
    case other = "other"

    var displayName: String {
        switch self {
        case .x: return "X (Twitter)"
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .youtube: return "YouTube"
        case .threads: return "Threads"
        case .other: return "その他"
        }
    }

    var iconName: String {
        switch self {
        case .x: return "xmark.circle.fill"
        case .instagram: return "camera.circle.fill"
        case .tiktok: return "music.note"
        case .youtube: return "play.rectangle.fill"
        case .threads: return "at.circle.fill"
        case .other: return "link.circle.fill"
        }
    }
}

// Block Data structures
struct BiasBlockData: Codable {
    var showFromMyBias: Bool
    var customBias: [CustomBias]?

    struct CustomBias: Codable, Identifiable {
        var artistId: String
        var artistName: String
        var memberId: String?
        var memberName: String?
        var imageUrl: String?

        var id: String { "\(artistId)-\(memberId ?? "group")" }
    }
}

struct LinkBlockData: Codable {
    var title: String
    var url: String
    var iconUrl: String?
    var backgroundColor: String?
}

struct MVLinkBlockData: Codable {
    var title: String
    var youtubeUrl: String
    var thumbnailUrl: String?
    var artistName: String?
}

struct SNSBlockData: Codable {
    var platform: SNSPlatform
    var username: String
    var url: String?
}

struct TextBlockData: Codable {
    var content: String
    var alignment: String
}

struct ImageBlockData: Codable {
    var imageUrl: String
    var caption: String?
    var linkUrl: String?
}

// MARK: - FanCard Block
struct FanCardBlock: Codable, Identifiable {
    var id: String
    var type: FanCardBlockType
    var order: Int
    var isVisible: Bool
    var data: BlockData

    enum BlockData: Codable {
        case bias(BiasBlockData)
        case link(LinkBlockData)
        case mvLink(MVLinkBlockData)
        case sns(SNSBlockData)
        case text(TextBlockData)
        case image(ImageBlockData)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let biasData = try? container.decode(BiasBlockData.self),
               biasData.showFromMyBias != nil || biasData.customBias != nil {
                self = .bias(biasData)
            } else if let linkData = try? container.decode(LinkBlockData.self),
                      !linkData.url.isEmpty {
                self = .link(linkData)
            } else if let mvLinkData = try? container.decode(MVLinkBlockData.self),
                      !mvLinkData.youtubeUrl.isEmpty {
                self = .mvLink(mvLinkData)
            } else if let snsData = try? container.decode(SNSBlockData.self),
                      !snsData.username.isEmpty {
                self = .sns(snsData)
            } else if let textData = try? container.decode(TextBlockData.self),
                      !textData.content.isEmpty {
                self = .text(textData)
            } else if let imageData = try? container.decode(ImageBlockData.self),
                      !imageData.imageUrl.isEmpty {
                self = .image(imageData)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown block data type")
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .bias(let data): try container.encode(data)
            case .link(let data): try container.encode(data)
            case .mvLink(let data): try container.encode(data)
            case .sns(let data): try container.encode(data)
            case .text(let data): try container.encode(data)
            case .image(let data): try container.encode(data)
            }
        }
    }
}

// MARK: - FanCard
struct FanCard: Codable, Identifiable {
    var id: String { odDisplayName }
    var odDisplayName: String
    var userId: String
    var displayName: String
    var bio: String
    var profileImageUrl: String
    var headerImageUrl: String
    var theme: FanCardTheme
    var blocks: [FanCardBlock]
    var isPublic: Bool
    var viewCount: Int
    var createdAt: String
    var updatedAt: String
}

// MARK: - API Request/Response
struct FanCardCreateRequest: Codable {
    var odDisplayName: String
    var displayName: String
    var bio: String?
    var profileImageUrl: String?
    var headerImageUrl: String?
    var theme: FanCardTheme?
    var blocks: [FanCardBlock]?
    var isPublic: Bool?
}

struct FanCardUpdateRequest: Codable {
    var displayName: String?
    var bio: String?
    var profileImageUrl: String?
    var headerImageUrl: String?
    var theme: FanCardTheme?
    var blocks: [FanCardBlock]?
    var isPublic: Bool?
}

struct CheckOdDisplayNameResponse: Codable {
    var available: Bool
    var normalizedName: String
}

// MARK: - API Response Wrapper
struct FanCardAPIResponse<T: Codable>: Codable {
    var success: Bool
    var data: T?
    var error: String?
}

struct FanCardDataResponse: Codable {
    var fanCard: FanCard?
}

struct CheckNameDataResponse: Codable {
    var available: Bool
    var normalizedName: String
}
