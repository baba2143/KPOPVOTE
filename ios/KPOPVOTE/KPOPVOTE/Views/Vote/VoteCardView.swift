//
//  VoteCardView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Vote Card Component
//

import SwiftUI

struct VoteCardView: View {
    let vote: InAppVote
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Cover Image Thumbnail
                if let coverImageUrl = vote.coverImageUrl,
                   let url = URL(string: coverImageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .cornerRadius(12)
                                .clipped()
                        case .failure(_), .empty:
                            DefaultThumbnail()
                        @unknown default:
                            DefaultThumbnail()
                        }
                    }
                } else {
                    DefaultThumbnail()
                }

                // Content
                VStack(alignment: .leading, spacing: 10) {
                    // Title and Status Badge
                    HStack(alignment: .top, spacing: 8) {
                        Text(vote.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Constants.Colors.textWhite)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        StatusBadge(status: vote.status)
                    }

                    // Description
                    Text(vote.description)
                        .font(.system(size: 13))
                        .foregroundColor(Constants.Colors.textGray)
                        .lineLimit(2)

                    // Info row
                    HStack(spacing: 12) {
                        // Period
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text(vote.formattedPeriod)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Constants.Colors.accentBlue)

                        // Required points
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                            Text("\(vote.requiredPoints)pt")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.yellow)

                        Spacer()

                        // Total votes
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 11))
                            Text("\(vote.totalVotes)票")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Constants.Colors.accentPink)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Constants.Spacing.medium)
            .background(Constants.Colors.cardDark)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Constants.Colors.accentPink.opacity(0.3),
                                Constants.Colors.accentBlue.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}

// MARK: - Default Thumbnail
struct DefaultThumbnail: View {
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
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 100, height: 100)
        .cornerRadius(12)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: VoteStatus

    var body: some View {
        Text(status.displayName)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status {
        case .upcoming:
            return .blue
        case .active:
            return .green
        case .ended:
            return .gray
        }
    }
}

// MARK: - Preview
struct VoteCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            VoteCardView(
                vote: InAppVote(
                    id: "1",
                    title: "K-POP ダンス対決",
                    description: "最高のダンスパフォーマンスを見せたアイドルに投票しよう！",
                    choices: [],
                    startDate: Date(),
                    endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                    requiredPoints: 5,
                    status: .active,
                    totalVotes: 125
                ),
                onTap: {}
            )

            VoteCardView(
                vote: InAppVote(
                    id: "2",
                    title: "ベストボーカル投票",
                    description: "心に響く歌声を持つアイドルは誰？",
                    choices: [],
                    startDate: Date().addingTimeInterval(2 * 24 * 60 * 60),
                    endDate: Date().addingTimeInterval(9 * 24 * 60 * 60),
                    requiredPoints: 3,
                    status: .upcoming,
                    totalVotes: 0
                ),
                onTap: {}
            )
        }
        .padding()
        .background(Constants.Colors.backgroundDark)
        .previewLayout(.sizeThatFits)
    }
}
