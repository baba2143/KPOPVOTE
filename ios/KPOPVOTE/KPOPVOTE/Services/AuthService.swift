//
//  AuthService.swift
//  OSHI Pick
//
//  OSHI Pick - Authentication Service
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isGuest = false

    // Phone authentication state
    @Published var verificationID: String?
    @Published var phoneNumber: String?

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
            debugLog("🔐 [Register] Creating Firebase Auth account for: \(email)")
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            debugLog("✅ [Register] Firebase Auth account created: \(authResult.user.uid)")

            // 2. Register user in Cloud Functions
            let url = URL(string: Constants.API.register)!
            debugLog("📡 [Register] Calling API: \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = [
                "uid": authResult.user.uid,
                "email": email
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            debugLog("📤 [Register] Request body: \(body)")

            let (data, response) = try await URLSession.shared.data(for: request)

            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                debugLog("📥 [Register] HTTP Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    debugLog("📥 [Register] Response body: \(responseString)")
                }

                guard httpResponse.statusCode == 200 else {
                    debugLog("❌ [Register] API returned non-200 status: \(httpResponse.statusCode)")
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
                debugLog("✅ [Register] Successfully decoded response")
            } catch let decodingError {
                debugLog("❌ [Register] JSON Decoding Error: \(decodingError)")
                if let responseString = String(data: data, encoding: .utf8) {
                    debugLog("❌ [Register] Raw response was: \(responseString)")
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

            // Sync pending bias data from tutorial
            await syncPendingBiasData()

            debugLog("✅ [Register] Registration complete for: \(email)")
            return user

        } catch let error as AuthError {
            debugLog("❌ [Register] AuthError: \(error.localizedDescription)")
            throw error
        } catch let error as NSError {
            debugLog("❌ [Register] NSError: domain=\(error.domain), code=\(error.code), description=\(error.localizedDescription)")
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
                    debugLog("❌ [Register] Unknown Firebase Auth error code: \(error.code)")
                    throw AuthError.apiError("Firebase Auth: \(error.localizedDescription)")
                }
            }
            throw AuthError.registrationFailed
        } catch {
            debugLog("❌ [Register] Unexpected error: \(error.localizedDescription)")
            throw AuthError.registrationFailed
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async throws -> User {
        do {
            // 1. Firebase Auth login
            debugLog("🔐 [Login] Attempting Firebase Auth login for: \(email)")
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            debugLog("✅ [Login] Firebase Auth successful: \(authResult.user.uid)")

            // 2. Get ID Token
            debugLog("🎫 [Login] Getting ID token...")
            let token = try await authResult.user.getIDToken()
            debugLog("✅ [Login] ID token obtained")

            // 3. Verify with Cloud Functions
            let url = URL(string: Constants.API.login)!
            debugLog("📡 [Login] Calling API: \(url.absoluteString)")

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                debugLog("📥 [Login] HTTP Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    debugLog("📥 [Login] Response body: \(responseString)")
                }

                guard httpResponse.statusCode == 200 else {
                    debugLog("❌ [Login] API returned non-200 status: \(httpResponse.statusCode)")
                    throw AuthError.loginFailed
                }
            }

            let result: LoginResponse
            do {
                result = try JSONDecoder().decode(LoginResponse.self, from: data)
                debugLog("✅ [Login] Successfully decoded response")
            } catch let decodingError {
                debugLog("❌ [Login] JSON Decoding Error: \(decodingError)")
                if let responseString = String(data: data, encoding: .utf8) {
                    debugLog("❌ [Login] Raw response was: \(responseString)")
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
            debugLog("✅ [Login] isAuthenticated set to true")

            // Register FCM token after successful login
            PushNotificationManager.shared.onUserLogin()

            // Sync pending bias data from tutorial
            await syncPendingBiasData()

            debugLog("✅ [Login] Login complete for: \(email)")
            return user

        } catch let error as AuthError {
            debugLog("❌ [Login] AuthError: \(error.localizedDescription)")
            throw error
        } catch {
            debugLog("❌ [Login] Unexpected error: \(error.localizedDescription)")
            throw AuthError.loginFailed
        }
    }

    // MARK: - Guest Mode
    func loginAsGuest() {
        isGuest = true
        isAuthenticated = false
        currentUser = nil
        AppStorageManager.shared.isGuestMode = true
        debugLog("👤 [Auth] User entered guest mode")
    }

    func exitGuestMode() {
        isGuest = false
        AppStorageManager.shared.isGuestMode = false
        debugLog("👤 [Auth] User exited guest mode")
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

    // MARK: - Delete Account (App Store Guideline 5.1.1(v) compliance)
    /// Permanently deletes user account and all associated data
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.loginFailed
        }

        debugLog("🗑️ [DeleteAccount] Starting account deletion for: \(user.uid)")

        // 1. Get ID Token for API authentication
        let token = try await user.getIDToken()

        // 2. Call Cloud Function to delete all user data from Firestore
        let url = URL(string: Constants.API.deleteAccount)!
        debugLog("📡 [DeleteAccount] Calling API: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            debugLog("📥 [DeleteAccount] HTTP Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                debugLog("📥 [DeleteAccount] Response body: \(responseString)")
            }

            guard httpResponse.statusCode == 200 else {
                debugLog("❌ [DeleteAccount] API returned non-200 status: \(httpResponse.statusCode)")
                if let errorResponse = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                    throw AuthError.apiError(errorResponse.error)
                }
                throw AuthError.apiError("アカウント削除に失敗しました")
            }
        }

        // 3. Unregister FCM token
        PushNotificationManager.shared.onUserLogout()

        // 4. Clear local state
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            self.isGuest = false
            AppStorageManager.shared.isGuestMode = false
        }

        // 5. Clear any cached data
        AppStorageManager.shared.clearPendingBias()

        debugLog("✅ [DeleteAccount] Account deletion completed successfully")
    }

    // MARK: - Update Current User
    func updateCurrentUser(_ user: User) async {
        await MainActor.run {
            self.currentUser = user
        }
        debugLog("✅ [Auth] Current user updated: \(user.displayName ?? user.email), photoURL: \(user.photoURL ?? "nil")")
    }

    // MARK: - Sync Pending Bias Data (チュートリアルで選択した推しをサーバーに同期)
    func syncPendingBiasData() async {
        // Check if there's pending bias data
        guard let pendingBiasIds = AppStorageManager.shared.pendingBiasIds, !pendingBiasIds.isEmpty else {
            debugLog("📱 [Auth] No pending bias data to sync")
            return
        }

        debugLog("📱 [Auth] Found \(pendingBiasIds.count) pending bias IDs to sync")

        do {
            // Fetch all idols to map IDs to idol objects
            let allIdols = try await IdolService.shared.fetchIdols()

            // Filter idols by pending IDs
            let selectedIdols = allIdols.filter { pendingBiasIds.contains($0.id) }

            if selectedIdols.isEmpty {
                debugLog("⚠️ [Auth] No matching idols found for pending IDs")
                AppStorageManager.shared.clearPendingBias()
                return
            }

            // Group idols by group name and build BiasSettings
            let groupedIdols = Dictionary(grouping: selectedIdols, by: { $0.groupName })
            var biasSettings: [BiasSettings] = []

            for (groupName, idols) in groupedIdols {
                let artistId = groupName
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "-", with: "_")

                let setting = BiasSettings(
                    artistId: artistId,
                    artistName: groupName,
                    memberIds: idols.map { $0.id },
                    memberNames: idols.map { $0.name }
                )
                biasSettings.append(setting)
            }

            // Save to server
            try await BiasService.shared.setBias(biasSettings)

            // Clear pending data
            AppStorageManager.shared.clearPendingBias()

            debugLog("✅ [Auth] Successfully synced \(selectedIdols.count) bias settings to server")

        } catch {
            debugLog("❌ [Auth] Failed to sync pending bias data: \(error.localizedDescription)")
            // Don't clear pending data on failure - will retry on next login
        }
    }

    // MARK: - Phone Authentication
    /// Send verification code to phone number
    /// - Parameter phoneNumber: Phone number with country code (e.g., +81901234567)
    /// - Returns: Verification ID for code verification
    func sendVerificationCode(phoneNumber: String) async throws -> String {
        debugLog("📱 [PhoneAuth] Sending verification code to: \(phoneNumber)")

        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    debugLog("❌ [PhoneAuth] Error sending verification code: \(error.localizedDescription)")
                    continuation.resume(throwing: AuthError.phoneVerificationFailed(error.localizedDescription))
                    return
                }

                guard let verificationID = verificationID else {
                    debugLog("❌ [PhoneAuth] No verification ID received")
                    continuation.resume(throwing: AuthError.phoneVerificationFailed("認証IDが取得できませんでした"))
                    return
                }

                debugLog("✅ [PhoneAuth] Verification code sent, ID: \(verificationID.prefix(10))...")
                Task { @MainActor in
                    self.verificationID = verificationID
                    self.phoneNumber = phoneNumber
                }
                continuation.resume(returning: verificationID)
            }
        }
    }

    /// Verify code and sign in
    /// - Parameters:
    ///   - verificationID: Verification ID from sendVerificationCode
    ///   - code: 6-digit verification code from SMS
    /// - Returns: Authenticated User
    func verifyCodeAndSignIn(verificationID: String, code: String) async throws -> User {
        debugLog("📱 [PhoneAuth] Verifying code...")

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )

        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            debugLog("✅ [PhoneAuth] Firebase Auth successful: \(authResult.user.uid)")

            // Get ID Token
            let token = try await authResult.user.getIDToken()

            // Register/Login with Cloud Functions
            let user = try await registerOrLoginWithPhone(
                uid: authResult.user.uid,
                phoneNumber: authResult.user.phoneNumber ?? self.phoneNumber ?? "",
                token: token
            )

            await MainActor.run {
                self.objectWillChange.send()
                self.currentUser = user
                self.isAuthenticated = true
                self.verificationID = nil
                self.phoneNumber = nil
            }

            // Register FCM token after successful login
            PushNotificationManager.shared.onUserLogin()

            // Sync pending bias data from tutorial
            await syncPendingBiasData()

            debugLog("✅ [PhoneAuth] Login complete")
            return user

        } catch let error as AuthError {
            debugLog("❌ [PhoneAuth] AuthError: \(error.localizedDescription)")
            throw error
        } catch let error as NSError {
            debugLog("❌ [PhoneAuth] NSError: domain=\(error.domain), code=\(error.code)")

            // Firebase Auth specific error handling
            if error.domain == "FIRAuthErrorDomain" {
                switch error.code {
                case 17044, 17046: // Invalid verification code
                    throw AuthError.invalidVerificationCode
                case 17051: // Session expired
                    throw AuthError.sessionExpired
                case 17020: // Network error
                    throw AuthError.networkError
                default:
                    throw AuthError.phoneVerificationFailed(error.localizedDescription)
                }
            }
            throw AuthError.phoneVerificationFailed(error.localizedDescription)
        }
    }

    /// Register or login user with phone number via Cloud Functions
    private func registerOrLoginWithPhone(uid: String, phoneNumber: String, token: String) async throws -> User {
        let url = URL(string: Constants.API.login)!
        debugLog("📡 [PhoneAuth] Calling API: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Include phone number in request body for registration
        let body: [String: Any] = [
            "phoneNumber": phoneNumber
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            debugLog("📥 [PhoneAuth] HTTP Status: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                debugLog("❌ [PhoneAuth] API returned non-200 status")
                throw AuthError.loginFailed
            }
        }

        let result = try JSONDecoder().decode(LoginResponse.self, from: data)

        return User(
            id: result.data.uid,
            email: result.data.email,
            displayName: result.data.displayName,
            photoURL: result.data.photoURL,
            points: result.data.points,
            isSuspended: result.data.isSuspended
        )
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
            debugLog("🔄 [Auth] loadUserData - photoURL from API: \(result.data.photoURL ?? "nil")")

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
                debugLog("🔄 [Auth] loadUserData - currentUser.photoURL set to: \(self.currentUser?.photoURL ?? "nil")")
            }

            // Register FCM token after auth state restored
            PushNotificationManager.shared.onUserLogin()

            // Sync pending bias data from tutorial (if any)
            await syncPendingBiasData()

            // Load blocked users for content filtering (Apple Guideline 1.2)
            do {
                try await BlockService.shared.loadBlockedUsers()
                debugLog("✅ [Auth] Blocked users loaded for content filtering")
            } catch {
                debugLog("⚠️ [Auth] Failed to load blocked users: \(error.localizedDescription)")
            }

        } catch {
            debugLog("❌ [Auth] Failed to load user data: \(error.localizedDescription)")
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
    // Phone authentication errors
    case phoneVerificationFailed(String)
    case invalidVerificationCode
    case sessionExpired
    case invalidPhoneNumber
    case tooManyRequests

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
        case .phoneVerificationFailed(let message):
            return "電話番号認証に失敗しました: \(message)"
        case .invalidVerificationCode:
            return "認証コードが正しくありません"
        case .sessionExpired:
            return "認証セッションが期限切れです。もう一度お試しください"
        case .invalidPhoneNumber:
            return "電話番号の形式が正しくありません"
        case .tooManyRequests:
            return "リクエストが多すぎます。しばらくしてからお試しください"
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
