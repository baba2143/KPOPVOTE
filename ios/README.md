# 📱 K-VOTE COLLECTOR - iOS アプリ開発

## 概要
K-VOTE COLLECTOR の iOS ネイティブアプリ開発プロジェクトです。

SwiftUI + Firebase を使用し、MVVM アーキテクチャで実装します。

---

## 🚀 クイックスタート

### 1. 開発環境の確認
```bash
# Xcode バージョン確認
xcodebuild -version
# 必要: Xcode 16.2 以上

# Swift バージョン確認
swift --version
# 必要: Swift 6.0 以上
```

### 2. セットアップガイドに従う
以下の順序でドキュメントを参照：

1. **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Xcode プロジェクト作成と Firebase SDK 統合
2. **[FIREBASE_SETUP.md](./FIREBASE_SETUP.md)** - Firebase Console での iOS アプリ登録
3. **[templates/README.md](./templates/README.md)** - コードテンプレートの使用方法

### 3. プロジェクト作成
`SETUP_GUIDE.md` の手順に従って Xcode プロジェクトを作成：

```
Product Name: KPOPVOTE
Bundle Identifier: com.kpopvote.collector
Interface: SwiftUI
Language: Swift
Minimum Deployment: iOS 16.0
```

### 4. Firebase 設定
`FIREBASE_SETUP.md` に従って Firebase Console から `GoogleService-Info.plist` をダウンロードし、プロジェクトに追加

### 5. テンプレートコピー
`templates/` ディレクトリ内の Swift ファイルを Xcode プロジェクトにコピー

---

## 📁 プロジェクト構造

```
KPOPVOTE/
├── App/
│   ├── KPOPVOTEApp.swift          # App entry point
│   └── ContentView.swift           # Root view
├── Models/
│   ├── User.swift                  # ユーザーモデル
│   ├── Task.swift                  # タスクモデル
│   └── Bias.swift                  # 推しモデル
├── ViewModels/
│   ├── AuthViewModel.swift         # 認証 ViewModel
│   ├── TaskViewModel.swift         # タスク ViewModel（実装予定）
│   └── BiasViewModel.swift         # 推し ViewModel（実装予定）
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift         # ログイン画面
│   │   └── RegisterView.swift      # 新規登録画面
│   ├── Home/
│   │   ├── HomeView.swift          # ホーム画面（実装予定）
│   │   └── TaskListView.swift      # タスク一覧（実装予定）
│   ├── Task/
│   │   ├── TaskDetailView.swift    # タスク詳細（実装予定）
│   │   └── AddTaskView.swift       # タスク登録（実装予定）
│   └── Settings/
│       ├── SettingsView.swift      # 設定画面（実装予定）
│       └── BiasSettingsView.swift  # 推し設定（実装予定）
├── Services/
│   ├── AuthService.swift           # 認証サービス
│   ├── TaskService.swift           # タスクサービス（実装予定）
│   └── BiasService.swift           # 推しサービス（実装予定）
├── Utilities/
│   ├── Constants.swift             # 定数定義
│   └── Extensions.swift            # 拡張機能（実装予定）
└── Resources/
    ├── Assets.xcassets             # アセット
    └── GoogleService-Info.plist    # Firebase 設定
```

---

## 🛠 技術スタック

### フロントエンド
- **言語**: Swift 6.0+
- **UI フレームワーク**: SwiftUI
- **最小対応 OS**: iOS 16.0
- **アーキテクチャ**: MVVM + Combine

### バックエンド連携
- **Firebase iOS SDK**: 10.x
  - Firebase Auth (認証)
  - Cloud Firestore (データベース)
  - Firebase Storage (ストレージ)
  - Firebase Cloud Messaging (通知)
- **API 通信**: URLSession + async/await
- **画像キャッシュ**: Kingfisher（実装予定）

### 開発ツール
- **Xcode**: 16.2
- **Swift Package Manager**: 依存関係管理
- **Git**: バージョン管理

---

## 📋 開発計画

詳細な開発計画は [`../docs/phase1_ios_plan.md`](../docs/phase1_ios_plan.md) を参照。

### マイルストーン

**M1: プロジェクト基盤** (Week 1-2)
- ✅ Xcode プロジェクト作成
- ✅ Firebase SDK 統合
- ✅ 基本構造実装
- ✅ テンプレートコード作成

**M2: 認証機能完成** (Week 3-4)
- ✅ ログイン・登録画面
- ✅ 認証状態管理
- ⏳ 自動ログイン

**M3: コア機能完成** (Week 5-8)
- ⏳ タスク一覧・詳細
- ⏳ タスク登録・編集
- ⏳ 推し設定

**M4: MVP 完成** (Week 9-10)
- ⏳ 全主要機能実装
- ⏳ API 連携完了
- ⏳ 基本テスト完了

**M5: App Store リリース** (Week 11-13)
- ⏳ 最終調整完了
- ⏳ App Store 申請
- ⏳ リリース

---

## 🎨 デザインシステム

### カラーパレット
```swift
// Primary Colors
primaryBlue:  #1976d2  // メインアクション、リンク
primaryPink:  #e91e63  // アクセント、強調

// Background
background:   #f5f5f5  // 画面背景
cardBackground: #ffffff // カード背景

// Text
textPrimary:   #000000 // 本文
textSecondary: #808080 // 補足テキスト

// Status Colors
statusPending:   #2196f3 // 未完了タスク
statusCompleted: #4caf50 // 完了タスク
statusExpired:   #f44336 // 期限切れ
```

### タイポグラフィ
- **Title**: 24pt, Bold
- **Headline**: 18pt, Semibold
- **Body**: 16pt, Regular
- **Caption**: 14pt, Regular

### スペーシング
- **Small**: 8pt
- **Medium**: 16pt
- **Large**: 24pt
- **Extra Large**: 32pt

---

## 🔌 API 統合

### Base URL
```
https://us-central1-kpopvote-9de2b.cloudfunctions.net
```

### 認証ヘッダー
```swift
let token = try await Auth.auth().currentUser?.getIDToken()
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
- `POST /fetchTaskOGP` - OGP 取得
- `PATCH /updateTaskStatus` - ステータス更新

詳細は [`../docs/phase1_ios_plan.md`](../docs/phase1_ios_plan.md) の「API 連携仕様」を参照。

---

## 🧪 テスト

### ユニットテスト
```swift
// 実装予定
```

### UI テスト
```swift
// 実装予定
```

### デバイステスト
- iPhone 15 Pro (iOS 17.0)
- iPhone 14 (iOS 16.0)
- iPhone SE (iOS 16.0)

---

## 📦 依存関係

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
]
```

### Firebase パッケージ
- FirebaseAuth
- FirebaseFirestore
- FirebaseStorage
- FirebaseMessaging

---

## 🚨 トラブルシューティング

### Firebase SDK エラー
```
Error: Module 'FirebaseCore' not found
```

**解決方法:**
1. Xcode を再起動
2. **File** → **Packages** → **Reset Package Caches**
3. **Product** → **Clean Build Folder** (⇧⌘K)
4. 再度ビルド

### GoogleService-Info.plist エラー
```
Error: Could not locate GoogleService-Info.plist
```

**解決方法:**
1. `GoogleService-Info.plist` がプロジェクトルートにあることを確認
2. **Copy items if needed** がチェックされていることを確認
3. **Add to targets: KPOPVOTE** がチェックされていることを確認

### ビルドエラー
**解決方法:**
1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Derived Data を削除: `~/Library/Developer/Xcode/DerivedData`
3. Xcode を再起動
4. 再度ビルド

---

## 📚 ドキュメント

- **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** - Xcode プロジェクトセットアップ
- **[FIREBASE_SETUP.md](./FIREBASE_SETUP.md)** - Firebase 設定
- **[templates/README.md](./templates/README.md)** - コードテンプレート説明
- **[../docs/phase1_ios_plan.md](../docs/phase1_ios_plan.md)** - 開発計画詳細

---

## 🤝 コントリビューション

開発規約：
- Swift コーディング規約に従う
- MVVM アーキテクチャを維持
- async/await を使用（Combine は補助的に使用）
- SwiftUI Best Practices に従う
- コメントは日本語で記述

---

## 📝 変更履歴

### 2025-11-12
- ✅ プロジェクト初期化
- ✅ セットアップガイド作成
- ✅ Firebase 設定ガイド作成
- ✅ コードテンプレート作成（Models, Services, ViewModels, Views）
- ✅ 開発計画ドキュメント作成

---

## 📞 サポート

質問や問題がある場合は：
1. ドキュメントを確認
2. トラブルシューティングセクションを参照
3. Issue を作成

---

**プロジェクト**: K-VOTE COLLECTOR iOS
**バージョン**: 1.0.0
**作成日**: 2025-11-12
**最終更新**: 2025-11-12
