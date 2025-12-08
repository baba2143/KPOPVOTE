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

    // MARK: - Report Community Post
    /// Submit a report for a community post
    /// - Parameters:
    ///   - postId: Post ID to report
    ///   - reason: Report reason
    func reportCommunityPost(postId: String, reason: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw CommunityError.notAuthenticated
        }

        let db = Firestore.firestore()
        let batch = db.batch()

        // 1. Add report to communityReports collection
        let reportRef = db.collection("communityReports").document()
        batch.setData([
            "postId": postId,
            "reporterId": user.uid,
            "reason": reason,
            "reportedAt": FieldValue.serverTimestamp()
        ], forDocument: reportRef)

        // 2. Update isReported and reportCount on the post
        let postRef = db.collection("communityPosts").document(postId)
        batch.updateData([
            "isReported": true,
            "reportCount": FieldValue.increment(Int64(1))
        ], forDocument: postRef)

        debugLog("📝 [ReportService] Submitting community post report for: \(postId)")

        try await batch.commit()

        debugLog("✅ [ReportService] Community post report submitted successfully")
    }
}
