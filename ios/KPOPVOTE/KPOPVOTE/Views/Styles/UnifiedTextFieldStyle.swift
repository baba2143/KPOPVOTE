//
//  UnifiedTextFieldStyle.swift
//  KPOPVOTE
//
//  Unified TextField/SecureField Style - Consistent UI across all input fields
//

import SwiftUI

// MARK: - Unified TextField Style
struct UnifiedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Constants.Colors.cardDark)
            .cornerRadius(12)
            .tint(Constants.Colors.accentPink)
            .foregroundStyle(.white) // iOS 16+ more reliable than foregroundColor
    }
}

// MARK: - Unified Input Style (for TextField & SecureField)
struct UnifiedInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Constants.Colors.cardDark)
            .cornerRadius(12)
            .tint(Constants.Colors.accentPink)
            .foregroundStyle(.white) // iOS 16+ more reliable than foregroundColor
    }
}

// MARK: - Extension for Easy Access
extension View {
    func unifiedInputStyle() -> some View {
        self.modifier(UnifiedInputStyle())
    }
}
