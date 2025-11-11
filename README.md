# 🎵 K-VOTE COLLECTOR

K-POPファン向け外部投票情報一元管理アプリケーション

## プロジェクト概要

**K-VOTE COLLECTOR** は、K-POPファンが複数の投票サイト・アプリの情報を一元管理できるモバイルアプリケーションです。

### 核となる価値

- 📊 **外部投票情報の一元管理**: 複数の投票サイトの情報を1箇所で管理
- 💖 **推し別タスク効率化**: メンバー単位で推し設定し、関連投票を自動フィルタリング
- 🔔 **投票抜け漏れ防止**: 締め切り通知と進捗管理で投票機会を逃さない

## 技術スタック

### バックエンド
- **Firebase Platform**: 認証、データベース、ストレージ、通知の統合管理
- **Cloud Firestore**: NoSQLデータベース
- **Cloud Functions**: サーバーレスAPI（Node.js/TypeScript）

### フロントエンド
- **iOS**: Swift, SwiftUI
- **Android**: Kotlin, Jetpack Compose (Phase 2)
- **Web管理画面**: React/Vue.js, Material UI/Ant Design

## プロジェクト構造

```
KPOPVOTE/
├── functions/              # Cloud Functions (Node.js/TypeScript)
│   ├── src/
│   │   ├── auth/          # 認証API
│   │   ├── user/          # ユーザー設定API
│   │   ├── task/          # タスク管理API
│   │   ├── middleware/    # 認証ミドルウェア
│   │   └── utils/         # ユーティリティ
│   └── test/              # テスト
├── firestore.rules        # Firestoreセキュリティルール
├── firestore.indexes.json # Firestoreインデックス
├── storage.rules          # Storageセキュリティルール
└── docs/                  # ドキュメント

```

## 開発フェーズ

### Phase 0: バックエンド基盤（2週間）✅ 進行中
- Firebase環境構築
- 認証API実装
- タスク管理API実装
- OGP取得機能

### Phase 0+: Web管理画面（3週間）
- ダッシュボード
- 独自投票管理
- マスターデータ管理
- ユーザー管理

### Phase 1: iOSアプリ（3ヶ月）
- SwiftUI実装
- Firebase SDK統合
- 全画面実装
- App Storeリリース

## セットアップ

### 前提条件
- Node.js 18以上
- Firebase CLI
- Xcode 15以上（iOS開発時）

### Firebase環境構築

```bash
# Firebase CLI インストール
npm install -g firebase-tools

# ログイン
firebase login

# 依存関係インストール
cd functions
npm install

# ビルド
npm run build

# エミュレーター起動
npm run serve
```

### デプロイ

```bash
# Functions デプロイ
firebase deploy --only functions

# Firestore ルール・インデックスデプロイ
firebase deploy --only firestore

# 全体デプロイ
firebase deploy
```

## API エンドポイント

**Base URL**: `https://us-central1-kpopvote-9de2b.cloudfunctions.net`

### 認証 ✅ デプロイ済み
- `POST /register` - ユーザー登録
  - リクエスト: `{ email, password, displayName? }`
  - レスポンス: `{ success, data: { uid, email, displayName, token } }`
- `POST /login` - ログイン
  - リクエスト: `{ email, password }`
  - レスポンス: `{ success, data: { uid, email, displayName, token } }`

### ユーザー管理 ✅ デプロイ済み
- `POST /setBias` - 推しメンバー設定
  - ヘッダー: `Authorization: Bearer <token>`
  - リクエスト: `{ myBias: [{ artistId, artistName, memberIds, memberNames }] }`
  - レスポンス: `{ success, data: { myBias } }`
- `GET /getBias` - 推し設定取得
  - ヘッダー: `Authorization: Bearer <token>`
  - レスポンス: `{ success, data: { myBias } }`

### タスク管理
- `POST /task/register` - 投票タスク登録
- `GET /task/getUserTasks` - タスク一覧取得
- `POST /task/fetchOGP` - OGP情報取得
- `PATCH /task/updateStatus` - ステータス更新

## ドキュメント

- [プロジェクト仕様](./KPOP%20VOTE.md)
- [データベース設計](./DBスキーマ設計案.txt)
- [タスク管理計画](./タスク管理計画.md)
- [実装ワークフロー](./implementation_workflow.md)
- [Phase 0ワークフロー](./phase0_workflow.md)

## ライセンス

Private - All Rights Reserved

## 開発者

K-VOTE COLLECTOR Development Team

---

**最終更新**: 2025-11-11
