//
//  DMReportService.swift
//  OSHI Pick
//
//  OSHI Pick - DM Report Service
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Report types for DM reports
enum DMReportType: String, Codable {
    case message = "message"
    case user = "user"
}

class DMReportService {
    static let shared = DMReportService()

    private init() {}

    // MARK: - Report Message
    /// Submit a report for a specific message
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - messageId: Message ID to report
    ///   - messageContent: Content of the reported message (for evidence)
    ///   - reporteeId: User ID of the message sender
    ///   - reason: Report reason (free text)
    func reportMessage(
        conversationId: String,
        messageId: String,
        messageContent: String,
        reporteeId: String,
        reason: String
    ) async throws {
        guard let user = Auth.auth().currentUser else {
            throw DMReportError.notAuthenticated
        }

        let db = Firestore.firestore()

        let reportData: [String: Any] = [
            "conversationId": conversationId,
            "messageId": messageId,
            "messageContent": messageContent,
            "reporterId": user.uid,
            "reporteeId": reporteeId,
            "reportType": DMReportType.message.rawValue,
            "reason": reason,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]

        debugLog("📝 [DMReportService] Reporting message: \(messageId) in conversation: \(conversationId)")

        try await db.collection("dmReports").addDocument(data: reportData)

        debugLog("✅ [DMReportService] Message report submitted successfully")
    }

    // MARK: - Report User
    /// Submit a report for a user (entire conversation)
    /// - Parameters:
    ///   - conversationId: Conversation ID
    ///   - reporteeId: User ID to report
    ///   - reason: Report reason (free text)
    func reportUser(
        conversationId: String,
        reporteeId: String,
        reason: String
    ) async throws {
        guard let user = Auth.auth().currentUser else {
            throw DMReportError.notAuthenticated
        }

        let db = Firestore.firestore()

        let reportData: [String: Any] = [
            "conversationId": conversationId,
            "reporterId": user.uid,
            "reporteeId": reporteeId,
            "reportType": DMReportType.user.rawValue,
            "reason": reason,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]

        debugLog("📝 [DMReportService] Reporting user: \(reporteeId) in conversation: \(conversationId)")

        try await db.collection("dmReports").addDocument(data: reportData)

        debugLog("✅ [DMReportService] User report submitted successfully")
    }
}

// MARK: - Error Types
enum DMReportError: LocalizedError {
    case notAuthenticated
    case reportFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログインが必要です"
        case .reportFailed:
            return "通報の送信に失敗しました"
        }
    }
}
