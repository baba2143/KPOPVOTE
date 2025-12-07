//
//  ReportService.swift
//  OSHI Pick
//
//  OSHI Pick - Report Service
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class ReportService {
    static let shared = ReportService()

    private init() {}

    // MARK: - Submit Report
    /// Submit a report for a collection
    /// - Parameters:
    ///   - collectionId: Collection ID to report
    ///   - reason: Report reason
    ///   - comment: Additional comment
    func submitReport(collectionId: String, reason: String, comment: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw CommunityError.notAuthenticated
        }

        let db = Firestore.firestore()

        let reportData: [String: Any] = [
            "collectionId": collectionId,
            "reporterId": user.uid,
            "reporterEmail": user.email ?? "",
            "reason": reason,
            "comment": comment,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]

        debugLog("📝 [ReportService] Submitting report for collection: \(collectionId)")

        try await db.collection("collectionReports").addDocument(data: reportData)

        debugLog("✅ [ReportService] Report submitted successfully")
    }
}
