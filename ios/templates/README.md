# 📱 K-VOTE COLLECTOR iOS - コードテンプレート集

## 概要
このディレクトリには、K-VOTE COLLECTOR iOS アプリの開発に使用できる Swift コードテンプレートが含まれています。

Xcode プロジェクトを作成した後、これらのファイルをプロジェクトにコピーして使用してください。

---

## ディレクトリ構造

```
templates/
├── Models/              # データモデル
│   ├── User.swift       # ユーザーモデル
│   ├── Task.swift       # タスクモデル
│   └── Bias.swift       # 推しモデル
├── Services/            # ビジネスロジック層
│   └── AuthService.swift # 認証サービス
├── ViewModels/          # MVVM ViewModels
│   └── AuthViewModel.swift # 認証 ViewModel
├── Views/               # SwiftUI ビュー
│   └── Auth/
│       ├── LoginView.swift     # ログイン画面
│       └── RegisterView.swift  # 新規登録画面
└── Utilities/           # ユーティリティ
    └── Constants.swift  # 定数定義
```

---

## 使用方法

### Step 1: Xcode プロジェクトを作成
`SETUP_GUIDE.md` に従って、Xcode プロジェクトを作成してください。

### Step 2: Firebase SDK を追加
`FIREBASE_SETUP.md` に従って、Firebase iOS SDK を追加してください。

### Step 3: テンプレートファイルをコピー

#### 3.1 フォルダ構造を作成
Xcode のプロジェクトナビゲーターで、以下のグループ（フォルダ）を作成：

```
KPOPVOTE/
├── App/ (既存)
├── Models/
├── Services/
├── ViewModels/
├── Views/
│   └── Auth/
├── Utilities/
└── Resources/ (既存)
```

#### 3.2 ファイルをコピー
各テンプレートファイルを対応するフォルダにコピー：

**Models フォルダ:**
- `Models/User.swift` → Xcode の `Models/` グループに追加
- `Models/Task.swift` → Xcode の `Models/` グループに追加
- `Models/Bias.swift` → Xcode の `Models/` グループに追加

**Services フォルダ:**
- `Services/AuthService.swift` → Xcode の `Services/` グループに追加

**ViewModels フォルダ:**
- `ViewModels/AuthViewModel.swift` → Xcode の `ViewModels/` グループに追加

**Views フォルダ:**
- `Views/Auth/LoginView.swift` → Xcode の `Views/Auth/` グループに追加
- `Views/Auth/RegisterView.swift` → Xcode の `Views/Auth/` グループに追加

**Utilities フォルダ:**
- `Utilities/Constants.swift` → Xcode の `Utilities/` グループに追加

#### 3.3 ファイル追加時の注意
各ファイルを Xcode に追加する際は：
- ✅ **Copy items if needed** にチェック
- ✅ **Add to targets: KPOPVOTE** にチェック
- **Create groups** を選択

---

## Step 4: ContentView.swift を編集

### 4.1 ContentView.swift を開く
プロジェクトナビゲーターで `ContentView.swift` を選択

### 4.2 コードを置き換え
以下のコードに置き換え：

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()

    var body: some View {
        Group {
            if authService.isAuthenticated {
                // ログイン後のメイン画面（後で実装）
                HomeView()
            } else {
                // ログイン画面
                LoginView(authService: authService)
            }
        }
    }
}

// 仮のHomeView（後で実装）
struct HomeView: View {
    var body: some View {
        Text("ホーム画面（実装予定）")
    }
}

#Preview {
    ContentView()
}
```

---

## Step 5: ビルドとテスト

### 5.1 ビルド
1. **Product** → **Build** (⌘B)
2. エラーがないことを確認

### 5.2 実行
1. シミュレーターを選択（例: iPhone 15 Pro）
2. **Product** → **Run** (⌘R)
3. ログイン画面が表示されることを確認

---

## コードテンプレートの説明

### 📦 Models

#### User.swift
ユーザー情報を管理するモデル

**機能:**
- Firebase Authentication UID との連携
- Firestore タイムスタンプの自動変換
- ユーザー表示名の取得
- ポイント表示のフォーマット

**使用例:**
```swift
let user = User(
    id: "user123",
    email: "user@example.com",
    displayName: "K-POP ファン",
    points: 100
)

print(user.displayNameOrEmail) // "K-POP ファン"
print(user.formattedPoints)    // "100pt"
```

#### Task.swift
投票タスクを管理するモデル

**機能:**
- タスクステータス管理（pending/completed/expired）
- 締め切りまでの残り時間計算
- OGP メタデータ保存
- 推し（bias）との関連付け

**使用例:**
```swift
let task = VoteTask(
    userId: "user123",
    title: "K-POP アワード投票",
    url: "https://example.com/vote",
    deadline: Date().addingTimeInterval(86400), // 24時間後
    biasIds: ["bias1", "bias2"]
)

print(task.timeRemaining)     // "1日"
print(task.isExpired)         // false
print(task.formattedDeadline) // "2025年11月13日 12:00"
```

#### Bias.swift
推し（アイドル）を管理するモデル

**機能:**
- 推しの名前とグループ情報
- プロフィール画像 URL
- 表示用の名前フォーマット

**使用例:**
```swift
let bias = Bias(
    name: "ジミン",
    group: "BTS",
    imageUrl: "https://example.com/image.jpg"
)

print(bias.displayName) // "ジミン (BTS)"
print(bias.initials)    // "ジミ"
```

---

### 🔧 Services

#### AuthService.swift
Firebase Authentication を使用した認証サービス

**機能:**
- ユーザー登録（Firebase Auth + Cloud Functions）
- ログイン（Firebase Auth + トークン検証）
- ログアウト
- 認証状態の監視（ObservableObject）

**使用例:**
```swift
let authService = AuthService()

// 登録
Task {
    let user = try await authService.register(
        email: "user@example.com",
        password: "password123"
    )
    print("登録成功: \(user.email)")
}

// ログイン
Task {
    let user = try await authService.login(
        email: "user@example.com",
        password: "password123"
    )
    print("ログイン成功: \(user.email)")
}

// ログアウト
try authService.logout()
```

---

### 🧠 ViewModels

#### AuthViewModel.swift
認証画面のビジネスロジックを管理する ViewModel

**機能:**
- 入力バリデーション（メールアドレス、パスワード）
- ローディング状態管理
- エラーハンドリング
- フォームのリセット

**使用例:**
```swift
@StateObject var viewModel = AuthViewModel(authService: authService)

// バリデーション
if viewModel.isValidEmail {
    print("有効なメールアドレス")
}

// ログイン実行
Task {
    await viewModel.login()
}
```

---

### 🎨 Views

#### LoginView.swift
ログイン画面の UI

**機能:**
- メールアドレス入力
- パスワード入力
- ログインボタン
- 新規登録画面へのナビゲーション
- エラー表示アラート

**デザイン:**
- Material Design 風のカード UI
- プライマリカラー: Blue (#1976d2)
- バリデーション付きフォーム

#### RegisterView.swift
新規登録画面の UI

**機能:**
- メールアドレス入力
- パスワード入力
- パスワード確認入力
- リアルタイムバリデーション
- 登録ボタン

**デザイン:**
- Material Design 風のカード UI
- プライマリカラー: Pink (#e91e63)
- インラインエラーメッセージ

---

### ⚙️ Utilities

#### Constants.swift
アプリ全体で使用する定数定義

**含まれる定数:**
- **API Base URL**: Cloud Functions のベース URL
- **Colors**: カラーパレット（Primary Blue, Primary Pink, Background, など）
- **Typography**: フォントサイズ定義
- **Spacing**: 余白サイズ定義
- **API Endpoints**: 全 API エンドポイント
- **UserDefaults Keys**: ローカルストレージキー

**使用例:**
```swift
// カラー
Text("タイトル")
    .foregroundColor(Constants.Colors.primaryBlue)

// API エンドポイント
let url = URL(string: Constants.API.register)!

// スペーシング
VStack(spacing: Constants.Spacing.medium) {
    // ...
}
```

**Hex Color Extension:**
16進数カラーコードから Color を作成可能：
```swift
let customColor = Color(hex: "1976d2")
```

---

## カスタマイズ

### カラーの変更
`Constants.swift` の `Colors` enum を編集：

```swift
enum Colors {
    static let primaryBlue = Color(hex: "YOUR_HEX_COLOR")
    static let primaryPink = Color(hex: "YOUR_HEX_COLOR")
}
```

### API エンドポイントの変更
`Constants.swift` の `apiBaseURL` を編集：

```swift
static let apiBaseURL = "https://your-project.cloudfunctions.net"
```

---

## 次のステップ

テンプレートを追加したら：

1. **ホーム画面の実装** (Week 5-6)
   - TaskListView
   - TaskCardView
   - TaskDetailView

2. **タスク登録機能** (Week 7-8)
   - AddTaskView
   - OGP 自動取得

3. **推し設定機能** (Week 9-10)
   - BiasSettingsView
   - 推しフィルター

---

## トラブルシューティング

### Q: ビルドエラー「Cannot find 'AuthService' in scope」
**A**: AuthService.swift が正しく追加されているか確認してください。**Add to targets** にチェックが入っている必要があります。

### Q: 「Module 'FirebaseCore' not found」エラー
**A**:
1. Xcode を再起動
2. **File** → **Packages** → **Reset Package Caches**
3. 再度ビルド

### Q: LoginView のプレビューでクラッシュ
**A**: プレビューは Firebase が初期化されていないため動作しない場合があります。実機またはシミュレーターで実行してください。

---

## コーディング規約

これらのテンプレートは以下の規約に従っています：

- **命名規則**: Swift 標準（PascalCase for types, camelCase for properties）
- **SwiftUI Best Practices**: @StateObject, @ObservedObject の適切な使用
- **async/await**: 非同期処理には async/await を使用
- **エラーハンドリング**: do-catch と Result 型
- **コメント**: MARK を使用してコードを整理

---

**作成日**: 2025-11-12
**更新日**: 2025-11-12
**対応 iOS バージョン**: iOS 16.0+
**Swift バージョン**: 6.0+
