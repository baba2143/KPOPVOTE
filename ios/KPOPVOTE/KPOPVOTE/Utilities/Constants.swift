//
//  Constants.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Application Constants
//

import SwiftUI

enum Constants {
    // MARK: - API Base URL
    static let apiBaseURL = "https://us-central1-kpopvote-9de2b.cloudfunctions.net"

    // MARK: - Color Palette
    enum Colors {
        static let primaryBlue = Color(hex: "1976d2")
        static let primaryPink = Color(hex: "e91e63")
        static let background = Color(hex: "f5f5f5")
        static let cardBackground = Color.white
        static let textPrimary = Color.black
        static let textSecondary = Color.gray

        // Task Status Colors
        static let statusPending = Color.blue
        static let statusCompleted = Color.green
        static let statusExpired = Color.red
    }

    // MARK: - Typography
    enum Typography {
        static let titleSize: CGFloat = 24
        static let headlineSize: CGFloat = 18
        static let bodySize: CGFloat = 16
        static let captionSize: CGFloat = 14
    }

    // MARK: - Spacing
    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let extraLarge: CGFloat = 32
    }

    // MARK: - API Endpoints
    enum API {
        // Auth
        static let register = "\(apiBaseURL)/register"
        static let login = "\(apiBaseURL)/login"

        // Bias
        static let setBias = "\(apiBaseURL)/setBias"
        static let getBias = "\(apiBaseURL)/getBias"

        // Task
        static let registerTask = "\(apiBaseURL)/registerTask"
        static let getUserTasks = "\(apiBaseURL)/getUserTasks"
        static let fetchTaskOGP = "\(apiBaseURL)/fetchTaskOGP"
        static let updateTaskStatus = "\(apiBaseURL)/updateTaskStatus"

        // Vote (Optional)
        static let getVoteList = "\(apiBaseURL)/getVoteList"
        static let castVote = "\(apiBaseURL)/castVote"
    }

    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let authToken = "authToken"
        static let userId = "userId"
        static let userEmail = "userEmail"
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
