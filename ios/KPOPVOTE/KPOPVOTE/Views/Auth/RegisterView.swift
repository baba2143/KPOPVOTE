//
//  RegisterView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Register View
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AuthViewModel

    init(authService: AuthService) {
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
                        // Header
                        VStack(spacing: Constants.Spacing.small) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(Constants.Colors.primaryPink)

                            Text("アカウント作成")
                                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textPrimary)

                            Text("K-VOTE COLLECTOR に登録")
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(Constants.Colors.textSecondary)
                        }
                        .padding(.top, 60)

                        // Registration Form
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

                                if !viewModel.email.isEmpty && !viewModel.isValidEmail {
                                    Text("有効なメールアドレスを入力してください")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            // Password TextField
                            VStack(alignment: .leading, spacing: 8) {
                                Text("パスワード")
                                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textSecondary)

                                SecureField("6文字以上", text: $viewModel.password)
                                    .unifiedInputStyle()

                                if !viewModel.password.isEmpty && !viewModel.isValidPassword {
                                    Text("パスワードは6文字以上である必要があります")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            // Confirm Password TextField
                            VStack(alignment: .leading, spacing: 8) {
                                Text("パスワード（確認）")
                                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textSecondary)

                                SecureField("もう一度入力", text: $viewModel.confirmPassword)
                                    .unifiedInputStyle()

                                if !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                                    Text("パスワードが一致しません")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            // Register Button
                            Button(action: {
                                Task {
                                    await viewModel.register()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("登録")
                                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isValidRegistration ? Constants.Colors.primaryPink : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(!viewModel.isValidRegistration || viewModel.isLoading)
                        }
                        .padding()
                        .background(Constants.Colors.cardBackground)
                        .cornerRadius(16)
                        .shadow(radius: 4)

                        // Privacy Policy Note
                        Text("登録することで、利用規約とプライバシーポリシーに同意したものとみなします")
                            .font(.system(size: 12))
                            .foregroundColor(Constants.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .padding(Constants.Spacing.medium)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
        }
    }
}

#Preview {
    RegisterView(authService: AuthService())
}
