//
//  AboutView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - About View
//

import SwiftUI
import StoreKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) var requestReview

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
            .navigationTitle("About")
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
                title: "Terms of Service",
                color: .blue
            ) {
                openURL("https://kpopvote.app/terms")
            }

            Divider()
                .padding(.leading, 60)
                .background(Constants.Colors.textGray.opacity(0.3))

            // Privacy Policy
            AboutMenuRow(
                icon: "lock.shield.fill",
                title: "Privacy Policy",
                color: .green
            ) {
                openURL("https://kpopvote.app/privacy")
            }

            Divider()
                .padding(.leading, 60)
                .background(Constants.Colors.textGray.opacity(0.3))

            // Contact Us
            AboutMenuRow(
                icon: "envelope.fill",
                title: "Contact Us",
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
                title: "Rate App",
                color: .yellow
            ) {
                requestReview()
            }

            Divider()
                .padding(.leading, 60)
                .background(Constants.Colors.textGray.opacity(0.3))

            // Licenses
            AboutMenuRow(
                icon: "doc.plaintext.fill",
                title: "Licenses",
                color: Constants.Colors.textGray
            ) {
                // Show licenses (placeholder)
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
        let email = "support@kpopvote.app"
        let subject = "KPOPVOTE App Feedback"
        let body = "App Version: \(appVersion) (\(buildNumber))\n\n"

        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
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
            .background(Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AboutView()
}
