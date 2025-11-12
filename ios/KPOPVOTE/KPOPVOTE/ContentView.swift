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
                    .environmentObject(authService)
            } else {
                // ログイン画面
                LoginView(authService: authService)
            }
        }
    }
}

// 仮のHomeView（後で実装）
struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationView {
            VStack(spacing: Constants.Spacing.large) {
                Spacer()

                // Welcome Message
                VStack(spacing: Constants.Spacing.small) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("ログイン成功！")
                        .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                        .foregroundColor(Constants.Colors.textPrimary)

                    if let email = authService.currentUser?.email {
                        Text(email)
                            .font(.system(size: Constants.Typography.bodySize))
                            .foregroundColor(Constants.Colors.textSecondary)
                    }
                }

                Spacer()

                // Logout Button
                Button(action: {
                    showLogoutConfirm = true
                }) {
                    Text("ログアウト")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("K-VOTE COLLECTOR")
            .background(Constants.Colors.background)
            .alert("ログアウト確認", isPresented: $showLogoutConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("ログアウト", role: .destructive) {
                    do {
                        try authService.logout()
                    } catch {
                        print("ログアウトエラー: \(error.localizedDescription)")
                    }
                }
            } message: {
                Text("ログアウトしますか？")
            }
        }
    }
}

#Preview {
    ContentView()
}
