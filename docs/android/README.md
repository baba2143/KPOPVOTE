# KPOPVOTE Android 版

iOS 版 KPOPVOTE（`ios/` ディレクトリ）の Android ネイティブ移植プロジェクト。

## プロジェクト状況

- **開始日**: 2026-04-18
- **現在のスプリント**: Sprint 7 完了（Profile / Bias / InviteCode — v1.0 MVP 最終ピース）
- **完了スプリント**: Sprint 1 ✅ / Sprint 2 ✅ / Sprint 3 ✅ / Sprint 4 ✅ / Sprint 7 ✅
- **リリース戦略**: MVP 分割 A案
- **初期リリース**: v1.0 MVP（課金なし、iOS収益化のみ）

## リリース計画

| バージョン | 含む機能 | 予定 |
|----------|---------|------|
| **v1.0 (MVP)** | Auth / Home / Tasks / Votes / Profile / Push / マスターデータ | Sprint 1-4, 7, 8 |
| **v1.1** | Community / DM / Fancard / Points履歴 | Sprint 5, 6 |
| **v1.2** | Admin機能 / 予約通知 / ログ | Sprint 7残り |
| **v2.0** | IAP（Google Play Billing + バックエンド追加） | 将来 |

## Sprint 7 成果物（2026-04-18 完了）

- **Profile タブ実体化**: `ProfileScreen` が `MainTabScreen` の Profile タブに配線
  - アバター（72dp）/ 表示名 / メール / ポイントのヘッダ + 3 グループの行メニュー
  - 利用規約 / プライバシーポリシーは Intent.ACTION_VIEW で外部ブラウザへ
  - サインアウトは `AuthRepository.signOut()` + ナビゲーション連携
- **プロフィール編集**: `ProfileEditScreen` / `ProfileEditViewModel`
  - 表示名（1-30）/ 自己紹介（0-150）/ 写真（≤2MB、`ImageCompress.compressUri` で事前圧縮）
  - R2 アップロードは `ProfileImageRepository`（パス: `profiles/{uid}/profile.jpg`）
  - 4 種のバリデーション（REQUIRED / TOO_LONG × 2 / PHOTO_TOO_LARGE）
- **推し設定**: `BiasSettingsScreen` / `BiasSettingsViewModel`
  - マスターデータ（`MasterDataRepository.refreshGroups/refreshIdols` を並列取得）
  - グループ / メンバー の 2 モードを SegmentedButton で切替、検索可
  - `BiasRepository.getBias/setBias` で iOS 準拠の形式（group-level + member-level 混在）
- **招待コード**: `InviteCodeScreen` / `InviteCodeViewModel`
  - 自分のコードをモノスペース表示 + クリップボードコピー + ACTION_SEND で共有
  - 他人のコード入力欄 + `applyInviteCode`、`InviteErrorMapper` が backend の 400/404 を
    `AppError.Invite.AlreadyApplied / SelfInvite / NotFound` に正規化
- **テスト**: **166 ユニットテスト全 green**（Sprint 4 時点の 133 から +33: Phase 1 Data 層 +12, Phase 4 ViewModel +21）

## Sprint 4 成果物（2026-04-18 完了）

- **アプリ内投票**: `VoteRepository` / `VoteListScreen` / `VoteDetailScreen` / `VoteRankingScreen`
  - ステータスフィルタ（upcoming / active / ended）、App Check ヘッダ付きで `executeVote`
  - 4種の業務エラーを `VoteErrorMapper` で `AppError.Vote.*` に正規化
- **コレクション**: `CollectionRepository` / `VotesTabScreen`（Discover / Saved / My Collections）
  - 検索・トレンド並び・タグフィルタ付き `DiscoverScreen`
  - `CollectionDetailScreen` で保存/一括追加/共有/削除（楽観更新 + ロールバック）
  - `CreateCollectionScreen` で作成/編集（カバー画像、タグ、visibility、タスク並べ替え）
- **HOME**: 注目投票の横スクロールを追加（タスク/Bias と並列取得、注目取得失敗は HOME 全体を止めない R12）
- **テスト**: **133 ユニットテスト全 green**（Sprint 3 時点の 52 から +81）

## 技術スタック

| 領域 | 採用 |
|------|------|
| 言語 | Kotlin 2.0+ |
| UI | Jetpack Compose + Material 3 |
| 最低SDK | 26 (Android 8.0) |
| ターゲットSDK | 35 (Android 15) |
| アーキテクチャ | MVVM + Clean Architecture 軽量版 |
| DI | Hilt |
| 非同期 | Coroutines + Flow |
| ナビゲーション | Navigation Compose (type-safe) |
| 画像 | Coil 3 |
| ネットワーク | OkHttp + Kotlinx Serialization（Bearer ID token / HTTP onRequest） |
| シリアライゼーション | Kotlinx Serialization |
| 認証 | Credential Manager + Google ID |
| ローカル永続化 | DataStore Preferences |
| 観測性 | Crashlytics + Analytics + Performance |

## 共有バックエンド

- Firebase プロジェクト: `kpopvote-9de2b`
- Cloud Functions: `https://us-central1-kpopvote-9de2b.cloudfunctions.net`
- Bundle ID: `com.kpopvote.collector`（iOS と同一、Firebase では別アプリ登録）

**Android 版ではバックエンドを変更しない方針**（v2.0 で IAP 対応時のみ追加検討）。

## ドキュメント構成

```
docs/android/
├── README.md                    # 本ファイル（プロジェクト概要）
├── architecture.md              # アーキテクチャ設計
├── setup-guide.md               # 初期セットアップ手順（Firebase 等）
├── sprint1-spec.md              # Sprint 1 仕様（基盤 + Auth）
├── sprint2-spec.md              # Sprint 2 仕様（コアデータ層 + マスターデータ）
├── sprint3-spec.md              # Sprint 3 仕様（Tasks + Home + MainTab + OGP stub）
├── sprint4-spec.md              # Sprint 4 仕様（In-app Votes + Collections）
├── sprint7-spec.md              # Sprint 7 仕様（Profile + Bias + InviteCode）
├── ios-android-parity.md        # iOS ↔ Android 機能対応表
└── design-tokens.md             # カラー/タイポ/スペーシングトークン
```

## コードベース構成

```
android/
├── settings.gradle.kts
├── build.gradle.kts
├── gradle/
│   └── libs.versions.toml       # Version Catalog
├── app/
│   ├── build.gradle.kts
│   ├── proguard-rules.pro
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/com/kpopvote/collector/
│       │   ├── KpopvoteApplication.kt
│       │   ├── MainActivity.kt
│       │   ├── di/              # Hilt モジュール
│       │   ├── core/            # 共通基盤
│       │   ├── data/            # Repository 層
│       │   ├── domain/          # ドメインモデル
│       │   ├── navigation/      # NavGraph
│       │   └── ui/              # Compose 画面
│       └── res/
│           └── values/
│               ├── strings.xml
│               └── themes.xml
└── google-services.json         # Firebase（ユーザーが手動配置）
```

## 開発開始手順

1. [`setup-guide.md`](./setup-guide.md) に従って Firebase / 環境セットアップ
2. Android Studio で `android/` ディレクトリを開く
3. `app/build.gradle.kts` の同期
4. デバイス/エミュレータで実行

## 関連ドキュメント

- iOS 版仕様: [`/KPOP VOTE.md`](../../KPOP%20VOTE.md)
- バックエンド実装状況: [`/BACKEND_IMPLEMENTATION_REPORT.md`](../../BACKEND_IMPLEMENTATION_REPORT.md)
- 投票機能仕様: [`/docs/votes-community-feature-spec.md`](../votes-community-feature-spec.md)
- コミュニティ機能仕様: [`/docs/community-feature-spec.md`](../community-feature-spec.md)
- Fancard 仕様: [`/docs/fancard-feature-spec.md`](../fancard-feature-spec.md)
- 収益化仕様: [`/docs/monetization-system-spec.md`](../monetization-system-spec.md)
