//
//  AboutView.swift
//  OSHI Pick
//
//  OSHI Pick - About View
//

import SwiftUI
import StoreKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) var requestReview

    // Sheet states
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showLicenses = false
    @State private var showCompanyInfo = false
    @State private var showEmailCopiedAlert = false

    // App version info
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.large) {
                        // App Icon and Version Section
                        appInfoSection

                        // Menu Section
                        menuSection

                        // Copyright
                        copyrightSection
                    }
                    .padding()
                }
            }
            .navigationTitle("アプリについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                }
            }
            .fullScreenCover(isPresented: $showTerms) {
                TermsOfServiceView()
            }
            .fullScreenCover(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
            .fullScreenCover(isPresented: $showLicenses) {
                LicensesView()
            }
            .fullScreenCover(isPresented: $showCompanyInfo) {
                CompanyInfoView()
            }
            .alert("メールアドレスをコピーしました", isPresented: $showEmailCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("info@switch-media-jp.com\n\nお使いのメールアプリでお問い合わせください。")
            }
        }
    }

    // MARK: - App Info Section
    @ViewBuilder
    private var appInfoSection: some View {
        VStack(spacing: Constants.Spacing.medium) {
            // App Icon
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // App Name
            Text("KPOPVOTE")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Constants.Colors.textWhite)

            // Version
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.system(size: Constants.Typography.captionSize))
                .foregroundColor(Constants.Colors.textGray)
        }
        .padding(.vertical, Constants.Spacing.large)
    }

    // MARK: - Menu Section
    @ViewBuilder
    private var menuSection: some View {
        VStack(spacing: 0) {
            // Terms of Service
            AboutMenuRow(
                icon: "doc.text.fill",
                title: "利用規約",
                color: .blue
            ) {
                showTerms = true
            }

            Divider()
                .padding(.leading, 60)
                .background(Constants.Colors.textGray.opacity(0.3))

            // Privacy Policy
            AboutMenuRow(
                icon: "lock.shield.fill",
                title: "プライバシーポリシー",
                color: .green
            ) {
                showPrivacy = true
            }

            Divider()
                .padding(.leading, 60)
                .background(Constants.Colors.textGray.opacity(0.3))

            // Contact Us
            AboutMenuRow(
                icon: "envelope.fill",
                title: "お問い合わせ",
                color: .orange
            ) {
                sendEmail()
            }

            Divider()
                .padding(.leading, 60)
                .background(Constants.Colors.textGray.opacity(0.3))

            // Rate App
            AboutMenuRow(
                icon: "star.fill",
                title: "アプリを評価",
                color: .yellow
            ) {
                requestReview()
            }

            Divider()
                .padding(.leading, 60)
                .background(Constants.Colors.textGray.opacity(0.3))

            // Company Info
            AboutMenuRow(
                icon: "building.2.fill",
                title: "運営会社について",
                color: .purple
            ) {
                showCompanyInfo = true
            }

            Divider()
                .padding(.leading, 60)
                .background(Constants.Colors.textGray.opacity(0.3))

            // Licenses
            AboutMenuRow(
                icon: "doc.plaintext.fill",
                title: "ライセンス",
                color: Constants.Colors.textGray
            ) {
                showLicenses = true
            }
        }
        .background(Constants.Colors.cardDark)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - Copyright Section
    @ViewBuilder
    private var copyrightSection: some View {
        Text("© 2024 KPOPVOTE Team")
            .font(.system(size: Constants.Typography.captionSize))
            .foregroundColor(Constants.Colors.textGray)
            .padding(.top, Constants.Spacing.large)
    }

    // MARK: - Helper Functions
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    private func sendEmail() {
        let email = "info@switch-media-jp.com"
        let subject = "KPOPVOTE App Feedback"
        let body = "App Version: \(appVersion) (\(buildNumber))\n\n"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Note: Check third-party apps first because mailto: canOpenURL returns true
        // even when Mail app is not installed (iOS shows restore dialog instead)

        // 1. Try Gmail
        if let gmailURL = URL(string: "googlegmail://co?to=\(email)&subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(gmailURL) {
            UIApplication.shared.open(gmailURL)
            return
        }

        // 2. Try Outlook
        if let outlookURL = URL(string: "ms-outlook://compose?to=\(email)&subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(outlookURL) {
            UIApplication.shared.open(outlookURL)
            return
        }

        // 3. Try Yahoo Mail
        if let yahooURL = URL(string: "ymail://mail/compose?to=\(email)&subject=\(encodedSubject)&body=\(encodedBody)"),
           UIApplication.shared.canOpenURL(yahooURL) {
            UIApplication.shared.open(yahooURL)
            return
        }

        // 4. Fallback: Copy email and show alert
        // Note: We skip mailto: because canOpenURL returns true even without Mail app installed,
        // which causes iOS to show the confusing "Restore Mail?" dialog
        UIPasteboard.general.string = email
        showEmailCopiedAlert = true
    }
}

// MARK: - About Menu Row Component
struct AboutMenuRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Constants.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40)

                Text(title)
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textWhite)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.textGray)
            }
            .padding()
            .contentShape(Rectangle())
            .background(Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AboutView()
}
