//
//  DeepLinkManager.swift
//  OSHI Pick
//
//  Universal Links / Deep Link handling
//

import Foundation
import Combine

/// Deep Link Manager - handles Universal Links for the app
final class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    /// Published vote ID to navigate to
    @Published var pendingVoteId: String?

    /// Published invite code to apply
    @Published var pendingInviteCode: String?

    private init() {}

    /// Handle incoming Universal Link URL
    /// - Parameter url: The incoming URL
    /// - Returns: true if the URL was handled
    @discardableResult
    func handleURL(_ url: URL) -> Bool {
        debugLog("🔗 [DeepLinkManager] Handling URL: \(url.absoluteString)")

        guard let host = url.host else {
            debugLog("⚠️ [DeepLinkManager] No host in URL")
            return false
        }

        // Check if it's our domain
        guard host == "kpopvote-9de2b.web.app" else {
            debugLog("⚠️ [DeepLinkManager] Unknown host: \(host)")
            return false
        }

        let path = url.path
        debugLog("🔗 [DeepLinkManager] Path: \(path)")

        // Handle vote deep link: /vote/{voteId}
        if path.hasPrefix("/vote/") {
            let voteId = String(path.dropFirst("/vote/".count))
            if !voteId.isEmpty {
                debugLog("✅ [DeepLinkManager] Found vote ID: \(voteId)")
                DispatchQueue.main.async {
                    self.pendingVoteId = voteId
                }
                return true
            }
        }

        // Handle invite deep link: /invite/{code}
        if path.hasPrefix("/invite/") {
            let inviteCode = String(path.dropFirst("/invite/".count))
            if !inviteCode.isEmpty {
                debugLog("✅ [DeepLinkManager] Found invite code: \(inviteCode)")
                DispatchQueue.main.async {
                    self.pendingInviteCode = inviteCode
                }
                return true
            }
        }

        debugLog("⚠️ [DeepLinkManager] Unhandled path: \(path)")
        return false
    }

    /// Clear pending navigation after it's been consumed
    func clearPendingVote() {
        pendingVoteId = nil
    }

    /// Clear pending invite code after it's been consumed
    func clearPendingInviteCode() {
        pendingInviteCode = nil
    }
}
