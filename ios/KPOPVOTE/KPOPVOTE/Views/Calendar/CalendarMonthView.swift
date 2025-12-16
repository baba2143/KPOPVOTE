//
//  CalendarMonthView.swift
//  OSHI Pick
//
//  OSHI Pick - Calendar Month View
//

import SwiftUI

struct CalendarMonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var selectedEvent: CalendarEvent?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    var body: some View {
        VStack(spacing: 0) {
            // Month navigation header
            monthNavigationHeader

            // Weekday header
            weekdayHeader

            // Calendar grid
            calendarGrid

            Divider()
                .background(Constants.Colors.textGray.opacity(0.3))

            // Selected date events
            selectedDateEventsView
        }
        .fullScreenCover(item: $selectedEvent) { event in
            EventDetailView(event: event, viewModel: viewModel)
        }
    }

    // MARK: - Month Navigation Header
    private var monthNavigationHeader: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Constants.Colors.accentPink)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(monthYearString(from: viewModel.currentMonth))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Constants.Colors.accentPink)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(symbol == "日" ? .red : symbol == "土" ? .blue : Constants.Colors.textGray)
                    .frame(height: 30)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let days = generateMonthDays()

        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    DayCell(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: calendar.isDateInToday(date),
                        hasEvents: viewModel.datesWithEvents.contains(calendar.startOfDay(for: date)),
                        eventTypes: getEventTypes(for: date)
                    )
                    .onTapGesture {
                        viewModel.selectDate(date)
                    }
                } else {
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Selected Date Events View
    private var selectedDateEventsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dateString(from: viewModel.selectedDate))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.selectedDateEvents.count)件のイベント")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textGray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if viewModel.selectedDateEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 24))
                        .foregroundColor(Constants.Colors.textGray)
                    Text("この日のイベントはありません")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.selectedDateEvents) { event in
                            EventRow(event: event)
                                .onTapGesture {
                                    selectedEvent = event
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(maxHeight: 200)
    }

    // MARK: - Helper Methods
    private func generateMonthDays() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: viewModel.currentMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var days: [Date?] = []

        // Add empty cells for days before month start
        let emptyDays = firstWeekday - 1
        for _ in 0..<emptyDays {
            days.append(nil)
        }

        // Add all days of the month
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    private func getEventTypes(for date: Date) -> [CalendarEventType] {
        let dayEvents = viewModel.events.filter {
            calendar.isDate($0.startDate, inSameDayAs: date)
        }
        return Array(Set(dayEvents.map { $0.eventType }))
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日(E)"
        return formatter.string(from: date)
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let eventTypes: [CalendarEventType]

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular))
                .foregroundColor(dayTextColor)

            // Event type indicators
            if hasEvents {
                HStack(spacing: 2) {
                    ForEach(eventTypes.prefix(3), id: \.self) { type in
                        Circle()
                            .fill(Color(hex: type.colorHex))
                            .frame(width: 4, height: 4)
                    }
                }
            } else {
                Color.clear.frame(height: 4)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? Constants.Colors.accentPink : Color.clear, lineWidth: 1)
        )
    }

    private var dayTextColor: Color {
        let weekday = calendar.component(.weekday, from: date)
        if isSelected {
            return .white
        } else if weekday == 1 { // Sunday
            return .red
        } else if weekday == 7 { // Saturday
            return .blue
        } else {
            return .white
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Constants.Colors.accentPink
        } else {
            return Color.clear
        }
    }
}

// MARK: - Event Row
struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // Event type color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: event.eventType.colorHex))
                .frame(width: 4)

            // Event type icon
            Image(systemName: event.eventType.icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: event.eventType.colorHex))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(timeString(from: event.startDate))
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)

                    if let location = event.location, !location.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(location)
                                .lineLimit(1)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(Constants.Colors.textGray)
                    }
                }
            }

            Spacer()

            // Attendance indicator
            if event.isAttending == true {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            // Attendee count
            HStack(spacing: 2) {
                Image(systemName: "person.2")
                    .font(.system(size: 10))
                Text("\(event.attendeeCount)")
            }
            .font(.system(size: 11))
            .foregroundColor(Constants.Colors.textGray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Constants.Colors.cardDark)
        .cornerRadius(8)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarMonthView(viewModel: CalendarViewModel())
        .background(Constants.Colors.backgroundDark)
}
