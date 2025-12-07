//
//  CalendarService.swift
//  OSHI Pick
//
//  OSHI Pick - Calendar Service
//

import Foundation
import FirebaseAuth

// MARK: - Calendar Error
enum CalendarError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case serverError(String)
    case networkError
    case createFailed
    case updateFailed
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログインが必要です"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .serverError(let message):
            return message
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .createFailed:
            return "イベントの作成に失敗しました"
        case .updateFailed:
            return "イベントの更新に失敗しました"
        case .deleteFailed:
            return "イベントの削除に失敗しました"
        }
    }
}

// MARK: - Calendar Service
class CalendarService {
    static let shared = CalendarService()

    private init() {}

    // MARK: - Get Events
    func getEvents(
        artistId: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        eventType: CalendarEventType? = nil,
        limit: Int = 50,
        lastEventId: String? = nil
    ) async throws -> (events: [CalendarEvent], hasMore: Bool) {
        var urlComponents = URLComponents(string: Constants.API.calendar)!
        var queryItems = [URLQueryItem(name: "artistId", value: artistId)]

        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "startDate", value: ISO8601DateFormatter().string(from: startDate)))
        }
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "endDate", value: ISO8601DateFormatter().string(from: endDate)))
        }
        if let eventType = eventType {
            queryItems.append(URLQueryItem(name: "eventType", value: eventType.rawValue))
        }
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        if let lastEventId = lastEventId {
            queryItems.append(URLQueryItem(name: "lastEventId", value: lastEventId))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw CalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add auth token if available
        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        debugLog("📅 [CalendarService] Fetching events for artist: \(artistId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [CalendarService] Error: \(errorString)")
            }
            throw CalendarError.serverError("Status: \(httpResponse.statusCode)")
        }

        let result = try JSONDecoder().decode(CalendarEventsResponse.self, from: data)

        guard result.success, let eventData = result.data else {
            throw CalendarError.serverError(result.error ?? "Unknown error")
        }

        debugLog("✅ [CalendarService] Fetched \(eventData.events.count) events")

        return (eventData.events, eventData.hasMore)
    }

    // MARK: - Get Event Detail
    func getEventDetail(eventId: String) async throws -> CalendarEvent {
        guard let url = URL(string: "\(Constants.API.calendar)/\(eventId)") else {
            throw CalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        debugLog("📅 [CalendarService] Fetching event detail: \(eventId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CalendarError.serverError("Status: \(httpResponse.statusCode)")
        }

        let result = try JSONDecoder().decode(CalendarEventResponse.self, from: data)

        guard result.success, let event = result.data else {
            throw CalendarError.serverError(result.error ?? "Unknown error")
        }

        return event
    }

    // MARK: - Create Event
    func createEvent(_ eventRequest: CreateCalendarEventRequest) async throws -> CalendarEvent {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CalendarError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.calendar) else {
            throw CalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(eventRequest)

        debugLog("📤 [CalendarService] Creating event: \(eventRequest.title)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [CalendarService] Error: \(errorString)")
            }
            throw CalendarError.createFailed
        }

        let result = try JSONDecoder().decode(CalendarEventResponse.self, from: data)

        guard result.success, let event = result.data else {
            throw CalendarError.serverError(result.error ?? "Unknown error")
        }

        debugLog("✅ [CalendarService] Event created: \(event.eventId)")

        return event
    }

    // MARK: - Update Event
    func updateEvent(eventId: String, updates: [String: Any]) async throws -> CalendarEvent {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CalendarError.notAuthenticated
        }

        guard let url = URL(string: "\(Constants.API.calendar)/\(eventId)") else {
            throw CalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: updates)

        debugLog("📤 [CalendarService] Updating event: \(eventId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CalendarError.updateFailed
        }

        let result = try JSONDecoder().decode(CalendarEventResponse.self, from: data)

        guard result.success, let event = result.data else {
            throw CalendarError.serverError(result.error ?? "Unknown error")
        }

        return event
    }

    // MARK: - Delete Event
    func deleteEvent(eventId: String) async throws {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CalendarError.notAuthenticated
        }

        guard let url = URL(string: "\(Constants.API.calendar)/\(eventId)") else {
            throw CalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("🗑️ [CalendarService] Deleting event: \(eventId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [CalendarService] Error: \(errorString)")
            }
            throw CalendarError.deleteFailed
        }

        debugLog("✅ [CalendarService] Event deleted")
    }

    // MARK: - Toggle Attendance
    func toggleAttendance(eventId: String) async throws -> (isAttending: Bool, attendeeCount: Int) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CalendarError.notAuthenticated
        }

        guard let url = URL(string: "\(Constants.API.calendar)/\(eventId)/attend") else {
            throw CalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        debugLog("👥 [CalendarService] Toggling attendance for: \(eventId)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CalendarError.serverError("Status: \(httpResponse.statusCode)")
        }

        let result = try JSONDecoder().decode(AttendanceResponse.self, from: data)

        guard result.success, let attendanceData = result.data else {
            throw CalendarError.serverError(result.error ?? "Unknown error")
        }

        debugLog("✅ [CalendarService] Attendance: \(attendanceData.isAttending ? "参加予定" : "キャンセル")")

        return (attendanceData.isAttending, attendanceData.attendeeCount)
    }

    // MARK: - Check Duplicate
    func checkDuplicate(
        artistId: String,
        eventType: CalendarEventType,
        title: String,
        startDate: Date
    ) async throws -> (hasDuplicate: Bool, duplicateEvents: [CalendarEvent]) {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw CalendarError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.checkDuplicate) else {
            throw CalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "artistId": artistId,
            "eventType": eventType.rawValue,
            "title": title,
            "startDate": ISO8601DateFormatter().string(from: startDate)
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        debugLog("🔍 [CalendarService] Checking duplicate for: \(title)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CalendarError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw CalendarError.serverError("Status: \(httpResponse.statusCode)")
        }

        let result = try JSONDecoder().decode(CheckDuplicateResponse.self, from: data)

        guard result.success, let duplicateData = result.data else {
            throw CalendarError.serverError(result.error ?? "Unknown error")
        }

        return (duplicateData.hasDuplicate, duplicateData.duplicateEvents ?? [])
    }
}
