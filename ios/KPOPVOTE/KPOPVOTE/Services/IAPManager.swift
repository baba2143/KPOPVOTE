//
//  IAPManager.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - In-App Purchase Manager using StoreKit 2
//

import Foundation
import StoreKit
import FirebaseAuth

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()

    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isPurchasing = false
    @Published var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?
    private var productConfig: ProductConfig?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await loadProductConfig()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    /// Load products from App Store
    func loadProducts() async {
        do {
            print("📦 [IAPManager] Loading products from App Store...")

            // Determine which product IDs to load based on config
            var productIDsToLoad: [String] = []

            if let config = productConfig, config.isPromoCurrentlyActive {
                // Load promo products
                productIDsToLoad = ProductID.allPromoProducts
                print("🎉 [IAPManager] Promo is active, loading promo products")
            } else {
                // Load normal products
                productIDsToLoad = ProductID.allNormalProducts
                print("📦 [IAPManager] Loading normal products")
            }

            // Load products from App Store
            let storeProducts = try await Product.products(for: productIDsToLoad)
            products = storeProducts.sorted { $0.price < $1.price }

            print("✅ [IAPManager] Loaded \(products.count) products")
            for product in products {
                print("  - \(product.id): \(product.displayPrice)")
            }
        } catch {
            print("❌ [IAPManager] Failed to load products: \(error.localizedDescription)")
            errorMessage = "商品の読み込みに失敗しました"
        }
    }

    // MARK: - Load Product Config
    /// Load product configuration from Firestore
    func loadProductConfig() async {
        do {
            print("🔧 [IAPManager] Loading product config from Firestore...")

            // In production, fetch from Firestore
            // For now, use default config
            productConfig = ProductConfig(
                isPromoActive: false,
                promoStartDate: nil,
                promoEndDate: nil,
                activeProductIds: ProductID.allNormalProducts
            )

            print("✅ [IAPManager] Product config loaded")
        } catch {
            print("❌ [IAPManager] Failed to load product config: \(error.localizedDescription)")
            // Use default config on error
            productConfig = ProductConfig(
                isPromoActive: false,
                promoStartDate: nil,
                promoEndDate: nil,
                activeProductIds: ProductID.allNormalProducts
            )
        }
    }

    // MARK: - Purchase Product
    /// Purchase a product
    func purchase(_ product: Product) async throws -> PurchaseVerificationResponse {
        guard !isPurchasing else {
            throw IAPError.purchaseInProgress
        }

        isPurchasing = true
        errorMessage = nil

        defer {
            isPurchasing = false
        }

        print("🛒 [IAPManager] Starting purchase for: \(product.id)")

        do {
            // Attempt purchase
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                print("✅ [IAPManager] Purchase successful, verifying with backend...")

                // Verify with backend and grant points
                let response = try await verifyPurchaseWithBackend(transaction: transaction, product: product)

                // Finish the transaction
                await transaction.finish()

                print("✅ [IAPManager] Purchase completed: +\(response.pointsGranted)P")

                return response

            case .userCancelled:
                print("⚠️ [IAPManager] User cancelled purchase")
                throw IAPError.userCancelled

            case .pending:
                print("⏳ [IAPManager] Purchase pending")
                throw IAPError.purchasePending

            @unknown default:
                print("❌ [IAPManager] Unknown purchase result")
                throw IAPError.unknown
            }
        } catch {
            print("❌ [IAPManager] Purchase failed: \(error.localizedDescription)")
            errorMessage = "購入に失敗しました"
            throw error
        }
    }

    // MARK: - Verify Purchase with Backend
    /// Verify purchase with backend API
    private func verifyPurchaseWithBackend(transaction: Transaction, product: Product) async throws -> PurchaseVerificationResponse {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw IAPError.notAuthenticated
        }

        guard let url = URL(string: Constants.API.verifyPurchase) else {
            throw IAPError.invalidURL
        }

        // Get receipt data
        guard let receiptData = try? await getReceiptData() else {
            throw IAPError.receiptNotFound
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

        print("📤 [IAPManager] Verifying purchase with backend...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw IAPError.invalidResponse
        }

        print("📥 [IAPManager] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [IAPManager] Error: \(errorString)")
            }
            throw IAPError.verificationFailed
        }

        struct VerifyResponse: Codable {
            let success: Bool
            let data: PurchaseVerificationResponse
        }

        let result = try JSONDecoder().decode(VerifyResponse.self, from: data)
        print("✅ [IAPManager] Verification successful: \(result.data.pointsGranted) points granted")

        return result.data
    }

    // MARK: - Get Receipt Data
    /// Get App Store receipt data
    private func getReceiptData() async throws -> String {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            throw IAPError.receiptNotFound
        }

        return receiptData.base64EncodedString()
    }

    // MARK: - Transaction Verification
    /// Check verified transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw IAPError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener
    /// Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)

                    print("🔔 [IAPManager] Transaction update: \(transaction.id)")

                    // Update purchased products
                    await updatePurchasedProducts()

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    print("❌ [IAPManager] Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Update Purchased Products
    /// Update list of purchased product IDs
    private func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchasedIDs.insert(transaction.productID)
            } catch {
                print("❌ [IAPManager] Failed to verify entitlement: \(error.localizedDescription)")
            }
        }

        purchasedProductIDs = purchasedIDs
        print("📋 [IAPManager] Updated purchased products: \(purchasedIDs)")
    }

    // MARK: - Restore Purchases
    /// Restore purchases
    func restorePurchases() async {
        print("🔄 [IAPManager] Restoring purchases...")

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            print("✅ [IAPManager] Purchases restored")
        } catch {
            print("❌ [IAPManager] Failed to restore purchases: \(error.localizedDescription)")
            errorMessage = "購入の復元に失敗しました"
        }
    }
}

// MARK: - IAP Errors
enum IAPError: LocalizedError {
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
