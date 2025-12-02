//
//  ReportService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Report Service
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

        print("📝 [ReportService] Submitting report for collection: \(collectionId)")

        try await db.collection("collectionReports").addDocument(data: reportData)

        print("✅ [ReportService] Report submitted successfully")
    }
}
