# 🚀 K-VOTE COLLECTOR iOS - セットアップガイド

## Step 1: Xcodeプロジェクト作成

### 1.1 Xcodeを開く
```bash
open -a Xcode
```

### 1.2 新規プロジェクト作成
1. **File** → **New** → **Project...**
2. **iOS** タブを選択
3. **App** テンプレートを選択
4. **Next** をクリック

### 1.3 プロジェクト設定
以下の設定を入力：

| 項目 | 値 |
|------|-----|
| Product Name | `KPOPVOTE` |
| Team | あなたのApple Developer Team |
| Organization Identifier | `com.kpopvote` |
| Bundle Identifier | `com.kpopvote.collector` |
| Interface | **SwiftUI** |
| Language | **Swift** |
| Storage | **None** (Core Dataは使用しない) |

### 1.4 プロジェクト保存先
```
/Users/makotobaba/Desktop/KPOPVOTE/ios/
```

**Next** → **Create** をクリック

---

## Step 2: プロジェクト基本設定

### 2.1 Deployment Target設定
1. プロジェクトナビゲーターで **KPOPVOTE** プロジェクトを選択
2. **General** タブを選択
3. **Deployment Info** セクションで：
   - **Minimum Deployments**: `iOS 16.0`
   - **Supported Destinations**: iPhone のみ（iPadは後で追加可能）

### 2.2 App Icon設定
1. **Assets.xcassets** を選択
2. **AppIcon** を選択
3. 後でアイコン画像を追加（現時点ではスキップ可）

---

## Step 3: Firebase SDK統合

### 3.1 Firebase iOS SDK追加
1. Xcodeで **File** → **Add Package Dependencies...**
2. 検索バーに以下を入力：
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. **Dependency Rule**: `Up to Next Major Version` - `10.0.0`
4. **Add Package** をクリック

### 3.2 必要なFirebase製品を選択
以下のパッケージを選択：
- ✅ **FirebaseAuth**
- ✅ **FirebaseFirestore**
- ✅ **FirebaseStorage**
- ✅ **FirebaseMessaging** (通知用)

**Add Package** をクリック

### 3.3 GoogleService-Info.plistのダウンロード
1. Firebase Console を開く: https://console.firebase.google.com/
2. プロジェクト **kpopvote-9de2b** を選択
3. **Project Settings** (歯車アイコン) をクリック
4. **Your apps** セクションで **Add app** をクリック
5. **iOS** アイコンを選択
6. **Apple bundle ID**: `com.kpopvote.collector` を入力
7. **Register app** をクリック
8. **GoogleService-Info.plist** をダウンロード

### 3.4 GoogleService-Info.plistをプロジェクトに追加
1. ダウンロードした `GoogleService-Info.plist` を見つける
2. Xcodeプロジェクトのルートディレクトリにドラッグ&ドロップ
3. **Copy items if needed** にチェック
4. **Add to targets: KPOPVOTE** にチェック
5. **Finish** をクリック

---

## Step 4: Firebase初期化コード追加

### 4.1 KPOPVOTEApp.swiftを編集
プロジェクトナビゲーターで `KPOPVOTEApp.swift` を開き、以下のコードに置き換え：

```swift
import SwiftUI
import FirebaseCore

@main
struct KPOPVOTEApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Step 5: プロジェクト構造作成

### 5.1 フォルダ構造を作成
Xcodeのプロジェクトナビゲーターで右クリック → **New Group** を繰り返し、以下の構造を作成：

```
KPOPVOTE/
├── App/
│   ├── KPOPVOTEApp.swift (既存)
│   └── ContentView.swift (既存)
├── Models/
├── ViewModels/
├── Views/
│   ├── Auth/
│   ├── Home/
│   ├── Task/
│   └── Settings/
├── Services/
├── Utilities/
└── Resources/ (Assets.xcassets, GoogleService-Info.plist)
```

### 5.2 既存ファイルを移動
- `KPOPVOTEApp.swift` → `App/` フォルダへ
- `ContentView.swift` → `App/` フォルダへ
- `Assets.xcassets` → `Resources/` フォルダへ
- `GoogleService-Info.plist` → `Resources/` フォルダへ

---

## Step 6: ビルドテスト

### 6.1 ビルド実行
1. **Product** → **Build** (⌘B)
2. エラーがないことを確認

### 6.2 シミュレーター実行
1. ターゲットデバイスを選択（例: iPhone 15 Pro）
2. **Product** → **Run** (⌘R)
3. アプリが起動することを確認

---

## Step 7: Git設定

### 7.1 .gitignoreファイル作成
`/Users/makotobaba/Desktop/KPOPVOTE/ios/` ディレクトリに `.gitignore` を作成：

```gitignore
# Xcode
*.xcodeproj/*
!*.xcodeproj/project.pbxproj
!*.xcodeproj/xcshareddata/
!*.xcworkspace/contents.xcworkspacedata
xcuserdata/
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# CocoaPods
Pods/

# Carthage
Carthage/Build/

# fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Firebase
GoogleService-Info.plist

# Swift Package Manager
.swiftpm/
.build/

# macOS
.DS_Store
```

---

## トラブルシューティング

### Q: Firebase SDKの追加でエラーが出る
**A**: Xcode を再起動してから再度試してください。

### Q: GoogleService-Info.plist が見つからない
**A**: Firebase Console で iOS アプリを追加し直してください。

### Q: ビルドエラーが出る
**A**:
1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Xcode を再起動
3. 再度ビルド

---

## 次のステップ

セットアップが完了したら：
1. **認証機能の実装** に進む
2. **Models** と **Services** の実装
3. **UI画面** の作成

---

**更新日**: 2025-11-12
