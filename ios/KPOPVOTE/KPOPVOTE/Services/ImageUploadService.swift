//
//  ImageUploadService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Image Upload Service
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseStorage

class ImageUploadService {
    static let shared = ImageUploadService()

    private init() {}

    /// Upload goods image to Firebase Storage (using Firebase Storage SDK directly)
    /// - Parameter image: UIImage to upload
    /// - Returns: Download URL with access token (works regardless of storage rules)
    func uploadGoodsImage(_ image: UIImage) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ImageUploadError.notAuthenticated
        }

        // Resize image if too large (max 800px for smaller file size)
        let resizedImage = resizeImage(image, maxDimension: 800)

        print("📐 [ImageUploadService] Original size: \(image.size), Resized: \(resizedImage.size)")

        // Convert to JPEG with good compression (0.7 = good quality, reasonable size)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw ImageUploadError.compressionFailed
        }

        print("📦 [ImageUploadService] Image data size: \(imageData.count) bytes (~\(imageData.count / 1024)KB)")

        // Check file size (max 5MB)
        let maxSize = 5 * 1024 * 1024 // 5MB
        guard imageData.count <= maxSize else {
            throw ImageUploadError.imageTooLarge
        }

        // Create unique filename
        let filename = "\(UUID().uuidString).jpg"
        let storagePath = "goods/\(userId)/\(filename)"

        // Get Firebase Storage reference
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child(storagePath)

        print("📤 [ImageUploadService] Uploading to Firebase Storage: \(storagePath)")

        // Upload image data
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await imageRef.putDataAsync(imageData, metadata: metadata)

        // Get download URL with token - this works regardless of storage rules!
        let downloadURL = try await imageRef.downloadURL()
        let downloadURLString = downloadURL.absoluteString

        print("✅ [ImageUploadService] Image uploaded successfully: \(downloadURLString)")

        return downloadURLString
    }

    /// Resize image to fit within max dimension while maintaining aspect ratio
    /// - Parameters:
    ///   - image: Original image
    ///   - maxDimension: Maximum width or height
    /// - Returns: Resized image
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If image is already smaller, return as is
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        var newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Render resized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
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
    case imageTooLarge

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
        case .imageTooLarge:
            return "画像サイズが大きすぎます (最大5MB)"
        }
    }
}
