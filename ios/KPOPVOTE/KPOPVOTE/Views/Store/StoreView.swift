//
//  StoreView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Store View (Point Purchase)
//

import SwiftUI

struct StoreView: View {
    @StateObject private var viewModel = StoreViewModel()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @StateObject private var pointsViewModel = PointsViewModel()

    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: Constants.Spacing.medium),
        GridItem(.flexible(), spacing: Constants.Spacing.medium),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.large) {
                        // Current Points Card
                        PointsBalanceCard(
                            points: pointsViewModel.points,
                            isPremium: pointsViewModel.isPremium,
                            isLoading: pointsViewModel.isLoading
                        )
                        .padding(.horizontal, Constants.Spacing.medium)

                        // Premium Subscription Section
                        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("プレミアム会員")
                                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                    .foregroundColor(Constants.Colors.textWhite)
                            }
                            .padding(.horizontal, Constants.Spacing.medium)

                            if subscriptionViewModel.isLoading && subscriptionViewModel.subscriptions.isEmpty {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                    .frame(maxWidth: .infinity)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: Constants.Spacing.medium) {
                                        ForEach(subscriptionViewModel.subscriptions) { subscription in
                                            SubscriptionCard(
                                                subscription: subscription,
                                                isActive: subscriptionViewModel.subscriptionStatus?.productId == subscription.id,
                                                isPurchasing: subscriptionViewModel.isPurchasing,
                                                onSubscribe: {
                                                    Task {
                                                        await subscriptionViewModel.subscribe(subscription)
                                                    }
                                                }
                                            )
                                            .frame(width: 280)
                                        }
                                    }
                                    .padding(.horizontal, Constants.Spacing.medium)
                                }
                            }
                        }

                        Divider()
                            .background(Constants.Colors.textGray.opacity(0.3))
                            .padding(.horizontal, Constants.Spacing.medium)

                        // Store Header
                        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                            Text("ポイントを購入")
                                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)

                            Text("投票やグッズ交換に使えるポイントを購入できます")
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(Constants.Colors.textGray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Constants.Spacing.medium)

                        // Products Grid
                        if viewModel.isLoading && viewModel.products.isEmpty {
                            // Loading State
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                Text("商品を読み込み中...")
                                    .font(.system(size: Constants.Typography.captionSize))
                                    .foregroundColor(Constants.Colors.textGray)
                                    .padding(.top, Constants.Spacing.small)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Constants.Spacing.extraLarge)

                        } else if viewModel.products.isEmpty {
                            // Empty State
                            VStack(spacing: Constants.Spacing.small) {
                                Image(systemName: "cart")
                                    .font(.system(size: 48))
                                    .foregroundColor(Constants.Colors.textGray)
                                Text("商品が見つかりません")
                                    .font(.system(size: Constants.Typography.bodySize))
                                    .foregroundColor(Constants.Colors.textGray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Constants.Spacing.extraLarge)

                        } else {
                            // Products Grid
                            LazyVGrid(columns: columns, spacing: Constants.Spacing.medium) {
                                ForEach(viewModel.products) { product in
                                    ProductCard(
                                        product: product,
                                        isPurchasing: viewModel.isPurchasing,
                                        onPurchase: {
                                            Task {
                                                await viewModel.purchase(product)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, Constants.Spacing.medium)
                        }

                        // Restore Purchases Button
                        Button(action: {
                            Task {
                                await viewModel.restorePurchases()
                            }
                        }) {
                            Text("購入を復元")
                                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                .foregroundColor(Constants.Colors.accentBlue)
                        }
                        .padding(.top, Constants.Spacing.small)
                        .padding(.bottom, Constants.Spacing.large)
                    }
                    .padding(.top, Constants.Spacing.medium)
                }
                .refreshable {
                    await viewModel.refresh()
                    await pointsViewModel.loadPoints()
                }
            }
            .navigationTitle("ストア")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ストア")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                }
            }
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
            }
            .alert("購入完了", isPresented: $viewModel.showPurchaseSuccess) {
                Button("OK", role: .cancel) {
                    Task {
                        await pointsViewModel.loadPoints()
                    }
                }
            } message: {
                Text(viewModel.purchaseSuccessMessage)
            }
            .alert("サブスクリプション開始", isPresented: $subscriptionViewModel.showSubscriptionSuccess) {
                Button("OK", role: .cancel) {
                    Task {
                        await pointsViewModel.loadPoints()
                    }
                }
            } message: {
                Text(subscriptionViewModel.subscriptionSuccessMessage)
            }
            .alert("エラー", isPresented: $subscriptionViewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptionViewModel.errorMessage ?? "不明なエラーが発生しました")
            }
            .task {
                await viewModel.loadProducts()
                await subscriptionViewModel.loadSubscriptions()
                await pointsViewModel.loadPoints()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    StoreView()
}
