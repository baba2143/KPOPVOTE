# App Store Connect 設定手順書

## サブスクリプション機能の有効化手順

このガイドでは、KPOPVOTEアプリのAuto-Renewable Subscription（月額プレミアム会員）をApp Store Connectで設定する手順を説明します。

---

## 前提条件

### 必須要件
- ✅ **Apple Developer Program加入済み**（年間$99または11,800円）
- ✅ **App Store Connectアカウント**
- ✅ **KPOPVOTEアプリがApp Store Connectに登録済み**

### 確認すべき情報
- **Bundle ID**: `com.yourcompany.KPOPVOTE`（実際のBundle IDを確認してください）
- **App名**: KPOPVOTE

---

## Step 1: App Store Connectにログイン

1. ブラウザで https://appstoreconnect.apple.com を開く
2. Apple IDでサインイン
3. 「マイApp」を選択
4. 「KPOPVOTE」アプリを選択

---

## Step 2: サブスクリプショングループの作成

### 2-1. App内課金セクションに移動

1. 左側メニューから「App内課金」をクリック
2. 「自動更新サブスクリプション」タブを選択
3. 「+」ボタンをクリック

### 2-2. サブスクリプショングループの作成

**サブスクリプショングループとは？**
- 同じカテゴリのサブスクリプション商品をグループ化するもの
- ユーザーは1つのグループ内で1つのサブスクリプションのみ購入可能

**設定内容：**
- **グループ参照名**: `Premium Membership`
- **グループ表示名**（日本語）: `プレミアム会員`

「作成」をクリック

---

## Step 3: 月額プランの登録

### 3-1. 基本情報

1. 作成したグループ内で「+」ボタン→「サブスクリプションを作成」
2. **参照名**: `Premium Monthly Subscription`
3. **商品ID**: `com.kpopvote.premium.monthly`
   ⚠️ **重要**: このIDは後から変更できません。コピー&ペースト推奨

### 3-2. サブスクリプション期間

- **期間**: `1ヶ月`

### 3-3. サブスクリプションの価格

1. 「サブスクリプションの価格」セクション
2. 「+」ボタンをクリック
3. **国または地域**: `日本`
4. **価格**: `¥550`
5. 「次へ」→「保存」

### 3-4. App Store情報（ローカリゼーション）

**日本語（ja）の情報を追加：**
1. 「+」ボタン→「日本語」を選択
2. **表示名**: `プレミアム会員（月額）`
3. **説明**:
```
毎月600ポイント自動付与！
初月は特別に1,200ポイントプレゼント🎁

【会員特典】
✨ 毎月600P自動付与
🎁 初月ボーナス1,200P
⭐ 限定機能（今後追加予定）

自動更新されます。いつでもキャンセル可能。
```

**英語（en）の情報も追加（任意だが推奨）：**
1. 「+」ボタン→「English (U.S.)」を選択
2. **表示名**: `Premium Monthly Membership`
3. **説明**: `Monthly auto-renewal. 600 points per month + 1,200 bonus for first month. Exclusive features coming soon.`

### 3-5. 審査情報

- **スクリーンショット**: アプリ内のサブスクリプション購入画面のスクリーンショット（任意だが審査で要求される場合あり）

「保存」をクリック

---

## Step 5: Sandboxテストアカウントの作成

### 5-1. Sandboxテスターページに移動

1. App Store Connectのトップページに戻る
2. 「ユーザーとアクセス」をクリック
3. 左側メニューから「Sandboxテスター」を選択

### 5-2. テストアカウントの作成

1. 「+」ボタンをクリック
2. 以下の情報を入力：

**必須情報：**
- **名**: `Test`
- **姓**: `User`
- **メールアドレス**: `test@example.com`（架空のメールアドレスでOK）
  💡 実際に存在する必要はありません
- **パスワード**: 安全なパスワード（8文字以上、大文字・小文字・数字含む）
- **確認**: パスワードを再入力
- **秘密の質問**: 任意の質問と回答を3つ選択
- **生年月日**: 18歳以上の日付
- **国または地域**: `日本`

3. 「保存」をクリック

### 5-3. 複数アカウントの作成（推奨）

異なるシナリオをテストするため、複数のSandboxアカウントを作成することを推奨：
- `test1@example.com` - 月額プランテスト用
- `test2@example.com` - 復元機能テスト用
- `test3@example.com` - 再購入テスト用

---

## Step 6: アプリの準備状況確認

### 6-1. サブスクリプション商品の状態確認

1. 「App内課金」→「自動更新サブスクリプション」に戻る
2. 月額プランが以下の状態であることを確認：
   - ✅ **月額プラン**: `com.kpopvote.premium.monthly`

### 6-2. 商品の公開状態

**注意：**
- サブスクリプション商品は、アプリが初めてApp Store Reviewに提出されるまで「準備完了」状態になりません
- しかし、Sandbox環境でのテストは即座に可能です

---

## Step 7: Xcodeでの設定（既に完了済み）

以下の設定は既に自動で完了しています：

✅ **Entitlementsファイル**
- `com.apple.developer.in-app-payments`が追加済み

✅ **StoreKit Configuration File**
- `/ios/KPOPVOTE/Configuration.storekit`が作成済み
- ローカルテスト用の商品情報を含む

---

## Step 8: ローカルテスト（App Store Connect不要）

### 8-1. StoreKit Configuration Fileを使用したテスト

1. **Xcodeを開く**
2. **KPOPVOTE.xcodeprojを開く**
3. メニューバーから **Product** → **Scheme** → **Edit Scheme...**
4. 左側で「Run」を選択
5. 「Options」タブを選択
6. **StoreKit Configuration**で`Configuration.storekit`を選択
7. 「Close」をクリック

### 8-2. テスト実行

1. シミュレーターまたは実機でアプリを実行
2. プロフィール画面→「プレミアム会員」をタップ
3. 月額プランの「プレミアム会員になる」をタップ
4. **ローカルテストの場合**:
   - システムダイアログでサブスクリプション確認
   - Touch ID/Face IDは不要
   - 実際の課金は発生しません
5. 購入完了を確認

### 8-3. トランザクションマネージャーでの確認

Xcodeメニュー → **Debug** → **StoreKit** → **Manage Transactions...**
- 購入したサブスクリプションが表示されます
- サブスクリプションの期限、更新状態を確認できます

---

## Step 9: Sandboxテスト（App Store Connect連携）

### 9-1. デバイス/シミュレーターの設定

**実機の場合：**
1. 設定アプリを開く
2. 「App Store」をタップ
3. 「Sandboxアカウント」をタップ
4. Step 5で作成したテストアカウントでサインイン
   - メールアドレス: `test@example.com`
   - パスワード: 設定したパスワード

**シミュレーターの場合：**
- サブスクリプション購入時にSandboxアカウント入力画面が表示されます

### 9-2. Xcodeスキームの変更

1. **Product** → **Scheme** → **Edit Scheme...**
2. **StoreKit Configuration**を`None`に変更
   （App Store Connectの商品を使用するため）
3. 「Close」をクリック

### 9-3. テスト実行

1. アプリを実行（Clean Buildを推奨）
2. プレミアム会員画面でサブスクリプション購入
3. Sandboxアカウントでサインイン
4. 購入完了を確認
5. Firebase Consoleで以下を確認：
   - `users/{userId}/isPremium`: `true`
   - `subscriptions/`コレクションに新規ドキュメント

---

## Step 10: トラブルシューティング

### 問題1: 「商品が見つかりません」エラー

**原因：**
- App Store Connectで商品IDが登録されていない
- Bundle IDが一致していない
- ネットワーク接続の問題

**解決方法：**
1. App Store Connectで商品ID確認：
   - `com.kpopvote.premium.monthly`
2. Xcodeの Bundle IDを確認
3. インターネット接続を確認
4. アプリを再ビルド

### 問題2: 購入ダイアログが表示されない

**原因：**
- Entitlementsが設定されていない
- StoreKit Configurationの競合

**解決方法：**
1. Entitlementsファイルを確認
2. Product → Clean Build Folder
3. アプリを再ビルド

### 問題3: バックエンド検証が失敗する

**原因：**
- Firebase Functionsがデプロイされていない
- 認証トークンの問題
- ネットワークエラー

**解決方法：**
1. Firebase Console → Functions → verifySubscription存在確認
2. ログイン状態を確認
3. ネットワーク接続を確認
4. Firebase Functions ログを確認

---

## Sandboxテストの注意点

### 時間加速機能

Sandbox環境では、サブスクリプション期間が大幅に短縮されます：

| 実際の期間 | Sandbox期間 |
|------------|-------------|
| 1週間      | 3分         |
| 1ヶ月      | 5分         |
| 2ヶ月      | 10分        |
| 3ヶ月      | 15分        |
| 6ヶ月      | 30分        |
| 1年        | 1時間       |

### 自動更新回数

- Sandboxでは最大6回まで自動更新されます
- 6回目以降は自動的にキャンセルされます

### 領収書の違い

- Sandbox環境の領収書は本番環境と異なります
- テスト用の検証エンドポイントを使用

---

## 次のステップ

### ローカルテストが成功したら：

1. ✅ **Sandboxテストの実行**
   - 実際のApp Store環境をシミュレート
   - バックエンド連携の確認

2. ✅ **本番環境への準備**
   - アプリの初回審査提出
   - サブスクリプション商品の審査

3. ✅ **App Store Server Notifications設定**
   - サブスクリプション更新/キャンセルの自動処理
   - Webhook設定

---

## サポート

### 参考リンク

- **Apple公式ドキュメント**: https://developer.apple.com/documentation/storekit
- **App Store Connect Help**: https://help.apple.com/app-store-connect/
- **Firebase Functions**: https://firebase.google.com/docs/functions

### 問題が解決しない場合

1. Xcodeコンソールログを確認
2. Firebase Functionsログを確認
3. App Store Connectステータスを確認

---

## チェックリスト

### App Store Connect設定

- [ ] サブスクリプショングループ作成済み
- [ ] 月額プラン（¥550）登録済み
- [ ] 日本語ローカリゼーション設定済み
- [ ] Sandboxテストアカウント作成済み

### ローカルテスト

- [ ] StoreKit Configuration設定済み
- [ ] 月額プラン購入テスト完了
- [ ] プレミアムバッジ表示確認
- [ ] ポイント付与確認（初月1,200P、更新600P）

### Sandboxテスト

- [ ] Sandboxアカウント設定完了
- [ ] 実際の購入フローテスト完了
- [ ] バックエンド検証成功確認
- [ ] Firestoreデータ更新確認
- [ ] サブスクリプション復元テスト完了

---

**このガイドに従って設定を完了すれば、KPOPVOTEのサブスクリプション機能が使用可能になります！**
