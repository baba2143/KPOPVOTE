//
//  ImageUploadService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Image Upload Service
//

import Foundation
import UIKit
import FirebaseAuth

class ImageUploadService {
    static let shared = ImageUploadService()

    private init() {}

    /// Upload goods image to Firebase Storage
    /// - Parameter image: UIImage to upload
    /// - Returns: Public URL of uploaded image
    func uploadGoodsImage(_ image: UIImage) async throws -> String {
        guard let token = try await Auth.auth().currentUser?.getIDToken() else {
            throw ImageUploadError.notAuthenticated
        }

        // Convert to JPEG with compression
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw ImageUploadError.compressionFailed
        }

        // Convert to Base64
        let base64String = imageData.base64EncodedString()

        print("📤 [ImageUploadService] Uploading image (\(imageData.count) bytes)")

        // Call Cloud Function
        guard let url = URL(string: Constants.API.uploadGoodsImage) else {
            throw ImageUploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: String] = ["imageData": base64String]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }

        print("📥 [ImageUploadService] HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ [ImageUploadService] Error: \(errorString)")
            }
            throw ImageUploadError.uploadFailed
        }

        let result = try JSONDecoder().decode(UploadImageResponse.self, from: data)
        print("✅ [ImageUploadService] Image uploaded: \(result.data.imageUrl)")

        return result.data.imageUrl
    }
}

// MARK: - Response Models
struct UploadImageResponse: Codable {
    let success: Bool
    let data: UploadImageData
}

struct UploadImageData: Codable {
    let imageUrl: String
}

// MARK: - Errors
enum ImageUploadError: LocalizedError {
    case notAuthenticated
    case compressionFailed
    case invalidURL
    case invalidResponse
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "認証が必要です"
        case .compressionFailed:
            return "画像の圧縮に失敗しました"
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .uploadFailed:
            return "画像のアップロードに失敗しました"
        }
    }
}
