//
//  VoteDetailView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote Detail Main View
//

import SwiftUI

struct VoteDetailView: View {
    let voteId: String
    @StateObject private var viewModel: VoteDetailViewModel
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showLoginPrompt = false

    init(voteId: String) {
        self.voteId = voteId
        _viewModel = StateObject(wrappedValue: VoteDetailViewModel(voteId: voteId))
        print("🎬 [VoteDetailView] Initialized with voteId: \(voteId)")
    }

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                    .foregroundColor(Constants.Colors.textWhite)
                    .onAppear {
                        print("📍 [VoteDetailView] Showing loading state")
                    }
            } else if let errorMessage = viewModel.errorMessage {
                ErrorDetailView(message: errorMessage) {
                    Task {
                        await viewModel.loadDetail()
                    }
                }
                .onAppear {
                    print("📍 [VoteDetailView] Showing error state: \(errorMessage)")
                }
            } else if let vote = viewModel.vote {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Vote Header
                        VoteHeaderView(vote: vote)

                        // Choices Section
                        if !viewModel.hasVoted && vote.isActive {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("投票先を選択")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Constants.Colors.textWhite)

                                VStack(spacing: 12) {
                                    ForEach(vote.choices) { choice in
                                        ChoiceButton(
                                            choice: choice,
                                            isSelected: viewModel.selectedChoiceId == choice.id,
                                            onTap: {
                                                viewModel.selectChoice(choice.id)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding()
                            .background(Constants.Colors.cardDark)
                            .cornerRadius(12)
                        }

                        // Ranking Section
                        if let ranking = viewModel.ranking {
                            RankingView(ranking: ranking)
                        }

                        // Vote Button
                        if !viewModel.hasVoted && vote.isActive {
                            VoteButton(
                                canVote: viewModel.canVote,
                                isExecuting: viewModel.isExecuting,
                                requiredPoints: vote.requiredPoints,
                                onVote: {
                                    // Check if user is guest
                                    if authService.isGuest {
                                        showLoginPrompt = true
                                    } else {
                                        Task {
                                            await viewModel.executeVote()
                                        }
                                    }
                                }
                            )
                        }

                        // Success/Already Voted Message
                        if viewModel.hasVoted {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)

                                    Text(viewModel.successMessage ?? "投票完了")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Constants.Colors.textWhite)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    print("📍 [VoteDetailView] Showing vote content for: \(vote.title)")
                }
                .refreshable {
                    await viewModel.refresh()
                }
            } else {
                Text("No content")
                    .foregroundColor(.white)
                    .onAppear {
                        print("⚠️ [VoteDetailView] Showing fallback 'No content' state")
                    }
            }
        }
        .navigationTitle("投票詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    print("❌ [VoteDetailView] Close button tapped")
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil && !viewModel.isLoading)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            print("🚀 [VoteDetailView] Task started - loading detail for voteId: \(voteId)")
            await viewModel.loadDetail()
            print("✅ [VoteDetailView] Task completed - vote loaded: \(viewModel.vote != nil)")
        }
        .onAppear {
            print("👀 [VoteDetailView] View appeared")
        }
        .onDisappear {
            print("👋 [VoteDetailView] View disappeared")
        }
        .overlay(
            Group {
                if showLoginPrompt {
                    LoginPromptView(isPresented: $showLoginPrompt, featureName: "投票")
                }
            }
        )
    }
}

// MARK: - Vote Header View
struct VoteHeaderView: View {
    let vote: InAppVote

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cover Image
            if let coverImageUrl = vote.coverImageUrl,
               let url = URL(string: coverImageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(16)
                    case .failure(_), .empty:
                        DefaultCoverImage()
                    @unknown default:
                        DefaultCoverImage()
                    }
                }
            } else {
                DefaultCoverImage()
            }

            // Title and Status
            HStack(alignment: .top) {
                Text(vote.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)
                    .lineLimit(3)

                Spacer()

                StatusBadge(status: vote.status)
            }

            // Description
            Text(vote.description)
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.textGray)
                .lineLimit(5)

            // Info Grid
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    InfoItem(
                        icon: "calendar",
                        label: "期間",
                        value: vote.formattedPeriod,
                        color: Constants.Colors.accentBlue
                    )

                    Spacer()

                    InfoItem(
                        icon: "star.fill",
                        label: "必要ポイント",
                        value: "\(vote.requiredPoints)pt",
                        color: .yellow
                    )
                }

                HStack(spacing: 16) {
                    InfoItem(
                        icon: "chart.bar.fill",
                        label: "総投票数",
                        value: "\(vote.totalVotes)票",
                        color: Constants.Colors.accentPink
                    )

                    Spacer()
                }
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Default Cover Image
struct DefaultCoverImage: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Constants.Colors.gradientPurple,
                    Constants.Colors.accentPink,
                    Constants.Colors.accentBlue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(height: 200)
        .cornerRadius(16)
    }
}

// MARK: - Info Item
struct InfoItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(Constants.Colors.textGray)

                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)
            }
        }
    }
}

// MARK: - Choice Button
struct ChoiceButton: View {
    let choice: VoteChoice
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Constants.Colors.accentPink : Constants.Colors.textGray, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Constants.Colors.accentPink)
                            .frame(width: 12, height: 12)
                    }
                }

                Text(choice.label)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()

                Text("\(choice.voteCount)票")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Constants.Colors.accentPink.opacity(0.2) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Constants.Colors.accentPink : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vote Button
struct VoteButton: View {
    let canVote: Bool
    let isExecuting: Bool
    let requiredPoints: Int
    let onVote: () -> Void

    var body: some View {
        Button(action: onVote) {
            HStack {
                if isExecuting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("投票中...")
                } else {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("投票する（\(requiredPoints)pt消費）")
                }
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: canVote ? [Constants.Colors.gradientPink, Constants.Colors.gradientPurple] : [Color.gray, Color.gray]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: canVote ? Constants.Colors.accentPink.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!canVote || isExecuting)
    }
}

// MARK: - Error Detail View
struct ErrorDetailView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(Constants.Colors.statusExpired)

            Text(message)
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("再読み込み") {
                onRetry()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Constants.Colors.accentPink)
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview
struct VoteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VoteDetailView(voteId: "1")
    }
}
