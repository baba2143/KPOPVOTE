# K-VOTE COLLECTOR 技術スタック

## アーキテクチャ概要

K-VOTE COLLECTORは、Firebase基盤のモバイルアプリケーションです。

```
┌─────────────┐         ┌──────────────────┐
│   iOS App   │────────▶│                  │
│   (Swift)   │         │                  │
└─────────────┘         │  Firebase        │
                        │  - Auth          │
┌─────────────┐         │  - Firestore     │◀──┐
│ Android App │────────▶│  - Storage       │   │
│  (Kotlin)   │         │  - Functions     │   │
└─────────────┘         │  - Messaging     │   │
                        └──────────────────┘   │
                                 │              │
                                 ▼              │
                        ┌──────────────────┐   │
                        │ Cloud Functions  │───┘
                        │   (Node.js)      │
                        │ - OGP Fetcher    │
                        │ - Notifications  │
                        │ - Point System   │
                        └──────────────────┘
```

## バックエンド

### Firebase Platform
- **役割**: 認証、データベース、ストレージ、通知の統合管理
- **選定理由**: 
  - 迅速な開発・デプロイ
  - スケーラビリティ
  - リアルタイムデータ同期
  - 組み込み認証システム

### Cloud Firestore (NoSQL)
- **役割**: 全データの管理
- **データモデル**: 
  - `users` - ユーザー情報、推し設定
  - `users/{uid}/tasks` - ユーザー別投票タスク（サブコレクション）
  - `communityPosts` - コミュニティ投稿
  - `inAppVotes` - アプリ内独自投票

### Cloud Functions (Node.js)
- **役割**: サーバーサイドロジック実行
- **主な機能**:
  - OGP画像自動取得（外部URL解析）
  - 投票ポイント計算・管理
  - プッシュ通知トリガー
  - データ検証・セキュリティ

## フロントエンド

### 管理画面（Web - Phase 0+）
- **フレームワーク**: React / Vue.js
- **UIライブラリ**: Material UI (MUI) / Ant Design
- **状態管理**: Redux / Pinia
- **データ視覚化**: Chart.js / Recharts
- **ホスティング**: Firebase Hosting
- **認証**: Firebase Admin Auth（管理者専用）
- **主な機能**:
  - ダッシュボード（統計・グラフ表示）
  - 独自投票管理（作成・編集・削除）
  - マスターデータ管理（アイドル・外部アプリ）
  - コミュニティ監視（不適切投稿対応）
  - ユーザー管理（検索・詳細・ポイント付与）
  - システムログ（エラー監視・API監視）

### iOS (Phase 1)
- **言語**: Swift
- **フレームワーク**: SwiftUI / UIKit
- **Firebase SDK**: 
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseMessaging

### Android (Phase 2)
- **言語**: Kotlin
- **フレームワーク**: Jetpack Compose / Android Views
- **Firebase SDK**: 
  - Firebase Android SDK（各種モジュール）

## API設計

### 認証API
- `POST /auth/register` - ユーザー登録
- `POST /auth/login` - ログイン

### ユーザー設定API
- `POST /user/setBias` - 推しメンバー設定
- `GET /user/getBias` - 推し設定取得

### タスク管理API
- `POST /task/register` - 投票タスク登録
- `GET /task/getUserTasks` - タスク一覧取得
- `PATCH /task/updateStatus` - 進捗ステータス更新
- `POST /task/fetchOGP` - OGP情報取得

### コミュニティAPI（Phase 0以降）
- `POST /community/post` - 投稿作成
- `GET /community/getPosts` - 投稿取得
- `POST /community/like` - いいね
- `POST /community/comment` - コメント

### 独自投票API（Phase 0以降）
- `GET /vote/getActive` - アクティブ投票取得
- `POST /vote/cast` - 投票実行

### 管理画面専用API（Phase 0+）
- **独自投票管理**:
  - `POST /admin/vote/create` - 独自投票作成
  - `PATCH /admin/vote/update` - 投票更新
  - `DELETE /admin/vote/delete` - 投票削除
  - `GET /admin/vote/statistics` - 投票統計取得

- **マスター管理**:
  - `POST /admin/master/idol/create` - アイドル登録
  - `PATCH /admin/master/idol/update` - アイドル更新
  - `DELETE /admin/master/idol/delete` - アイドル削除
  - `POST /admin/master/app/create` - 外部アプリ登録
  - `PATCH /admin/master/app/update` - 外部アプリ更新
  - `DELETE /admin/master/app/delete` - 外部アプリ削除

- **コミュニティ監視**:
  - `GET /admin/community/reported` - 報告された投稿取得
  - `DELETE /admin/community/delete` - 投稿削除
  - `POST /admin/community/dismissReport` - 報告却下

- **ユーザー管理**:
  - `GET /admin/user/search` - ユーザー検索
  - `GET /admin/user/details` - ユーザー詳細取得
  - `PATCH /admin/user/addPoints` - ポイント付与
  - `PATCH /admin/user/suspend` - アカウント停止

## 外部連携

### 投票サイト・アプリ
- IDOL CHAMP
- Mnet Plus App
- MUBEAT
- Show Champion
- Golden Disc Awards
- その他各種音楽番組・授賞式投票

### OGP取得
- **ライブラリ候補**: 
  - `cheerio` - HTMLパーサー
  - `open-graph-scraper` - 専用OGPスクレイパー
- **取得情報**: 
  - `og:title` - 投票名
  - `og:image` - サムネイル画像

## 開発環境

### 必要ツール（Phase 1開始時）
- **iOS開発**:
  - Xcode 15+
  - Swift 5.9+
  - CocoaPods / Swift Package Manager
  
- **バックエンド開発**:
  - Node.js 18+
  - Firebase CLI
  - npm / yarn

### 推奨開発環境
- macOS（iOS開発必須）
- Git（バージョン管理）
- Visual Studio Code（Cloud Functions開発）

## セキュリティ

### Firestore Security Rules
- 認証済みユーザーのみデータアクセス可能
- ユーザーは自分のタスクのみ読み書き可能
- コミュニティ投稿は全員閲覧可、作成者のみ編集可

### 認証
- Firebase Authentication
- Email/Password認証
- 将来的にソーシャルログイン追加可能

## パフォーマンス考慮

### データ構造最適化
- タスクはユーザー単位でサブコレクション化（クエリ効率化）
- インデックス設定（deadline, targetMembers）
- ページネーション実装

### OGP取得
- タイムアウト: 10秒
- リトライ: 3回
- 非同期処理でUI待機を最小化
