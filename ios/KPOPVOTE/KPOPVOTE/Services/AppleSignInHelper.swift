//
//  AppleSignInHelper.swift
//  KPOPVOTE
//
//  Apple Sign-In Helper for Firebase Authentication
//

import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth

/// Apple Sign-In を処理するヘルパークラス
/// ASAuthorizationControllerDelegate を実装し、Firebase との連携を行う
@MainActor
class AppleSignInHelper: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: AppleSignInError?

    // MARK: - Private Properties
    private var currentNonce: String?
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    /// 最後に取得したcredential（既存アカウントでのサインイン用）
    private var lastCredential: AuthCredential?
    /// 最後に取得したメールアドレス（アラート表示用）
    private var lastEmail: String?

    // MARK: - Singleton
    static let shared = AppleSignInHelper()

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Apple Sign-In を開始し、Firebase credential を返す
    /// - Returns: Firebase AuthCredential
    func signIn() async throws -> AuthCredential {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // Generate nonce
        let nonce = randomNonceString()
        currentNonce = nonce

        // Create Apple ID request
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        // Execute authorization
        let appleCredential = try await performAuthorization(request: request)

        // メールアドレスを保存（アラート表示用）
        // 注: Appleは初回認証時のみemailを返す。2回目以降はnilの場合がある
        self.lastEmail = appleCredential.email

        // Create Firebase credential
        guard let appleIDToken = appleCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AppleSignInError.invalidCredential
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        return firebaseCredential
    }

    /// 現在のユーザーに Apple アカウントをリンク
    /// - Returns: Firebase AuthDataResult
    func linkToCurrentUser() async throws -> AuthDataResult {
        guard let currentUser = Auth.auth().currentUser else {
            throw AppleSignInError.noCurrentUser
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        let credential = try await signIn()

        // credential を保持（既存アカウントでのサインイン用）
        self.lastCredential = credential

        do {
            let result = try await currentUser.link(with: credential)
            debugLog("✅ [AppleSignIn] Successfully linked Apple account to user: \(currentUser.uid)")
            return result
        } catch let linkError as NSError {
            debugLog("❌ [AppleSignIn] Link error: \(linkError.code) - \(linkError.localizedDescription)")
            throw mapFirebaseError(linkError)
        }
    }

    /// 保存されたcredentialで既存アカウントにサインイン
    /// - Note: linkToCurrentUser() で CREDENTIAL_ALREADY_IN_USE エラーが発生した場合に使用
    /// - Returns: Firebase AuthDataResult
    func signInWithStoredCredential() async throws -> AuthDataResult {
        guard let credential = lastCredential else {
            debugLog("❌ [AppleSignIn] No stored credential available")
            throw AppleSignInError.invalidCredential
        }

        isLoading = true
        defer {
            isLoading = false
            lastCredential = nil  // 使用後はクリア
        }

        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            debugLog("✅ [AppleSignIn] Successfully signed in with stored credential: \(authResult.user.uid)")
            return authResult
        } catch let nsError as NSError {
            debugLog("❌ [AppleSignIn] Sign-in with stored credential failed: \(nsError.code) - \(nsError.localizedDescription)")
            throw mapFirebaseError(nsError)
        }
    }

    /// 保存されたcredentialが存在するかどうか
    var hasStoredCredential: Bool {
        return lastCredential != nil
    }

    /// 保存されたメールアドレス（アラート表示用）
    var storedEmail: String? {
        return lastEmail
    }

    /// 保存されたcredentialをクリア
    func clearStoredCredential() {
        lastCredential = nil
        lastEmail = nil
    }

    /// Apple Sign-In でサインイン（新規/既存ユーザー）
    /// - Returns: Firebase AuthDataResult
    func signInWithApple() async throws -> AuthDataResult {
        isLoading = true
        error = nil

        defer { isLoading = false }

        let credential = try await signIn()

        do {
            let result = try await Auth.auth().signIn(with: credential)
            debugLog("✅ [AppleSignIn] Successfully signed in with Apple: \(result.user.uid)")
            return result
        } catch let signInError as NSError {
            debugLog("❌ [AppleSignIn] Sign-in error: \(signInError.code) - \(signInError.localizedDescription)")
            throw mapFirebaseError(signInError)
        }
    }

    // MARK: - Private Methods

    private func performAuthorization(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    /// Generate random nonce string
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    /// SHA256 hash
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }

    /// Firebase エラーをカスタムエラーにマッピング
    private func mapFirebaseError(_ error: NSError) -> AppleSignInError {
        // Firebase Auth error codes
        switch error.code {
        case 17006: // ERROR_PROVIDER_CONFIGURATION_NOT_FOUND
            return .serverError("Appleログインが設定されていません。Firebase Consoleで有効化してください。")
        case 17025: // ERROR_CREDENTIAL_ALREADY_IN_USE
            return .credentialAlreadyInUse
        case 17015: // ERROR_PROVIDER_ALREADY_LINKED
            return .providerAlreadyLinked
        case 17014: // ERROR_EMAIL_ALREADY_IN_USE
            return .emailAlreadyInUse
        case 17020: // ERROR_NETWORK_REQUEST_FAILED
            return .networkError
        case 17995: // ERROR_WEB_CONTEXT_CANCELLED
            return .userCancelled
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInHelper: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            Task { @MainActor in
                self.continuation?.resume(throwing: AppleSignInError.invalidCredential)
                self.continuation = nil
            }
            return
        }

        Task { @MainActor in
            self.continuation?.resume(returning: appleIDCredential)
            self.continuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError

        Task { @MainActor in
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                self.continuation?.resume(throwing: AppleSignInError.userCancelled)
            } else {
                self.continuation?.resume(throwing: AppleSignInError.authorizationFailed(error.localizedDescription))
            }
            self.continuation = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInHelper: ASAuthorizationControllerPresentationContextProviding {

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window for presentation
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window ?? UIWindow()
    }
}

// MARK: - Apple Sign-In Errors
enum AppleSignInError: LocalizedError {
    case userCancelled
    case invalidCredential
    case authorizationFailed(String)
    case noCurrentUser
    case credentialAlreadyInUse
    case providerAlreadyLinked
    case emailAlreadyInUse
    case networkError
    case serverError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "サインインがキャンセルされました"
        case .invalidCredential:
            return "無効な認証情報です"
        case .authorizationFailed(let message):
            return "Apple認証に失敗しました: \(message)"
        case .noCurrentUser:
            return "ログインしていません"
        case .credentialAlreadyInUse:
            return "このApple IDは別のアカウントで使用されています"
        case .providerAlreadyLinked:
            return "すでにAppleアカウントと連携済みです"
        case .emailAlreadyInUse:
            return "このメールアドレスは既に登録されています"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .serverError(let message):
            return message
        case .unknown(let message):
            return "エラー: \(message)"
        }
    }
}
