# Sprint 1 仕様書 — 基盤 + Firebase + Auth

## 期間・工数
- **推定**: 60〜80時間（約2〜3週間、1名フルタイム）
- **複雑度**: Medium
- **ブロッカー**: Firebase Android アプリ登録（ユーザー手動実施）

## 目的

Android プロジェクトの基盤を構築し、iOS 版と同一の Firebase バックエンドで**認証フロー**が動作する状態にする。

## スコープ

### 含むもの
- Android Studio プロジェクト雛形（Gradle KTS）
- Firebase SDK 統合（Auth / Functions / Analytics / Crashlytics / App Check / Performance）
- Hilt DI セットアップ
- Material 3 テーマ（iOS パレット反映）
- ログイン / 新規登録画面（Compose）
- Email / Password 認証
- Google Sign-In（**Credential Manager API**、旧 GoogleSignInClient は使用しない）
- ナビゲーション雛形（Auth Graph / Main Graph の切替）
- 認証状態の `StateFlow` 保持と自動ログイン

### 含まないもの
- Firestore / Functions の業務 API 呼び出し（Sprint 2）
- Home / Tasks / Votes などの機能画面（Sprint 3+）
- FCM 通知受信（Sprint 7）
- IAP（v2.0 送り）

## 成果物

### ファイル一覧

```
android/
├── settings.gradle.kts
├── build.gradle.kts
├── gradle.properties
├── gradle/
│   └── libs.versions.toml
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/com/kpopvote/collector/
│       │   ├── KpopvoteApplication.kt
│       │   ├── MainActivity.kt
│       │   ├── di/
│       │   │   ├── AppModule.kt
│       │   │   ├── FirebaseModule.kt
│       │   │   └── RepositoryModule.kt
│       │   ├── core/
│       │   │   ├── auth/
│       │   │   │   ├── AuthState.kt
│       │   │   │   └── AuthStateHolder.kt
│       │   │   ├── common/
│       │   │   │   └── AppError.kt
│       │   │   └── analytics/
│       │   │       └── CrashlyticsTree.kt
│       │   ├── data/
│       │   │   └── repository/
│       │   │       ├── AuthRepository.kt
│       │   │       └── AuthRepositoryImpl.kt
│       │   ├── ui/
│       │   │   ├── theme/
│       │   │   │   ├── Color.kt
│       │   │   │   ├── Theme.kt
│       │   │   │   ├── Type.kt
│       │   │   │   └── Shape.kt
│       │   │   ├── components/
│       │   │   │   ├── KpopvoteButton.kt
│       │   │   │   └── KpopvoteTextField.kt
│       │   │   └── auth/
│       │   │       ├── login/
│       │   │       │   ├── LoginScreen.kt
│       │   │       │   ├── LoginViewModel.kt
│       │   │       │   └── LoginUiState.kt
│       │   │       └── register/
│       │   │           ├── RegisterScreen.kt
│       │   │           ├── RegisterViewModel.kt
│       │   │           └── RegisterUiState.kt
│       │   └── navigation/
│       │       ├── Routes.kt
│       │       └── NavGraph.kt
│       └── res/
│           ├── values/
│           │   ├── strings.xml
│           │   ├── themes.xml
│           │   └── colors.xml
│           ├── values-night/
│           │   └── themes.xml
│           └── xml/
│               ├── backup_rules.xml
│               └── data_extraction_rules.xml
└── google-services.json       # ユーザーが Firebase コンソールから取得
```

## 受入基準

### 機能要件
- [ ] **Email/Password ログイン**: iOS 版で作成済みアカウントでログインできる
- [ ] **新規登録**: Email/Password で新規アカウント作成 → Firebase Auth に反映 → `register` Cloud Function 経由で Firestore に `users/{uid}` ドキュメント作成
- [ ] **Google Sign-In**: Credential Manager 経由でサインインできる（iOS と同一 Google アカウントで）
- [ ] **ログアウト**: ログアウト後、画面遷移が Auth Graph にリセットされる
- [ ] **自動ログイン**: アプリ再起動時、前回のセッションが残っていれば Main Graph に遷移
- [ ] **エラー表示**: 認証失敗時、ユーザーに分かる日本語メッセージを表示（パスワード間違い、ネットワークエラー等）

### 非機能要件
- [ ] Crashlytics にテストクラッシュが記録される
- [ ] App Check（Play Integrity）トークンが Firebase に送信される
- [ ] Analytics に `login` / `sign_up` イベントが記録される
- [ ] Material 3 ダークモードテーマが iOS パレットで表示される
- [ ] Compose UI Test で Login/Register のフォーム入力フローが PASS
- [ ] Gradle ビルドが警告なしで成功（`./gradlew assembleDebug`）

### コード品質
- [ ] ktlint / detekt エラー 0
- [ ] `minSdk = 26`, `targetSdk = 35`, `compileSdk = 35`
- [ ] Hilt 依存性注入が全 ViewModel / Repository に適用されている
- [ ] UI 文字列はすべて `strings.xml`（ハードコード禁止）

## 依存

### ブロッキング前提
1. **Firebase コンソール**で Android アプリを追加（ユーザー実施）
   - Bundle ID: `com.kpopvote.collector`
   - デバッグ用 SHA-1 登録
   - `google-services.json` ダウンロード → `android/app/` に配置
2. **Google Sign-In 用 OAuth クライアント ID**（Web Client ID）を Firebase から取得
3. **App Check**: Play Integrity API を GCP で有効化

詳細は [`setup-guide.md`](./setup-guide.md) 参照。

## テスト計画

### Unit Test（JVM）
| 対象 | ケース |
|------|-------|
| `LoginViewModel` | Email 入力 → state 更新 |
| | パスワード入力 → state 更新 |
| | ログイン成功 → `isSuccess = true` |
| | ログイン失敗 → `error != null` |
| `RegisterViewModel` | 同上 + バリデーション（メール形式 / パスワード 8文字以上） |
| `AuthRepositoryImpl` | Firebase Auth モックで成功/失敗パス |

### Compose UI Test
| 対象 | ケース |
|------|-------|
| `LoginScreen` | Email/Password 入力欄が表示される |
| | Google サインインボタンが表示される |
| | ログイン中はローディング表示 |
| `RegisterScreen` | 入力バリデーションエラー表示 |
| | 登録成功で次画面へ遷移 |

### 統合テスト（Firebase Emulator）
| 対象 | ケース |
|------|-------|
| Email 登録→ログイン | エミュレータ経由で実際の Auth 動作確認 |
| Google サインイン | （実機必須、CI では省略） |

## リスク

| リスク | 対応 |
|--------|-----|
| Credential Manager の新 API が不安定 | 公式サンプル準拠、context7 で最新ドキュメント確認 |
| SHA-1 登録忘れで Google Sign-In 失敗 | setup-guide.md に明記、CI でも SHA チェック |
| Play Integrity API の課金発生 | 無料枠（1日10,000リクエスト）で MVP 期間は問題なし |
| Firebase Emulator と本番の差異 | 認証のみなので差異小、Functions は Sprint 2 で対応 |

## 次スプリント準備

Sprint 2（コアデータ層 + マスターデータ）に引き継ぐもの:
- `FunctionsClient` の基盤コード
- `Result<T>` 共通型
- Repository パターンの型定義
- エラーハンドリング UI コンポーネント
