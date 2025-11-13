//
//  Task.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Task Model
//

import Foundation

struct VoteTask: Codable, Identifiable {
    let id: String
    let userId: String
    var title: String
    var url: String
    var deadline: Date
    var status: TaskStatus
    var biasIds: [String]
    var externalAppId: String?
    var externalAppName: String?
    var externalAppIconUrl: String?
    var ogpImage: String?
    var ogpTitle: String?
    var ogpDescription: String?
    var createdAt: Date
    var updatedAt: Date

    enum TaskStatus: String, Codable {
        case pending = "pending"
        case completed = "completed"
        case expired = "expired"
        case archived = "archived"
    }

    enum CodingKeys: String, CodingKey {
        case id = "taskId"
        case userId
        case title
        case url
        case deadline
        case status
        case biasIds
        case externalAppId
        case externalAppName
        case externalAppIconUrl
        case ogpImage
        case ogpTitle
        case ogpDescription
        case createdAt
        case updatedAt
    }

    // Firestore Date conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(String.self, forKey: .url)

        let statusString = try container.decode(String.self, forKey: .status)
        status = TaskStatus(rawValue: statusString) ?? .pending

        biasIds = try container.decode([String].self, forKey: .biasIds)
        externalAppId = try container.decodeIfPresent(String.self, forKey: .externalAppId)
        externalAppName = try container.decodeIfPresent(String.self, forKey: .externalAppName)
        externalAppIconUrl = try container.decodeIfPresent(String.self, forKey: .externalAppIconUrl)
        ogpImage = try container.decodeIfPresent(String.self, forKey: .ogpImage)
        ogpTitle = try container.decodeIfPresent(String.self, forKey: .ogpTitle)
        ogpDescription = try container.decodeIfPresent(String.self, forKey: .ogpDescription)

        // Handle Firestore Timestamp for deadline
        if let timestamp = try? container.decode(Double.self, forKey: .deadline) {
            deadline = Date(timeIntervalSince1970: timestamp)
        } else {
            deadline = Date()
        }

        // Handle Firestore Timestamp for createdAt
        if let timestamp = try? container.decode(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            createdAt = Date()
        }

        // Handle Firestore Timestamp for updatedAt
        if let timestamp = try? container.decode(Double.self, forKey: .updatedAt) {
            updatedAt = Date(timeIntervalSince1970: timestamp)
        } else {
            updatedAt = Date()
        }
    }

    // Default initializer
    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String,
        url: String,
        deadline: Date,
        status: TaskStatus = .pending,
        biasIds: [String] = [],
        externalAppId: String? = nil,
        externalAppName: String? = nil,
        externalAppIconUrl: String? = nil,
        ogpImage: String? = nil,
        ogpTitle: String? = nil,
        ogpDescription: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.url = url
        self.deadline = deadline
        self.status = status
        self.biasIds = biasIds
        self.externalAppId = externalAppId
        self.externalAppName = externalAppName
        self.externalAppIconUrl = externalAppIconUrl
        self.ogpImage = ogpImage
        self.ogpTitle = ogpTitle
        self.ogpDescription = ogpDescription
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Task Extension
extension VoteTask {
    var isExpired: Bool {
        return deadline < Date() && status != .completed && status != .archived
    }

    var isCompleted: Bool {
        return status == .completed
    }

    var isArchived: Bool {
        return status == .archived
    }

    var timeRemaining: String {
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: Date(), to: deadline)

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

    var formattedDeadline: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: deadline)
    }

    var statusColor: String {
        switch status {
        case .pending:
            return isExpired ? "red" : "blue"
        case .completed:
            return "green"
        case .expired:
            return "gray"
        case .archived:
            return "gray"
        }
    }
}
