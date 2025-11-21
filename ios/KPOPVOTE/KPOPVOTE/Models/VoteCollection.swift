//
//  VoteCollection.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote Collection Models
//

import Foundation
import FirebaseFirestore

/// Vote Collection - User-created collection of voting tasks
struct VoteCollection: Codable, Identifiable {
    // MARK: - Basic Information
    let id: String              // collectionId
    let creatorId: String
    let creatorName: String
    let creatorAvatarUrl: String?

    // MARK: - Collection Content
    var title: String           // Max 50 characters
    var description: String     // Max 500 characters
    var coverImage: String?
    var tags: [String]          // Max 10 tags

    // MARK: - Included Tasks
    var tasks: [VoteTaskInCollection]  // Max 50 tasks
    var taskCount: Int

    // MARK: - Visibility Settings
    var visibility: CollectionVisibility

    // MARK: - Engagement Metrics
    var likeCount: Int
    var saveCount: Int
    var viewCount: Int
    var commentCount: Int

    // MARK: - Timestamps
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id = "collectionId"
        case creatorId
        case creatorName
        case creatorAvatarUrl
        case title
        case description
        case coverImage
        case tags
        case tasks
        case taskCount
        case visibility
        case likeCount
        case saveCount
        case viewCount
        case commentCount
        case createdAt
        case updatedAt
    }

    // MARK: - Firestore Conversion
    init(from document: DocumentSnapshot) throws {
        let data = document.data() ?? [:]

        self.id = document.documentID
        self.creatorId = data["creatorId"] as? String ?? ""
        self.creatorName = data["creatorName"] as? String ?? ""
        self.creatorAvatarUrl = data["creatorAvatarUrl"] as? String

        self.title = data["title"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.coverImage = data["coverImage"] as? String
        self.tags = data["tags"] as? [String] ?? []

        // Parse tasks
        if let tasksData = data["tasks"] as? [[String: Any]] {
            self.tasks = tasksData.compactMap { VoteTaskInCollection(from: $0) }
        } else {
            self.tasks = []
        }

        self.taskCount = data["taskCount"] as? Int ?? self.tasks.count

        if let visibilityString = data["visibility"] as? String {
            self.visibility = CollectionVisibility(rawValue: visibilityString) ?? .public
        } else {
            self.visibility = .public
        }

        self.likeCount = data["likeCount"] as? Int ?? 0
        self.saveCount = data["saveCount"] as? Int ?? 0
        self.viewCount = data["viewCount"] as? Int ?? 0
        self.commentCount = data["commentCount"] as? Int ?? 0

        // Parse timestamps
        if let createdTimestamp = data["createdAt"] as? Timestamp {
            self.createdAt = createdTimestamp.dateValue()
        } else {
            self.createdAt = Date()
        }

        if let updatedTimestamp = data["updatedAt"] as? Timestamp {
            self.updatedAt = updatedTimestamp.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
}

/// Task within a Collection
struct VoteTaskInCollection: Codable, Identifiable {
    let id: String              // taskId
    let title: String
    let url: String
    let deadline: Date
    let externalAppId: String?
    let externalAppName: String?
    let externalAppIconUrl: String?
    let coverImage: String?
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id = "taskId"
        case title
        case url
        case deadline
        case externalAppId
        case externalAppName
        case externalAppIconUrl
        case coverImage
        case orderIndex
    }

    // MARK: - Dictionary Conversion
    init?(from dict: [String: Any]) {
        guard let taskId = dict["taskId"] as? String,
              let title = dict["title"] as? String,
              let url = dict["url"] as? String else {
            return nil
        }

        self.id = taskId
        self.title = title
        self.url = url

        if let deadlineTimestamp = dict["deadline"] as? Timestamp {
            self.deadline = deadlineTimestamp.dateValue()
        } else {
            self.deadline = Date()
        }

        self.externalAppId = dict["externalAppId"] as? String
        self.externalAppName = dict["externalAppName"] as? String
        self.externalAppIconUrl = dict["externalAppIconUrl"] as? String
        self.coverImage = dict["coverImage"] as? String
        self.orderIndex = dict["orderIndex"] as? Int ?? 0
    }

    // MARK: - Time Remaining
    var timeRemaining: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: Date(), to: deadline)

        if let days = components.day, days > 0 {
            return "\(days)日"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)時間"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)分"
        } else {
            return "期限切れ"
        }
    }

    var isExpired: Bool {
        return deadline < Date()
    }
}

/// Collection Visibility Options
enum CollectionVisibility: String, Codable {
    case `public` = "public"
    case followers = "followers"
    case `private` = "private"

    var displayText: String {
        switch self {
        case .public:
            return "全体公開"
        case .followers:
            return "フォロワーのみ"
        case .private:
            return "非公開"
        }
    }

    var icon: String {
        switch self {
        case .public:
            return "globe"
        case .followers:
            return "person.2.fill"
        case .private:
            return "lock.fill"
        }
    }
}

/// User Collection Save Record
struct UserCollectionSave: Codable, Identifiable {
    var id: String { "\(userId)_\(collectionId)" }
    let userId: String
    let collectionId: String
    let savedAt: Date
    var addedToTasks: Bool
    var addedTaskIds: [String]?

    enum CodingKeys: String, CodingKey {
        case userId
        case collectionId
        case savedAt
        case addedToTasks
        case addedTaskIds
    }

    // MARK: - Firestore Conversion
    init(from document: DocumentSnapshot) throws {
        let data = document.data() ?? [:]

        self.userId = data["userId"] as? String ?? ""
        self.collectionId = data["collectionId"] as? String ?? ""
        self.addedToTasks = data["addedToTasks"] as? Bool ?? false
        self.addedTaskIds = data["addedTaskIds"] as? [String]

        if let savedTimestamp = data["savedAt"] as? Timestamp {
            self.savedAt = savedTimestamp.dateValue()
        } else {
            self.savedAt = Date()
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension VoteCollection {
    static var preview: VoteCollection {
        VoteCollection(
            id: "coll_preview",
            creatorId: "user_abc",
            creatorName: "K-POP Master",
            creatorAvatarUrl: nil,
            title: "BTS MAMA 2024 完全投票パック",
            description: "BTSのMAMA 2024投票を網羅！期限別にまとめています。",
            coverImage: nil,
            tags: ["BTS", "MAMA2024", "授賞式"],
            tasks: [
                VoteTaskInCollection(from: [
                    "taskId": "task_001",
                    "title": "MAMA Best Male Group",
                    "url": "https://vote.mnet.com/...",
                    "deadline": Timestamp(date: Date(timeIntervalSinceNow: 86400 * 18)),
                    "orderIndex": 0
                ])!,
                VoteTaskInCollection(from: [
                    "taskId": "task_002",
                    "title": "MAMA Worldwide Fans' Choice",
                    "url": "https://vote.mnet.com/...",
                    "deadline": Timestamp(date: Date(timeIntervalSinceNow: 86400 * 12)),
                    "orderIndex": 1
                ])!
            ],
            taskCount: 2,
            visibility: .public,
            likeCount: 245,
            saveCount: 89,
            viewCount: 1523,
            commentCount: 34,
            createdAt: Date(timeIntervalSinceNow: -86400 * 3),
            updatedAt: Date(timeIntervalSinceNow: -86400)
        )
    }
}
#endif
