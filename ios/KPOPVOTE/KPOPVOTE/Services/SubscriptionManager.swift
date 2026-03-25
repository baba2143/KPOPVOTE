//
//  SubscriptionManager.swift
//  OSHI Pick
//
//  OSHI Pick - Auto-Renewable Subscription Manager
//

import Foundation
import StoreKit
import FirebaseAuth

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var subscriptions: [Product] = []
    @Published var subscriptionStatus: SubscriptionStatus?
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for subscription updates
        updateListenerTask = listenForSubscriptionUpdates()

        Task {
            await loadSubscriptions()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Subscriptions
    /// Load subscription products from App Store
    func loadSubscriptions() async {
        do {
            debugLog("📦 [SubscriptionManager] Loading subscriptions from App Store...")
            debugLog("📦 [SubscriptionManager] Requesting Product IDs: \(SubscriptionProductID.allProducts)")
            debugLog("📦 [SubscriptionManager] Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

            let products = try await Product.products(for: SubscriptionProductID.allProducts)
            subscriptions = products.sorted { $0.price < $1.price }

            debugLog("✅ [SubscriptionManager] Loaded \(subscriptions.count) subscriptions")
            if subscriptions.isEmpty {
                debugLog("⚠️ [SubscriptionManager] WARNING: No products returned from App Store")
                debugLog("⚠️ [SubscriptionManager] Possible causes:")
                debugLog("   - Product IDs not registered in App Store Connect")
                debugLog("   - Bundle ID mismatch")
                debugLog("   - Sandbox account not signed in")
                debugLog("   - Paid Applications contract not active")
            }
            for product in subscriptions {
                debugLog("  - \(product.id): \(product.displayPrice)")
            }
        } catch {
            debugLog("❌ [SubscriptionManager] Failed to load subscriptions")
            debugLog("❌ [SubscriptionManager] Error: \(error)")
            debugLog("❌ [SubscriptionManager] Error Description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                debugLog("❌ [SubscriptionManager] Error Domain: \(nsError.domain)")
                debugLog("❌ [SubscriptionManager] Error Code: \(nsError.code)")
                debugLog("❌ [SubscriptionManager] Error UserInfo: \(nsError.userInfo)")
            }
            errorMessage = "サブスクリプションの読み込みに失敗しました"
        }
    }

    // MARK: - Check Subscription Status
    /// Check current subscription status
    func checkSubscriptionStatus() async {
        do {
            debugLog("🔍 [SubscriptionManager] Checking subscription status...")

            // Check current entitlements
            for await result in Transaction.currentEntitlements {
                if let transaction = try? checkVerified(result) {
                    // Check if this is a subscription product
                    if SubscriptionProductID.allProducts.contains(transaction.productID) {
                        // Check if subscription is still active
                        if let expirationDate = transaction.expirationDate,
                           expirationDate > Date() {
                            subscriptionStatus = SubscriptionStatus(
                                isActive: true,
                                productId: transaction.productID,
                                expiresAt: expirationDate,
                                autoRenewing: transaction.revocationDate == nil
                            )

                            debugLog("✅ [SubscriptionManager] Active subscription found: \(transaction.productID)")
                            return
                        }
                    }
                }
            }

            // No active subscription found
            subscriptionStatus = SubscriptionStatus(
                isActive: false,
                productId: nil,
                expiresAt: nil,
                autoRenewing: false
            )

            debugLog("ℹ️ [SubscriptionManager] No active subscription")
        }
    }

    // MARK: - Subscribe
    /// Purchase a subscription
    func subscribe(_ product: Product) async throws -> SubscriptionVerificationResponse {
        guard !isPurchasing else {
            throw SubscriptionError.purchaseInProgress
        }

        isPurchasing = true
        errorMessage = nil

        defer {
            isPurchasing = false
        }

        debugLog("🛒 [SubscriptionManager] Starting subscription: \(product.id)")

        do {
            // Attempt purchase
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                debugLog("✅ [SubscriptionManager] Subscription successful, verifying with backend...")

                // Detect if this is local testing environment (StoreKit Configuration)
                let isLocalTesting = transaction.environment == .xcode

                // Verify with backend (skip for local testing)
                let response: SubscriptionVerificationResponse
                if isLocalTesting {
                    debugLog("⚠️ [SubscriptionManager] Local testing environment detected, skipping backend verification")
                    response = SubscriptionVerificationResponse(
                        success: true,
                        isPremium: true,
                        expiresAt: Date(timeIntervalSinceNow: 30 * 24 * 60 * 60).ISO8601Format(),
                        productId: product.id
                    )
                } else {
                    response = try await verifySubscriptionWithBackend(
                        transaction: transaction,
                        product: product
                    )
                }

                // Finish the transaction
                await transaction.finish()

                // Update subscription status
                await checkSubscriptionStatus()

                debugLog("✅ [SubscriptionManager] Subscription completed")

                return response

            case .userCancelled:
                debugLog("⚠️ [SubscriptionManager] User cancelled subscription")
                throw SubscriptionError.userCancelled

            case .pending:
                debugLog("⏳ [SubscriptionManager] Subscription pending")
                throw SubscriptionError.purchasePending

            @unknown default:
                debugLog("❌ [SubscriptionManager] Unknown subscription result")
                throw SubscriptionError.unknown
            }
        } catch {
            debugLog("❌ [SubscriptionManager] Subscription failed: \(error.localizedDescription)")
            errorMessage = "サブスクリプションに失敗しました"
            throw error
        }
    }

    // MARK: - Verify Subscription with Backend
    /// Verify subscription with backend API
    private func verifySubscriptionWithBackend(
        transaction: Transaction,
        product: Product
    ) async throws -> SubscriptionVerificationResponse {
        let token = try await FirebaseTokenHelper.shared.getToken()

        guard let url = URL(string: Constants.API.verifySubscription) else {
            throw SubscriptionError.invalidURL
        }

        // Get receipt data
        guard let receiptData = try? await getReceiptData() else {
            throw SubscriptionError.receiptNotFound
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "receiptData": receiptData,
            "productId": product.id,
            "transactionId": String(transaction.id),
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        debugLog("📤 [SubscriptionManager] Verifying subscription with backend...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionError.invalidResponse
        }

        debugLog("📥 [SubscriptionManager] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                debugLog("❌ [SubscriptionManager] Error: \(errorString)")
            }
            throw SubscriptionError.verificationFailed
        }

        let result = try JSONDecoder().decode(SubscriptionVerificationResponse.self, from: data)
        debugLog("✅ [SubscriptionManager] Verification successful")

        return result
    }

    // MARK: - Get Receipt Data
    /// Get App Store receipt data
    private func getReceiptData() async throws -> String {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            throw SubscriptionError.receiptNotFound
        }

        return receiptData.base64EncodedString()
    }

    // MARK: - Transaction Verification
    /// Check verified transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Subscription Updates Listener
    /// Listen for subscription updates
    private func listenForSubscriptionUpdates() -> Task<Void, Error> {
        return Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)

                    debugLog("🔔 [SubscriptionManager] Subscription update: \(transaction.id)")

                    // Check if this is a subscription product
                    if SubscriptionProductID.allProducts.contains(transaction.productID) {
                        // Update subscription status
                        await checkSubscriptionStatus()
                    }

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    debugLog("❌ [SubscriptionManager] Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Restore Subscriptions
    /// Restore subscriptions
    func restoreSubscriptions() async {
        debugLog("🔄 [SubscriptionManager] Restoring subscriptions...")

        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            debugLog("✅ [SubscriptionManager] Subscriptions restored")
        } catch {
            debugLog("❌ [SubscriptionManager] Failed to restore subscriptions: \(error.localizedDescription)")
            errorMessage = "サブスクリプションの復元に失敗しました"
        }
    }
}

// MARK: - Subscription Errors
enum SubscriptionError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case receiptNotFound
    case failedVerification
    case purchaseInProgress
    case userCancelled
    case purchasePending
    case invalidResponse
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .invalidURL:
            return "無効なURL"
        case .receiptNotFound:
            return "レシートが見つかりません"
        case .failedVerification:
            return "検証に失敗しました"
        case .purchaseInProgress:
            return "購入処理中です"
        case .userCancelled:
            return "購入がキャンセルされました"
        case .purchasePending:
            return "購入が保留中です"
        case .invalidResponse:
            return "無効なレスポンス"
        case .verificationFailed:
            return "検証に失敗しました"
        case .unknown:
            return "不明なエラー"
        }
    }
}
