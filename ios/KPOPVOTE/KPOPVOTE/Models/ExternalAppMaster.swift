//
//  ExternalAppMaster.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - External App Master Model
//

import Foundation

struct ExternalAppMaster: Identifiable, Codable {
    let id: String
    let appName: String
    let appUrl: String
    let iconUrl: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "appId"
        case appName
        case appUrl
        case iconUrl
        case createdAt
        case updatedAt
    }

    // Computed property for display
    var displayName: String {
        appName
    }
}

// MARK: - Sample Data for Preview
extension ExternalAppMaster {
    static let sampleData: [ExternalAppMaster] = [
        ExternalAppMaster(
            id: "idol-champ",
            appName: "IDOL CHAMP",
            appUrl: "https://www.idolchamp.com",
            iconUrl: "https://firebasestorage.googleapis.com/v0/b/kpopvote-9de2b.appspot.com/o/app-icons%2Fidol_champ.png?alt=media",
            createdAt: Date(),
            updatedAt: Date()
        ),
        ExternalAppMaster(
            id: "mnet-plus",
            appName: "Mnet Plus",
            appUrl: "https://www.mnetplus.world",
            iconUrl: "https://firebasestorage.googleapis.com/v0/b/kpopvote-9de2b.appspot.com/o/app-icons%2Fmnet_plus.png?alt=media",
            createdAt: Date(),
            updatedAt: Date()
        ),
        ExternalAppMaster(
            id: "mubeat",
            appName: "MUBEAT",
            appUrl: "https://www.mubeat.io",
            iconUrl: "https://firebasestorage.googleapis.com/v0/b/kpopvote-9de2b.appspot.com/o/app-icons%2Fmubeat.png?alt=media",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
