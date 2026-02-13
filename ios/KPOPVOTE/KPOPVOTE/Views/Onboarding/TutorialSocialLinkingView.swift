//
//  TutorialSocialLinkingView.swift
//  OSHI Pick
//
//  オンボーディング用 Apple/Google連携ステップView
//  SMS認証後に必ず1つ以上のソーシャルアカウント連携を必須とする
//

import SwiftUI

struct TutorialSocialLinkingView: View {
    @ObservedObject var authService: AuthService
    let onComplete: () -> Void

    @State private var isLinkingApple = false
    @State private var isLinkingGoogle = false
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var linkedApple = false
    @State private var linkedGoogle = false

    // CREDENTIAL_ALREADY_IN_USE エラー時のカスタムアラート
    @State private var showCredentialInUseAlert = false
    @State private var credentialInUseProvider: String? // "google" or "apple"
    @State private var credentialInUseEmail: String? // 既存アカウントのメールアドレス
    @State private var isSigningInWithExisting = false

    /// 連携済みかどうか（最低1つ）
    private var hasLinkedAny: Bool {
        linkedApple || linkedGoogle
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo
            Image("oshi_pick_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)

            // Title & Description
            VStack(spacing: 12) {
                Text("アカウント連携")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Constants.Colors.textWhite)

                Text("Apple または Googleと連携すると\n次回からかんたんにログインできます")
                    .font(.system(size: 16))
                    .foregroundColor(Constants.Colors.textGray)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Linking Buttons
            VStack(spacing: 16) {
                // Apple Link Button
                Button(action: {
                    Task {
                        await linkApple()
                    }
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))

                        Text("Appleでサインイン")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))

                        Spacer()

                        if isLinkingApple {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else if linkedApple {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Text("連携する")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                    .cornerRadius(16)
                }
                .disabled(isLinkingApple || isLinkingGoogle || linkedApple)
                .opacity(linkedApple ? 0.7 : 1.0)

                // Google Link Button
                Button(action: {
                    Task {
                        await linkGoogle()
                    }
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))

                        Text("Googleでサインイン")
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))

                        Spacer()

                        if isLinkingGoogle {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else if linkedGoogle {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Text("連携する")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Constants.Colors.accentBlue)
                    .cornerRadius(16)
                }
                .disabled(isLinkingApple || isLinkingGoogle || linkedGoogle)
                .opacity(linkedGoogle ? 0.7 : 1.0)
            }
            .padding(.horizontal, 16)

            // Status message
            if hasLinkedAny {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("連携が完了しました")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }

            // Complete Button
            VStack(spacing: 12) {
                Button(action: {
                    completeOnboarding()
                }) {
                    HStack {
                        Text("はじめる")
                            .font(.system(size: Constants.Typography.bodySize, weight: .bold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        hasLinkedAny ?
                            LinearGradient(
                                colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .cornerRadius(16)
                    .shadow(
                        color: hasLinkedAny ? Constants.Colors.accentPink.opacity(0.4) : Color.clear,
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                }
                .disabled(!hasLinkedAny)

                if !hasLinkedAny {
                    Text("続行するには Apple または Google と連携してください")
                        .font(.system(size: 12))
                        .foregroundColor(Constants.Colors.textGray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage ?? "エラーが発生しました")
        }
        .alert("アカウントが見つかりました", isPresented: $showCredentialInUseAlert) {
            Button("別のアカウントを試す", role: .cancel) {
                // credential をクリア
                if credentialInUseProvider == "google" {
                    GoogleSignInHelper.shared.clearStoredCredential()
                } else {
                    AppleSignInHelper.shared.clearStoredCredential()
                }
                credentialInUseProvider = nil
                credentialInUseEmail = nil
            }
            Button("このアカウントでログイン") {
                Task {
                    await signInWithExistingAccount()
                }
            }
        } message: {
            if let email = credentialInUseEmail {
                Text("\(email) は既に登録済みです。\nこのアカウントでログインしますか？\n\n※現在の電話番号アカウントは破棄されます")
            } else if credentialInUseProvider == "google" {
                Text("このGoogleアカウントは既に登録済みです。\nこのアカウントでログインしますか？\n\n※現在の電話番号アカウントは破棄されます")
            } else {
                Text("このApple IDは既に登録済みです。\nこのアカウントでログインしますか？\n\n※現在の電話番号アカウントは破棄されます")
            }
        }
        .onAppear {
            checkLinkedProviders()
        }
    }

    // MARK: - Methods

    private func checkLinkedProviders() {
        let providers = authService.getLinkedProviders()
        linkedApple = providers.contains("apple.com")
        linkedGoogle = providers.contains("google.com")
    }

    private func linkApple() async {
        isLinkingApple = true
        defer { isLinkingApple = false }

        do {
            try await authService.linkAppleAccount()
            linkedApple = true
            authService.refreshLinkedProviders()
        } catch AuthError.apiError(let message) where message.contains("別のアカウントで使用") {
            // CREDENTIAL_ALREADY_IN_USE エラー（AuthService経由）
            credentialInUseProvider = "apple"
            credentialInUseEmail = AppleSignInHelper.shared.storedEmail
            showCredentialInUseAlert = true
        } catch AppleSignInError.credentialAlreadyInUse {
            // AppleSignInError.credentialAlreadyInUse（直接）
            credentialInUseProvider = "apple"
            credentialInUseEmail = AppleSignInHelper.shared.storedEmail
            showCredentialInUseAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func linkGoogle() async {
        isLinkingGoogle = true
        defer { isLinkingGoogle = false }

        do {
            try await authService.linkGoogleAccount()
            linkedGoogle = true
            authService.refreshLinkedProviders()
        } catch AuthError.apiError(let message) where message.contains("別のアカウントで使用") {
            // CREDENTIAL_ALREADY_IN_USE エラー（AuthService経由）
            credentialInUseProvider = "google"
            credentialInUseEmail = GoogleSignInHelper.shared.storedEmail
            showCredentialInUseAlert = true
        } catch GoogleSignInError.credentialAlreadyInUse {
            // GoogleSignInError.credentialAlreadyInUse（直接）
            credentialInUseProvider = "google"
            credentialInUseEmail = GoogleSignInHelper.shared.storedEmail
            showCredentialInUseAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// 既存アカウントでサインイン（CREDENTIAL_ALREADY_IN_USE 時の回復処理）
    private func signInWithExistingAccount() async {
        guard let provider = credentialInUseProvider else { return }

        isSigningInWithExisting = true
        defer {
            isSigningInWithExisting = false
            credentialInUseProvider = nil
            credentialInUseEmail = nil
        }

        do {
            if provider == "google" {
                _ = try await authService.signInWithExistingGoogleAccount()
            } else {
                _ = try await authService.signInWithExistingAppleAccount()
            }

            // サインイン成功 - 連携済み状態を更新
            checkLinkedProviders()

            // ソーシャル連携は既に完了しているので、オンボーディングを完了
            AppStorageManager.shared.hasCompletedSocialLinking = true
            AppStorageManager.shared.hasCompletedOnboarding = true
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func completeOnboarding() {
        guard hasLinkedAny else { return }
        AppStorageManager.shared.hasCompletedSocialLinking = true
        AppStorageManager.shared.hasCompletedOnboarding = true
        onComplete()
    }
}

// MARK: - Preview
#Preview {
    TutorialSocialLinkingView(
        authService: AuthService(),
        onComplete: {}
    )
    .background(Constants.Colors.backgroundDark)
}
