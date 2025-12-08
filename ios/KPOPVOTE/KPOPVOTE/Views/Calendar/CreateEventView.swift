//
//  CreateEventView.swift
//  OSHI Pick
//
//  OSHI Pick - Create Event View
//

import SwiftUI

struct CreateEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var eventType: CalendarEventType = .tv
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasEndDate: Bool = false
    @State private var location: String = ""
    @State private var url: String = ""

    @State private var isSubmitting: Bool = false
    @State private var showDuplicateAlert: Bool = false
    @State private var duplicateEvents: [CalendarEvent] = []
    @State private var errorMessage: String?

    // MARK: - Initializer
    init(viewModel: CalendarViewModel, initialDate: Date = Date()) {
        self.viewModel = viewModel
        // Initialize @State variables with the provided initial date
        _startDate = State(initialValue: initialDate)
        _endDate = State(initialValue: initialDate.addingTimeInterval(3600))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Event Type Selection
                        eventTypeSection

                        // Title
                        titleSection

                        // Date/Time
                        dateTimeSection

                        // Location
                        locationSection

                        // URL
                        urlSection

                        // Description
                        descriptionSection

                        // Submit Button
                        submitButton
                    }
                    .padding(20)
                }
                .dismissKeyboardOnTap()
                .keyboardDoneButton()
            }
            .navigationTitle("イベントを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Constants.Colors.textGray)
                }
            }
            .alert("類似イベントが見つかりました", isPresented: $showDuplicateAlert) {
                Button("キャンセル", role: .cancel) {}
                Button("それでも追加", role: .destructive) {
                    Task {
                        await createEventForced()
                    }
                }
            } message: {
                Text("同じ日に似たイベントが既に登録されています。それでも追加しますか？")
            }
        }
    }

    // MARK: - Event Type Section
    private var eventTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("イベントの種類")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.Colors.textGray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CalendarEventType.allCases, id: \.self) { type in
                        EventTypeButton(
                            type: type,
                            isSelected: eventType == type
                        ) {
                            eventType = type
                        }
                    }
                }
            }
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タイトル *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.Colors.textGray)

            TextField("", text: $title)
                .placeholder(when: title.isEmpty) {
                    Text("イベントのタイトルを入力")
                        .foregroundColor(Constants.Colors.textGray.opacity(0.5))
                }
                .foregroundColor(.white)
                .padding()
                .background(Constants.Colors.cardDark)
                .cornerRadius(10)
        }
    }

    // MARK: - Date Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日時 *")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Constants.Colors.textGray)

            // Start Date
            VStack(alignment: .leading, spacing: 4) {
                Text("開始")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textGray)

                HStack {
                    // Display formatted date in Japanese era format
                    Text(formatJapaneseDate(startDate))
                        .font(.system(size: 15))
                        .foregroundColor(.white)

                    Spacer()

                    DatePicker(
                        "",
                        selection: $startDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accentColor(Constants.Colors.accentPink)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                }
            }
            .padding()
            .background(Constants.Colors.cardDark)
            .cornerRadius(10)

            // End Date Toggle
            Toggle(isOn: $hasEndDate) {
                Text("終了時刻を設定")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .tint(Constants.Colors.accentPink)
            .padding(.horizontal)

            // End Date (if enabled)
            if hasEndDate {
                VStack(alignment: .leading, spacing: 4) {
                    Text("終了")
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)

                    HStack {
                        // Display formatted date in Japanese era format
                        Text(formatJapaneseDate(endDate))
                            .font(.system(size: 15))
                            .foregroundColor(.white)

                        Spacer()

                        DatePicker(
                            "",
                            selection: $endDate,
                            in: startDate...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .accentColor(Constants.Colors.accentPink)
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                    }
                }
                .padding()
                .background(Constants.Colors.cardDark)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Date Formatting Helper
    private func formatJapaneseDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.dateFormat = "GGGGy年M月d日 H:mm"
        return formatter.string(from: date)
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("場所")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Constants.Colors.textGray)

                Text("(任意)")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textGray.opacity(0.7))
            }

            TextField("", text: $location)
                .placeholder(when: location.isEmpty) {
                    Text("会場名や場所を入力")
                        .foregroundColor(Constants.Colors.textGray.opacity(0.5))
                }
                .foregroundColor(.white)
                .padding()
                .background(Constants.Colors.cardDark)
                .cornerRadius(10)
        }
    }

    // MARK: - URL Section
    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("関連URL")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Constants.Colors.textGray)

                Text("(任意)")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textGray.opacity(0.7))
            }

            TextField("", text: $url)
                .placeholder(when: url.isEmpty) {
                    Text("https://...")
                        .foregroundColor(Constants.Colors.textGray.opacity(0.5))
                }
                .foregroundColor(.white)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .padding()
                .background(Constants.Colors.cardDark)
                .cornerRadius(10)
        }
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("詳細説明")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Constants.Colors.textGray)

                Text("(任意)")
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.textGray.opacity(0.7))
            }

            TextEditor(text: $description)
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
                .frame(minHeight: 100)
                .padding()
                .background(Constants.Colors.cardDark)
                .cornerRadius(10)
                .overlay(
                    Group {
                        if description.isEmpty {
                            Text("イベントの詳細情報を入力")
                                .foregroundColor(Constants.Colors.textGray.opacity(0.5))
                                .padding(.leading, 20)
                                .padding(.top, 24)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        VStack(spacing: 8) {
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }

            Button {
                Task {
                    await checkAndCreateEvent()
                }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "plus.circle.fill")
                        Text("イベントを追加")
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: isValid ? [Constants.Colors.gradientPink, Constants.Colors.gradientPurple] : [Color.gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(!isValid || isSubmitting)
        }
        .padding(.top, 8)
    }

    // MARK: - Computed Properties
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Methods
    private func checkAndCreateEvent() async {
        isSubmitting = true
        errorMessage = nil

        do {
            // Check for duplicates
            let result = try await viewModel.checkDuplicate(
                eventType: eventType,
                title: title,
                startDate: startDate
            )

            if result.hasDuplicate {
                duplicateEvents = result.duplicateEvents
                showDuplicateAlert = true
                isSubmitting = false
            } else {
                await createEventForced()
            }
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }

    private func createEventForced() async {
        isSubmitting = true
        errorMessage = nil

        // Debug: Log the date being sent
        print("📅 [CreateEventView] Creating event with startDate: \(startDate)")
        print("📅 [CreateEventView] ISO8601 format: \(ISO8601DateFormatter().string(from: startDate))")

        do {
            let _ = try await viewModel.createEvent(
                eventType: eventType,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                location: location.isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines),
                url: url.isEmpty ? nil : url.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            dismiss()
        } catch {
            print("❌ [CreateEventView] Error creating event: \(error)")
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
}

// MARK: - Event Type Button
struct EventTypeButton: View {
    let type: CalendarEventType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))

                Text(type.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: type.colorHex))
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: type.colorHex) : Color(hex: type.colorHex).opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: type.colorHex), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    CreateEventView(viewModel: CalendarViewModel())
}
