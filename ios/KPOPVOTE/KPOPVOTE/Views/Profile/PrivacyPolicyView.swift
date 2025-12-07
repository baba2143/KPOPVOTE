//
//  PrivacyPolicyView.swift
//  OSHI Pick
//
//  OSHI Pick - Privacy Policy View
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                        Text(privacyText)
                            .font(.system(size: Constants.Typography.bodySize))
                            .foregroundColor(Constants.Colors.textWhite)
                            .lineSpacing(6)
                    }
                    .padding()
                }
            }
            .navigationTitle("プライバシーポリシー")
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

    private var privacyText: String {
        """
        KPOPVOTEプライバシーポリシー

        最終更新日: 2024年12月

        KPOPVOTE（以下「本アプリ」）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めます。本プライバシーポリシーは、本アプリにおける個人情報の取り扱いについて説明するものです。

        1. 収集する情報
        本アプリでは、以下の情報を収集することがあります。

        (1) アカウント情報
        - メールアドレス
        - ユーザー名
        - プロフィール画像

        (2) 利用情報
        - 投票履歴
        - お気に入り登録情報
        - コレクション情報

        (3) 端末情報
        - デバイスの種類
        - OSバージョン
        - アプリバージョン

        2. 情報の利用目的
        収集した情報は、以下の目的で利用します。
        - 本アプリのサービス提供および改善
        - ユーザーサポートの提供
        - 新機能やアップデートのお知らせ
        - 不正利用の防止

        3. 情報の第三者提供
        当社は、以下の場合を除き、ユーザーの個人情報を第三者に提供しません。
        - ユーザーの同意がある場合
        - 法令に基づく場合
        - 人の生命、身体または財産の保護のために必要がある場合

        4. 情報の安全管理
        当社は、収集した個人情報の漏洩、滅失、毀損の防止その他の安全管理のために必要かつ適切な措置を講じます。

        5. 外部サービスの利用
        本アプリでは、以下の外部サービスを利用しています。
        - Firebase Authentication（認証）
        - Firebase Firestore（データベース）
        - Firebase Storage（ファイル保存）
        - Firebase Analytics（利用状況分析）

        これらのサービスは、それぞれのプライバシーポリシーに従って情報を取り扱います。

        6. お問い合わせ
        本ポリシーに関するお問い合わせは、以下の連絡先までお願いいたします。
        メール: info@switch-media-jp.com

        7. プライバシーポリシーの変更
        当社は、必要に応じて本ポリシーを変更することがあります。重要な変更がある場合は、本アプリ内でお知らせします。

        以上
        """
    }
}

#Preview {
    PrivacyPolicyView()
}
