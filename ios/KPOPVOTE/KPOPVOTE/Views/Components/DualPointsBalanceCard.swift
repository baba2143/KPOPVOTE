//
//  DualPointsBalanceCard.swift
//  OSHI Pick
//
//  OSHI Pick - Dual Points Balance Card Component
//

import SwiftUI

struct DualPointsBalanceCard: View {
    let premiumPoints: Int
    let regularPoints: Int

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("マイポイント")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            // Points display
            HStack(spacing: 0) {
                // Premium points (left)
                PointTypeCard(
                    type: .premium,
                    points: premiumPoints
                )

                // Divider
                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // Regular points (right)
                PointTypeCard(
                    type: .regular,
                    points: regularPoints
                )
            }

            // Total votes capacity
            HStack {
                Text("合計投票可能数:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(totalVotes)票")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var totalVotes: Int {
        PointType.premium.calculateVotes(from: premiumPoints) +
        PointType.regular.calculateVotes(from: regularPoints)
    }
}

// MARK: - Point Type Card
struct PointTypeCard: View {
    let type: PointType
    let points: Int

    var body: some View {
        VStack(spacing: 8) {
            // Icon and label
            HStack(spacing: 4) {
                Text(type.icon)
                Text(type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Points value
            Text("\(points)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(type.color)

            Text("pt")
                .font(.caption)
                .foregroundColor(.secondary)

            // Vote capacity
            Text("(\(votesFromPoints)票分)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var votesFromPoints: Int {
        type.calculateVotes(from: points)
    }
}

// MARK: - Compact Version
struct DualPointsBalanceCompact: View {
    let premiumPoints: Int
    let regularPoints: Int

    var body: some View {
        HStack(spacing: 16) {
            // Premium
            HStack(spacing: 4) {
                Text(PointType.premium.icon)
                Text("\(premiumPoints)pt")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(PointType.premium.color)
            }

            // Regular
            HStack(spacing: 4) {
                Text(PointType.regular.icon)
                Text("\(regularPoints)pt")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(PointType.regular.color)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        DualPointsBalanceCard(
            premiumPoints: 50,
            regularPoints: 200
        )

        DualPointsBalanceCard(
            premiumPoints: 0,
            regularPoints: 100
        )

        HStack {
            Text("Compact:")
            Spacer()
            DualPointsBalanceCompact(
                premiumPoints: 50,
                regularPoints: 200
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    .padding()
}
