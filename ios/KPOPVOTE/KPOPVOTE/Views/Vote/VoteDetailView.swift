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
    @StateObject private var pointsViewModel = PointsViewModel()
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
                            VStack(spacing: Constants.Spacing.small) {
                                // Premium Multiplier Badge
                                if pointsViewModel.isPremium {
                                    PremiumMultiplierBadge(multiplier: 2, style: .medium)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }

                                // Multiple vote support
                                if let restrictions = vote.restrictions {
                                    MultipleVoteSection(
                                        voteCount: $viewModel.voteCount,
                                        maxVoteCount: viewModel.maxVoteCount,
                                        pointsToBeUsed: viewModel.pointsToBeUsed,
                                        minVoteCount: restrictions.minVoteCount ?? 1,
                                        canVote: viewModel.canVote,
                                        isExecuting: viewModel.isExecuting,
                                        isPremium: pointsViewModel.isPremium,
                                        onVoteCountChange: { newCount in
                                            viewModel.updateVoteCount(newCount)
                                        },
                                        onVoteAll: {
                                            viewModel.voteAll()
                                        },
                                        onVote: {
                                            if authService.isGuest {
                                                showLoginPrompt = true
                                            } else {
                                                Task {
                                                    await viewModel.executeVote()
                                                }
                                            }
                                        }
                                    )
                                } else {
                                    VoteButton(
                                        canVote: viewModel.canVote,
                                        isExecuting: viewModel.isExecuting,
                                        requiredPoints: vote.requiredPoints,
                                        isPremium: pointsViewModel.isPremium,
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
                            }
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
            await pointsViewModel.loadPoints()
            viewModel.updatePoints(premium: pointsViewModel.premiumPoints, regular: pointsViewModel.regularPoints)
            print("✅ [VoteDetailView] Task completed - vote loaded: \(viewModel.vote != nil), premium: \(pointsViewModel.isPremium)")
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
    let isPremium: Bool
    let onVote: () -> Void

    var earnedPoints: Int {
        isPremium ? requiredPoints * 2 : requiredPoints
    }

    var body: some View {
        Button(action: onVote) {
            VStack(spacing: 8) {
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

                // Show earned points if premium
                if isPremium && !isExecuting {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        Text("\(earnedPoints)pt 獲得")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.yellow)
                }
            }
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

// MARK: - Multiple Vote Section
struct MultipleVoteSection: View {
    @Binding var voteCount: Int
    let maxVoteCount: Int
    let pointsToBeUsed: Int
    let minVoteCount: Int
    let canVote: Bool
    let isExecuting: Bool
    let isPremium: Bool
    let onVoteCountChange: (Int) -> Void
    let onVoteAll: () -> Void
    let onVote: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Vote count selector
            VoteCountSelector(
                voteCount: $voteCount,
                minCount: minVoteCount,
                maxCount: maxVoteCount,
                onChange: onVoteCountChange
            )

            // Points info
            VotePointsInfo(
                pointsToBeUsed: pointsToBeUsed,
                maxVoteCount: maxVoteCount
            )

            // Buttons
            HStack(spacing: 12) {
                // Vote button
                Button(action: onVote) {
                    HStack {
                        if isExecuting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("投票中...")
                        } else {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("投票する（\(pointsToBeUsed)pt）")
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
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
                }
                .disabled(!canVote || isExecuting)

                // Vote All button
                if maxVoteCount > voteCount {
                    Button(action: onVoteAll) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 20))
                            Text("全部投票")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                        .padding(.vertical, 12)
                        .background(Constants.Colors.accentBlue)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Vote Count Selector
struct VoteCountSelector: View {
    @Binding var voteCount: Int
    let minCount: Int
    let maxCount: Int
    let onChange: (Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("投票数")
                .font(.system(size: 14))
                .foregroundColor(Constants.Colors.textGray)

            HStack(spacing: 20) {
                // Minus button
                Button(action: {
                    if voteCount > minCount {
                        voteCount -= 1
                        onChange(voteCount)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(voteCount > minCount ? Constants.Colors.accentPink : Color.gray)
                }
                .disabled(voteCount <= minCount)

                // Count display
                Text("\(voteCount)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)
                    .frame(minWidth: 80)

                // Plus button
                Button(action: {
                    if voteCount < maxCount {
                        voteCount += 1
                        onChange(voteCount)
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(voteCount < maxCount ? Constants.Colors.accentPink : Color.gray)
                }
                .disabled(voteCount >= maxCount)
            }

            Text("\(minCount)〜\(maxCount)票")
                .font(.system(size: 12))
                .foregroundColor(Constants.Colors.textGray)
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Vote Points Info
struct VotePointsInfo: View {
    let pointsToBeUsed: Int
    let maxVoteCount: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)
                Text("消費ポイント:")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
                Spacer()
                Text("\(pointsToBeUsed)pt")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Constants.Colors.accentPink)
            }

            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.accentBlue)
                Text("最大投票可能数:")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
                Spacer()
                Text("\(maxVoteCount)票")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Constants.Colors.accentBlue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct VoteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        VoteDetailView(voteId: "1")
    }
}
