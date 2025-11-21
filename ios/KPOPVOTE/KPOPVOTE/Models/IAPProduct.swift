//
//  IAPProduct.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - In-App Purchase Product Models
//

import Foundation
import StoreKit

/// IAP Product information
struct IAPProduct: Identifiable {
    let id: String // Product ID
    let price: String // Localized price
    let points: Int // Points granted
    let displayName: String // Display name
    let isPromo: Bool // Is this a promo version?

    init(from product: Product, points: Int, isPromo: Bool = false) {
        self.id = product.id
        self.price = product.displayPrice
        self.points = points
        self.isPromo = isPromo

        // Generate display name from product ID
        if isPromo {
            self.displayName = "週末限定 2倍"
        } else {
            self.displayName = "通常"
        }
    }

    // Test/Preview initializer
    init(id: String, price: String, points: Int, displayName: String, isPromo: Bool) {
        self.id = id
        self.price = price
        self.points = points
        self.displayName = displayName
        self.isPromo = isPromo
    }
}

/// Product configuration from Firestore
struct ProductConfig: Codable {
    let isPromoActive: Bool // Whether promo products are currently active
    let promoStartDate: String? // Promo start date (ISO8601)
    let promoEndDate: String? // Promo end date (ISO8601)
    let activeProductIds: [String] // List of product IDs to display

    /// Check if promo is currently active based on dates
    var isPromoCurrentlyActive: Bool {
        guard isPromoActive else { return false }

        let formatter = ISO8601DateFormatter()
        let now = Date()

        // Check start date
        if let startDateString = promoStartDate,
           let startDate = formatter.date(from: startDateString),
           now < startDate {
            return false
        }

        // Check end date
        if let endDateString = promoEndDate,
           let endDate = formatter.date(from: endDateString),
           now > endDate {
            return false
        }

        return true
    }
}

/// Product ID constants
enum ProductID {
    // Normal versions
    static let points330 = "com.kpopvote.points.330"
    static let points550 = "com.kpopvote.points.550"
    static let points1100 = "com.kpopvote.points.1100"
    static let points3300 = "com.kpopvote.points.3300"
    static let points5500 = "com.kpopvote.points.5500"

    // Promo versions (2x points)
    static let points330Promo = "com.kpopvote.points.330.promo"
    static let points550Promo = "com.kpopvote.points.550.promo"
    static let points1100Promo = "com.kpopvote.points.1100.promo"
    static let points3300Promo = "com.kpopvote.points.3300.promo"
    static let points5500Promo = "com.kpopvote.points.5500.promo"

    // All product IDs
    static let allNormalProducts = [
        points330,
        points550,
        points1100,
        points3300,
        points5500,
    ]

    static let allPromoProducts = [
        points330Promo,
        points550Promo,
        points1100Promo,
        points3300Promo,
        points5500Promo,
    ]

    static let allProducts = allNormalProducts + allPromoProducts
}

/// Product ID to points mapping
enum ProductPoints {
    static let mapping: [String: Int] = [
        // Normal versions
        ProductID.points330: 300,
        ProductID.points550: 550,
        ProductID.points1100: 1200,
        ProductID.points3300: 3800,
        ProductID.points5500: 6500,
        // Promo versions (2x points)
        ProductID.points330Promo: 600,
        ProductID.points550Promo: 1100,
        ProductID.points1100Promo: 2400,
        ProductID.points3300Promo: 7600,
        ProductID.points5500Promo: 13000,
    ]

    static func points(for productId: String) -> Int {
        return mapping[productId] ?? 0
    }
}

/// Purchase verification response
struct PurchaseVerificationResponse: Codable {
    let success: Bool
    let pointsGranted: Int
    let newBalance: Int
    let transactionId: String
}
