//
//  SubscriptionCard.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Subscription Card Component
//

import SwiftUI

struct SubscriptionCard: View {
    let subscription: SubscriptionProduct
    let isActive: Bool
    let isPurchasing: Bool
    let onSubscribe: () -> Void

    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            // Active Badge
            if isActive {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                    Text("有効")
                        .font(.system(size: Constants.Typography.captionSize, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, Constants.Spacing.small)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(12)
            }

            // Savings Badge (Yearly only)
            if let savings = subscription.savings {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12))
                    Text(savings)
                        .font(.system(size: Constants.Typography.captionSize, weight: .bold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, Constants.Spacing.small)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
            }

            // Plan Name
            Text(subscription.displayName)
                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)

            // Period Display
            Text(subscription.period.displayText)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textGray)

            // Price Display
            VStack(spacing: 4) {
                Text(subscription.price)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)
            }

            Divider()
                .background(Constants.Colors.textGray.opacity(0.3))

            // Premium Benefits
            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                SubscriptionBenefitRow(
                    icon: "star.fill",
                    title: "投票ボーナス",
                    description: "2倍ポイント獲得"
                )

                SubscriptionBenefitRow(
                    icon: "crown.fill",
                    title: "特別バッジ",
                    description: "プロフィールに表示"
                )

                SubscriptionBenefitRow(
                    icon: "sparkles",
                    title: "限定機能",
                    description: "優先アクセス"
                )
            }
            .padding(.vertical, Constants.Spacing.small)

            // Subscribe Button
            Button(action: onSubscribe) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                            Text("現在のプラン")
                        } else {
                            Image(systemName: "crown.fill")
                            Text("プレミアム会員になる")
                        }
                    }
                }
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.Spacing.medium)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isActive ? .green : Constants.Colors.accentPink,
                            isActive ? .green.opacity(0.7) : Constants.Colors.gradientPink,
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(isActive || isPurchasing)
        }
        .padding(Constants.Spacing.large)
        .background(Constants.Colors.cardDark)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.yellow,
                            Color.orange
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isActive ? 2 : 0
                )
        )
    }
}

// MARK: - Subscription Benefit Row Component
struct SubscriptionBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Constants.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Constants.Colors.accentPink)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(Constants.Colors.textGray)
            }

            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Monthly Plan (Inactive)
        SubscriptionCard(
            subscription: SubscriptionProduct(
                id: SubscriptionProductID.monthly,
                price: "¥550",
                period: .monthly,
                displayName: "月額プラン",
                savings: nil
            ),
            isActive: false,
            isPurchasing: false,
            onSubscribe: {}
        )

        // Monthly Plan (Active)
        SubscriptionCard(
            subscription: SubscriptionProduct(
                id: SubscriptionProductID.monthly,
                price: "¥550",
                period: .monthly,
                displayName: "月額プラン",
                savings: nil
            ),
            isActive: true,
            isPurchasing: false,
            onSubscribe: {}
        )
    }
    .padding()
    .background(Constants.Colors.backgroundDark)
}
