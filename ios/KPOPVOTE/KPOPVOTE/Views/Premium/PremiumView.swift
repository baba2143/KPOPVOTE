//
//  PremiumView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Premium Membership View
//

import SwiftUI

struct PremiumView: View {
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @StateObject private var pointsViewModel = PointsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.large) {
                        // Premium Header
                        VStack(spacing: Constants.Spacing.medium) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.yellow, .orange]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("プレミアム会員")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)

                            Text(subscriptionViewModel.subscriptionStatus?.isPremium == true ?
                                 "ご利用中のプラン" : "限定特典をお楽しみください")
                                .font(.system(size: Constants.Typography.bodySize))
                                .foregroundColor(Constants.Colors.textGray)
                        }
                        .padding(.top, Constants.Spacing.large)

                        // Current Subscription Status
                        if let status = subscriptionViewModel.subscriptionStatus, status.isActive {
                            CurrentSubscriptionCard(
                                status: status,
                                subscriptions: subscriptionViewModel.subscriptions
                            )
                            .padding(.horizontal, Constants.Spacing.medium)
                        }

                        // Premium Benefits
                        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                            Text("プレミアム特典")
                                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)
                                .padding(.horizontal, Constants.Spacing.medium)

                            VStack(spacing: Constants.Spacing.small) {
                                ForEach(PremiumBenefit.allCases, id: \.self) { benefit in
                                    PremiumBenefitCard(
                                        benefit: benefit,
                                        isPremium: subscriptionViewModel.subscriptionStatus?.isPremium ?? false
                                    )
                                }
                            }
                            .padding(.horizontal, Constants.Spacing.medium)
                        }

                        // Subscription Plans
                        if subscriptionViewModel.subscriptionStatus?.isActive != true {
                            VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                                Text("プランを選択")
                                    .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                    .foregroundColor(Constants.Colors.textWhite)
                                    .padding(.horizontal, Constants.Spacing.medium)

                                if subscriptionViewModel.isLoading && subscriptionViewModel.subscriptions.isEmpty {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Constants.Colors.accentPink))
                                        .frame(maxWidth: .infinity)
                                } else {
                                    ForEach(subscriptionViewModel.subscriptions) { subscription in
                                        SubscriptionCard(
                                            subscription: subscription,
                                            isActive: false,
                                            isPurchasing: subscriptionViewModel.isPurchasing,
                                            onSubscribe: {
                                                Task {
                                                    await subscriptionViewModel.subscribe(subscription)
                                                }
                                            }
                                        )
                                        .padding(.horizontal, Constants.Spacing.medium)
                                    }
                                }
                            }
                        }

                        // FAQ Section
                        VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                            Text("よくある質問")
                                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)
                                .padding(.horizontal, Constants.Spacing.medium)

                            VStack(spacing: Constants.Spacing.small) {
                                FAQItem(
                                    question: "いつでもキャンセルできますか？",
                                    answer: "はい、いつでもキャンセル可能です。次回更新日まで特典をご利用いただけます。"
                                )

                                FAQItem(
                                    question: "プラン変更はできますか？",
                                    answer: "はい、いつでも月額プランから年額プランへ変更可能です。"
                                )

                                FAQItem(
                                    question: "特典はいつ適用されますか？",
                                    answer: "サブスクリプション開始後、すぐに全ての特典がご利用いただけます。"
                                )
                            }
                            .padding(.horizontal, Constants.Spacing.medium)
                        }
                        .padding(.bottom, Constants.Spacing.large)
                    }
                }
                .refreshable {
                    await subscriptionViewModel.refresh()
                    await pointsViewModel.loadPoints()
                }
            }
            .navigationTitle("プレミアム会員")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("プレミアム会員")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                await subscriptionViewModel.loadSubscriptions()
                await pointsViewModel.loadPoints()
            }
        }
    }
}

// MARK: - Current Subscription Card
struct CurrentSubscriptionCard: View {
    let status: SubscriptionStatus
    let subscriptions: [SubscriptionProduct]

    var currentSubscription: SubscriptionProduct? {
        subscriptions.first { $0.id == status.productId }
    }

    var body: some View {
        VStack(spacing: Constants.Spacing.medium) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("ご利用中")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)

                    Text(currentSubscription?.displayName ?? "プレミアムプラン")
                        .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                        .foregroundColor(Constants.Colors.textWhite)
                }

                Spacer()

                Text(currentSubscription?.price ?? "")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Constants.Colors.accentPink)
            }

            Divider()
                .background(Constants.Colors.textGray.opacity(0.3))

            VStack(spacing: Constants.Spacing.small) {
                HStack {
                    Text("次回更新日")
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.textGray)
                    Spacer()
                    Text(status.expirationText)
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)
                }

                HStack {
                    Text("自動更新")
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(Constants.Colors.textGray)
                    Spacer()
                    Text(status.autoRenewing ? "オン" : "オフ")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(status.autoRenewing ? .green : .orange)
                }
            }
        }
        .padding(Constants.Spacing.large)
        .background(Constants.Colors.cardDark)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green, lineWidth: 2)
        )
    }
}

// MARK: - Premium Benefit Card
struct PremiumBenefitCard: View {
    let benefit: PremiumBenefit
    let isPremium: Bool

    var body: some View {
        HStack(spacing: Constants.Spacing.medium) {
            Image(systemName: benefit.icon)
                .font(.system(size: 24))
                .foregroundColor(isPremium ? Constants.Colors.accentPink : Constants.Colors.textGray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text(benefit.description)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)
            }

            Spacer()

            if isPremium {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - FAQ Item
struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Constants.Colors.textGray)
                }
            }

            if isExpanded {
                Text(answer)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)
                    .multilineTextAlignment(.leading)
                    .transition(.opacity)
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    PremiumView()
}
