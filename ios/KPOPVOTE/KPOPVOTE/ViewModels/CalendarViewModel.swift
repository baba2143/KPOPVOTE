//
//  CalendarViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Calendar ViewModel
//

import Foundation
import SwiftUI

// MARK: - Calendar View Mode
enum CalendarViewMode: String, CaseIterable {
    case month = "month"
    case list = "list"

    var displayName: String {
        switch self {
        case .month:
            return "月表示"
        case .list:
            return "リスト"
        }
    }

    var icon: String {
        switch self {
        case .month:
            return "calendar"
        case .list:
            return "list.bullet"
        }
    }
}

// MARK: - Calendar ViewModel
@MainActor
class CalendarViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var events: [CalendarEvent] = []
    @Published var selectedArtistId: String?
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var viewMode: CalendarViewMode = .month
    @Published var isLoading: Bool = false
    @Published var hasMore: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let calendarService = CalendarService.shared
    private var lastEventId: String?

    // MARK: - Computed Properties

    /// Events for the current month
    var monthEvents: [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, equalTo: currentMonth, toGranularity: .month)
        }
    }

    /// Events for the selected date
    var selectedDateEvents: [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, equalTo: selectedDate, toGranularity: .day)
        }.sorted { $0.startDate < $1.startDate }
    }

    /// Upcoming events (for list view)
    var upcomingEvents: [CalendarEvent] {
        let now = Date()
        return events.filter { $0.startDate >= now }
            .sorted { $0.startDate < $1.startDate }
    }

    /// Events grouped by date (for list view)
    var eventsByDate: [(date: Date, events: [CalendarEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: upcomingEvents) { event in
            calendar.startOfDay(for: event.startDate)
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, events: $0.value) }
    }

    /// Dates with events in current month
    var datesWithEvents: Set<Date> {
        let calendar = Calendar.current
        var dates = Set<Date>()
        for event in monthEvents {
            let startOfDay = calendar.startOfDay(for: event.startDate)
            dates.insert(startOfDay)
        }
        return dates
    }

    // MARK: - Actions

    /// Load events for the selected artist
    func loadEvents() async {
        guard let artistId = selectedArtistId else {
            debugLog("⚠️ [CalendarVM] No artist selected")
            return
        }

        isLoading = true
        errorMessage = nil
        lastEventId = nil

        do {
            // Get events from 1 month before to 3 months ahead
            let calendar = Calendar.current
            let startDate = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            let endDate = calendar.date(byAdding: .month, value: 3, to: Date()) ?? Date()

            let result = try await calendarService.getEvents(
                artistId: artistId,
                startDate: startDate,
                endDate: endDate,
                limit: 100
            )

            events = result.events
            hasMore = result.hasMore
            lastEventId = result.events.last?.eventId

            debugLog("✅ [CalendarVM] Loaded \(events.count) events")
        } catch {
            errorMessage = error.localizedDescription
            debugLog("❌ [CalendarVM] Error: \(error)")
        }

        isLoading = false
    }

    /// Load more events (pagination)
    func loadMoreEvents() async {
        guard let artistId = selectedArtistId,
              hasMore,
              !isLoading else { return }

        isLoading = true

        do {
            let result = try await calendarService.getEvents(
                artistId: artistId,
                limit: 50,
                lastEventId: lastEventId
            )

            events.append(contentsOf: result.events)
            hasMore = result.hasMore
            lastEventId = result.events.last?.eventId
        } catch {
            debugLog("❌ [CalendarVM] Load more error: \(error)")
        }

        isLoading = false
    }

    /// Refresh events
    func refresh() async {
        await loadEvents()
    }

    /// Change selected artist
    func selectArtist(_ artistId: String) async {
        selectedArtistId = artistId
        await loadEvents()
    }

    /// Navigate to previous month
    func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    /// Navigate to next month
    func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    /// Select a date
    func selectDate(_ date: Date) {
        selectedDate = date
    }

    /// Toggle attendance for an event
    func toggleAttendance(for eventId: String) async {
        do {
            let result = try await calendarService.toggleAttendance(eventId: eventId)

            // Update the event in our list
            if let index = events.firstIndex(where: { $0.eventId == eventId }) {
                var updatedEvent = events[index]
                updatedEvent.isAttending = result.isAttending
                events[index] = CalendarEvent(
                    eventId: updatedEvent.eventId,
                    artistId: updatedEvent.artistId,
                    eventType: updatedEvent.eventType,
                    title: updatedEvent.title,
                    description: updatedEvent.description,
                    startDate: updatedEvent.startDate,
                    endDate: updatedEvent.endDate,
                    location: updatedEvent.location,
                    url: updatedEvent.url,
                    thumbnailUrl: updatedEvent.thumbnailUrl,
                    createdBy: updatedEvent.createdBy,
                    createdAt: updatedEvent.createdAt,
                    updatedAt: updatedEvent.updatedAt,
                    attendeeCount: result.attendeeCount,
                    isAttending: result.isAttending
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Create a new event
    func createEvent(
        eventType: CalendarEventType,
        title: String,
        description: String? = nil,
        startDate: Date,
        endDate: Date? = nil,
        location: String? = nil,
        url: String? = nil
    ) async throws -> CalendarEvent {
        guard let artistId = selectedArtistId else {
            throw CalendarError.invalidResponse
        }

        let request = CreateCalendarEventRequest(
            artistId: artistId,
            eventType: eventType,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location,
            url: url
        )

        let newEvent = try await calendarService.createEvent(request)

        // Add to local list
        events.append(newEvent)
        events.sort { $0.startDate < $1.startDate }

        return newEvent
    }

    /// Delete an event
    func deleteEvent(_ eventId: String) async {
        do {
            try await calendarService.deleteEvent(eventId: eventId)
            events.removeAll { $0.eventId == eventId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Check for duplicate events
    func checkDuplicate(
        eventType: CalendarEventType,
        title: String,
        startDate: Date
    ) async throws -> (hasDuplicate: Bool, duplicateEvents: [CalendarEvent]) {
        guard let artistId = selectedArtistId else {
            throw CalendarError.invalidResponse
        }

        return try await calendarService.checkDuplicate(
            artistId: artistId,
            eventType: eventType,
            title: title,
            startDate: startDate
        )
    }
}
