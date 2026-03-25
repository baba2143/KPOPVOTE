//
//  VoteDetailView.swift
//  OSHI Pick
//
//  OSHI Pick - Vote Detail Main View
//

import SwiftUI

struct VoteDetailView: View {
    let voteId: String
    @StateObject private var viewModel: VoteDetailViewModel
    @StateObject private var pointsViewModel = PointsViewModel()
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showLoginPrompt = false
    @State private var showShareSheet = false

    init(voteId: String) {
        self.voteId = voteId
        _viewModel = StateObject(wrappedValue: VoteDetailViewModel(voteId: voteId))
        print("🎬 [VoteDetailView] Initialized with voteId: \(voteId)")
    }

    /// Generate Universal Link URL for this vote
    private var shareURL: URL {
        URL(string: "https://kpopvote-9de2b.web.app/vote/\(voteId)")!
    }

    /// Share text for the vote (includes URL for clipboard copy compatibility)
    private var shareText: String {
        if let vote = viewModel.vote {
            return "\(vote.title) - OSHI Pickで投票しよう！\n\(shareURL.absoluteString)"
        }
        return "OSHI Pickで投票しよう！"
    }

    var body: some View {
        NavigationView {
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

                        // Unified Ranking List - アイドルランキングと同じスタイル
                        VoteRankingListView(
                            vote: vote,
                            viewModel: viewModel,
                            authService: authService,
                            showLoginPrompt: $showLoginPrompt
                        )
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
        .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    print("❌ [VoteDetailView] Cancel button tapped")
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    print("📤 [VoteDetailView] Share button tapped")
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText, shareURL])
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
        .alert("投票完了", isPresented: $viewModel.showVoteSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("投票しました!")
        }
        .task {
            print("🚀 [VoteDetailView] Task started - loading detail for voteId: \(voteId)")
            await viewModel.loadDetail()
            // 単一ポイント制
            if FeatureFlags.pointsEnabled {
                await pointsViewModel.loadPoints()
                viewModel.updatePoints(pointsViewModel.points)
            }
            print("✅ [VoteDetailView] Task completed - vote loaded: \(viewModel.vote != nil), points: \(pointsViewModel.points)")
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
        .navigationViewStyle(.stack)
    }
}

// MARK: - Vote Header View
struct VoteHeaderView: View {
    let vote: InAppVote
    @State private var showPointsHistory = false

    /// Markdownテキストを解析してAttributedStringに変換
    private func markdownDescription(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(text)
        }
    }

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

            // Description (Markdown対応)
            Text(markdownDescription(vote.description))
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.textGray)

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

                    // Phase 1: ポイント機能無効化 - 必要ポイント非表示
                    if FeatureFlags.pointsEnabled {
                        VStack(alignment: .trailing, spacing: 4) {
                            InfoItem(
                                icon: "star.fill",
                                label: "必要ポイント",
                                value: "\(vote.requiredPoints)pt",
                                color: .yellow
                            )

                            Button(action: {
                                showPointsHistory = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 12))
                                    Text("ポイントの貯め方")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(Constants.Colors.accentPink)
                            }
                        }
                    }
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
        .sheet(isPresented: $showPointsHistory) {
            PointsHistoryView()
        }
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

// MARK: - Vote Ranking List View (Unified Ranking + Voting)
struct VoteRankingListView: View {
    let vote: InAppVote
    @ObservedObject var viewModel: VoteDetailViewModel
    @ObservedObject var authService: AuthService
    @Binding var showLoginPrompt: Bool

    // 投票数順にソート
    private var sortedChoices: [VoteChoice] {
        vote.choices.sorted { $0.voteCount > $1.voteCount }
    }

    // ワンタップ投票可能かどうか
    private var canVoteNow: Bool {
        // 日次上限がある場合、残り投票数が0なら投票不可
        if let remaining = viewModel.remainingVotes, remaining <= 0 {
            return false
        }
        return !viewModel.hasVoted && vote.isActive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Daily Limit Badge (if dailyVoteLimitPerUser is set)
            if viewModel.hasDailyLimit, let limit = viewModel.dailyVoteLimit {
                let used = (viewModel.vote?.userDailyVotes ?? 0)
                DailyLimitBadgeView(votesUsed: used, maxVotes: limit)
                    .padding(.horizontal)
                    .padding(.top)
            }

            // Header with total votes
            HStack {
                Text("ランキング")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()

                Text("総投票数: \(vote.totalVotes)")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
            }
            .padding()

            // Ranking rows
            ForEach(Array(sortedChoices.enumerated()), id: \.element.id) { index, choice in
                VoteRankingRowView(
                    rank: index + 1,
                    choice: choice,
                    resolvedImageUrl: choice.resolvedImageUrl(using: viewModel.lookupService),
                    resolvedGroupName: choice.resolvedGroupName(using: viewModel.lookupService),
                    canVote: canVoteNow,
                    isVoting: viewModel.isExecuting && viewModel.selectedChoiceId == choice.id,
                    onVote: {
                        if authService.isGuest {
                            showLoginPrompt = true
                        } else {
                            viewModel.selectChoice(choice.id)
                            Task {
                                await viewModel.executeVote()
                            }
                        }
                    }
                )
                if index < sortedChoices.count - 1 {
                    Divider()
                        .background(Constants.Colors.backgroundDark)
                }
            }
        }
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Vote Ranking Row View (IdolRanking Style with Rank Number)
struct VoteRankingRowView: View {
    let rank: Int
    let choice: VoteChoice
    let resolvedImageUrl: String?
    let resolvedGroupName: String?
    let canVote: Bool
    let isVoting: Bool
    let onVote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            rankView

            // Profile Image (50x50)
            profileImage

            // Name & Group
            VStack(alignment: .leading, spacing: 2) {
                Text(choice.label)
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textWhite)
                    .lineLimit(1)

                if let groupName = choice.groupName, !groupName.isEmpty {
                    Text(groupName)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textGray)
                        .lineLimit(1)
                } else if let groupName = resolvedGroupName, !groupName.isEmpty {
                    Text(groupName)
                        .font(.caption)
                        .foregroundColor(Constants.Colors.textGray)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Vote Count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(choice.voteCount.formatted())")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Constants.Colors.textWhite)
                Text("票")
                    .font(.caption2)
                    .foregroundColor(Constants.Colors.textGray)
            }

            // Vote Button (Heart)
            voteButton
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    // Rank medal view (like IdolRankingEntryView)
    private var rankView: some View {
        Group {
            if rank <= 3 {
                Text(rankMedal)
                    .font(.title2)
                    .frame(width: 32)
            } else {
                Text("\(rank)")
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textGray)
                    .frame(width: 32)
            }
        }
    }

    private var rankMedal: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    private var effectiveImageUrl: String? {
        if let imageUrl = choice.imageUrl, !imageUrl.isEmpty {
            return imageUrl
        }
        return resolvedImageUrl
    }

    private var profileImage: some View {
        Group {
            if let imageUrl = effectiveImageUrl,
               let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        Circle()
            .fill(Constants.Colors.cardDark)
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: choice.isGroupChoice ? "person.3.fill" : "person.fill")
                    .foregroundColor(Constants.Colors.textGray)
            )
    }

    private var voteButton: some View {
        Button(action: onVote) {
            if isVoting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(canVote ? Constants.Colors.accentPink : Constants.Colors.textGray)
                    .frame(width: 44, height: 44)
            }
        }
        .disabled(!canVote || isVoting)
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
            HStack {
                if isExecuting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("投票中...")
                } else {
                    Image(systemName: "heart.fill")
                    // Phase 1: ポイント消費なしで投票
                    if FeatureFlags.pointsEnabled {
                        Text("投票（\(requiredPoints)pt消費）")
                    } else {
                        Text("投票")
                    }
                }
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canVote ? Constants.Colors.accentPink : Color.gray)
            .cornerRadius(16)
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

// MARK: - Multiple Vote Section（単一ポイント制）
struct MultipleVoteSection: View {
    @Binding var voteCount: Int
    let maxVoteCount: Int
    let pointsToBeUsed: Int
    let points: Int  // 単一ポイント
    let minVoteCount: Int
    let canVote: Bool
    let isExecuting: Bool
    let minVoteCountError: String?
    let onVoteCountChange: (Int) -> Void
    let onVoteAll: () -> Void
    let onVote: () -> Void

    private var canVoteWithPoints: Bool {
        return canVote && minVoteCountError == nil && pointsToBeUsed <= points
    }

    var body: some View {
        VStack(spacing: 16) {
            // Vote count selector
            VoteCountSelector(
                voteCount: $voteCount,
                minCount: minVoteCount,
                maxCount: maxVoteCount,
                onChange: onVoteCountChange
            )

            // 最低投票数警告
            if let minError = minVoteCountError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(minError)
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Point usage display（単一ポイント制）
            if FeatureFlags.pointsEnabled {
                HStack {
                    Text("消費ポイント:")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
                    Spacer()
                    Text("\(pointsToBeUsed)P")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Constants.Colors.accentPink)
                    Text("/ \(points)P")
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)
                }
                .padding()
                .background(Constants.Colors.cardDark)
                .cornerRadius(8)
            }

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
                            Image(systemName: "heart.fill")
                            // 単一ポイント制
                            if FeatureFlags.pointsEnabled {
                                Text("投票（\(pointsToBeUsed)P）")
                            } else {
                                Text("投票")
                            }
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canVoteWithPoints ? Constants.Colors.accentPink : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(!canVoteWithPoints || isExecuting)

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
