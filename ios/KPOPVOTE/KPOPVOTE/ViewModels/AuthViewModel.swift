//
//  AuthViewModel.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Authentication ViewModel
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // Debug用: ログイン成功時のアラート表示
    @Published var debugMessage: String?
    @Published var showDebugAlert = false

    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Validation
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    var isValidPassword: Bool {
        return password.count >= 6
    }

    var isValidRegistration: Bool {
        return isValidEmail && isValidPassword && password == confirmPassword
    }

    var isValidLogin: Bool {
        return isValidEmail && isValidPassword
    }

    // MARK: - Register
    func register() async {
        guard isValidRegistration else {
            showError(message: "入力内容を確認してください")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.register(email: email, password: password)
            // Success - auth state listener will update UI
        } catch {
            showError(message: error.localizedDescription)
        }

        isLoading = false
    }

    // MARK: - Login
    func login() async {
        guard isValidLogin else {
            showError(message: "メールアドレスとパスワードを入力してください")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.login(email: email, password: password)
            // Debug: 成功時にアラート表示（TestFlight診断用）
            let isAuth = authService.isAuthenticated
            debugMessage = "✅ ログイン成功\n\nユーザー: \(user.email)\nID: \(user.id)\nisAuthenticated: \(isAuth)"
            showDebugAlert = true
        } catch {
            // Debug: エラー時に詳細情報を表示
            let errorType = String(describing: type(of: error))
            debugMessage = "❌ ログイン失敗\n\nエラー: \(error.localizedDescription)\n\n型: \(errorType)"
            showDebugAlert = true
        }

        isLoading = false
    }

    // MARK: - Logout
    func logout() {
        do {
            try authService.logout()
        } catch {
            showError(message: "ログアウトに失敗しました")
        }
    }

    // MARK: - Error Handling
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    func clearDebugAlert() {
        debugMessage = nil
        showDebugAlert = false
    }

    // MARK: - Reset
    func resetForm() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
        showError = false
    }
}
