//
//  PremiumBadge.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Premium Badge Component
//

import SwiftUI

// MARK: - Premium Badge Styles
enum PremiumBadgeStyle {
    case small  // For inline use (next to names)
    case medium // For cards and sections
    case large  // For headers and prominent displays

    var fontSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }

    var padding: EdgeInsets {
        switch self {
        case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
        case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .large: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        }
    }
}

// MARK: - Premium Badge Component
struct PremiumBadge: View {
    let style: PremiumBadgeStyle
    let text: String?

    init(style: PremiumBadgeStyle = .medium, text: String? = "プレミアム") {
        self.style = style
        self.text = text
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: style.iconSize))

            if let text = text {
                Text(text)
                    .font(.system(size: style.fontSize, weight: .bold))
            }
        }
        .foregroundStyle(
            LinearGradient(
                gradient: Gradient(colors: [.yellow, .orange]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .padding(style.padding)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.yellow.opacity(0.2),
                    Color.orange.opacity(0.2)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(style == .small ? 6 : 8)
    }
}

// MARK: - Premium Multiplier Badge
struct PremiumMultiplierBadge: View {
    let multiplier: Int
    let style: PremiumBadgeStyle

    init(multiplier: Int = 2, style: PremiumBadgeStyle = .medium) {
        self.multiplier = multiplier
        self.style = style
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: style.iconSize))

            Text("\(multiplier)x ボーナス")
                .font(.system(size: style.fontSize, weight: .bold))
        }
        .foregroundColor(.yellow)
        .padding(style.padding)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.yellow.opacity(0.2),
                    Color.orange.opacity(0.2)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(style == .small ? 6 : 8)
    }
}

// MARK: - Premium Feature Lock Badge
struct PremiumFeatureLockBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12))

            Text("プレミアム会員限定")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(Constants.Colors.textGray)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Constants.Colors.cardDark)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Constants.Colors.textGray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Premium Benefits Display
struct PremiumBenefitsDisplay: View {
    let isPremium: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack {
                Image(systemName: isPremium ? "checkmark.circle.fill" : "lock.circle.fill")
                    .foregroundColor(isPremium ? .green : Constants.Colors.textGray)
                Text("プレミアム特典")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)
            }

            VStack(alignment: .leading, spacing: 8) {
                BenefitRow(
                    icon: "star.fill",
                    text: "投票時2倍ポイント獲得",
                    isActive: isPremium
                )

                BenefitRow(
                    icon: "crown.fill",
                    text: "プロフィールにクラウンバッジ表示",
                    isActive: isPremium
                )

                BenefitRow(
                    icon: "sparkles",
                    text: "限定機能への優先アクセス",
                    isActive: isPremium
                )
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }

    struct BenefitRow: View {
        let icon: String
        let text: String
        let isActive: Bool

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isActive ? Constants.Colors.accentPink : Constants.Colors.textGray)
                    .frame(width: 20)

                Text(text)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(isActive ? Constants.Colors.textWhite : Constants.Colors.textGray)

                Spacer()

                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - Premium Points Display
struct PremiumPointsDisplay: View {
    let basePoints: Int
    let isPremium: Bool

    var totalPoints: Int {
        isPremium ? basePoints * 2 : basePoints
    }

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.yellow)

                Text("\(totalPoints)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text("P")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Constants.Colors.accentPink)
            }

            if isPremium {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)

                    Text("\(basePoints) x 2")
                        .font(.system(size: 11))
                        .foregroundColor(Constants.Colors.textGray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .cornerRadius(6)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: Constants.Spacing.large) {
        // Badge Styles
        VStack(spacing: Constants.Spacing.small) {
            PremiumBadge(style: .small)
            PremiumBadge(style: .medium)
            PremiumBadge(style: .large)
        }

        // Multiplier Badge
        PremiumMultiplierBadge()

        // Feature Lock
        PremiumFeatureLockBadge()

        // Benefits Display
        PremiumBenefitsDisplay(isPremium: true)
        PremiumBenefitsDisplay(isPremium: false)

        // Points Display
        PremiumPointsDisplay(basePoints: 10, isPremium: true)
        PremiumPointsDisplay(basePoints: 10, isPremium: false)
    }
    .padding()
    .background(Constants.Colors.backgroundDark)
}
