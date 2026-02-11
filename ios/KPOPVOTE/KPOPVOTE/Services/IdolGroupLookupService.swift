//
//  IdolGroupLookupService.swift
//  OSHI Pick
//
//  OSHI Pick - Idol/Group Name Lookup Service
//

import Foundation

@MainActor
class IdolGroupLookupService: ObservableObject {
    static let shared = IdolGroupLookupService()

    @Published private(set) var idols: [IdolMaster] = []
    @Published private(set) var groups: [GroupMaster] = []
    @Published private(set) var isLoaded = false

    private var idolsByName: [String: IdolMaster] = [:]
    private var groupsByName: [String: GroupMaster] = [:]

    private init() {}

    func loadIfNeeded() async {
        guard !isLoaded else { return }
        do {
            async let idolsFetch = IdolService.shared.fetchIdols()
            async let groupsFetch = GroupService.shared.fetchGroups()
            let (fetchedIdols, fetchedGroups) = try await (idolsFetch, groupsFetch)

            self.idols = fetchedIdols
            self.groups = fetchedGroups

            for idol in fetchedIdols {
                idolsByName[idol.name.lowercased()] = idol
            }
            for group in fetchedGroups {
                groupsByName[group.name.lowercased()] = group
            }
            isLoaded = true
            debugLog("✅ [IdolGroupLookupService] Loaded \(fetchedIdols.count) idols, \(fetchedGroups.count) groups")
        } catch {
            debugLog("❌ [IdolGroupLookupService] Failed: \(error)")
        }
    }

    func findIdol(byName name: String) -> IdolMaster? {
        return idolsByName[name.lowercased()]
    }

    func findGroup(byName name: String) -> GroupMaster? {
        return groupsByName[name.lowercased()]
    }

    func getImageUrl(forLabel label: String) -> String? {
        if let idol = findIdol(byName: label) { return idol.imageUrl }
        if let group = findGroup(byName: label) { return group.imageUrl }
        return nil
    }

    func getGroupName(forLabel label: String) -> String? {
        return findIdol(byName: label)?.groupName
    }
}
