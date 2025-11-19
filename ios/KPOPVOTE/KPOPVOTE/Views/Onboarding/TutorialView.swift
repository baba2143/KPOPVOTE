//
//  TutorialView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Tutorial/Onboarding View
//

import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var authService: AuthService
    @State private var currentPage = 0
    @State private var showLogin = false

    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "hand.raised.fill",
            title: "推しに投票しよう",
            description: "K-POPアイドルの投票に参加して、あなたの推しを応援できます",
            color: Constants.Colors.accentPink
        ),
        TutorialPage(
            icon: "person.3.fill",
            title: "コミュニティで繋がる",
            description: "同じ推しを持つファンと投稿をシェアして交流できます",
            color: Constants.Colors.accentBlue
        ),
        TutorialPage(
            icon: "gift.fill",
            title: "グッズ交換",
            description: "トレカやグッズを他のファンと交換・取引できます",
            color: Constants.Colors.gradientPurple
        ),
        TutorialPage(
            icon: "star.fill",
            title: "さあ、始めましょう",
            description: "K-VOTEで推し活をもっと楽しく！",
            color: Constants.Colors.gradientPink
        )
    ]

    var body: some View {
        ZStack {
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip Button (top right)
                if currentPage < pages.count - 1 {
                    HStack {
                        Spacer()
                        Button("スキップ") {
                            completeOnboarding()
                        }
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.textGray)
                        .padding()
                    }
                } else {
                    Spacer().frame(height: 60)
                }

                // Tutorial Pages
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        TutorialPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

                // Bottom Buttons
                VStack(spacing: Constants.Spacing.medium) {
                    if currentPage == pages.count - 1 {
                        // Last page: Show login and skip buttons
                        Button(action: {
                            showLogin = true
                        }) {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("ログイン・新規登録")
                                    .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Constants.Colors.accentPink.opacity(0.4), radius: 12, x: 0, y: 4)
                        }
                        .padding(.horizontal)

                        Button(action: {
                            completeOnboarding()
                        }) {
                            Text("後で認証する")
                                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                .foregroundColor(Constants.Colors.textGray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    } else {
                        // Other pages: Show next button
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("次へ")
                                    .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Constants.Colors.accentBlue, Constants.Colors.gradientPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            NavigationView {
                LoginView(authService: authService)
            }
        }
    }

    private func completeOnboarding() {
        AppStorageManager.shared.hasCompletedOnboarding = true
        authService.loginAsGuest()
    }
}

// MARK: - Tutorial Page Model
struct TutorialPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Tutorial Page View
struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        VStack(spacing: Constants.Spacing.extraLarge) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(page.color.opacity(0.3))
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(page.color)
                    .frame(width: 120, height: 120)

                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    TutorialView()
        .environmentObject(AuthService())
}
