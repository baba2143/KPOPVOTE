//
//  BiasViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Bias Settings ViewModel
//

import Foundation
import Combine

@MainActor
class BiasViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allIdols: [IdolMaster] = []
    @Published var selectedIdols: Set<String> = [] // idol IDs
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // MARK: - Computed Properties

    /// Group idols by groupName
    var groupedIdols: [String: [IdolMaster]] {
        Dictionary(grouping: allIdols, by: { $0.groupName })
    }

    /// Sorted group names
    var groupNames: [String] {
        groupedIdols.keys.sorted()
    }

    /// Selected idol objects
    var selectedIdolObjects: [IdolMaster] {
        allIdols.filter { selectedIdols.contains($0.id) }
    }

    /// Count of selected idols
    var selectedCount: Int {
        selectedIdols.count
    }

    // MARK: - Methods

    /// Load all idols from backend
    func loadIdols() async {
        isLoading = true
        errorMessage = nil

        do {
            print("📱 [BiasViewModel] Loading idols...")
            allIdols = try await IdolService.shared.fetchIdols()
            print("✅ [BiasViewModel] Loaded \(allIdols.count) idols")

            // Load current bias settings
            await loadCurrentBias()
        } catch {
            print("❌ [BiasViewModel] Failed to load idols: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load current bias settings from backend
    func loadCurrentBias() async {
        do {
            print("📱 [BiasViewModel] Loading current bias settings...")
            let biasSettings = try await BiasService.shared.getBias()

            // Extract all memberIds from biasSettings
            let memberIds = biasSettings.flatMap { $0.memberIds }
            selectedIdols = Set(memberIds)

            print("✅ [BiasViewModel] Loaded bias settings: \(selectedIdols.count) members selected")
        } catch {
            print("⚠️ [BiasViewModel] Failed to load current bias (may be first time): \(error)")
            // Don't show error for first-time users with no bias set
        }
    }

    /// Toggle idol selection
    /// - Parameter idol: Idol to toggle
    func toggleIdol(_ idol: IdolMaster) {
        if selectedIdols.contains(idol.id) {
            selectedIdols.remove(idol.id)
            print("➖ [BiasViewModel] Deselected: \(idol.name)")
        } else {
            selectedIdols.insert(idol.id)
            print("➕ [BiasViewModel] Selected: \(idol.name)")
        }
    }

    /// Check if idol is selected
    /// - Parameter idol: Idol to check
    /// - Returns: True if selected
    func isSelected(_ idol: IdolMaster) -> Bool {
        selectedIdols.contains(idol.id)
    }

    /// Save bias settings to backend
    func saveBias() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            let biasSettings = buildBiasSettings()
            print("📱 [BiasViewModel] Saving \(biasSettings.count) bias groups...")

            try await BiasService.shared.setBias(biasSettings)

            successMessage = "推し設定を保存しました"
            print("✅ [BiasViewModel] Successfully saved bias settings")
        } catch {
            print("❌ [BiasViewModel] Failed to save bias: \(error)")
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    /// Build BiasSettings array from selected idols
    /// - Returns: Array of BiasSettings grouped by artist
    private func buildBiasSettings() -> [BiasSettings] {
        var settings: [BiasSettings] = []

        // Group selected idols by group
        for (groupName, idols) in groupedIdols {
            let selectedGroupIdols = idols.filter { selectedIdols.contains($0.id) }

            if !selectedGroupIdols.isEmpty {
                // Create artistId from group name (simplified)
                let artistId = groupName
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "-", with: "_")

                let setting = BiasSettings(
                    artistId: artistId,
                    artistName: groupName,
                    memberIds: selectedGroupIdols.map { $0.id },
                    memberNames: selectedGroupIdols.map { $0.name }
                )

                settings.append(setting)

                print("📦 [BiasViewModel] Group '\(groupName)': \(selectedGroupIdols.count) members")
            }
        }

        return settings
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Clear success message
    func clearSuccess() {
        successMessage = nil
    }
}
