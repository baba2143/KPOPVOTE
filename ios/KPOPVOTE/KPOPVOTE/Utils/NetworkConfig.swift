//
//  NetworkConfig.swift
//  OSHI Pick
//
//  OSHI Pick - Network Configuration
//

import Foundation

/// Network configuration constants
enum NetworkConfig {
    /// Default timeout for network requests (30 seconds)
    static let defaultTimeout: TimeInterval = 30

    /// Timeout for upload operations (60 seconds)
    static let uploadTimeout: TimeInterval = 60

    /// Timeout for download operations (60 seconds)
    static let downloadTimeout: TimeInterval = 60
}

/// URLRequest extension for consistent timeout configuration
extension URLRequest {
    /// Creates a URLRequest with default timeout
    /// - Parameter url: The URL for the request
    /// - Returns: URLRequest with timeout configured
    static func withTimeout(url: URL, timeout: TimeInterval = NetworkConfig.defaultTimeout) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        return request
    }

    /// Sets timeout interval on the request
    /// - Parameter timeout: Timeout in seconds
    /// - Returns: Self for chaining
    mutating func withTimeoutInterval(_ timeout: TimeInterval = NetworkConfig.defaultTimeout) {
        self.timeoutInterval = timeout
    }
}
