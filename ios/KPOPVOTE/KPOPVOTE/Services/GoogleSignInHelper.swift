//
//  GoogleSignInHelper.swift
//  KPOPVOTE
//
//  Google Sign-In Helper for Firebase Authentication
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

/// Google Sign-In を処理するヘルパークラス
@MainActor
class GoogleSignInHelper: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: GoogleSignInError?

    // MARK: - Singleton
    static let shared = GoogleSignInHelper()

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Google Sign-In でサインイン（新規/既存ユーザー）
    /// - Returns: Firebase AuthDataResult
    func signInWithGoogle() async throws -> AuthDataResult {
        isLoading = true
        error = nil

        defer { isLoading = false }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw GoogleSignInError.configurationError
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw GoogleSignInError.presentationError
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw GoogleSignInError.invalidCredential
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            debugLog("✅ [GoogleSignIn] Successfully signed in with Google: \(authResult.user.uid)")
            return authResult

        } catch let gidError as GIDSignInError {
            debugLog("❌ [GoogleSignIn] GIDSignIn error: \(gidError.code) - \(gidError.localizedDescription)")
            throw mapGIDError(gidError)
        } catch let nsError as NSError {
            debugLog("❌ [GoogleSignIn] NSError: \(nsError.code) - \(nsError.localizedDescription)")
            throw mapFirebaseError(nsError)
        }
    }

    /// 現在のユーザーに Google アカウントをリンク
    /// - Returns: Firebase AuthDataResult
    func linkToCurrentUser() async throws -> AuthDataResult {
        guard let currentUser = Auth.auth().currentUser else {
            throw GoogleSignInError.noCurrentUser
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw GoogleSignInError.configurationError
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw GoogleSignInError.presentationError
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: topController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw GoogleSignInError.invalidCredential
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await currentUser.link(with: credential)
            debugLog("✅ [GoogleSignIn] Successfully linked Google account to user: \(currentUser.uid)")
            return authResult

        } catch let gidError as GIDSignInError {
            debugLog("❌ [GoogleSignIn] GIDSignIn link error: \(gidError.code) - \(gidError.localizedDescription)")
            throw mapGIDError(gidError)
        } catch let nsError as NSError {
            debugLog("❌ [GoogleSignIn] Link NSError: \(nsError.code) - \(nsError.localizedDescription)")
            throw mapFirebaseError(nsError)
        }
    }

    // MARK: - Private Methods

    /// GIDSignInError をカスタムエラーにマッピング
    private func mapGIDError(_ error: GIDSignInError) -> GoogleSignInError {
        switch error.code {
        case .canceled:
            return .userCancelled
        case .EMM:
            return .emmError
        case .hasNoAuthInKeychain:
            return .noAuthInKeychain
        case .scopesAlreadyGranted:
            return .scopesAlreadyGranted
        default:
            return .unknown(error.localizedDescription)
        }
    }

    /// Firebase エラーをカスタムエラーにマッピング
    private func mapFirebaseError(_ error: NSError) -> GoogleSignInError {
        // Firebase Auth error codes
        switch error.code {
        case 17006: // ERROR_PROVIDER_CONFIGURATION_NOT_FOUND
            return .serverError("Googleログインが設定されていません。Firebase Consoleで有効化してください。")
        case 17025: // ERROR_CREDENTIAL_ALREADY_IN_USE
            return .credentialAlreadyInUse
        case 17015: // ERROR_PROVIDER_ALREADY_LINKED
            return .providerAlreadyLinked
        case 17014: // ERROR_EMAIL_ALREADY_IN_USE
            return .emailAlreadyInUse
        case 17020: // ERROR_NETWORK_REQUEST_FAILED
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

// MARK: - Google Sign-In Errors
enum GoogleSignInError: LocalizedError {
    case userCancelled
    case invalidCredential
    case noCurrentUser
    case configurationError
    case presentationError
    case credentialAlreadyInUse
    case providerAlreadyLinked
    case emailAlreadyInUse
    case networkError
    case emmError
    case noAuthInKeychain
    case scopesAlreadyGranted
    case serverError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "サインインがキャンセルされました"
        case .invalidCredential:
            return "無効な認証情報です"
        case .noCurrentUser:
            return "ログインしていません"
        case .configurationError:
            return "Google Sign-In の設定エラーです"
        case .presentationError:
            return "画面の表示に失敗しました"
        case .credentialAlreadyInUse:
            return "このGoogleアカウントは別のアカウントで使用されています"
        case .providerAlreadyLinked:
            return "すでにGoogleアカウントと連携済みです"
        case .emailAlreadyInUse:
            return "このメールアドレスは既に登録されています"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .emmError:
            return "企業モバイル管理（EMM）エラーです"
        case .noAuthInKeychain:
            return "認証情報が見つかりません"
        case .scopesAlreadyGranted:
            return "すでにスコープが付与されています"
        case .serverError(let message):
            return message
        case .unknown(let message):
            return "エラー: \(message)"
        }
    }
}
