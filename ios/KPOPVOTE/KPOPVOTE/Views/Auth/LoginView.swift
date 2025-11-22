//
//  LoginView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Login View
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var showRegister = false
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: authService))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Constants.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.large) {
                        // Logo/Title
                        VStack(spacing: Constants.Spacing.small) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundColor(Constants.Colors.primaryBlue)

                            Text("K-VOTE COLLECTOR")
                                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textPrimary)

                            Text("推しの投票を管理しよう")
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(Constants.Colors.textSecondary)
                        }
                        .padding(.top, 60)

                        // Login Form
                        VStack(spacing: Constants.Spacing.medium) {
                            // Email TextField
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メールアドレス")
                                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textSecondary)

                                TextField("example@email.com", text: $viewModel.email)
                                    .unifiedInputStyle()
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                            }

                            // Password TextField
                            VStack(alignment: .leading, spacing: 8) {
                                Text("パスワード")
                                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textSecondary)

                                SecureField("6文字以上", text: $viewModel.password)
                                    .unifiedInputStyle()
                            }

                            // Login Button
                            Button(action: {
                                Task {
                                    await viewModel.login()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("ログイン")
                                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isValidLogin ? Constants.Colors.primaryBlue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(!viewModel.isValidLogin || viewModel.isLoading)
                        }
                        .padding()
                        .background(Constants.Colors.cardBackground)
                        .cornerRadius(16)
                        .shadow(radius: 4)

                        // Register Link
                        Button(action: {
                            showRegister = true
                        }) {
                            Text("アカウントをお持ちでない方はこちら")
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(Constants.Colors.primaryBlue)
                        }

                        Spacer()
                    }
                    .padding(Constants.Spacing.medium)
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
            .sheet(isPresented: $showRegister) {
                RegisterView(authService: authService)
            }
        }
    }
}

#Preview {
    LoginView(authService: AuthService())
}
