//
//  StoreViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Store View Model
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class StoreViewModel: ObservableObject {
    @Published var products: [IAPProduct] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showPurchaseSuccess = false
    @Published var purchaseSuccessMessage = ""

    private let iapManager = IAPManager.shared
    private let pointsViewModel = PointsViewModel()

    init() {
        // Observe IAP Manager state
        Task {
            await loadProducts()
        }
    }

    // MARK: - Load Products
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            debugLog("🛒 [StoreViewModel] Loading products...")

            // Wait for IAP Manager to load products
            await iapManager.loadProducts()

            // Convert StoreKit Products to IAPProduct
            var iapProducts: [IAPProduct] = []

            for product in iapManager.products {
                let points = ProductPoints.points(for: product.id)
                let isPromo = product.id.contains(".promo")
                let iapProduct = IAPProduct(
                    from: product,
                    points: points,
                    isPromo: isPromo
                )
                iapProducts.append(iapProduct)
            }

            products = iapProducts
            debugLog("✅ [StoreViewModel] Loaded \(products.count) products")
        } catch {
            debugLog("❌ [StoreViewModel] Failed to load products: \(error.localizedDescription)")
            errorMessage = "商品の読み込みに失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Purchase Product
    func purchase(_ iapProduct: IAPProduct) async {
        // Find matching StoreKit Product
        guard let product = iapManager.products.first(where: { $0.id == iapProduct.id }) else {
            errorMessage = "商品が見つかりません"
            showError = true
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            debugLog("🛒 [StoreViewModel] Purchasing: \(product.id)")

            // Execute purchase through IAP Manager
            let response = try await iapManager.purchase(product)

            debugLog("✅ [StoreViewModel] Purchase successful: +\(response.pointsGranted)P")

            // Show success message
            purchaseSuccessMessage = "+\(response.pointsGranted)P 獲得しました！\n新しい残高: \(response.newBalance)P"
            showPurchaseSuccess = true

            // Refresh points
            await pointsViewModel.loadPoints()

        } catch IAPError.userCancelled {
            debugLog("⚠️ [StoreViewModel] User cancelled")
            // Don't show error for user cancellation
        } catch {
            debugLog("❌ [StoreViewModel] Purchase failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true

        await iapManager.restorePurchases()

        // Refresh points after restore
        await pointsViewModel.loadPoints()

        isLoading = false
    }

    // MARK: - Refresh
    func refresh() async {
        await loadProducts()
        await pointsViewModel.loadPoints()
    }

    // MARK: - Format Price
    func formatPrice(_ price: String) -> String {
        return price
    }
}
