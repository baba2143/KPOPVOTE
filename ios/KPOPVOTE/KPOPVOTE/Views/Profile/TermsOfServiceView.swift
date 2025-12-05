//
//  TermsOfServiceView.swift
//  KPOPVOTE
//
//  K-VOTE COLLECTOR - Terms of Service View
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Constants.Spacing.medium) {
                        Text(termsText)
                            .font(.system(size: Constants.Typography.bodySize))
                            .foregroundColor(Constants.Colors.textWhite)
                            .lineSpacing(6)
                    }
                    .padding()
                }
            }
            .navigationTitle("利用規約")
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

    private var termsText: String {
        """
        KPOPVOTE利用規約

        最終更新日: 2024年12月

        第1条（適用）
        本規約は、KPOPVOTE（以下「本アプリ」）の利用に関する条件を定めるものです。ユーザーは本規約に同意の上、本アプリをご利用ください。

        第2条（利用登録）
        1. 本アプリの利用を希望する方は、本規約に同意の上、所定の方法により利用登録を行うものとします。
        2. 当社は、利用登録の申請者に以下の事由があると判断した場合、利用登録の申請を承認しないことがあります。
           - 虚偽の事項を届け出た場合
           - 本規約に違反したことがある者からの申請である場合
           - その他、当社が利用登録を相当でないと判断した場合

        第3条（禁止事項）
        ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。
        1. 法令または公序良俗に違反する行為
        2. 犯罪行為に関連する行為
        3. 当社のサーバーまたはネットワークの機能を破壊したり、妨害したりする行為
        4. 当社のサービスの運営を妨害するおそれのある行為
        5. 他のユーザーに関する個人情報等を収集または蓄積する行為
        6. 他のユーザーに成りすます行為
        7. 当社のサービスに関連して、反社会的勢力に対して直接または間接に利益を供与する行為
        8. その他、当社が不適切と判断する行為

        第4条（本アプリの提供の停止等）
        当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本アプリの全部または一部の提供を停止または中断することができるものとします。
        1. 本アプリにかかるコンピュータシステムの保守点検または更新を行う場合
        2. 地震、落雷、火災、停電または天災などの不可抗力により、本アプリの提供が困難となった場合
        3. コンピュータまたは通信回線等が事故により停止した場合
        4. その他、当社が本アプリの提供が困難と判断した場合

        第5条（著作権）
        1. ユーザーは、自ら著作権等の必要な知的財産権を有するか、または必要な権利者の許諾を得た文章、画像等のみ、本アプリを利用して投稿することができるものとします。
        2. 本アプリ上のコンテンツの著作権は、当社または正当な権利を有する第三者に帰属します。

        第6条（免責事項）
        1. 当社は、本アプリに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含みます。）がないことを明示的にも黙示的にも保証しておりません。
        2. 当社は、本アプリに起因してユーザーに生じたあらゆる損害について一切の責任を負いません。

        第7条（サービス内容の変更等）
        当社は、ユーザーに通知することなく、本アプリの内容を変更しまたは本アプリの提供を中止することができるものとし、これによってユーザーに生じた損害について一切の責任を負いません。

        第8条（利用規約の変更）
        当社は、必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。

        第9条（準拠法・裁判管轄）
        本規約の解釈にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、当社の本店所在地を管轄する裁判所を専属的合意管轄とします。

        以上
        """
    }
}

#Preview {
    TermsOfServiceView()
}
