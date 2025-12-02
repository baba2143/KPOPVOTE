//
//  KPOPVOTEApp.swift
//  KPOPVOTE
//
//  Created by MAKOTO BABA on R 7/11/12.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct KPOPVOTEApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        FirebaseApp.configure()

        // Global UITextField/UITextView appearance settings
        // Set text color to white for all text inputs
        UITextField.appearance().textColor = .white
        UITextView.appearance().textColor = .white
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
