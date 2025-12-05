//
//  LicensesView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Licenses View
//

import SwiftUI

struct LicensesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Constants.Spacing.medium) {
                        ForEach(licenses, id: \.name) { license in
                            LicenseCard(license: license)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("ライセンス")
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

    private var licenses: [LicenseInfo] {
        [
            LicenseInfo(
                name: "Firebase",
                version: "11.x",
                license: "Apache License 2.0",
                url: "https://firebase.google.com",
                description: "Firebase iOS SDK - Authentication, Firestore, Storage, Analytics"
            ),
            LicenseInfo(
                name: "SwiftUI",
                version: "Built-in",
                license: "Apple SDK",
                url: "https://developer.apple.com/xcode/swiftui/",
                description: "Apple's declarative UI framework"
            )
        ]
    }
}

// MARK: - License Info Model
struct LicenseInfo {
    let name: String
    let version: String
    let license: String
    let url: String
    let description: String
}

// MARK: - License Card Component
struct LicenseCard: View {
    let license: LicenseInfo
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(license.name)
                            .font(.system(size: Constants.Typography.bodySize, weight: .semibold))
                            .foregroundColor(Constants.Colors.textWhite)

                        Text(license.license)
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.accentPink)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(Constants.Colors.textGray)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Constants.Colors.textGray.opacity(0.3))

                    HStack {
                        Text("バージョン:")
                            .foregroundColor(Constants.Colors.textGray)
                        Text(license.version)
                            .foregroundColor(Constants.Colors.textWhite)
                    }
                    .font(.system(size: Constants.Typography.captionSize))

                    Text(license.description)
                        .font(.system(size: Constants.Typography.captionSize))
                        .foregroundColor(Constants.Colors.textGray)
                        .lineSpacing(4)

                    if let url = URL(string: license.url) {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                Text(license.url)
                            }
                            .font(.system(size: Constants.Typography.captionSize))
                            .foregroundColor(Constants.Colors.accentPink)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

#Preview {
    LicensesView()
}
