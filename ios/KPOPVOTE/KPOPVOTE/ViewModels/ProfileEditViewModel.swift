//
//  ProfileEditViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Profile Edit ViewModel
//

import Foundation
import Combine

@MainActor
class ProfileEditViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var selectedBiasIds: [String] = []
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false

    // Validation
    @Published var displayNameError: String?
    @Published var bioError: String?

    private var originalDisplayName: String = ""
    private var originalBio: String = ""
    private var originalBiasIds: [String] = []

    // MARK: - Load Current Profile
    func loadCurrentProfile(user: User) {
        displayName = user.displayName ?? ""
        bio = user.bio ?? ""
        selectedBiasIds = user.biasIds

        // Store original values
        originalDisplayName = displayName
        originalBio = bio
        originalBiasIds = selectedBiasIds

        print("📱 [ProfileEditViewModel] Loaded profile: \(displayName), bio: \(bio.isEmpty ? "empty" : "exists")")
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
               selectedBiasIds != originalBiasIds
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

            print("💾 [ProfileEditViewModel] Saving profile...")

            let updatedUser = try await ProfileService.shared.updateProfile(
                displayName: trimmedDisplayName,
                bio: trimmedBio.isEmpty ? nil : trimmedBio,
                biasIds: selectedBiasIds
            )

            print("✅ [ProfileEditViewModel] Profile saved successfully")

            // Update original values
            originalDisplayName = trimmedDisplayName
            originalBio = trimmedBio
            originalBiasIds = selectedBiasIds

            showSuccess = true
            isSaving = false

            return updatedUser
        } catch {
            print("❌ [ProfileEditViewModel] Save error: \(error)")
            errorMessage = error.localizedDescription
            isSaving = false
            return nil
        }
    }

    // MARK: - Add/Remove Bias
    func toggleBias(idolId: String) {
        if selectedBiasIds.contains(idolId) {
            selectedBiasIds.removeAll { $0 == idolId }
        } else {
            selectedBiasIds.append(idolId)
        }
    }

    func removeBias(idolId: String) {
        selectedBiasIds.removeAll { $0 == idolId }
    }
}
