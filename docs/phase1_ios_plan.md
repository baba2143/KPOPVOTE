# 📱 Phase 1: iOSアプリ開発計画

## プロジェクト概要

**期間**: 3ヶ月
**目標**: K-VOTE COLLECTOR iOS版の完全実装とApp Storeリリース

## 技術スタック

### フロントエンド
- **言語**: Swift 6.0+
- **UIフレームワーク**: SwiftUI
- **最小対応OS**: iOS 16.0
- **アーキテクチャ**: MVVM + Combine

### バックエンド連携
- **Firebase iOS SDK**: 10.x
  - Firebase Auth
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging (通知)
- **API通信**: URLSession + async/await
- **画像キャッシュ**: Kingfisher

### 開発ツール
- **Xcode**: 16.2
- **Swift Package Manager**: 依存関係管理
- **Git**: バージョン管理

## Week 1-2: プロジェクト基盤構築

### 1.1 Xcodeプロジェクト作成
- [ ] iOS Appプロジェクト作成
- [ ] Bundle Identifier設定: `com.kpopvote.collector`
- [ ] Deployment Target: iOS 16.0
- [ ] SwiftUI + Swift Concurrency有効化

### 1.2 Firebase SDK統合
- [ ] Firebase iOS SDK追加（Swift Package Manager）
- [ ] GoogleService-Info.plist設定
- [ ] Firebase初期化コード実装
- [ ] 認証テスト実装

### 1.3 プロジェクト構造設計
```
KPOPVOTE-iOS/
├── App/
│   ├── KPOPVOTEApp.swift        # App entry point
│   └── ContentView.swift         # Root view
├── Models/
│   ├── User.swift
│   ├── Task.swift
│   ├── Vote.swift
│   └── Bias.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── TaskViewModel.swift
│   └── VoteViewModel.swift
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── RegisterView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── TaskListView.swift
│   ├── Task/
│   │   ├── TaskDetailView.swift
│   │   └── AddTaskView.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── BiasSettingsView.swift
├── Services/
│   ├── AuthService.swift
│   ├── TaskService.swift
│   └── VoteService.swift
└── Utilities/
    ├── Constants.swift
    └── Extensions.swift
```

### 1.4 デザインシステム構築
- [ ] カラーパレット定義
- [ ] タイポグラフィ定義
- [ ] 共通コンポーネント作成
  - Button
  - TextField
  - Card
  - LoadingView

## Week 3-4: 認証機能実装

### 2.1 ログイン画面
- [ ] LoginView UI実装
- [ ] メール・パスワードフォーム
- [ ] Firebase Auth連携
- [ ] エラーハンドリング

### 2.2 新規登録画面
- [ ] RegisterView UI実装
- [ ] バリデーション実装
- [ ] 登録処理実装

### 2.3 認証状態管理
- [ ] AuthViewModel実装
- [ ] 自動ログイン処理
- [ ] トークン管理

## Week 5-6: ホーム画面・タスク一覧

### 3.1 ホーム画面
- [ ] HomeView UI実装
- [ ] タスク一覧表示
- [ ] 推しフィルター機能
- [ ] Pull to Refresh

### 3.2 タスクカード
- [ ] TaskCardView実装
- [ ] 締め切り表示
- [ ] ステータス表示
- [ ] タップアクション

### 3.3 タスク詳細画面
- [ ] TaskDetailView実装
- [ ] OGP画像表示
- [ ] 投票サイトリンク
- [ ] ステータス更新機能

## Week 7-8: タスク登録・編集機能

### 4.1 タスク登録画面
- [ ] AddTaskView UI実装
- [ ] URLフォーム
- [ ] 締め切り日時選択
- [ ] 推し選択機能
- [ ] OGP自動取得

### 4.2 タスク編集・削除
- [ ] 編集画面実装
- [ ] 削除確認ダイアログ
- [ ] 楽観的UI更新

## Week 9-10: 推し設定機能

### 5.1 推し設定画面
- [ ] BiasSettingsView実装
- [ ] アーティスト検索
- [ ] メンバー複数選択
- [ ] 保存処理

### 5.2 推し関連機能
- [ ] 推しフィルター切り替え
- [ ] 推しベースの通知設定

## Week 11-12: アプリ内投票機能（オプション）

### 6.1 投票画面
- [ ] VoteListView実装
- [ ] 投票詳細画面
- [ ] ポイント消費投票
- [ ] ランキング表示

## Week 13: 最終調整・テスト

### 7.1 最終調整
- [ ] UI/UX調整
- [ ] パフォーマンス最適化
- [ ] アクセシビリティ対応
- [ ] ダークモード対応

### 7.2 テスト
- [ ] ユニットテスト実装
- [ ] UIテスト実装
- [ ] デバイステスト（実機）
- [ ] ベータテスト

### 7.3 App Store準備
- [ ] アプリアイコン作成
- [ ] スクリーンショット作成
- [ ] App Store説明文作成
- [ ] プライバシーポリシー作成

## API連携仕様

### Base URL
```
https://us-central1-kpopvote-9de2b.cloudfunctions.net
```

### 認証ヘッダー
```swift
let headers = [
    "Authorization": "Bearer \(token)",
    "Content-Type": "application/json"
]
```

### 主要エンドポイント
- `POST /register` - ユーザー登録
- `POST /login` - ログイン
- `POST /setBias` - 推し設定
- `GET /getBias` - 推し取得
- `POST /registerTask` - タスク登録
- `GET /getUserTasks` - タスク一覧
- `POST /fetchTaskOGP` - OGP取得
- `PATCH /updateTaskStatus` - ステータス更新

## デザインガイドライン

### カラーパレット
```swift
// Primary Colors
static let primaryBlue = Color(hex: "1976d2")
static let primaryPink = Color(hex: "e91e63")

// Background
static let background = Color(hex: "f5f5f5")
static let cardBackground = Color.white

// Text
static let textPrimary = Color.black
static let textSecondary = Color.gray
```

### タイポグラフィ
- **Title**: 24pt, Bold
- **Headline**: 18pt, Semibold
- **Body**: 16pt, Regular
- **Caption**: 14pt, Regular

## マイルストーン

### M1: プロジェクト基盤 (Week 2終了時)
- ✅ Xcodeプロジェクト作成
- ✅ Firebase SDK統合
- ✅ 基本構造実装

### M2: 認証機能完成 (Week 4終了時)
- ✅ ログイン・登録画面
- ✅ 認証状態管理
- ✅ 自動ログイン

### M3: コア機能完成 (Week 8終了時)
- ✅ タスク一覧・詳細
- ✅ タスク登録・編集
- ✅ 推し設定

### M4: MVP完成 (Week 10終了時)
- ✅ 全主要機能実装
- ✅ API連携完了
- ✅ 基本テスト完了

### M5: App Storeリリース (Week 13終了時)
- ✅ 最終調整完了
- ✅ App Store申請
- ✅ リリース

## リスク管理

### 技術リスク
- **Firebase iOS SDK互換性**: 最新SDKを使用し、定期的に更新
- **API変更**: バージョニング対応、fallback処理実装

### スケジュールリスク
- **機能過多**: MVP優先、アプリ内投票は後回し可能
- **テスト不足**: 週次でのテストマイルストーン設定

### 品質リスク
- **パフォーマンス**: 画像キャッシュ、リスト最適化を早期実装
- **クラッシュ**: Firebase Crashlytics統合

---

**作成日**: 2025-11-12
**更新日**: 2025-11-12
**バージョン**: 1.0
