//
//  CalendarEvent.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Calendar Event Model
//

import Foundation

// MARK: - Calendar Event Type
enum CalendarEventType: String, Codable, CaseIterable {
    case tv = "tv"
    case release = "release"
    case live = "live"
    case vote = "vote"
    case youtube = "youtube"

    var displayName: String {
        switch self {
        case .tv:
            return "TV出演"
        case .release:
            return "カムバック/リリース"
        case .live:
            return "ライブ/イベント"
        case .vote:
            return "投票"
        case .youtube:
            return "YouTube/MV"
        }
    }

    var icon: String {
        switch self {
        case .tv:
            return "tv"
        case .release:
            return "opticaldisc"
        case .live:
            return "music.mic"
        case .vote:
            return "checkmark.square"
        case .youtube:
            return "play.rectangle"
        }
    }

    var colorHex: String {
        switch self {
        case .tv:
            return "3B82F6" // Blue
        case .release:
            return "8B5CF6" // Purple
        case .live:
            return "EC4899" // Pink
        case .vote:
            return "F97316" // Orange
        case .youtube:
            return "EF4444" // Red
        }
    }
}

// MARK: - Calendar Event
struct CalendarEvent: Codable, Identifiable {
    let eventId: String
    let artistId: String
    let eventType: CalendarEventType
    let title: String
    let description: String?
    let startDate: Date
    let endDate: Date?
    let location: String?
    let url: String?
    let thumbnailUrl: String?
    let createdBy: String
    let createdAt: Date
    let updatedAt: Date
    let attendeeCount: Int
    var isAttending: Bool?

    var id: String { eventId }

    enum CodingKeys: String, CodingKey {
        case eventId, artistId, eventType, title, description
        case startDate, endDate, location, url, thumbnailUrl
        case createdBy, createdAt, updatedAt, attendeeCount, isAttending
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        eventId = try container.decode(String.self, forKey: .eventId)
        artistId = try container.decode(String.self, forKey: .artistId)
        eventType = try container.decode(CalendarEventType.self, forKey: .eventType)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        attendeeCount = try container.decode(Int.self, forKey: .attendeeCount)
        isAttending = try container.decodeIfPresent(Bool.self, forKey: .isAttending)

        // Parse ISO8601 dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let startDateString = try container.decode(String.self, forKey: .startDate)
        if let date = dateFormatter.date(from: startDateString) {
            startDate = date
        } else {
            // Try without fractional seconds
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let date = dateFormatter.date(from: startDateString) {
                startDate = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .startDate, in: container, debugDescription: "Invalid date format")
            }
        }

        if let endDateString = try container.decodeIfPresent(String.self, forKey: .endDate) {
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = dateFormatter.date(from: endDateString) {
                endDate = date
            } else {
                dateFormatter.formatOptions = [.withInternetDateTime]
                endDate = dateFormatter.date(from: endDateString)
            }
        } else {
            endDate = nil
        }

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = dateFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        }

        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = dateFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            dateFormatter.formatOptions = [.withInternetDateTime]
            updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        }
    }

    // For creating new events
    init(eventId: String = UUID().uuidString,
         artistId: String,
         eventType: CalendarEventType,
         title: String,
         description: String? = nil,
         startDate: Date,
         endDate: Date? = nil,
         location: String? = nil,
         url: String? = nil,
         thumbnailUrl: String? = nil,
         createdBy: String = "",
         createdAt: Date = Date(),
         updatedAt: Date = Date(),
         attendeeCount: Int = 0,
         isAttending: Bool? = nil) {
        self.eventId = eventId
        self.artistId = artistId
        self.eventType = eventType
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.attendeeCount = attendeeCount
        self.isAttending = isAttending
    }
}

// MARK: - API Response Wrappers
struct CalendarEventsResponse: Codable {
    let success: Bool
    let data: CalendarEventsData?
    let error: String?
}

struct CalendarEventsData: Codable {
    let events: [CalendarEvent]
    let count: Int
    let hasMore: Bool
}

struct CalendarEventResponse: Codable {
    let success: Bool
    let data: CalendarEvent?
    let error: String?
}

struct AttendanceResponse: Codable {
    let success: Bool
    let data: AttendanceData?
    let error: String?
}

struct AttendanceData: Codable {
    let eventId: String
    let isAttending: Bool
    let attendeeCount: Int
}

struct CheckDuplicateResponse: Codable {
    let success: Bool
    let data: CheckDuplicateData?
    let error: String?
}

struct CheckDuplicateData: Codable {
    let hasDuplicate: Bool
    let duplicateEvents: [CalendarEvent]?
}

// MARK: - Create Event Request
struct CreateCalendarEventRequest: Codable {
    let artistId: String
    let eventType: String
    let title: String
    let description: String?
    let startDate: String
    let endDate: String?
    let location: String?
    let url: String?
    let thumbnailUrl: String?

    init(artistId: String,
         eventType: CalendarEventType,
         title: String,
         description: String? = nil,
         startDate: Date,
         endDate: Date? = nil,
         location: String? = nil,
         url: String? = nil,
         thumbnailUrl: String? = nil) {
        self.artistId = artistId
        self.eventType = eventType.rawValue
        self.title = title
        self.description = description
        self.startDate = ISO8601DateFormatter().string(from: startDate)
        self.endDate = endDate.map { ISO8601DateFormatter().string(from: $0) }
        self.location = location
        self.url = url
        self.thumbnailUrl = thumbnailUrl
    }
}
