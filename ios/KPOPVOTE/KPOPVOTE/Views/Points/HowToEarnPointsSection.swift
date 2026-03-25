//
//  HowToEarnPointsSection.swift
//  OSHI Pick
//
//  OSHI Pick - How To Earn Points Section
//  ポイントの貯め方セクション
//

import SwiftUI

// MARK: - How To Earn Points Section
struct HowToEarnPointsSection: View {
    @State private var expandedCategories: Set<EarnCategory> = []

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            // Section Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Constants.Colors.accentPink)
                Text("ポイントの貯め方")
                    .font(.system(size: Constants.Typography.headlineSize, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)
                Spacer()
            }

            // Category List
            VStack(spacing: Constants.Spacing.small) {
                ForEach(EarnCategory.allCases, id: \.self) { category in
                    EarnCategoryCard(
                        category: category,
                        isExpanded: expandedCategories.contains(category),
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedCategories.contains(category) {
                                    expandedCategories.remove(category)
                                } else {
                                    expandedCategories.insert(category)
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding(Constants.Spacing.medium)
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }
}

// MARK: - Earn Category Card
struct EarnCategoryCard: View {
    let category: EarnCategory
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Category Header
            Button(action: onToggle) {
                HStack(spacing: Constants.Spacing.small) {
                    // Category Icon
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: category.icon)
                            .font(.system(size: 16))
                            .foregroundColor(category.color)
                    }

                    // Category Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)
                        Text(category.subtitle)
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                    }

                    Spacer()

                    // Expand/Collapse Icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Constants.Colors.textGray)
                }
                .padding(.vertical, Constants.Spacing.small)
            }
            .buttonStyle(PlainButtonStyle())

            // Actions List (when expanded)
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(EarnAction.actions(for: category)) { action in
                        EarnActionRow(action: action)
                        if action.id != EarnAction.actions(for: category).last?.id {
                            Divider()
                                .background(Constants.Colors.textGray.opacity(0.2))
                                .padding(.leading, 44)
                        }
                    }
                }
                .padding(.leading, Constants.Spacing.small)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, Constants.Spacing.small)
        .background(Constants.Colors.backgroundDark.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Earn Action Row
struct EarnActionRow: View {
    let action: EarnAction

    var body: some View {
        HStack(spacing: Constants.Spacing.small) {
            // Action Icon
            Image(systemName: action.icon)
                .font(.system(size: 14))
                .foregroundColor(action.category.color)
                .frame(width: 24)

            // Action Name
            Text(action.name)
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(Constants.Colors.textWhite)

            Spacer()

            // Daily Limit (if any)
            if let limitText = action.limitText {
                Text(limitText)
                    .font(.system(size: 11))
                    .foregroundColor(Constants.Colors.textGray)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Constants.Colors.textGray.opacity(0.2))
                    .cornerRadius(4)
            }

            // Points
            HStack(spacing: 2) {
                Text("+\(action.points)")
                    .font(.system(size: Constants.Typography.captionSize, weight: .bold))
                    .foregroundColor(Constants.Colors.accentPink)
                Text("P")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Constants.Colors.accentPink.opacity(0.7))
            }
        }
        .padding(.vertical, Constants.Spacing.small)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Constants.Colors.backgroundDark
            .ignoresSafeArea()

        ScrollView {
            HowToEarnPointsSection()
                .padding()
        }
    }
}
