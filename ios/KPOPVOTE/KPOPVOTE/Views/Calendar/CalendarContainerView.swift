//
//  CalendarContainerView.swift
//  OSHI Pick
//
//  OSHI Pick - Calendar Container View
//

import SwiftUI

struct CalendarContainerView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showCreateEvent = false

    let artistId: String
    let artistName: String

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with view mode toggle
                headerView

                // Content based on view mode
                if viewModel.isLoading && viewModel.events.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    contentView
                }
            }
        }
        .fullScreenCover(isPresented: $showCreateEvent) {
            CreateEventView(viewModel: viewModel, initialDate: viewModel.selectedDate)
        }
        .task {
            await viewModel.selectArtist(artistId)
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            // Artist name
            Text(artistName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack {
                // View mode picker
                Picker("", selection: $viewModel.viewMode) {
                    ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                            Text(mode.displayName)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Spacer()

                // Add event button
                Button {
                    showCreateEvent = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("追加")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Constants.Colors.gradientPink, Constants.Colors.gradientPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Constants.Colors.cardDark)
    }

    // MARK: - Content View
    private var contentView: some View {
        Group {
            switch viewModel.viewMode {
            case .month:
                CalendarMonthView(viewModel: viewModel)
            case .list:
                CalendarListView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                .scaleEffect(1.5)
            Text("読み込み中...")
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textGray)
            Spacer()
        }
    }

    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
            Button("再読み込み") {
                Task {
                    await viewModel.refresh()
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Constants.Colors.accentPink)
            .cornerRadius(20)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    CalendarContainerView(artistId: "test-artist", artistName: "TWICE")
}
