//
//  ProductCard.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Product Card Component
//

import SwiftUI
import StoreKit

struct ProductCard: View {
    let product: IAPProduct
    let isPurchasing: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            // Promo Badge
            if product.isPromo {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text("週末限定 2倍")
                        .font(.system(size: Constants.Typography.captionSize, weight: .bold))
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, Constants.Spacing.small)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(12)
            }

            // Points Display
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(product.points)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                    Text("P")
                        .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                        .foregroundColor(Constants.Colors.accentPink)
                }

                // Bonus Points Indicator
                if product.isPromo {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10))
                        Text("+\(product.points / 2)P ボーナス")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(Constants.Colors.accentPink)
                }
            }

            Divider()
                .background(Constants.Colors.textGray.opacity(0.3))

            // Price
            Text(product.price)
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(Constants.Colors.textGray)

            // Purchase Button
            Button(action: onPurchase) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "cart.fill")
                        Text("購入")
                    }
                }
                .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.Spacing.small)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Constants.Colors.accentPink,
                            Constants.Colors.gradientPink,
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(isPurchasing)
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardDark)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    product.isPromo ?
                    LinearGradient(
                        gradient: Gradient(colors: [.yellow, .orange]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [.clear]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: product.isPromo ? 2 : 0
                )
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Normal Product
        ProductCard(
            product: IAPProduct(
                id: "test.normal",
                price: "¥330",
                points: 300,
                displayName: "通常",
                isPromo: false
            ),
            isPurchasing: false,
            onPurchase: {}
        )

        // Promo Product
        ProductCard(
            product: IAPProduct(
                id: "test.promo",
                price: "¥330",
                points: 600,
                displayName: "週末限定 2倍",
                isPromo: true
            ),
            isPurchasing: false,
            onPurchase: {}
        )
    }
    .padding()
    .background(Constants.Colors.backgroundDark)
}
