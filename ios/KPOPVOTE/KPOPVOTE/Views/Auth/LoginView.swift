//
//  LoginView.swift
//  OSHI Pick
//
//  OSHI Pick - Login View (Phone Authentication)
//

import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var viewModel: PhoneAuthLoginViewModel
    @ObservedObject var authService: AuthService

    // EULA Agreement
    @State private var agreedToTerms = false
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false

    init(authService: AuthService) {
        self.authService = authService
        _viewModel = StateObject(wrappedValue: PhoneAuthLoginViewModel(authService: authService))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background (ダークモード)
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.large) {
                        // Logo/Title
                        VStack(spacing: Constants.Spacing.small) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 60))
                                .foregroundColor(Constants.Colors.primaryBlue)

                            Text("OSHI Pick")
                                .font(.system(size: Constants.Typography.titleSize, weight: .bold))
                                .foregroundColor(Constants.Colors.textWhite)

                            Text("電話番号で認証")
                                .font(.system(size: Constants.Typography.captionSize))
                                .foregroundColor(Constants.Colors.textGray)
                        }
                        .padding(.top, 60)

                        // Phone Number Input Form
                        VStack(spacing: Constants.Spacing.medium) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("電話番号")
                                    .font(.system(size: Constants.Typography.captionSize, weight: .semibold))
                                    .foregroundColor(Constants.Colors.textGray)

                                HStack(spacing: 8) {
                                    // Country Code Picker
                                    Menu {
                                        ForEach(viewModel.countryCodes, id: \.code) { country in
                                            Button(action: {
                                                viewModel.selectedCountryCode = country.code
                                            }) {
                                                Text("\(country.flag) \(country.name) (\(country.code))")
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(viewModel.selectedCountryFlag)
                                                .font(.system(size: 20))
                                            Text(viewModel.selectedCountryCode)
                                                .font(.system(size: Constants.Typography.bodySize))
                                                .foregroundColor(Constants.Colors.textWhite)
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(Constants.Colors.textGray)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 14)
                                        .background(Constants.Colors.cardDark)
                                        .cornerRadius(10)
                                    }

                                    // Phone Number TextField
                                    TextField("09012345678", text: $viewModel.phoneNumber)
                                        .keyboardType(.phonePad)
                                        .unifiedInputStyle()
                                }

                                if let error = viewModel.phoneNumberError {
                                    Text(error)
                                        .font(.system(size: Constants.Typography.captionSize))
                                        .foregroundColor(.red)
                                }
                            }

                            // Send Code Button
                            Button(action: {
                                Task {
                                    await viewModel.sendVerificationCode()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "message.fill")
                                        Text("認証コードを送信")
                                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isValidPhoneNumber && agreedToTerms ? Constants.Colors.primaryBlue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(!viewModel.isValidPhoneNumber || viewModel.isLoading || !agreedToTerms)
                        }
                        .padding()
                        .background(Constants.Colors.cardDark)
                        .cornerRadius(16)

                        // Terms Agreement Checkbox
                        VStack(spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                Button(action: {
                                    agreedToTerms.toggle()
                                }) {
                                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 22))
                                        .foregroundColor(agreedToTerms ? Constants.Colors.primaryBlue : Constants.Colors.textGray)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 0) {
                                        Button(action: { showTermsOfService = true }) {
                                            Text("利用規約")
                                                .font(.system(size: 14))
                                                .foregroundColor(Constants.Colors.primaryBlue)
                                                .underline()
                                        }
                                        Text(" と ")
                                            .font(.system(size: 14))
                                            .foregroundColor(Constants.Colors.textGray)
                                        Button(action: { showPrivacyPolicy = true }) {
                                            Text("プライバシーポリシー")
                                                .font(.system(size: 14))
                                                .foregroundColor(Constants.Colors.primaryBlue)
                                                .underline()
                                        }
                                    }
                                    Text("に同意します")
                                        .font(.system(size: 14))
                                        .foregroundColor(Constants.Colors.textGray)
                                }
                            }

                            if !agreedToTerms {
                                Text("利用規約とプライバシーポリシーへの同意が必要です")
                                    .font(.system(size: 11))
                                    .foregroundColor(Constants.Colors.textGray)
                            }
                        }

                        // Guest Mode Button
                        Button(action: {
                            authService.loginAsGuest()
                        }) {
                            Text("ゲストとして利用")
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
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "エラーが発生しました")
            }
            .navigationDestination(isPresented: $viewModel.showVerificationView) {
                VerificationCodeView(
                    authService: authService,
                    verificationID: viewModel.verificationID ?? "",
                    phoneNumber: viewModel.fullPhoneNumber
                )
                .environmentObject(authService)
            }
            .onChange(of: authService.isAuthenticated) { newValue in
                if newValue {
                    // 認証成功時にNavigationをリセットしてContentViewにMainTabViewを表示させる
                    print("✅ [LoginView] isAuthenticated changed to true, resetting navigation")
                    viewModel.showVerificationView = false
                }
            }
            .fullScreenCover(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .fullScreenCover(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }
}

// MARK: - PhoneAuthLoginViewModel
@MainActor
class PhoneAuthLoginViewModel: ObservableObject {
    @Published var phoneNumber = ""
    @Published var selectedCountryCode = "+81"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var phoneNumberError: String?
    @Published var showVerificationView = false
    @Published var verificationID: String?

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    struct CountryCode {
        let code: String
        let name: String
        let flag: String
    }

    let countryCodes: [CountryCode] = [
        CountryCode(code: "+81", name: "日本", flag: "🇯🇵"),
        CountryCode(code: "+82", name: "韓国", flag: "🇰🇷"),
        CountryCode(code: "+1", name: "アメリカ", flag: "🇺🇸"),
        CountryCode(code: "+86", name: "中国", flag: "🇨🇳"),
        CountryCode(code: "+886", name: "台湾", flag: "🇹🇼"),
        CountryCode(code: "+852", name: "香港", flag: "🇭🇰"),
        CountryCode(code: "+65", name: "シンガポール", flag: "🇸🇬"),
        CountryCode(code: "+60", name: "マレーシア", flag: "🇲🇾"),
        CountryCode(code: "+66", name: "タイ", flag: "🇹🇭"),
        CountryCode(code: "+63", name: "フィリピン", flag: "🇵🇭"),
        CountryCode(code: "+62", name: "インドネシア", flag: "🇮🇩"),
        CountryCode(code: "+84", name: "ベトナム", flag: "🇻🇳"),
    ]

    var selectedCountryFlag: String {
        countryCodes.first { $0.code == selectedCountryCode }?.flag ?? "🌏"
    }

    var fullPhoneNumber: String {
        // Remove leading zeros and format
        let cleanedNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
        return "\(selectedCountryCode)\(cleanedNumber)"
    }

    var isValidPhoneNumber: Bool {
        let cleanedNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        // Japanese phone numbers: 10-11 digits (with or without leading 0)
        if selectedCountryCode == "+81" {
            return cleanedNumber.count >= 10 && cleanedNumber.count <= 11 && cleanedNumber.allSatisfy { $0.isNumber }
        }

        // Other countries: minimum 6 digits
        return cleanedNumber.count >= 6 && cleanedNumber.allSatisfy { $0.isNumber }
    }

    init(authService: AuthService) {
        self.authService = authService

        // authService.isAuthenticatedを監視して認証成功時にNavigationをリセット
        // ViewModelはNavigationStackの状態に関係なく常にアクティブなので確実に検知できる
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    print("✅ [PhoneAuthLoginViewModel] isAuthenticated changed to true, resetting navigation")
                    self?.showVerificationView = false
                }
            }
            .store(in: &cancellables)
    }

    func sendVerificationCode() async {
        guard isValidPhoneNumber else {
            phoneNumberError = "有効な電話番号を入力してください"
            return
        }

        phoneNumberError = nil
        isLoading = true

        do {
            let verificationID = try await authService.sendVerificationCode(phoneNumber: fullPhoneNumber)
            self.verificationID = verificationID
            showVerificationView = true
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
        } catch {
            showError(message: "認証コードの送信に失敗しました")
        }

        isLoading = false
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}

#Preview {
    LoginView(authService: AuthService())
}
