# Android 版 セットアップガイド

初回開発時にユーザーが手動で実施する必要がある作業をまとめる。**コードの変更では解決できない**手順のみを記載。

## 前提ツール

- **Android Studio**: Ladybug Feature Drop (2024.2) 以降
- **JDK**: 17 以上（Android Gradle Plugin 8.x 要件）
- **Android SDK**: API 35 (Android 15)
- **Gradle**: 8.9+（プロジェクトで自動ダウンロード）
- **Firebase CLI**: 必要に応じて（テスト用）

## 1. Firebase コンソール設定

### 1-1. Android アプリ追加

1. Firebase コンソール（https://console.firebase.google.com/）にログイン
2. プロジェクト `kpopvote-9de2b` を選択
3. 「プロジェクトの設定」→「マイアプリ」→「アプリを追加」→ Android アイコン
4. 以下を入力:
   - **Android パッケージ名**: `com.kpopvote.collector`（iOS と同一）
   - **アプリのニックネーム**: `KPOPVOTE Android`
   - **デバッグ用署名証明書 SHA-1**: 下記コマンドで取得
5. 「アプリを登録」→ `google-services.json` をダウンロード
6. ダウンロードしたファイルを `/Users/makotobaba/KPOPVOTE/android/app/google-services.json` に配置

### 1-2. SHA-1 / SHA-256 取得

**デバッグキー（開発時）:**
```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

出力の `SHA1:` と `SHA-256:` の両方を Firebase に登録。

**リリースキー（Play Store 申請時）:**
```bash
keytool -list -v \
  -keystore <リリース用keystoreのパス> \
  -alias <エイリアス名>
```

リリースキーは Sprint 8 で作成。

### 1-3. Web Client ID 取得（Google Sign-In 用）

1. Firebase コンソール → 認証 → Sign-in method
2. Google プロバイダを有効化（まだの場合）
3. 「ウェブ SDK 構成」セクションの **Web クライアント ID** をコピー
4. `app/src/main/res/values/strings.xml` の `default_web_client_id` に設定（ビルド時に自動差し替えも可）

## 2. Google Cloud Platform 設定

### 2-1. App Check（Play Integrity）有効化

1. GCP コンソール（https://console.cloud.google.com/）でプロジェクト `kpopvote-9de2b` を選択
2. 「API とサービス」→「ライブラリ」→ `Play Integrity API` を検索
3. 「有効にする」をクリック
4. Firebase コンソール → App Check → Android アプリ → Play Integrity を登録

### 2-2. 認証情報（OAuth Client ID）

Firebase Android アプリ追加時に自動で OAuth クライアント ID が生成される。追加設定不要。

## 3. 開発環境セットアップ

### 3-1. リポジトリ準備

```bash
cd /Users/makotobaba/KPOPVOTE/android
```

### 3-2. google-services.json 配置確認

```bash
ls -la app/google-services.json
```

ファイルが存在しないとビルドエラー。

### 3-3. 初回ビルド

Android Studio で `android/` ディレクトリを開く → Gradle 同期 → 実行。

または CLI:
```bash
./gradlew assembleDebug
```

### 3-4. エミュレータ推奨構成

- **デバイス**: Pixel 7 以降
- **API**: 35（Android 15）
- **Google Play サービス**: あり（Play Integrity / Google Sign-In に必須）

## 4. Firebase Emulator（開発時の任意利用）

Cloud Functions を本番で呼ばずローカルで検証する場合:

```bash
cd /Users/makotobaba/KPOPVOTE/functions
npm run serve
```

Android アプリから Emulator に接続するには、`FirebaseModule.kt` の `useEmulator` フラグを `true` に（`buildConfigField` で切替可能）。Sprint 2 で詳細化。

## 5. Play Console 設定（Sprint 8 で実施）

### 5-1. アカウント準備
- Google Play デベロッパーアカウント登録（$25 買い切り）
- 本人確認書類提出
- 税務情報入力

### 5-2. アプリ作成
- アプリ名: KPOPVOTE（または K-Pop Vote）
- カテゴリ: エンタテインメント / SNS
- 料金: 無料（IAP は v2.0 から）

### 5-3. 内部テスト配布
- Sprint 8 で内部テスター向けトラックに初版アップロード

## 6. トラブルシューティング

### ビルドエラー: `Missing google-services.json`
→ Firebase コンソールから再ダウンロードして `app/` に配置

### Google Sign-In: `ApiException: 10`
→ SHA-1 未登録 or 間違った Web Client ID。Firebase コンソールで再確認

### App Check 認証失敗
→ GCP で Play Integrity API が有効化されているか、Firebase コンソールで Android アプリに Play Integrity が登録されているか確認

### Functions 呼び出し: `UNAUTHENTICATED`
→ `FirebaseAuth` でログイン状態を確認。`getIdToken()` が新しいトークンを返しているか

## 7. チーム共有情報

**機密情報（リポジトリに含めない）:**
- `google-services.json`（`.gitignore` 追加推奨）
- リリース用 keystore ファイル
- Firebase Admin SDK サービスアカウント JSON

**共有が必要な情報:**
- Firebase プロジェクト ID: `kpopvote-9de2b`
- Bundle ID: `com.kpopvote.collector`
- Cloud Functions base URL: `https://us-central1-kpopvote-9de2b.cloudfunctions.net`
