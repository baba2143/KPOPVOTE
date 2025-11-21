//
//  NetworkErrorHandler.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Network Error Handling Utility (Phase 2 Week 4)
//

import Foundation

/// Network Error Handler - Provides user-friendly error messages and retry logic
@MainActor
class NetworkErrorHandler {

    /// Error types with user-friendly messages
    enum NetworkErrorType {
        case noInternet
        case timeout
        case serverError
        case unauthorized
        case notFound
        case rateLimited
        case invalidData
        case unknown

        var userMessage: String {
            switch self {
            case .noInternet:
                return "インターネット接続を確認してください"
            case .timeout:
                return "リクエストがタイムアウトしました\n時間をおいて再度お試しください"
            case .serverError:
                return "サーバーエラーが発生しました\nしばらくしてから再度お試しください"
            case .unauthorized:
                return "認証エラーが発生しました\n再度ログインしてください"
            case .notFound:
                return "データが見つかりませんでした"
            case .rateLimited:
                return "リクエストが多すぎます\nしばらく待ってから再度お試しください"
            case .invalidData:
                return "データの形式が正しくありません"
            case .unknown:
                return "エラーが発生しました\n再度お試しください"
            }
        }

        var canRetry: Bool {
            switch self {
            case .noInternet, .timeout, .serverError, .rateLimited:
                return true
            case .unauthorized, .notFound, .invalidData, .unknown:
                return false
            }
        }
    }

    /// Parse error into user-friendly type
    /// - Parameter error: The error to parse
    /// - Returns: NetworkErrorType with appropriate message
    static func parseError(_ error: Error) -> NetworkErrorType {
        // Check for URL errors (network issues)
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternet
            case .timedOut:
                return .timeout
            case .cannotFindHost, .cannotConnectToHost:
                return .serverError
            default:
                return .unknown
            }
        }

        // Check for HTTP status codes
        if let httpError = error as? HTTPError {
            switch httpError.statusCode {
            case 401:
                return .unauthorized
            case 404:
                return .notFound
            case 429:
                return .rateLimited
            case 500...599:
                return .serverError
            default:
                return .unknown
            }
        }

        // Check for decoding errors
        if error is DecodingError {
            return .invalidData
        }

        return .unknown
    }

    /// Get user-friendly error message
    /// - Parameter error: The error to convert
    /// - Returns: User-friendly message
    static func getUserMessage(for error: Error) -> String {
        return parseError(error).userMessage
    }

    /// Check if error is retryable
    /// - Parameter error: The error to check
    /// - Returns: True if retry is recommended
    static func canRetry(_ error: Error) -> Bool {
        return parseError(error).canRetry
    }
}

/// HTTP Error type for status code handling
struct HTTPError: Error {
    let statusCode: Int
    let message: String?
}
