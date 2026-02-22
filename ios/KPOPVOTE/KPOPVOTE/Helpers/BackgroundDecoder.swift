//
//  BackgroundDecoder.swift
//  KPOPVOTE
//
//  JSONデコードをバックグラウンドスレッドで実行
//  大きなJSONレスポンスでUIがブロックされるのを防ぐ
//

import Foundation

/// バックグラウンドスレッドでJSONデコードを実行するヘルパー
/// メインスレッドでのデコードによるUI遅延を防ぐ
enum BackgroundDecoder {
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    /// バックグラウンドでJSONをデコード
    /// - Parameters:
    ///   - type: デコード先の型
    ///   - data: JSONデータ
    /// - Returns: デコードされたオブジェクト
    static func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) async throws -> T {
        try await Task.detached(priority: .userInitiated) {
            try decoder.decode(type, from: data)
        }.value
    }

    /// カスタムデコーダーでバックグラウンドデコード
    /// - Parameters:
    ///   - type: デコード先の型
    ///   - data: JSONデータ
    ///   - decoder: カスタムJSONDecoder
    /// - Returns: デコードされたオブジェクト
    static func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        using decoder: JSONDecoder
    ) async throws -> T {
        try await Task.detached(priority: .userInitiated) {
            try decoder.decode(type, from: data)
        }.value
    }
}
