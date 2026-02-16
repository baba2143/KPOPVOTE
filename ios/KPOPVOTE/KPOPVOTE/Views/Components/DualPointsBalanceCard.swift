//
//  DualPointsBalanceCard.swift
//  OSHI Pick
//
//  OSHI Pick - Single Points Balance Card Component
//  単一ポイント制（2024/02 移行）
//

import SwiftUI

// MARK: - Single Points Balance Card (単一ポイント制)
struct SinglePointsBalanceCard: View {
    let points: Int

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("マイポイント")
                    .font(.headline)
                    .foregroundColor(Constants.Colors.textWhite)
                Spacer()
            }

            // Points display
            VStack(spacing: 8) {
                // Points value
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(points)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Constants.Colors.accentPink)
                    Text("P")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Constants.Colors.accentPink.opacity(0.7))
                }

                // Vote capacity (1P = 1票)
                Text("(\(points)票分)")
                    .font(.subheadline)
                    .foregroundColor(Constants.Colors.textGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Constants.Colors.gradientPink.opacity(0.15),
                    Constants.Colors.gradientBlue.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Compact Version (単一ポイント制)
struct SinglePointsBalanceCompact: View {
    let points: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .foregroundColor(Constants.Colors.accentPink)
                .font(.system(size: 12))
            Text("\(points)P")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Constants.Colors.accentPink)
        }
    }
}

// MARK: - Legacy Aliases (後方互換性のため)
// 既存コードが DualPointsBalanceCard を参照している場合のため
typealias DualPointsBalanceCard = SinglePointsBalanceCard
typealias DualPointsBalanceCompact = SinglePointsBalanceCompact

// MARK: - Legacy initializer extension (後方互換性)
extension SinglePointsBalanceCard {
    /// 後方互換性: premiumPoints と regularPoints を受け取り、合計を表示
    init(premiumPoints: Int, regularPoints: Int) {
        // 単一ポイント制: premiumPoints のみ使用（regularPoints は破棄済み）
        self.points = premiumPoints
    }
}

extension SinglePointsBalanceCompact {
    /// 後方互換性: premiumPoints と regularPoints を受け取り、合計を表示
    init(premiumPoints: Int, regularPoints: Int) {
        // 単一ポイント制: premiumPoints のみ使用（regularPoints は破棄済み）
        self.points = premiumPoints
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SinglePointsBalanceCard(points: 250)

        SinglePointsBalanceCard(points: 0)

        HStack {
            Text("Compact:")
            Spacer()
            SinglePointsBalanceCompact(points: 250)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    .padding()
}
