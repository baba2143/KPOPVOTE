//
//  ProfileEditViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Profile Edit ViewModel
//

import Foundation
import Combine
import UIKit

@MainActor
class ProfileEditViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false

    // Profile Image
    @Published var selectedImage: UIImage?
    @Published var currentPhotoURL: String?
    @Published var isUploadingImage: Bool = false

    // Validation
    @Published var displayNameError: String?
    @Published var bioError: String?

    private var originalDisplayName: String = ""
    private var originalBio: String = ""
    private var originalPhotoURL: String?

    // MARK: - Load Current Profile
    func loadCurrentProfile(user: User) {
        displayName = user.displayName ?? ""
        bio = user.bio ?? ""
        currentPhotoURL = user.photoURL

        // Store original values
        originalDisplayName = displayName
        originalBio = bio
        originalPhotoURL = user.photoURL

        debugLog("📱 [ProfileEditViewModel] Loaded profile: \(displayName), bio: \(bio.isEmpty ? "empty" : "exists"), photoURL: \(user.photoURL ?? "none")")
    }

    // MARK: - Validation
    func validate() -> Bool {
        displayNameError = nil
        bioError = nil

        // Display name validation
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDisplayName.isEmpty {
            displayNameError = "表示名を入力してください"
            return false
        }
        if trimmedDisplayName.count > 30 {
            displayNameError = "表示名は30文字以内で入力してください"
            return false
        }

        // Bio validation
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedBio.count > 150 {
            bioError = "自己紹介は150文字以内で入力してください"
            return false
        }

        return true
    }

    // MARK: - Check if Changed
    func hasChanges() -> Bool {
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedDisplayName != originalDisplayName ||
               trimmedBio != originalBio ||
               selectedImage != nil
    }

    // MARK: - Save Profile
    func saveProfile() async -> User? {
        guard validate() else {
            return nil
        }

        guard hasChanges() else {
            errorMessage = "変更がありません"
            return nil
        }

        isSaving = true
        errorMessage = nil

        do {
            let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedBio = bio.trimmingCharacters(in: .whitespacesAndNewlines)

            debugLog("💾 [ProfileEditViewModel] Saving profile...")

            // Upload image if selected
            var newPhotoURL: String?
            if let image = selectedImage {
                isUploadingImage = true
                debugLog("📸 [ProfileEditViewModel] Uploading profile image...")
                newPhotoURL = try await ImageUploadService.shared.uploadProfileImage(image)
                isUploadingImage = false
                debugLog("✅ [ProfileEditViewModel] Image uploaded: \(newPhotoURL ?? "")")
            }

            let updatedUser = try await ProfileService.shared.updateProfile(
                displayName: trimmedDisplayName,
                bio: trimmedBio.isEmpty ? nil : trimmedBio,
                biasIds: nil,  // biasIdsはBiasSettingsViewで管理するため、ここでは送信しない
                photoURL: newPhotoURL
            )

            debugLog("✅ [ProfileEditViewModel] Profile saved successfully")

            // Update original values
            originalDisplayName = trimmedDisplayName
            originalBio = trimmedBio
            if let newPhotoURL = newPhotoURL {
                originalPhotoURL = newPhotoURL
                currentPhotoURL = newPhotoURL
            }
            selectedImage = nil

            showSuccess = true
            isSaving = false

            return updatedUser
        } catch {
            debugLog("❌ [ProfileEditViewModel] Save error: \(error)")
            errorMessage = error.localizedDescription
            isUploadingImage = false
            isSaving = false
            return nil
        }
    }
}
