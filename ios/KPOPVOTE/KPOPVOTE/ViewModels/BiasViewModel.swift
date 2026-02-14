//
//  BiasViewModel.swift
//  OSHI Pick
//
//  OSHI Pick - Bias Settings ViewModel
//

import Foundation
import Combine

// MARK: - Selection Mode
enum BiasSelectionMode: String, CaseIterable {
    case group = "グループ"
    case member = "メンバー"
}

@MainActor
class BiasViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allIdols: [IdolMaster] = []
    @Published var allGroups: [GroupMaster] = []
    @Published var selectedIdols: Set<String> = [] // idol IDs
    @Published var selectedGroups: Set<String> = [] // group IDs
    @Published var selectionMode: BiasSelectionMode = .group
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedChar: String = "ALL" // Selected alphabet filter
    @Published var searchText: String = "" // Search query

    // MARK: - Computed Properties

    /// Alphabet options for filtering
    let ALPHABET = ["ALL"] + (65...90).map { String(UnicodeScalar($0)!) } + ["#"]

    /// Get first character of name for indexing
    func getFirstChar(_ name: String) -> String {
        guard let firstChar = name.first?.uppercased() else { return "#" }
        return firstChar.rangeOfCharacter(from: .letters) != nil ? firstChar : "#"
    }

    /// Filtered idols by selected alphabet and search text
    var filteredIdols: [IdolMaster] {
        var idols = allIdols

        // アルファベットフィルター
        if selectedChar != "ALL" {
            idols = idols.filter { getFirstChar($0.name) == selectedChar }
        }

        // テキスト検索
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            idols = idols.filter {
                $0.name.lowercased().contains(query) ||
                $0.groupName.lowercased().contains(query)
            }
        }

        return idols
    }

    /// Group idols by groupName (from filtered idols)
    var groupedIdols: [String: [IdolMaster]] {
        Dictionary(grouping: filteredIdols, by: { $0.groupName })
    }

    /// Sorted group names
    var groupNames: [String] {
        groupedIdols.keys.sorted()
    }

    /// Count of idols per alphabet character
    var alphabetCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for idol in allIdols {
            let char = getFirstChar(idol.name)
            counts[char, default: 0] += 1
        }
        return counts
    }

    /// Selected idol objects
    var selectedIdolObjects: [IdolMaster] {
        allIdols.filter { selectedIdols.contains($0.id) }
    }

    /// Selected group objects
    var selectedGroupObjects: [GroupMaster] {
        allGroups.filter { selectedGroups.contains($0.id) }
    }

    /// Count of selected items (groups or idols depending on mode)
    var selectedCount: Int {
        switch selectionMode {
        case .group:
            return selectedGroups.count
        case .member:
            return selectedIdols.count
        }
    }

    /// Filtered groups by search text
    var filteredGroups: [GroupMaster] {
        if searchText.isEmpty {
            return allGroups
        }
        let query = searchText.lowercased()
        return allGroups.filter { $0.name.lowercased().contains(query) }
    }

    /// Group alphabet counts
    var groupAlphabetCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for group in allGroups {
            let char = getFirstChar(group.name)
            counts[char, default: 0] += 1
        }
        return counts
    }

    /// Filtered groups by alphabet
    var filteredGroupsByAlphabet: [GroupMaster] {
        var groups = allGroups

        // Alphabet filter
        if selectedChar != "ALL" {
            groups = groups.filter { getFirstChar($0.name) == selectedChar }
        }

        // Text search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            groups = groups.filter { $0.name.lowercased().contains(query) }
        }

        return groups.sorted { $0.name < $1.name }
    }

    // MARK: - Methods

    /// Load all data (groups and idols) from backend
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            debugLog("📱 [BiasViewModel] Loading groups, idols, and bias settings...")

            // 1. まずマスターデータを並列で取得
            async let groupsTask = GroupService.shared.fetchGroups()
            async let idolsTask = IdolService.shared.fetchIdols()

            allGroups = try await groupsTask
            allIdols = try await idolsTask

            debugLog("✅ [BiasViewModel] Loaded \(allGroups.count) groups and \(allIdols.count) idols")

            // 2. マスターデータ取得完了後に推し設定を取得
            // loadCurrentBias()はallGroupsに依存するため、必ず後に実行
            await loadCurrentBias()
        } catch is CancellationError {
            debugLog("⏸️ [BiasViewModel] Data loading cancelled (view transition)")
        } catch let urlError as URLError where urlError.code == .cancelled {
            debugLog("⏸️ [BiasViewModel] URLSession cancelled (view transition)")
        } catch {
            debugLog("❌ [BiasViewModel] Failed to load data: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load all idols from backend (legacy - for backward compatibility)
    func loadIdols() async {
        await loadData()
    }

    /// Load current bias settings from backend
    func loadCurrentBias() async {
        do {
            debugLog("📱 [BiasViewModel] Loading current bias settings...")
            let biasSettings = try await BiasService.shared.getBias()

            // Separate group-level and member-level settings
            var groupIds: Set<String> = []
            var memberIds: Set<String> = []

            for setting in biasSettings {
                if setting.isGroupLevel {
                    // Find group by name (artistName matches group name)
                    if let group = allGroups.first(where: { $0.name == setting.artistName }) {
                        groupIds.insert(group.id)
                    }
                } else {
                    // Member-level selection
                    for memberId in setting.memberIds {
                        memberIds.insert(memberId)
                    }
                }
            }

            selectedGroups = groupIds
            selectedIdols = memberIds

            debugLog("✅ [BiasViewModel] Loaded bias settings: \(selectedGroups.count) groups, \(selectedIdols.count) members selected")
        } catch {
            debugLog("⚠️ [BiasViewModel] Failed to load current bias (may be first time): \(error)")
            // Don't show error for first-time users with no bias set
        }
    }

    /// Toggle idol selection
    /// - Parameter idol: Idol to toggle
    func toggleIdol(_ idol: IdolMaster) {
        if selectedIdols.contains(idol.id) {
            selectedIdols.remove(idol.id)
            debugLog("➖ [BiasViewModel] Deselected: \(idol.name)")
        } else {
            selectedIdols.insert(idol.id)
            debugLog("➕ [BiasViewModel] Selected: \(idol.name)")
        }
    }

    /// Check if idol is selected
    /// - Parameter idol: Idol to check
    /// - Returns: True if selected
    func isSelected(_ idol: IdolMaster) -> Bool {
        selectedIdols.contains(idol.id)
    }

    /// Toggle group selection
    /// - Parameter group: Group to toggle
    func toggleGroup(_ group: GroupMaster) {
        if selectedGroups.contains(group.id) {
            selectedGroups.remove(group.id)
            debugLog("➖ [BiasViewModel] Deselected group: \(group.name)")
        } else {
            selectedGroups.insert(group.id)
            debugLog("➕ [BiasViewModel] Selected group: \(group.name)")
        }
    }

    /// Check if group is selected
    /// - Parameter group: Group to check
    /// - Returns: True if selected
    func isGroupSelected(_ group: GroupMaster) -> Bool {
        selectedGroups.contains(group.id)
    }

    /// Save bias settings to backend
    func saveBias() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            let biasSettings = buildBiasSettings()
            debugLog("📱 [BiasViewModel] Saving \(biasSettings.count) bias groups...")

            try await BiasService.shared.setBias(biasSettings)

            successMessage = "推し設定を保存しました"
            debugLog("✅ [BiasViewModel] Successfully saved bias settings")
        } catch {
            debugLog("❌ [BiasViewModel] Failed to save bias: \(error)")
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    /// Build BiasSettings array from selected groups and idols
    /// - Returns: Array of BiasSettings
    private func buildBiasSettings() -> [BiasSettings] {
        var settings: [BiasSettings] = []

        // Add group-level selections
        for group in selectedGroupObjects {
            let artistId = group.id

            let setting = BiasSettings(
                artistId: artistId,
                artistName: group.name,
                memberIds: [],
                memberNames: [],
                isGroupLevel: true
            )

            settings.append(setting)
            debugLog("📦 [BiasViewModel] Group (group-level): '\(group.name)'")
        }

        // Add member-level selections (group selected idols by group)
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
                    memberNames: selectedGroupIdols.map { $0.name },
                    isGroupLevel: false
                )

                settings.append(setting)
                debugLog("📦 [BiasViewModel] Group (member-level) '\(groupName)': \(selectedGroupIdols.count) members")
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
