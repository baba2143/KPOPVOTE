# 🔥 Firebase iOS アプリ設定ガイド

## 概要
このガイドでは、Firebase Console で iOS アプリを登録し、`GoogleService-Info.plist` を取得する手順を説明します。

---

## Step 1: Firebase Console にアクセス

### 1.1 Firebase Console を開く
```
https://console.firebase.google.com/
```

### 1.2 プロジェクトを選択
- **kpopvote-9de2b** プロジェクトを選択

---

## Step 2: iOS アプリを追加

### 2.1 アプリ追加画面に移動
1. Firebase Console のホーム画面で **歯車アイコン** (⚙️) をクリック
2. **プロジェクトの設定** を選択
3. **全般** タブを選択
4. **マイアプリ** セクションまでスクロール
5. **アプリを追加** ボタンをクリック
6. **iOS** アイコンを選択

### 2.2 iOS バンドル ID を登録
以下の情報を入力：

| 項目 | 値 |
|------|-----|
| **Apple バンドル ID** | `com.kpopvote.collector` |
| **アプリのニックネーム（オプション）** | `K-VOTE COLLECTOR iOS` |
| **App Store ID（オプション）** | 空欄（後で追加可能） |

**次へ** をクリック

---

## Step 3: GoogleService-Info.plist をダウンロード

### 3.1 設定ファイルをダウンロード
1. **GoogleService-Info.plist をダウンロード** ボタンをクリック
2. ファイルを保存（デフォルトは `~/Downloads/`）
3. **次へ** をクリック

### 3.2 ファイル内容確認
ダウンロードした `GoogleService-Info.plist` には以下の情報が含まれています：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CLIENT_ID</key>
    <string>[YOUR_CLIENT_ID].apps.googleusercontent.com</string>
    <key>REVERSED_CLIENT_ID</key>
    <string>com.googleusercontent.apps.[YOUR_CLIENT_ID]</string>
    <key>API_KEY</key>
    <string>[YOUR_API_KEY]</string>
    <key>GCM_SENDER_ID</key>
    <string>[YOUR_SENDER_ID]</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>com.kpopvote.collector</string>
    <key>PROJECT_ID</key>
    <string>kpopvote-9de2b</string>
    <key>STORAGE_BUCKET</key>
    <string>kpopvote-9de2b.appspot.com</string>
    <key>IS_ADS_ENABLED</key>
    <false/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
    <key>IS_APPINVITE_ENABLED</key>
    <true/>
    <key>IS_GCM_ENABLED</key>
    <true/>
    <key>IS_SIGNIN_ENABLED</key>
    <true/>
    <key>GOOGLE_APP_ID</key>
    <string>[YOUR_GOOGLE_APP_ID]</string>
</dict>
</plist>
```

---

## Step 4: Firebase SDK を追加（省略可）

Firebase Console の指示に従って：
1. **SDK の追加** 画面が表示されますが、**これは SETUP_GUIDE.md で既に説明済み**
2. **次へ** をクリック
3. **初期化コードを追加** 画面も **SETUP_GUIDE.md で説明済み**
4. **次へ** をクリック
5. **コンソールに進む** をクリック

---

## Step 5: Xcode プロジェクトに追加

### 5.1 GoogleService-Info.plist を配置
1. Finder でダウンロードした `GoogleService-Info.plist` を見つける
2. Xcode を開き、プロジェクトナビゲーター（左側パネル）を表示
3. `GoogleService-Info.plist` を Xcode プロジェクトの **ルート** にドラッグ&ドロップ

### 5.2 ファイル追加オプション
ダイアログが表示されるので、以下を確認：

- ✅ **Copy items if needed** （必ずチェック）
- ✅ **Add to targets: KPOPVOTE** （必ずチェック）
- **Create groups** （ラジオボタン選択）
- **Finish** をクリック

### 5.3 配置確認
プロジェクトナビゲーターで以下のように表示されることを確認：

```
KPOPVOTE/
├── App/
│   ├── KPOPVOTEApp.swift
│   └── ContentView.swift
├── Assets.xcassets
├── GoogleService-Info.plist ← ここに配置されていること
└── Info.plist
```

---

## Step 6: 設定検証

### 6.1 ビルドテスト
1. **Product** → **Build** (⌘B)
2. エラーがないことを確認

### 6.2 Firebase 初期化確認
`KPOPVOTEApp.swift` に以下のコードが含まれていることを確認：

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

### 6.3 実行テスト
1. **Product** → **Run** (⌘R)
2. シミュレーターでアプリが起動
3. Xcode コンソールで Firebase 初期化ログを確認：

```
[Firebase/Core][I-COR000003] The default Firebase app has not yet been configured...
[Firebase/Core][I-COR000001] Firebase App initialized successfully.
```

---

## トラブルシューティング

### Q: GoogleService-Info.plist が見つからないエラー
**A**:
1. ファイルが Xcode プロジェクトのルートにあるか確認
2. **Copy items if needed** がチェックされているか確認
3. **Add to targets** で KPOPVOTE がチェックされているか確認

### Q: ビルドエラー「FirebaseCore module not found」
**A**:
1. Xcode を再起動
2. **File** → **Packages** → **Reset Package Caches**
3. **Product** → **Clean Build Folder** (⇧⌘K)
4. 再度ビルド

### Q: Firebase 初期化エラー
**A**:
1. `GoogleService-Info.plist` のバンドル ID が `com.kpopvote.collector` であることを確認
2. PROJECT_ID が `kpopvote-9de2b` であることを確認
3. ファイルが正しくコピーされているか確認

---

## 次のステップ

Firebase 設定が完了したら：
1. **認証機能の実装** → `SETUP_GUIDE.md` Week 3-4
2. **Firestore 統合** → データベース接続
3. **Storage 統合** → 画像アップロード機能

---

**作成日**: 2025-11-12
**更新日**: 2025-11-12
**Firebase プロジェクト**: kpopvote-9de2b
**バンドル ID**: com.kpopvote.collector
