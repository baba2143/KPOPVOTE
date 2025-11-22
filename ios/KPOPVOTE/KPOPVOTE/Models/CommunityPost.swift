//
//  CommunityPost.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Community Post Model
//

import Foundation

// MARK: - Post Type
enum PostType: String, Codable {
    case image = "image"
    case myVotes = "my_votes"
    case goodsTrade = "goods_trade"
    case collection = "collection"

    // カスタムデコーダーで後方互換性対応
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        // 旧名称 "vote_share" を新名称 "my_votes" として扱う
        if rawValue == "vote_share" {
            self = .myVotes
        } else if let type = PostType(rawValue: rawValue) {
            self = type
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot initialize PostType from invalid String value \(rawValue)"
            )
        }
    }

    var displayName: String {
        switch self {
        case .image:
            return "画像投稿"
        case .myVotes:
            return "マイ投票"
        case .goodsTrade:
            return "グッズ交換"
        case .collection:
            return "コレクション"
        }
    }
}

// MARK: - Goods Trade Content
struct GoodsTradeContent: Codable {
    var idolId: String
    var idolName: String
    var groupName: String
    var goodsImageUrl: String
    var goodsTags: [String]
    var goodsName: String
    var tradeType: String // "want" or "offer"
    var condition: String? // "new", "excellent", "good", "fair"
    var description: String?
    var status: String // "available", "reserved", "completed"

    init(idolId: String, idolName: String, groupName: String, goodsImageUrl: String, goodsTags: [String], goodsName: String, tradeType: String, condition: String? = nil, description: String? = nil, status: String = "available") {
        self.idolId = idolId
        self.idolName = idolName
        self.groupName = groupName
        self.goodsImageUrl = goodsImageUrl
        self.goodsTags = goodsTags
        self.goodsName = goodsName
        self.tradeType = tradeType
        self.condition = condition
        self.description = description
        self.status = status
    }
}

// MARK: - Post Content
struct PostContent: Codable {
    var text: String?
    var images: [String]?
    var voteIds: [String]?
    var voteSnapshots: [InAppVote]?
    var myVotes: [MyVoteItem]?
    var goodsTrade: GoodsTradeContent?
    var collectionId: String?
    var collectionTitle: String?
    var collectionDescription: String?
    var collectionCoverImage: String?
    var collectionTaskCount: Int?

    enum CodingKeys: String, CodingKey {
        case text, images, voteIds, voteSnapshots, myVotes, goodsTrade
        case collectionId, collectionTitle, collectionDescription, collectionCoverImage, collectionTaskCount
        case voteId  // For backward compatibility
        case voteSnapshot  // For backward compatibility
    }

    init(text: String? = nil, images: [String]? = nil, voteIds: [String]? = nil, voteSnapshots: [InAppVote]? = nil, myVotes: [MyVoteItem]? = nil, goodsTrade: GoodsTradeContent? = nil, collectionId: String? = nil, collectionTitle: String? = nil, collectionDescription: String? = nil, collectionCoverImage: String? = nil, collectionTaskCount: Int? = nil) {
        self.text = text
        self.images = images
        self.voteIds = voteIds
        self.voteSnapshots = voteSnapshots
        self.myVotes = myVotes
        self.goodsTrade = goodsTrade
        self.collectionId = collectionId
        self.collectionTitle = collectionTitle
        self.collectionDescription = collectionDescription
        self.collectionCoverImage = collectionCoverImage
        self.collectionTaskCount = collectionTaskCount
    }

    // Custom decoding for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        text = try container.decodeIfPresent(String.self, forKey: .text)
        images = try container.decodeIfPresent([String].self, forKey: .images)
        myVotes = try container.decodeIfPresent([MyVoteItem].self, forKey: .myVotes)
        goodsTrade = try container.decodeIfPresent(GoodsTradeContent.self, forKey: .goodsTrade)
        collectionId = try container.decodeIfPresent(String.self, forKey: .collectionId)
        collectionTitle = try container.decodeIfPresent(String.self, forKey: .collectionTitle)
        collectionDescription = try container.decodeIfPresent(String.self, forKey: .collectionDescription)
        collectionCoverImage = try container.decodeIfPresent(String.self, forKey: .collectionCoverImage)
        collectionTaskCount = try container.decodeIfPresent(Int.self, forKey: .collectionTaskCount)

        // Try to decode new format first (arrays)
        if let voteIds = try? container.decodeIfPresent([String].self, forKey: .voteIds) {
            self.voteIds = voteIds
        } else if let singleVoteId = try? container.decodeIfPresent(String.self, forKey: .voteId) {
            // Fallback to old format (single value)
            self.voteIds = [singleVoteId]
        } else {
            self.voteIds = nil
        }

        if let voteSnapshots = try? container.decodeIfPresent([InAppVote].self, forKey: .voteSnapshots) {
            self.voteSnapshots = voteSnapshots
        } else if let singleSnapshot = try? container.decodeIfPresent(InAppVote.self, forKey: .voteSnapshot) {
            // Fallback to old format (single value)
            self.voteSnapshots = [singleSnapshot]
        } else {
            self.voteSnapshots = nil
        }
    }

    // Custom encoding (always use new format)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(images, forKey: .images)
        try container.encodeIfPresent(voteIds, forKey: .voteIds)
        try container.encodeIfPresent(voteSnapshots, forKey: .voteSnapshots)
        try container.encodeIfPresent(myVotes, forKey: .myVotes)
        try container.encodeIfPresent(goodsTrade, forKey: .goodsTrade)
        try container.encodeIfPresent(collectionId, forKey: .collectionId)
        try container.encodeIfPresent(collectionTitle, forKey: .collectionTitle)
        try container.encodeIfPresent(collectionDescription, forKey: .collectionDescription)
        try container.encodeIfPresent(collectionCoverImage, forKey: .collectionCoverImage)
        try container.encodeIfPresent(collectionTaskCount, forKey: .collectionTaskCount)
    }
}

// MARK: - My Vote Item
struct MyVoteItem: Codable, Identifiable {
    let id: String
    let voteId: String
    let title: String
    let selectedChoiceId: String?
    let selectedChoiceLabel: String?
    let pointsUsed: Int
    let votedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case voteId
        case title
        case selectedChoiceId
        case selectedChoiceLabel
        case pointsUsed
        case votedAt
    }

    init(id: String = UUID().uuidString, voteId: String, title: String, selectedChoiceId: String? = nil, selectedChoiceLabel: String? = nil, pointsUsed: Int, votedAt: Date) {
        self.id = id
        self.voteId = voteId
        self.title = title
        self.selectedChoiceId = selectedChoiceId
        self.selectedChoiceLabel = selectedChoiceLabel
        self.pointsUsed = pointsUsed
        self.votedAt = votedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        voteId = try container.decode(String.self, forKey: .voteId)
        title = try container.decode(String.self, forKey: .title)
        selectedChoiceId = try container.decodeIfPresent(String.self, forKey: .selectedChoiceId)
        selectedChoiceLabel = try container.decodeIfPresent(String.self, forKey: .selectedChoiceLabel)
        pointsUsed = try container.decode(Int.self, forKey: .pointsUsed)

        if let timestamp = try? container.decode(Double.self, forKey: .votedAt) {
            votedAt = Date(timeIntervalSince1970: timestamp)
        } else {
            votedAt = Date()
        }
    }
}

// MARK: - Community Post
struct CommunityPost: Codable, Identifiable {
    let id: String
    let userId: String
    var user: User
    let type: PostType
    var content: PostContent
    var biasIds: [String]
    var likesCount: Int
    var commentsCount: Int
    var sharesCount: Int
    var isReported: Bool
    var reportCount: Int
    var createdAt: Date
    var updatedAt: Date

    // Client-side properties (not in Firestore)
    var isLiked: Bool = false
    var isLikedByCurrentUser: Bool?
    var userDisplayName: String?
    var userPhotoURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case user
        case type
        case content
        case biasIds
        case likesCount
        case commentsCount
        case sharesCount
        case isReported
        case reportCount
        case createdAt
        case updatedAt
        case isLiked
    }

    init(id: String = UUID().uuidString, userId: String, user: User, type: PostType, content: PostContent, biasIds: [String], likesCount: Int = 0, commentsCount: Int = 0, sharesCount: Int = 0, isReported: Bool = false, reportCount: Int = 0, isLiked: Bool = false) {
        self.id = id
        self.userId = userId
        self.user = user
        self.type = type
        self.content = content
        self.biasIds = biasIds
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.sharesCount = sharesCount
        self.isReported = isReported
        self.reportCount = reportCount
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isLiked = isLiked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        user = try container.decode(User.self, forKey: .user)
        type = try container.decode(PostType.self, forKey: .type)
        content = try container.decode(PostContent.self, forKey: .content)
        biasIds = try container.decodeIfPresent([String].self, forKey: .biasIds) ?? []
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount) ?? 0
        sharesCount = try container.decodeIfPresent(Int.self, forKey: .sharesCount) ?? 0
        isReported = try container.decodeIfPresent(Bool.self, forKey: .isReported) ?? false
        reportCount = try container.decodeIfPresent(Int.self, forKey: .reportCount) ?? 0
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false

        if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            createdAt = Date()
        }

        if let timestamp = try? container.decode(Double.self, forKey: .updatedAt) {
            updatedAt = Date(timeIntervalSince1970: timestamp)
        } else {
            updatedAt = Date()
        }
    }
}

// MARK: - Community Post Extension
extension CommunityPost {
    var formattedCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    var hasImages: Bool {
        return content.images?.isEmpty == false
    }

    var hasVote: Bool {
        return content.voteIds?.isEmpty == false && content.voteSnapshots?.isEmpty == false
    }

    var hasMyVotes: Bool {
        return content.myVotes?.isEmpty == false
    }
}
