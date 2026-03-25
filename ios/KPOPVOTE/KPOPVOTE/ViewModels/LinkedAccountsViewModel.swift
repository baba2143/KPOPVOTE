//
//  LinkedAccountsViewModel.swift
//  KPOPVOTE
//
//  ViewModel for managing linked accounts (Apple/Google)
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class LinkedAccountsViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var successMessage: String?
    @Published var showSuccess = false

    // Linked provider status
    @Published var isPhoneLinked = false
    @Published var isAppleLinked = false
    @Published var isGoogleLinked = false

    // User info
    @Published var phoneNumber: String?

    // MARK: - Private Properties
    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(authService: AuthService) {
        self.authService = authService
        refreshLinkedStatus()

        // Observe auth service linked providers changes
        authService.$linkedProviders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshLinkedStatus()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// 連携状態を更新
    func refreshLinkedStatus() {
        guard let firebaseUser = Auth.auth().currentUser else {
            isPhoneLinked = false
            isAppleLinked = false
            isGoogleLinked = false
            phoneNumber = nil
            return
        }

        let providers = firebaseUser.providerData.map { $0.providerID }
        debugLog("🔗 [LinkedAccounts] Current providers: \(providers)")

        isPhoneLinked = providers.contains("phone")
        isAppleLinked = providers.contains("apple.com")
        isGoogleLinked = providers.contains("google.com")

        // Get phone number from provider data
        if let phoneProvider = firebaseUser.providerData.first(where: { $0.providerID == "phone" }) {
            phoneNumber = phoneProvider.phoneNumber
        } else {
            phoneNumber = firebaseUser.phoneNumber
        }

        authService.refreshLinkedProviders()
    }

    /// Apple アカウントをリンク
    func linkAppleAccount() async {
        guard !isAppleLinked else {
            showErrorMessage("すでにAppleアカウントと連携済みです")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.linkAppleAccount()
            refreshLinkedStatus()
            showSuccessMessage("Appleアカウントと連携しました")
        } catch let error as AuthError {
            showErrorMessage(error.localizedDescription)
        } catch let error as AppleSignInError {
            showErrorMessage(error.localizedDescription ?? "Apple連携エラー")
        } catch {
            showErrorMessage("連携に失敗しました: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Google アカウントをリンク
    func linkGoogleAccount() async {
        guard !isGoogleLinked else {
            showErrorMessage("すでにGoogleアカウントと連携済みです")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.linkGoogleAccount()
            refreshLinkedStatus()
            showSuccessMessage("Googleアカウントと連携しました")
        } catch let error as AuthError {
            showErrorMessage(error.localizedDescription)
        } catch let error as GoogleSignInError {
            showErrorMessage(error.localizedDescription ?? "Google連携エラー")
        } catch {
            showErrorMessage("連携に失敗しました: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Private Methods

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    func clearSuccess() {
        successMessage = nil
        showSuccess = false
    }

    // MARK: - Formatted Phone Number
    var formattedPhoneNumber: String {
        guard let phone = phoneNumber else {
            return "未設定"
        }
        // Format phone number for display (mask middle digits)
        if phone.count > 6 {
            let prefix = String(phone.prefix(4))
            let suffix = String(phone.suffix(4))
            return "\(prefix)-xxxx-\(suffix)"
        }
        return phone
    }
}
