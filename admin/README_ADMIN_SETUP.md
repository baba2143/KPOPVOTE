# 管理者アカウント作成手順

## Week 1 Day 3 完了状況

✅ **完了した作業:**
- React環境構築（CRA + TypeScript + MUI v7 + Firebase SDK）
- 認証システム実装（AuthContext + Custom Claims確認）
- 管理画面レイアウト実装（AppBar + Drawer + ルーティング）
- MUI v7 Grid API対応
- ビルド成功
- Firebase Hostingへデプロイ完了

🌐 **管理画面URL:** https://kpopvote-admin.web.app

## 📋 次のステップ: 管理者ユーザー作成

✅ **ユーザー作成済み:**
- Email: `baba_m@switch-media-jp.com`
- UID: `nn8L3RmgATPEqgfua6WdOMJwxdc2`

⚠️ **Custom Claims設定が必要:**
Firebase ConsoleのUIではCustom Claimsを編集できないため、以下の方法を使用してください。

---

## 🚀 Custom Claims設定方法

### 方法1: Google Cloud Shell（最も推奨・確実）

**詳細手順:** [`CLOUD_SHELL_SETUP.md`](./CLOUD_SHELL_SETUP.md) を参照

**概要:**
1. Google Cloud Consoleを開く
2. Cloud Shellを起動（ブラウザ内ターミナル）
3. Firebase Admin SDKをインストール
4. スクリプトを実行してCustom Claimsを設定

**メリット:**
- ✅ ブラウザ内で完結
- ✅ サービスアカウントキー不要
- ✅ すでに認証済み
- ✅ 組織ポリシーの制約を受けない

---

### 方法2: Firebase Console（通常の場合）

1. **Firebase Console** にアクセス
   ```
   https://console.firebase.google.com/project/kpopvote-9de2b/authentication/users
   ```

2. **ユーザーを追加** をクリック

3. **ユーザー情報を入力:**
   - メールアドレス: `admin@kpopvote.com`（または任意のメールアドレス）
   - パスワード: 強力なパスワードを設定

4. **作成** をクリック

5. **Custom Claimsを設定:**
   - 作成したユーザーをクリック
   - **Custom Claims** セクションまでスクロール
   - 以下のJSONを入力:
     ```json
     {"admin": true}
     ```
   - **保存** をクリック

### 方法2: Firebase CLI + スクリプト

```bash
cd /Users/makotobaba/Desktop/KPOPVOTE/functions

# 管理者作成スクリプトを実行（要認証設定）
GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json" \
node scripts/createAdmin.js
```

**注意:** サービスアカウントキーが必要です。Firebase Console から取得してください:
```
https://console.firebase.google.com/project/kpopvote-9de2b/settings/serviceaccounts/adminsdk
```

### 方法3: Cloud Functions API経由

```bash
# 1. ユーザー登録（register関数を使用）
curl -X POST https://us-central1-kpopvote-9de2b.cloudfunctions.net/register \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "email": "admin@kpopvote.com",
      "password": "YourSecurePassword123!",
      "displayName": "管理者"
    }
  }'

# 2. UIDを確認
firebase auth:export /tmp/users.json --project kpopvote-9de2b

# 3. Custom Claimを設定（setAdmin関数を使用 - 要管理者認証）
```

## 🧪 テスト手順

管理者アカウント作成後:

1. **ログインテスト:**
   ```
   https://kpopvote-admin.web.app/login
   ```
   - 作成したメールアドレスとパスワードでログイン
   - ログイン成功後、ダッシュボードにリダイレクトされることを確認

2. **保護ルートのテスト:**
   - ログアウトして `/` にアクセス → `/login` にリダイレクトされることを確認
   - ログインして各ページ（`/votes`, `/idols`, `/apps`, `/community`, `/users`）にアクセス可能か確認

3. **管理者権限のテスト:**
   - Custom Claimsが正しく設定されているか確認
   - 管理者専用機能が使用可能か確認

## 📝 次のフェーズ

Week 1 Day 4-5: ダッシュボード実装
- 統計データの取得と表示
- Chart.js/Recharts でグラフ実装
- リアルタイムデータ更新

## 🔧 トラブルシューティング

### ログインできない
- Custom Claimsが設定されているか確認
- Firebase Console で `{"admin": true}` が正しく保存されているか確認
- ブラウザのキャッシュをクリアして再試行

### 「アクセス拒否」と表示される
- Custom Claimsの`admin`プロパティが`true`に設定されているか確認
- ログアウト→ログインで token をリフレッシュ

### 開発用ローカル実行
```bash
cd /Users/makotobaba/Desktop/KPOPVOTE/admin
npm start
# http://localhost:3000 でアクセス
```

## 📊 デプロイ状況

- ✅ Cloud Functions: 34エンドポイント稼働中
- ✅ Firebase Hosting (admin): https://kpopvote-admin.web.app
- ⏳ Firebase Hosting (app): 未デプロイ（ユーザー向けアプリは後のフェーズ）

## 🎯 Phase 0+ 進捗

- ✅ Week 1 Day 1-2: バックエンドAPI実装・デプロイ
- ✅ Week 1 Day 3: React環境構築（本ドキュメントの内容）
- ⏳ Week 1 Day 4-5: ダッシュボード実装
- ⏳ Week 2 Day 6-8: 独自投票管理
- ⏳ Week 2 Day 9-10: マスターデータ管理
- ⏳ Week 3 Day 11-12: コミュニティ監視
- ⏳ Week 3 Day 13-14: ユーザー管理
- ⏳ Week 3 Day 15: システムログ・最終デプロイ
