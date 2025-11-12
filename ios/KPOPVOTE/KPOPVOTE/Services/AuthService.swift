//
//  AuthService.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Authentication Service
//

import Foundation
import FirebaseAuth
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false

    private var cancellables = Set<AnyCancellable>()
    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        // Monitor Firebase Auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    await self.loadUserData(uid: firebaseUser.uid, email: firebaseUser.email ?? "")
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
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
        // 1. Create Firebase Auth account
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)

        // 2. Register user in Cloud Functions
        let url = URL(string: Constants.API.register)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "uid": authResult.user.uid,
            "email": email
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.registrationFailed
        }

        let result = try JSONDecoder().decode(RegisterResponse.self, from: data)

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

        return user
    }

    // MARK: - Login
    func login(email: String, password: String) async throws -> User {
        // 1. Firebase Auth login
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)

        // 2. Get ID Token
        let token = try await authResult.user.getIDToken()

        // 3. Verify with Cloud Functions
        let url = URL(string: Constants.API.login)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.loginFailed
        }

        let result = try JSONDecoder().decode(LoginResponse.self, from: data)

        // 4. Create User object
        let user = User(
            id: result.data.uid,
            email: result.data.email,
            displayName: result.data.displayName,
            points: result.data.points,
            isSuspended: result.data.isSuspended
        )

        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
        }

        return user
    }

    // MARK: - Logout
    func logout() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
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

            let user = User(
                id: result.data.uid,
                email: result.data.email,
                displayName: result.data.displayName,
                points: result.data.points,
                isSuspended: result.data.isSuspended
            )

            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }

        } catch {
            print("Failed to load user data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case registrationFailed
    case loginFailed
    case invalidCredentials
    case accountSuspended

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
        let points: Int
        let isSuspended: Bool
    }
}
