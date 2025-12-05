//
//  AuthService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Authentication Service
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isGuest = false

    private var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        // Check if user was in guest mode
        isGuest = AppStorageManager.shared.isGuestMode

        // Monitor Firebase Auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    await self.loadUserData(uid: firebaseUser.uid, email: firebaseUser.email ?? "")
                    // Exit guest mode when authenticated
                    self.isGuest = false
                    AppStorageManager.shared.isGuestMode = false
                } else {
                    // Only set not authenticated if not in guest mode
                    if !self.isGuest {
                        self.currentUser = nil
                        self.isAuthenticated = false
                    }
                }
            }
        }
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Register
    func register(email: String, password: String) async throws -> User {
        do {
            // 1. Create Firebase Auth account
            print("🔐 [Register] Creating Firebase Auth account for: \(email)")
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            print("✅ [Register] Firebase Auth account created: \(authResult.user.uid)")

            // 2. Register user in Cloud Functions
            let url = URL(string: Constants.API.register)!
            print("📡 [Register] Calling API: \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "uid": authResult.user.uid,
                "email": email
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            print("📤 [Register] Request body: \(body)")

            let (data, response) = try await URLSession.shared.data(for: request)

            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 [Register] HTTP Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 [Register] Response body: \(responseString)")
                }

                guard httpResponse.statusCode == 200 else {
                    print("❌ [Register] API returned non-200 status: \(httpResponse.statusCode)")
                    // Try to parse error message from response
                    if let errorResponse = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                        throw AuthError.apiError(errorResponse.error)
                    }
                    throw AuthError.registrationFailed
                }
            }

            let result: RegisterResponse
            do {
                result = try JSONDecoder().decode(RegisterResponse.self, from: data)
                print("✅ [Register] Successfully decoded response")
            } catch let decodingError {
                print("❌ [Register] JSON Decoding Error: \(decodingError)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ [Register] Raw response was: \(responseString)")
                }
                throw AuthError.apiError("レスポンス解析エラー")
            }

            // 3. Create User object
            let user = User(
                id: authResult.user.uid,
                email: email,
                points: result.data.points
            )

            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }

            // Register FCM token after successful registration
            PushNotificationManager.shared.onUserLogin()

            print("✅ [Register] Registration complete for: \(email)")
            return user

        } catch let error as AuthError {
            print("❌ [Register] AuthError: \(error.localizedDescription)")
            throw error
        } catch let error as NSError {
            print("❌ [Register] NSError: domain=\(error.domain), code=\(error.code), description=\(error.localizedDescription)")
            // Firebase Auth specific error handling
            if error.domain == "FIRAuthErrorDomain" {
                switch error.code {
                case 17007: // ERROR_EMAIL_ALREADY_IN_USE
                    throw AuthError.emailAlreadyInUse
                case 17026: // ERROR_WEAK_PASSWORD
                    throw AuthError.weakPassword
                case 17008: // ERROR_INVALID_EMAIL
                    throw AuthError.invalidEmail
                case 17020: // ERROR_NETWORK_REQUEST_FAILED
                    throw AuthError.networkError
                default:
                    print("❌ [Register] Unknown Firebase Auth error code: \(error.code)")
                    throw AuthError.apiError("Firebase Auth: \(error.localizedDescription)")
                }
            }
            throw AuthError.registrationFailed
        } catch {
            print("❌ [Register] Unexpected error: \(error.localizedDescription)")
            throw AuthError.registrationFailed
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async throws -> User {
        do {
            // 1. Firebase Auth login
            print("🔐 [Login] Attempting Firebase Auth login for: \(email)")
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ [Login] Firebase Auth successful: \(authResult.user.uid)")

            // 2. Get ID Token
            print("🎫 [Login] Getting ID token...")
            let token = try await authResult.user.getIDToken()
            print("✅ [Login] ID token obtained")

            // 3. Verify with Cloud Functions
            let url = URL(string: Constants.API.login)!
            print("📡 [Login] Calling API: \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 [Login] HTTP Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 [Login] Response body: \(responseString)")
                }

                guard httpResponse.statusCode == 200 else {
                    print("❌ [Login] API returned non-200 status: \(httpResponse.statusCode)")
                    throw AuthError.loginFailed
                }
            }

            let result: LoginResponse
            do {
                result = try JSONDecoder().decode(LoginResponse.self, from: data)
                print("✅ [Login] Successfully decoded response")
            } catch let decodingError {
                print("❌ [Login] JSON Decoding Error: \(decodingError)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ [Login] Raw response was: \(responseString)")
                }
                throw AuthError.apiError("ログインレスポンス解析エラー")
            }

            // 4. Create User object
            let user = User(
                id: result.data.uid,
                email: result.data.email,
                displayName: result.data.displayName,
                photoURL: result.data.photoURL,
                points: result.data.points,
                isSuspended: result.data.isSuspended
            )

            // 明示的にSwiftUIに変更を通知（Release buildでの問題回避）
            self.objectWillChange.send()
            self.currentUser = user
            self.isAuthenticated = true
            print("✅ [Login] isAuthenticated set to true")

            // Register FCM token after successful login
            PushNotificationManager.shared.onUserLogin()

            print("✅ [Login] Login complete for: \(email)")
            return user

        } catch let error as AuthError {
            print("❌ [Login] AuthError: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ [Login] Unexpected error: \(error.localizedDescription)")
            throw AuthError.loginFailed
        }
    }

    // MARK: - Guest Mode
    func loginAsGuest() {
        isGuest = true
        isAuthenticated = false
        currentUser = nil
        AppStorageManager.shared.isGuestMode = true
        print("👤 [Auth] User entered guest mode")
    }

    func exitGuestMode() {
        isGuest = false
        AppStorageManager.shared.isGuestMode = false
        print("👤 [Auth] User exited guest mode")
    }

    // MARK: - Logout
    func logout() throws {
        // Unregister FCM token before logout
        PushNotificationManager.shared.onUserLogout()

        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
        isGuest = false
        AppStorageManager.shared.isGuestMode = false
    }

    // MARK: - Update Current User
    func updateCurrentUser(_ user: User) async {
        await MainActor.run {
            self.currentUser = user
        }
        print("✅ [Auth] Current user updated: \(user.displayName ?? user.email), photoURL: \(user.photoURL ?? "nil")")
    }

    // MARK: - Load User Data
    private func loadUserData(uid: String, email: String) async {
        do {
            guard let token = try await Auth.auth().currentUser?.getIDToken() else {
                return
            }

            let url = URL(string: Constants.API.login)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return
            }

            let result = try JSONDecoder().decode(LoginResponse.self, from: data)
            print("🔄 [Auth] loadUserData - photoURL from API: \(result.data.photoURL ?? "nil")")

            let user = User(
                id: result.data.uid,
                email: result.data.email,
                displayName: result.data.displayName,
                photoURL: result.data.photoURL,
                points: result.data.points,
                isSuspended: result.data.isSuspended
            )

            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                print("🔄 [Auth] loadUserData - currentUser.photoURL set to: \(self.currentUser?.photoURL ?? "nil")")
            }

            // Register FCM token after auth state restored
            PushNotificationManager.shared.onUserLogin()

        } catch {
            print("❌ [Auth] Failed to load user data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case registrationFailed
    case loginFailed
    case invalidCredentials
    case accountSuspended
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    case networkError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "アカウント登録に失敗しました"
        case .loginFailed:
            return "ログインに失敗しました"
        case .invalidCredentials:
            return "メールアドレスまたはパスワードが正しくありません"
        case .accountSuspended:
            return "このアカウントは停止されています"
        case .emailAlreadyInUse:
            return "このメールアドレスは既に使用されています"
        case .weakPassword:
            return "パスワードは6文字以上で入力してください"
        case .invalidEmail:
            return "メールアドレスの形式が正しくありません"
        case .networkError:
            return "ネットワークエラーが発生しました。接続を確認してください"
        case .apiError(let message):
            return "サーバーエラー: \(message)"
        }
    }
}

// MARK: - Response Models
struct RegisterResponse: Codable {
    let success: Bool
    let data: RegisterData

    struct RegisterData: Codable {
        let uid: String
        let email: String
        let points: Int
    }
}

struct LoginResponse: Codable {
    let success: Bool
    let data: LoginData

    struct LoginData: Codable {
        let uid: String
        let email: String
        let displayName: String?
        let photoURL: String?
        let points: Int
        let isSuspended: Bool
    }
}

struct ApiErrorResponse: Codable {
    let success: Bool
    let error: String
}
