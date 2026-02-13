//
//  View+KeyboardDismiss.swift
//  KPOPVOTE
//
//  Keyboard dismissal extension for SwiftUI views
//

import SwiftUI

extension View {
    /// Dismiss keyboard when tapping on the view
    /// Uses simultaneousGesture to allow buttons/list items to also receive taps
    func dismissKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
    }

    /// Dismiss keyboard when dragging (useful with ScrollView)
    func dismissKeyboardOnDrag() -> some View {
        self.simultaneousGesture(
            DragGesture().onChanged { _ in
                hideKeyboard()
            }
        )
    }

    /// キーボード上部に「完了」ボタンを追加
    func keyboardDoneButton() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    hideKeyboard()
                }
            }
        }
    }
}

/// Global function to hide keyboard
func hideKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil, from: nil, for: nil
    )
}
