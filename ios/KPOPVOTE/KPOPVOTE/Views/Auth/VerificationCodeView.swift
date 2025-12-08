//
//  VerificationCodeView.swift
//  OSHI Pick
//
//  OSHI Pick - SMS Verification Code Input View
//

import SwiftUI

struct VerificationCodeView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VerificationCodeViewModel
    @FocusState private var isTextFieldFocused: Bool

    let phoneNumber: String

    init(authService: AuthService, verificationID: String, phoneNumber: String) {
        self.phoneNumber = phoneNumber
        _viewModel = StateObject(wrappedValue: VerificationCodeViewModel(
            authService: authService,
            verificationID: verificationID,
            phoneNumber: phoneNumber
        ))
    }

    var body: some View {
        ZStack {
            // Background (ダークモード)
            Constants.Colors.backgroundDark
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Constants.Spacing.large) {
                    // Header
                    VStack(spacing: Constants.Spacing.small) {
                        Image(systemName: "message.badge.checkmark.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Constants.Colors.primaryBlue)

                        Text("認証コードを入力")
                            .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                            .foregroundColor(Constants.Colors.textWhite)

                        Text("\(viewModel.maskedPhoneNumber) に送信しました")
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.textGray)
                    }
                    .padding(.top, 60)

                    // Code Input Form
                    VStack(spacing: Constants.Spacing.medium) {
                        // 6-digit Code Input
                        HStack(spacing: 8) {
                            ForEach(0..<6, id: \.self) { index in
                                CodeDigitView(
                                    digit: viewModel.digit(at: index),
                                    isFocused: viewModel.focusedIndex == index
                                )
                            }
                        }
                        .overlay(
                            TextField("", text: $viewModel.code)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                                .focused($isTextFieldFocused)
                                .opacity(0.01) // Nearly invisible but still functional
                                .onChange(of: viewModel.code) { newValue in
                                    viewModel.handleCodeChange(newValue)
                                }
                        )
                        .onTapGesture {
                            isTextFieldFocused = true
                        }

                        if let error = viewModel.codeError {
                            Text(error)
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(.red)
                        }

                        // Verify Button
                        Button(action: {
                            Task {
                                await viewModel.verifyCode()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("確認")
                                        .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isValidCode ? Constants.Colors.primaryBlue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.isValidCode || viewModel.isLoading)
                    }
                    .padding()
                    .background(Constants.Colors.cardDark)
                    .cornerRadius(16)

                    // Resend Code
                    VStack(spacing: 8) {
                        if viewModel.canResend {
                            Button(action: {
                                Task {
                                    await viewModel.resendCode()
                                }
                            }) {
                                Text("認証コードを再送信")
                                    .font(.system(size: Constants.Typography.captionSize))
                                    .foregroundColor(Constants.Colors.primaryBlue)
                            }
                        } else {
                            Text("再送信まで \(viewModel.resendCountdown)秒")
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(Constants.Colors.textGray)
                        }
                    }

                    // Back Button
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("電話番号を変更")
                        }
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                    }

                    Spacer()
                }
                .padding(Constants.Spacing.medium)
            }
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
        }
        .navigationBarBackButtonHidden(true)
        .alert("エラー", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "エラーが発生しました")
        }
        .onAppear {
            viewModel.startResendTimer()
            // 自動でキーボードを表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .onChange(of: viewModel.loginSucceeded) { newValue in
            // 認証成功時にビューをdismissしてContentViewに戻る
            if newValue {
                print("✅ [VerificationCodeView] loginSucceeded changed to true, dismissing view")
                dismiss()
            }
        }
    }
}

// MARK: - Code Digit View
struct CodeDigitView: View {
    let digit: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Constants.Colors.primaryBlue : Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: 45, height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Constants.Colors.cardDark)
                )

            Text(digit)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Constants.Colors.textWhite)
        }
    }
}

// MARK: - VerificationCodeViewModel
@MainActor
class VerificationCodeViewModel: ObservableObject {
    @Published var code = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var codeError: String?
    @Published var focusedIndex = 0
    @Published var canResend = false
    @Published var resendCountdown = 60
    @Published var loginSucceeded = false

    private let authService: AuthService
    private var verificationID: String
    private let phoneNumber: String
    private var resendTimer: Timer?

    var maskedPhoneNumber: String {
        // Mask phone number for display: +8190****5678
        guard phoneNumber.count > 6 else { return phoneNumber }
        let prefix = String(phoneNumber.prefix(5))
        let suffix = String(phoneNumber.suffix(4))
        return "\(prefix)****\(suffix)"
    }

    var isValidCode: Bool {
        code.count == 6 && code.allSatisfy { $0.isNumber }
    }

    init(authService: AuthService, verificationID: String, phoneNumber: String) {
        self.authService = authService
        self.verificationID = verificationID
        self.phoneNumber = phoneNumber
    }

    func digit(at index: Int) -> String {
        guard index < code.count else { return "" }
        let digitIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[digitIndex])
    }

    func handleCodeChange(_ newValue: String) {
        // Only allow 6 digits
        let filtered = newValue.filter { $0.isNumber }
        if filtered.count <= 6 {
            code = filtered
            focusedIndex = min(filtered.count, 5)
        }

        // Auto-submit when 6 digits entered
        if code.count == 6 {
            Task {
                await verifyCode()
            }
        }
    }

    func verifyCode() async {
        guard isValidCode else {
            codeError = "6桁の認証コードを入力してください"
            return
        }

        codeError = nil
        isLoading = true

        do {
            _ = try await authService.verifyCodeAndSignIn(verificationID: verificationID, code: code)
            // 成功時にフラグを設定してViewに通知
            print("✅ [VerificationCodeViewModel] Setting loginSucceeded = true")
            loginSucceeded = true
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            code = ""
            focusedIndex = 0
        } catch {
            showError(message: "認証に失敗しました")
            code = ""
            focusedIndex = 0
        }

        isLoading = false
    }

    func resendCode() async {
        isLoading = true

        do {
            let newVerificationID = try await authService.sendVerificationCode(phoneNumber: phoneNumber)
            verificationID = newVerificationID
            code = ""
            focusedIndex = 0
            startResendTimer()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
        } catch {
            showError(message: "認証コードの再送信に失敗しました")
        }

        isLoading = false
    }

    func startResendTimer() {
        canResend = false
        resendCountdown = 60

        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                if self.resendCountdown > 0 {
                    self.resendCountdown -= 1
                } else {
                    self.canResend = true
                    timer.invalidate()
                }
            }
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    deinit {
        resendTimer?.invalidate()
    }
}

#Preview {
    VerificationCodeView(
        authService: AuthService(),
        verificationID: "test-verification-id",
        phoneNumber: "+819012345678"
    )
}
