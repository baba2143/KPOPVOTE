//
//  CalendarListView.swift
//  OSHI Pick
//
//  OSHI Pick - Calendar List View
//

import SwiftUI

struct CalendarListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var selectedEvent: CalendarEvent?
    @State private var filterType: CalendarEventType?

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            filterChipsView

            // Events list
            if filteredEvents.isEmpty {
                emptyStateView
            } else {
                eventsList
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, viewModel: viewModel)
        }
    }

    // MARK: - Filter Chips
    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                FilterChip(
                    title: "すべて",
                    icon: "list.bullet",
                    color: Constants.Colors.accentPink,
                    isSelected: filterType == nil
                ) {
                    filterType = nil
                }

                // Event type filters
                ForEach(CalendarEventType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.displayName,
                        icon: type.icon,
                        color: Color(hex: type.colorHex),
                        isSelected: filterType == type
                    ) {
                        filterType = filterType == type ? nil : type
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Constants.Colors.cardDark)
    }

    // MARK: - Events List
    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedEvents, id: \.date) { group in
                    Section {
                        ForEach(group.events) { event in
                            EventListCard(event: event) {
                                selectedEvent = event
                            } onAttendanceToggle: {
                                Task {
                                    await viewModel.toggleAttendance(for: event.eventId)
                                }
                            }
                        }
                    } header: {
                        DateSectionHeader(date: group.date, eventCount: group.events.count)
                    }
                }

                // Load more trigger
                if viewModel.hasMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                        .padding()
                        .onAppear {
                            Task {
                                await viewModel.loadMoreEvents()
                            }
                        }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(Constants.Colors.textGray)

            Text("予定されているイベントはありません")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Constants.Colors.textGray)

            Text("イベントを追加して、ファン同士で情報を共有しましょう！")
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textGray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Computed Properties
    private var filteredEvents: [CalendarEvent] {
        if let filterType = filterType {
            return viewModel.upcomingEvents.filter { $0.eventType == filterType }
        }
        return viewModel.upcomingEvents
    }

    private var groupedEvents: [(date: Date, events: [CalendarEvent])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEvents) { event in
            calendar.startOfDay(for: event.startDate)
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, events: $0.value.sorted { $0.startDate < $1.startDate }) }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color, lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Date Section Header
struct DateSectionHeader: View {
    let date: Date
    let eventCount: Int

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(dateString)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    if isToday {
                        Text("今日")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Constants.Colors.accentPink)
                            .cornerRadius(4)
                    } else if isTomorrow {
                        Text("明日")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Constants.Colors.accentBlue)
                            .cornerRadius(4)
                    }
                }

                Text("\(eventCount)件のイベント")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textGray)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Constants.Colors.backgroundDark)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
}

// MARK: - Event List Card
struct EventListCard: View {
    let event: CalendarEvent
    let onTap: () -> Void
    let onAttendanceToggle: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Event type color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: event.eventType.colorHex))
                    .frame(width: 4)

                // Time
                VStack(spacing: 2) {
                    Text(timeString(from: event.startDate))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    if let endDate = event.endDate {
                        Text(timeString(from: endDate))
                            .font(.system(size: 11))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }
                .frame(width: 45)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Event type badge
                    HStack(spacing: 4) {
                        Image(systemName: event.eventType.icon)
                            .font(.system(size: 10))
                        Text(event.eventType.displayName)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(Color(hex: event.eventType.colorHex))

                    // Title
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Location
                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(location)
                                .lineLimit(1)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)
                    }

                    // Attendee count
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("\(event.attendeeCount)人が参加予定")
                        }
                        .font(.system(size: 11))
                        .foregroundColor(Constants.Colors.textGray)

                        if event.url != nil {
                            HStack(spacing: 2) {
                                Image(systemName: "link")
                                    .font(.system(size: 10))
                                Text("リンクあり")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(Constants.Colors.accentBlue)
                        }
                    }
                }

                Spacer()

                // Attendance button
                Button(action: onAttendanceToggle) {
                    VStack(spacing: 2) {
                        Image(systemName: event.isAttending == true ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(event.isAttending == true ? .green : Constants.Colors.textGray)

                        Text(event.isAttending == true ? "参加予定" : "参加する")
                            .font(.system(size: 9))
                            .foregroundColor(event.isAttending == true ? .green : Constants.Colors.textGray)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Constants.Colors.cardDark)
        }
        .buttonStyle(.plain)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarListView(viewModel: CalendarViewModel())
        .background(Constants.Colors.backgroundDark)
}
