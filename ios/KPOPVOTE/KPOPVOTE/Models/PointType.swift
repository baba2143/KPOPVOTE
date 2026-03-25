//
//  PointType.swift
//  OSHI Pick
//
//  OSHI Pick - Point Type Model
//  単一ポイント制（2024/02 移行）
//

import Foundation
import SwiftUI

// MARK: - Point Balance (単一ポイント制)
struct PointBalance: Codable {
    var points: Int
    var lastUpdated: String?

    init(points: Int = 0, lastUpdated: String? = nil) {
        self.points = points
        self.lastUpdated = lastUpdated
    }

    /// 投票可能数（1P = 1票）
    var totalVotesAvailable: Int {
        return points
    }

    /// 投票可能数を計算（1P = 1票）
    func calculateVotes() -> Int {
        return points
    }

    /// 指定票数に必要なポイント数を計算（1P = 1票）
    func calculateRequiredPoints(for votes: Int) -> Int {
        return votes
    }
}
