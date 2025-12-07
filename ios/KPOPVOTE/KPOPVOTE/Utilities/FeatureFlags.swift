//
//  FeatureFlags.swift
//  OSHI Pick
//
//  Phase 1: ポイント・課金機能無効化のためのフィーチャーフラグ
//  Phase 2で再有効化時は各フラグをtrueに変更
//

import Foundation

/// フィーチャーフラグ管理
/// Phase 1ではポイント・課金機能を無効化
struct FeatureFlags {

    // MARK: - ポイント機能

    /// ポイント機能の有効/無効
    /// false = ポイント表示・消費を無効化
    static let pointsEnabled = false

    // MARK: - 課金機能

    /// App Store アプリ内課金の有効/無効
    /// false = IAP購入機能を無効化
    static let iapEnabled = false

    /// サブスクリプションの有効/無効
    /// false = サブスク機能を無効化
    static let subscriptionEnabled = false

    // MARK: - ストア機能

    /// ストア画面の表示有効/無効
    /// false = ストア画面へのナビゲーションを非表示
    static var storeEnabled: Bool {
        return iapEnabled || subscriptionEnabled
    }

    // MARK: - デイリーログイン

    /// デイリーログインボーナスの有効/無効
    /// false = ログインボーナス機能を無効化
    static let dailyLoginBonusEnabled = false
}
