//
//  CompanyInfoView.swift
//  KPOPVOTE
//
//  KPOPVOTE - Company Information View
//

import SwiftUI

struct CompanyInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                        // Company Logo/Icon Section
                        HStack {
                            Spacer()
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Constants.Colors.accentPink, Constants.Colors.gradientPink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Spacer()
                        }
                        .padding(.vertical, Constants.Spacing.medium)

                        // Company Information Cards
                        VStack(spacing: Constants.Spacing.medium) {
                            CompanyInfoRow(
                                icon: "building.fill",
                                title: "会社名",
                                value: "合同会社スイッチメディア"
                            )

                            CompanyInfoRow(
                                icon: "globe",
                                title: "会社HP",
                                value: "https://switch-media-jp.com/",
                                isLink: true
                            )

                            CompanyInfoRow(
                                icon: "calendar",
                                title: "設立",
                                value: "2025年6月13日"
                            )

                            CompanyInfoRow(
                                icon: "person.fill",
                                title: "代表",
                                value: "馬場 誠"
                            )

                            CompanyInfoRow(
                                icon: "mappin.and.ellipse",
                                title: "所在地",
                                value: "東京都渋谷区道玄坂1丁目10番8号\n渋谷道玄坂東急ビル2F-C"
                            )

                            // Business Description Section
                            VStack(alignment: .leading, spacing: Constants.Spacing.small) {
                                HStack(spacing: Constants.Spacing.small) {
                                    Image(systemName: "briefcase.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Constants.Colors.accentPink)
                                        .frame(width: 24)

                                    Text("事業内容")
                                        .font(.system(size: Constants.Typography.captionSize))
                                        .foregroundColor(Constants.Colors.textGray)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    BusinessItem(text: "新規事業開発／アライアンス支援")
                                    BusinessItem(text: "Webプロダクト企画／開発")
                                    BusinessItem(text: "Web3事業企画／開発")
                                    BusinessItem(text: "ファンマーケティング事業")
                                    BusinessItem(text: "Webマーケティング支援")
                                }
                                .padding(.leading, 32)
                            }
                            .padding()
                            .background(Constants.Colors.cardDark)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("運営会社について")
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
}

// MARK: - Company Info Row Component
struct CompanyInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var isLink: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.small) {
            HStack(spacing: Constants.Spacing.small) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Constants.Colors.accentPink)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: Constants.Typography.captionSize))
                    .foregroundColor(Constants.Colors.textGray)
            }

            if isLink {
                Button {
                    if let url = URL(string: value) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(value)
                        .font(.system(size: Constants.Typography.bodySize))
                        .foregroundColor(.blue)
                        .underline()
                        .padding(.leading, 32)
                }
            } else {
                Text(value)
                    .font(.system(size: Constants.Typography.bodySize))
                    .foregroundColor(Constants.Colors.textWhite)
                    .padding(.leading, 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Constants.Colors.cardDark)
        .cornerRadius(12)
    }
}

// MARK: - Business Item Component
struct BusinessItem: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(Constants.Colors.accentPink)
            Text(text)
                .font(.system(size: Constants.Typography.bodySize))
                .foregroundColor(Constants.Colors.textWhite)
        }
    }
}

#Preview {
    CompanyInfoView()
}
