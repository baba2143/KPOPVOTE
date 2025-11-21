//
//  SubscriptionProduct.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Auto-Renewable Subscription Models
//

import Foundation
import StoreKit

/// Subscription Product information
struct SubscriptionProduct: Identifiable {
    let id: String // Product ID
    let price: String // Localized price
    let period: SubscriptionPeriod // Subscription period
    let displayName: String // Display name
    let savings: String? // Savings text (e.g., "17%お得")

    init(from product: Product) {
        self.id = product.id
        self.price = product.displayPrice
        self.displayName = SubscriptionProduct.displayName(for: product.id)

        // Only monthly subscription is supported
        self.period = .monthly
        self.savings = nil
    }

    // Test/Preview initializer
    init(id: String, price: String, period: SubscriptionPeriod, displayName: String, savings: String?) {
        self.id = id
        self.price = price
        self.period = period
        self.displayName = displayName
        self.savings = savings
    }

    /// Get display name for product ID
    private static func displayName(for productId: String) -> String {
        return "プレミアム会員（月額）"
    }
}

/// Subscription period
enum SubscriptionPeriod {
    case monthly

    var displayText: String {
        return "月額"
    }

    var pricePerMonth: String {
        return "¥550/月"
    }
}

/// Subscription Product IDs
enum SubscriptionProductID {
    static let monthly = "com.kpopvote.premium.monthly"

    static let allProducts = [monthly]
}

/// Subscription status
struct SubscriptionStatus: Codable {
    let isActive: Bool
    let productId: String?
    let expiresAt: Date?
    let autoRenewing: Bool

    var isPremium: Bool {
        return isActive
    }

    var expirationText: String {
        guard let expiresAt = expiresAt else {
            return "有効期限なし"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")

        return "有効期限: \(formatter.string(from: expiresAt))"
    }
}

/// Subscription verification response
struct SubscriptionVerificationResponse: Codable {
    let success: Bool
    let isPremium: Bool
    let expiresAt: String
    let productId: String
}

/// Premium benefits
enum PremiumBenefit: CaseIterable {
    case voteBonus
    case specialBadge
    case exclusiveFeatures
    case adFree

    var icon: String {
        switch self {
        case .voteBonus:
            return "star.fill"
        case .specialBadge:
            return "crown.fill"
        case .exclusiveFeatures:
            return "sparkles"
        case .adFree:
            return "eye.slash.fill"
        }
    }

    var title: String {
        switch self {
        case .voteBonus:
            return "投票ボーナス"
        case .specialBadge:
            return "特別バッジ"
        case .exclusiveFeatures:
            return "限定機能"
        case .adFree:
            return "広告非表示"
        }
    }

    var description: String {
        switch self {
        case .voteBonus:
            return "通常投票で2倍ポイント獲得"
        case .specialBadge:
            return "プロフィールにクラウンマーク表示"
        case .exclusiveFeatures:
            return "将来の機能拡張に優先アクセス"
        case .adFree:
            return "広告なし体験（将来実装）"
        }
    }
}
