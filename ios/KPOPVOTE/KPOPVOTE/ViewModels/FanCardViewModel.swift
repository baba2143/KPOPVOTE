//
//  FanCardViewModel.swift
//  KPOPVOTE
//
//  FanCard ViewModel
//

import Foundation
import Combine
import UIKit

@MainActor
class FanCardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var fanCard: FanCard?
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false
    @Published var hasFanCard: Bool = false

    // MARK: - Edit Properties
    @Published var odDisplayName: String = ""
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var isPublic: Bool = true
    @Published var theme: FanCardTheme = .default
    @Published var blocks: [FanCardBlock] = []

    // MARK: - Validation
    @Published var odDisplayNameError: String?
    @Published var odDisplayNameAvailable: Bool?
    @Published var isCheckingOdDisplayName: Bool = false

    // MARK: - Image Properties
    @Published var profileImage: UIImage?
    @Published var headerImage: UIImage?
    @Published var profileImageUrl: String = ""
    @Published var headerImageUrl: String = ""

    private var checkOdDisplayNameTask: Task<Void, Never>?

    // MARK: - Load FanCard
    func loadFanCard() async {
        isLoading = true
        errorMessage = nil

        do {
            let card = try await FanCardService.shared.getMyFanCard()
            fanCard = card
            hasFanCard = true
            loadFromFanCard(card)
            debugLog("✅ [FanCardViewModel] Loaded FanCard: \(card.odDisplayName)")
        } catch FanCardError.fanCardNotFound {
            hasFanCard = false
            debugLog("ℹ️ [FanCardViewModel] No FanCard found")
        } catch {
            errorMessage = error.localizedDescription
            debugLog("❌ [FanCardViewModel] Load error: \(error)")
        }

        isLoading = false
    }

    private func loadFromFanCard(_ card: FanCard) {
        odDisplayName = card.odDisplayName
        displayName = card.displayName
        bio = card.bio
        isPublic = card.isPublic
        theme = card.theme
        blocks = card.blocks
        profileImageUrl = card.profileImageUrl
        headerImageUrl = card.headerImageUrl
    }

    // MARK: - Check odDisplayName
    func checkOdDisplayName() {
        checkOdDisplayNameTask?.cancel()

        let name = odDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Basic validation
        if name.isEmpty {
            odDisplayNameError = nil
            odDisplayNameAvailable = nil
            return
        }

        if name.count < 3 {
            odDisplayNameError = "3文字以上で入力してください"
            odDisplayNameAvailable = false
            return
        }

        if name.count > 30 {
            odDisplayNameError = "30文字以内で入力してください"
            odDisplayNameAvailable = false
            return
        }

        // Only allow alphanumeric, underscore, hyphen, ampersand
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-&"))
        if name.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            odDisplayNameError = "英数字、アンダースコア、ハイフン、&のみ使用可能です"
            odDisplayNameAvailable = false
            return
        }

        odDisplayNameError = nil
        isCheckingOdDisplayName = true

        checkOdDisplayNameTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce

                let (available, normalized) = try await FanCardService.shared.checkOdDisplayName(name)
                odDisplayNameAvailable = available
                odDisplayName = normalized

                if !available {
                    odDisplayNameError = "このIDは既に使用されています"
                }
            } catch {
                if !Task.isCancelled {
                    debugLog("❌ [FanCardViewModel] checkOdDisplayName error: \(error)")
                    odDisplayNameError = "確認できませんでした: \(error.localizedDescription)"
                }
            }

            isCheckingOdDisplayName = false
        }
    }

    // MARK: - Create FanCard
    func createFanCard() async -> Bool {
        guard validateForCreate() else { return false }

        isSaving = true
        errorMessage = nil

        do {
            // Upload images if selected
            var profileUrl = profileImageUrl
            var headerUrl = headerImageUrl

            if let image = profileImage {
                profileUrl = try await ImageUploadService.shared.uploadProfileImage(image)
            }

            if let image = headerImage {
                headerUrl = try await ImageUploadService.shared.uploadGoodsImage(image)
            }

            // Filter out incomplete blocks
            let validBlocks = blocks.filter { isBlockValid($0) }

            let request = FanCardCreateRequest(
                odDisplayName: odDisplayName,
                displayName: displayName,
                bio: bio.isEmpty ? nil : bio,
                profileImageUrl: profileUrl.isEmpty ? nil : profileUrl,
                headerImageUrl: headerUrl.isEmpty ? nil : headerUrl,
                theme: theme,
                blocks: validBlocks.isEmpty ? nil : validBlocks,
                isPublic: isPublic
            )

            let card = try await FanCardService.shared.createFanCard(request: request)
            fanCard = card
            hasFanCard = true
            showSuccess = true

            debugLog("✅ [FanCardViewModel] Created FanCard: \(card.odDisplayName)")
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            debugLog("❌ [FanCardViewModel] Create error: \(error)")
            isSaving = false
            return false
        }
    }

    // MARK: - Update FanCard
    func updateFanCard() async -> Bool {
        guard validateForUpdate() else { return false }

        isSaving = true
        errorMessage = nil

        do {
            // Upload images if selected
            var profileUrl: String? = nil
            var headerUrl: String? = nil

            if let image = profileImage {
                profileUrl = try await ImageUploadService.shared.uploadProfileImage(image)
            }

            if let image = headerImage {
                headerUrl = try await ImageUploadService.shared.uploadGoodsImage(image)
            }

            // Filter out incomplete blocks
            let validBlocks = blocks.filter { isBlockValid($0) }

            let request = FanCardUpdateRequest(
                displayName: displayName,
                bio: bio,
                profileImageUrl: profileUrl,
                headerImageUrl: headerUrl,
                theme: theme,
                blocks: validBlocks,
                isPublic: isPublic
            )

            let card = try await FanCardService.shared.updateFanCard(request: request)
            fanCard = card
            showSuccess = true

            debugLog("✅ [FanCardViewModel] Updated FanCard")
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            debugLog("❌ [FanCardViewModel] Update error: \(error)")
            isSaving = false
            return false
        }
    }

    // MARK: - Block Validation
    private func isBlockValid(_ block: FanCardBlock) -> Bool {
        switch block.data {
        case .bias:
            return true // bias block is always valid
        case .link(let data):
            return !data.url.isEmpty
        case .mvLink(let data):
            return !data.youtubeUrl.isEmpty
        case .sns(let data):
            return !data.username.isEmpty
        case .text(let data):
            return !data.content.isEmpty
        case .image(let data):
            return !data.imageUrl.isEmpty
        }
    }

    // MARK: - Delete FanCard
    func deleteFanCard() async -> Bool {
        isSaving = true
        errorMessage = nil

        do {
            try await FanCardService.shared.deleteFanCard()
            fanCard = nil
            hasFanCard = false
            resetForm()

            debugLog("✅ [FanCardViewModel] Deleted FanCard")
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            debugLog("❌ [FanCardViewModel] Delete error: \(error)")
            isSaving = false
            return false
        }
    }

    // MARK: - Validation
    private func validateForCreate() -> Bool {
        if odDisplayName.isEmpty {
            errorMessage = "FanCard IDを入力してください"
            return false
        }

        if odDisplayNameAvailable != true {
            errorMessage = "有効なFanCard IDを入力してください"
            return false
        }

        if displayName.isEmpty {
            errorMessage = "表示名を入力してください"
            return false
        }

        return true
    }

    private func validateForUpdate() -> Bool {
        if displayName.isEmpty {
            errorMessage = "表示名を入力してください"
            return false
        }

        return true
    }

    // MARK: - Block Management
    func addBlock(_ block: FanCardBlock) {
        blocks.append(block)
        reorderBlocks()
    }

    func removeBlock(at index: Int) {
        guard index >= 0 && index < blocks.count else { return }
        blocks.remove(at: index)
        reorderBlocks()
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        blocks.move(fromOffsets: source, toOffset: destination)
        reorderBlocks()
    }

    private func reorderBlocks() {
        for (index, _) in blocks.enumerated() {
            blocks[index].order = index + 1
        }
    }

    // MARK: - Share URL
    var shareURL: URL? {
        guard let card = fanCard else { return nil }
        return FanCardService.shared.getFanCardShareURL(odDisplayName: card.odDisplayName)
    }

    // MARK: - Reset
    func resetForm() {
        odDisplayName = ""
        displayName = ""
        bio = ""
        isPublic = true
        theme = .default
        blocks = []
        profileImage = nil
        headerImage = nil
        profileImageUrl = ""
        headerImageUrl = ""
        odDisplayNameError = nil
        odDisplayNameAvailable = nil
    }
}
