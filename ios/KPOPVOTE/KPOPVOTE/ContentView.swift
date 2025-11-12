//
//  ContentView.swift
//  KPOPVOTE
//
//  Created by MAKOTO BABA on R 7/11/12.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // ログイン後のメイン画面（後で実装）
                HomeView()
            } else {
                // ログイン画面
                LoginView(authService: authService)
            }
        }
    }
}

// 仮のHomeView（後で実装）
struct HomeView: View {
    var body: some View {
        Text("ホーム画面（実装予定）")
    }
}

#Preview {
    ContentView()
}
