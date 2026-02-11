//
//  LinkedAccountsView.swift
//  KPOPVOTE
//
//  View for managing linked accounts (Apple/Google Sign-In)
//

import SwiftUI
import AuthenticationServices

struct LinkedAccountsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel: LinkedAccountsViewModel

    init(authService: AuthService) {
        _viewModel = StateObject(wrappedValue: LinkedAccountsViewModel(authService: authService))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.large) {
                        // Header
                        headerSection

                        // Phone Number Section
                        phoneSection

                        // Apple Section
                        appleSection

                        // Google Section
                        googleSection

                        // Info Section
                        infoSection

                        Spacer()
                    }
                    .padding()
                }

                // Loading Overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("連携アカウント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Constants.Colors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
            .alert("成功", isPresented: $viewModel.showSuccess) {
                Button("OK") { viewModel.clearSuccess() }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .onAppear {
                viewModel.refreshLinkedStatus()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Constants.Spacing.small) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Constants.Colors.primaryBlue)

            Text("アカウント連携")
                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)

            Text("Apple IDやGoogleアカウントを連携すると、\n次回からソーシャルログインが利用できます")
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(Constants.Colors.textGray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Constants.Spacing.medium)
    }

    // MARK: - Phone Section
    private var phoneSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: Constants.Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: "phone.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("電話番号")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(viewModel.formattedPhoneNumber)
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                }

                Spacer()

                // Status
                if viewModel.isPhoneLinked {
                    linkedBadge
                }
            }
            .padding()
        }
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }

    // MARK: - Apple Section
    private var appleSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: Constants.Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "apple.logo")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(viewModel.isAppleLinked ? "連携済み" : "未連携")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(viewModel.isAppleLinked ? .green : Constants.Colors.textGray)
                }

                Spacer()

                // Action
                if viewModel.isAppleLinked {
                    linkedBadge
                } else {
                    Button(action: {
                        Task {
                            await viewModel.linkAppleAccount()
                        }
                    }) {
                        Text("連携する")
                            .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .cornerRadius(20)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding()
        }
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }

    // MARK: - Google Section
    private var googleSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: Constants.Spacing.medium) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)

                    // Google "G" icon simulation
                    Text("G")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Google")
                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                        .foregroundColor(Constants.Colors.textWhite)

                    Text(viewModel.isGoogleLinked ? "連携済み" : "未連携")
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(viewModel.isGoogleLinked ? .green : Constants.Colors.textGray)
                }

                Spacer()

                // Action
                if viewModel.isGoogleLinked {
                    linkedBadge
                } else {
                    Button(action: {
                        Task {
                            await viewModel.linkGoogleAccount()
                        }
                    }) {
                        Text("連携する")
                            .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Constants.Colors.primaryBlue)
                            .cornerRadius(20)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding()
        }
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }

    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Constants.Colors.primaryBlue)
                Text("連携について")
                    .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                    .foregroundColor(Constants.Colors.textWhite)
            }

            VStack(alignment: .leading, spacing: 8) {
                infoRow(text: "連携したアカウントで次回からログインできます")
                infoRow(text: "既存のデータはそのまま引き継がれます")
                infoRow(text: "連携済みのアカウントは解除できません")
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
    }

    // MARK: - Helper Views

    private var linkedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
            Text("連携済み")
                .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
        }
        .foregroundColor(.green)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.2))
        .cornerRadius(16)
    }

    private func infoRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(Constants.Colors.textGray)
            Text(text)
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(Constants.Colors.textGray)
        }
    }
}

#Preview {
    LinkedAccountsView(authService: AuthService())
        .environmentObject(AuthService())
}
