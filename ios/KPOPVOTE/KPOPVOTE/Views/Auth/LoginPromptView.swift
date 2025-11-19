//
//  LoginPromptView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Login Prompt Modal
//

import SwiftUI

struct LoginPromptView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var isPresented: Bool
    let featureName: String

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Modal content
            VStack(spacing: Constants.Spacing.large) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Constants.Colors.accentPink.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Constants.Colors.accentPink)
                }

                // Title
                Text("ログインが必要です")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                // Description
                Text("\(featureName)を利用するには、アカウント登録またはログインが必要です")
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Benefits
                VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                    BenefitRow(icon: "hand.raised.fill", text: "投票に参加できます")
                    BenefitRow(icon: "bubble.left.and.bubble.right.fill", text: "コミュニティに投稿できます")
                    BenefitRow(icon: "gift.fill", text: "グッズ交換ができます")
                    BenefitRow(icon: "star.fill", text: "推し活がもっと楽しくなります")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                // Buttons
                VStack(spacing: Constants.Spacing.medium) {
                    // Login Button
                    Button(action: {
                        isPresented = false
                        authService.exitGuestMode()
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

                    // Cancel Button
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("キャンセル")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textGray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                    }
                }
            }
            .padding(Constants.Spacing.large)
            .background(Constants.Colors.cardDark)
            .cornerRadius(24)
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Benefit Row Component
struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Constants.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.accentPink)
                .frame(width: 24)

            Text(text)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    LoginPromptView(
        isPresented: .constant(true),
        featureName: "投票"
    )
    .environmentObject(AuthService())
}
