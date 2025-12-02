//
//  EventDetailView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Event Detail View
//

import SwiftUI

struct EventDetailView: View {
    let event: CalendarEvent
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isTogglingAttendance = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with event type
                    eventHeader

                    // Event details
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text(event.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        // Date/Time
                        dateTimeSection

                        // Location
                        if let location = event.location, !location.isEmpty {
                            locationSection(location)
                        }

                        // Description
                        if let description = event.description, !description.isEmpty {
                            descriptionSection(description)
                        }

                        // URL
                        if let urlString = event.url, let url = URL(string: urlString) {
                            urlSection(url)
                        }

                        Divider()
                            .background(Constants.Colors.textGray.opacity(0.3))

                        // Attendance section
                        attendanceSection

                        Divider()
                            .background(Constants.Colors.textGray.opacity(0.3))

                        // Created info
                        createdInfoSection
                    }
                    .padding(20)
                }
            }
            .background(Constants.Colors.backgroundDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isCreator {
                        Menu {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(Constants.Colors.accentPink)
                        }
                    }
                }
            }
            .alert("イベントを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    Task {
                        await viewModel.deleteEvent(event.eventId)
                        dismiss()
                    }
                }
            } message: {
                Text("このイベントを削除してもよろしいですか？この操作は取り消せません。")
            }
        }
    }

    // MARK: - Event Header
    private var eventHeader: some View {
        VStack(spacing: 8) {
            // Event type icon
            ZStack {
                Circle()
                    .fill(Color(hex: event.eventType.colorHex).opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: event.eventType.icon)
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: event.eventType.colorHex))
            }

            // Event type name
            Text(event.eventType.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: event.eventType.colorHex))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: event.eventType.colorHex).opacity(0.15))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: event.eventType.colorHex).opacity(0.3),
                    Constants.Colors.backgroundDark
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Date Time Section
    private var dateTimeSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 18))
                .foregroundColor(Constants.Colors.accentPink)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(dateString(from: event.startDate))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Text(timeString(from: event.startDate))
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)

                    if let endDate = event.endDate {
                        Text("〜")
                            .foregroundColor(Constants.Colors.textGray)
                        Text(timeString(from: endDate))
                            .font(.system(size: 14))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                }
            }
        }
    }

    // MARK: - Location Section
    private func locationSection(_ location: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle")
                .font(.system(size: 18))
                .foregroundColor(Constants.Colors.accentBlue)
                .frame(width: 24)

            Text(location)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }

    // MARK: - Description Section
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 18))
                    .foregroundColor(Constants.Colors.textGray)
                    .frame(width: 24)

                Text("詳細")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Constants.Colors.textGray)
            }

            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.leading, 36)
        }
    }

    // MARK: - URL Section
    private func urlSection(_ url: URL) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "link")
                .font(.system(size: 18))
                .foregroundColor(Constants.Colors.accentBlue)
                .frame(width: 24)

            Link(destination: url) {
                Text("関連リンクを開く")
                    .font(.system(size: 15))
                    .foregroundColor(Constants.Colors.accentBlue)
                    .underline()
            }
        }
    }

    // MARK: - Attendance Section
    private var attendanceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)

                Text("\(event.attendeeCount)人が参加予定")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Spacer()
            }

            Button {
                guard !isTogglingAttendance else { return }
                isTogglingAttendance = true
                Task {
                    await viewModel.toggleAttendance(for: event.eventId)
                    isTogglingAttendance = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isTogglingAttendance {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: event.isAttending == true ? "checkmark.circle.fill" : "plus.circle")
                    }
                    Text(event.isAttending == true ? "参加予定をキャンセル" : "参加予定に追加")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(event.isAttending == true ? Color.red.opacity(0.8) : Color.green)
                )
            }
            .disabled(isTogglingAttendance)
        }
    }

    // MARK: - Created Info Section
    private var createdInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("イベント情報")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Constants.Colors.textGray)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("作成日")
                        .font(.system(size: 11))
                        .foregroundColor(Constants.Colors.textGray)
                    Text(dateTimeString(from: event.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("更新日")
                        .font(.system(size: 11))
                        .foregroundColor(Constants.Colors.textGray)
                    Text(dateTimeString(from: event.updatedAt))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var isCreator: Bool {
        // Check if current user is the creator
        // For now, we'll return false - implement with AuthService
        return false
    }

    // MARK: - Helper Methods
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日(E)"
        return formatter.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func dateTimeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    EventDetailView(
        event: CalendarEvent(
            eventId: "test",
            artistId: "test-artist",
            eventType: .live,
            title: "TWICE 5th World Tour 'READY TO BE' in JAPAN",
            description: "TWICE 5回目のワールドツアー日本公演。東京ドームで開催される2日間の公演。",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            location: "東京ドーム",
            url: "https://example.com"
        ),
        viewModel: CalendarViewModel()
    )
}
