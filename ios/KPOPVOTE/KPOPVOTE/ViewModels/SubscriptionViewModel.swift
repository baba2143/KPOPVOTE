//
//  SubscriptionViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Subscription View Model
//

import Foundation
import SwiftUI

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [SubscriptionProduct] = []
    @Published var subscriptionStatus: SubscriptionStatus?
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSubscriptionSuccess = false
    @Published var subscriptionSuccessMessage = ""

    private let subscriptionManager = SubscriptionManager.shared

    init() {
        Task {
            await loadSubscriptions()
            await loadSubscriptionStatus()
        }
    }

    // MARK: - Load Subscriptions
    func loadSubscriptions() async {
        isLoading = true
        errorMessage = nil

        do {
            print("🛒 [SubscriptionViewModel] Loading subscriptions...")

            // Wait for SubscriptionManager to load products
            await subscriptionManager.loadSubscriptions()

            // Convert StoreKit Products to SubscriptionProduct
            var subProducts: [SubscriptionProduct] = []

            for product in subscriptionManager.subscriptions {
                let subProduct = SubscriptionProduct(from: product)
                subProducts.append(subProduct)
            }

            subscriptions = subProducts
            print("✅ [SubscriptionViewModel] Loaded \(subscriptions.count) subscriptions")
        } catch {
            print("❌ [SubscriptionViewModel] Failed to load subscriptions: \(error.localizedDescription)")
            errorMessage = "サブスクリプションの読み込みに失敗しました"
            showError = true
        }

        isLoading = false
    }

    // MARK: - Load Subscription Status
    func loadSubscriptionStatus() async {
        await subscriptionManager.checkSubscriptionStatus()
        subscriptionStatus = subscriptionManager.subscriptionStatus
    }

    // MARK: - Subscribe
    func subscribe(_ subscription: SubscriptionProduct) async {
        // Find matching StoreKit Product
        guard let product = subscriptionManager.subscriptions.first(where: { $0.id == subscription.id }) else {
            errorMessage = "サブスクリプションが見つかりません"
            showError = true
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            print("🛒 [SubscriptionViewModel] Subscribing: \(product.id)")

            // Execute subscription through SubscriptionManager
            let response = try await subscriptionManager.subscribe(product)

            print("✅ [SubscriptionViewModel] Subscription successful")

            // Show success message
            let periodText = subscription.period == .monthly ? "月額プラン" : "年額プラン"
            subscriptionSuccessMessage = "プレミアム会員になりました！\n\(periodText)が有効です"
            showSubscriptionSuccess = true

            // Refresh subscription status
            await loadSubscriptionStatus()

        } catch SubscriptionError.userCancelled {
            print("⚠️ [SubscriptionViewModel] User cancelled")
            // Don't show error for user cancellation
        } catch {
            print("❌ [SubscriptionViewModel] Subscription failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
    }

    // MARK: - Restore Subscriptions
    func restoreSubscriptions() async {
        isLoading = true

        await subscriptionManager.restoreSubscriptions()

        // Refresh subscription status after restore
        await loadSubscriptionStatus()

        isLoading = false
    }

    // MARK: - Refresh
    func refresh() async {
        await loadSubscriptions()
        await loadSubscriptionStatus()
    }
}
