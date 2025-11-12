//
//  KPOPVOTEApp.swift
//  KPOPVOTE
//
//  Created by MAKOTO BABA on R 7/11/12.
//

import SwiftUI
import FirebaseCore

@main
struct KPOPVOTEApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
