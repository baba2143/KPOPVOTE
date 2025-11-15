//
//  FeaturedVoteSlider.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Featured Vote Slider for HOME
//

import SwiftUI

struct FeaturedVoteSlider: View {
    let votes: [InAppVote]
    let onVoteTap: (InAppVote) -> Void

    var body: some View {
        TabView {
            ForEach(votes) { vote in
                FeaturedVoteCard(vote: vote, onTap: {
                    onVoteTap(vote)
                })
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .frame(height: 180)
        .cornerRadius(20)
    }
}

// MARK: - Featured Vote Card
struct FeaturedVoteCard: View {
    let vote: InAppVote
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            print("🔘 [FeaturedVoteCard] Button tapped for vote: \(vote.id) - \(vote.title)")
            onTap()
        }) {
            ZStack {
                // Cover Image or Gradient Background
                if let coverImageUrl = vote.coverImageUrl, let url = URL(string: coverImageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                        case .failure(_), .empty:
                            DefaultGradientBackground()
                        @unknown default:
                            DefaultGradientBackground()
                        }
                    }
                } else {
                    DefaultGradientBackground()
                }

                // Dark overlay for text readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Abstract wave pattern overlay
                WavePatternOverlay()

                // Content
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(vote.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Spacer()

                        StatusBadge(status: vote.status)
                    }

                    Spacer()

                    HStack {
                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .padding(Constants.Spacing.large)
                .frame(height: 180, alignment: .topLeading)
            }
            .frame(height: 180)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Default Gradient Background
struct DefaultGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Constants.Colors.gradientPurple,
                Constants.Colors.accentPink,
                Constants.Colors.accentBlue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 180)
    }
}

// MARK: - Wave Pattern Overlay
struct WavePatternOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                path.move(to: CGPoint(x: 0, y: height * 0.7))
                path.addQuadCurve(
                    to: CGPoint(x: width, y: height * 0.5),
                    control: CGPoint(x: width * 0.5, y: height * 0.3)
                )
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(Color.white.opacity(0.1))
        }
        .frame(height: 180)
    }
}

// MARK: - Preview
struct FeaturedVoteSlider_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FeaturedVoteSlider(
                votes: [
                    InAppVote(
                        id: "1",
                        title: "K-POP ダンス対決",
                        description: "最高のダンスパフォーマンスを見せたアイドルに投票しよう！",
                        choices: [],
                        startDate: Date(),
                        endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                        requiredPoints: 5,
                        status: .active,
                        totalVotes: 125,
                        coverImageUrl: nil,
                        isFeatured: true,
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    InAppVote(
                        id: "2",
                        title: "ベストボーカル投票",
                        description: "心に響く歌声を持つアイドルは誰？",
                        choices: [],
                        startDate: Date().addingTimeInterval(2 * 24 * 60 * 60),
                        endDate: Date().addingTimeInterval(9 * 24 * 60 * 60),
                        requiredPoints: 3,
                        status: .upcoming,
                        totalVotes: 0,
                        coverImageUrl: nil,
                        isFeatured: true,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ],
                onVoteTap: { _ in }
            )
            .padding()

            Spacer()
        }
        .background(Constants.Colors.backgroundDark)
    }
}
