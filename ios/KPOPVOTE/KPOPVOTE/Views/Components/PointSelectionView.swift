//
//  PointSelectionView.swift
//  OSHI Pick
//
//  OSHI Pick - Point Selection Component
//

import SwiftUI

struct PointSelectionView: View {
    @Binding var selectedMode: PointSelectionMode
    let premiumPoints: Int
    let regularPoints: Int
    let premiumPointsToBeUsed: Int
    let regularPointsToBeUsed: Int
    let pointSelectionError: String?
    let onModeChange: (PointSelectionMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("ポイント選択")
                .font(.headline)
                .foregroundColor(.primary)

            // Radio button options
            VStack(spacing: 8) {
                ForEach(PointSelectionMode.allCases, id: \.self) { mode in
                    PointSelectionRow(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        premiumPoints: premiumPoints,
                        regularPoints: regularPoints
                    ) {
                        selectedMode = mode
                        onModeChange(mode)
                    }
                }
            }

            // Divider
            Divider()
                .padding(.vertical, 4)

            // Point usage summary
            VStack(alignment: .leading, spacing: 8) {
                // Points to be used
                HStack {
                    Text("消費予定:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    PointUsageLabel(
                        premiumPoints: premiumPointsToBeUsed,
                        regularPoints: regularPointsToBeUsed
                    )
                }

                // Current balance
                HStack {
                    Text("残高:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 12) {
                        PointBadge(type: .premium, points: premiumPoints)
                        PointBadge(type: .regular, points: regularPoints)
                    }
                }

                // Error message
                if let error = pointSelectionError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Point Selection Row
struct PointSelectionRow: View {
    let mode: PointSelectionMode
    let isSelected: Bool
    let premiumPoints: Int
    let regularPoints: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Radio button
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray)
                    .font(.system(size: 22))

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(mode.displayName)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundColor(.primary)

                        if mode == .auto {
                            Text("おすすめ")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .cornerRadius(4)
                        }
                    }

                    Text(modeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                // Vote capacity for this mode
                if mode != .auto {
                    VStack(alignment: .trailing) {
                        Text("\(votesAvailable)票")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(votesAvailable > 0 ? .primary : .secondary)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var modeDescription: String {
        switch mode {
        case .auto:
            return "🔴優先で使用し、不足分は🔵で補完"
        case .premium:
            return "Premium会員向け（1P = 1票）"
        case .regular:
            return "通常ポイント（5P = 1票）"
        }
    }

    private var votesAvailable: Int {
        switch mode {
        case .auto:
            return PointType.premium.calculateVotes(from: premiumPoints) +
                   PointType.regular.calculateVotes(from: regularPoints)
        case .premium:
            return PointType.premium.calculateVotes(from: premiumPoints)
        case .regular:
            return PointType.regular.calculateVotes(from: regularPoints)
        }
    }
}

// MARK: - Point Usage Label
struct PointUsageLabel: View {
    let premiumPoints: Int
    let regularPoints: Int

    var body: some View {
        HStack(spacing: 4) {
            if premiumPoints > 0 && regularPoints > 0 {
                Text("\(premiumPoints)pt")
                    .foregroundColor(.red)
                Text("(🔴)")
                Text("+")
                    .foregroundColor(.secondary)
                Text("\(regularPoints)pt")
                    .foregroundColor(.blue)
                Text("(🔵)")
                Text("=")
                    .foregroundColor(.secondary)
                Text("\(premiumPoints + regularPoints)pt")
                    .fontWeight(.semibold)
            } else if premiumPoints > 0 {
                Text("\(premiumPoints)pt")
                    .foregroundColor(.red)
                Text("(🔴)")
            } else if regularPoints > 0 {
                Text("\(regularPoints)pt")
                    .foregroundColor(.blue)
                Text("(🔵)")
            } else {
                Text("0pt")
                    .foregroundColor(.secondary)
            }
        }
        .font(.subheadline)
    }
}

// MARK: - Point Badge
struct PointBadge: View {
    let type: PointType
    let points: Int

    var body: some View {
        HStack(spacing: 4) {
            Text(type.icon)
            Text("\(points)pt")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(type.color)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        PointSelectionView(
            selectedMode: .constant(.auto),
            premiumPoints: 50,
            regularPoints: 200,
            premiumPointsToBeUsed: 30,
            regularPointsToBeUsed: 20,
            pointSelectionError: nil,
            onModeChange: { _ in }
        )

        PointSelectionView(
            selectedMode: .constant(.premium),
            premiumPoints: 10,
            regularPoints: 200,
            premiumPointsToBeUsed: 50,
            regularPointsToBeUsed: 0,
            pointSelectionError: "🔴 赤ポイントが不足しています（必要: 50P）",
            onModeChange: { _ in }
        )
    }
    .padding()
}
