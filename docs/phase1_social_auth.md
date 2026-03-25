# Phase 1: ソーシャルログイン実装メモ

## 概要

Phase 0ではメール/パスワード認証のみを実装。
Phase 1（iOS開発時）に以下のソーシャルログインプロバイダーを追加予定。

## 実装予定プロバイダー

### 1. Google Sign-In
- **難易度**: ⭐️（最も簡単）
- **必要な設定**:
  - Firebase Console で Google プロバイダー有効化
  - OAuth 2.0 クライアントID設定（iOS/Android/Web）
- **iOS実装**: `GoogleSignIn` SDK使用
- **メリット**: 設定が簡単、広く使われている

### 2. Apple Sign-In
- **難易度**: ⭐️⭐️
- **必要な設定**:
  - Apple Developer Program登録必須
  - Sign in with Apple 機能有効化
  - Service ID, Key ID, Team ID設定
- **iOS実装**: `AuthenticationServices` フレームワーク使用
- **メリット**: iOS必須要件、プライバシー重視
- **注意**: iOS 13以上必須、Appleアカウント必須

### 3. LINE Login
- **難易度**: ⭐️⭐️⭐️
- **必要な設定**:
  - LINE Developers コンソールでチャネル作成
  - Firebase カスタム認証統合
  - LINE SDK統合
- **iOS実装**: `LineSDK` 使用
- **メリット**: K-POPファン層に人気、日本/韓国で普及
- **注意**: カスタム認証フロー実装が必要

### 4. Twitter/X Sign-In
- **難易度**: ⭐️⭐️
- **必要な設定**:
  - Twitter Developer Portal でアプリ登録
  - API Key, API Secret取得
  - Firebase Console で Twitter プロバイダー有効化
- **iOS実装**: Firebase Authentication SDK使用
- **メリット**: K-POPファンコミュニティで広く使用
- **注意**: Twitter API利用ポリシー確認

## 実装手順（Phase 1）

### Step 1: Firebase Console 設定
各プロバイダーをFirebase Authenticationで有効化

### Step 2: iOS アプリ実装
SwiftUIでソーシャルログインボタン追加

```swift
// Google Sign-In例
Button("Sign in with Google") {
    // GoogleSignIn SDK使用
}

// Apple Sign-In例
SignInWithAppleButton(.signIn) { request in
    // Apple認証リクエスト
}
```

### Step 3: バックエンド統合
既存の認証ミドルウェアで全プロバイダー対応済み
（Firebase Authentication統合のため追加実装不要）

### Step 4: ユーザープロフィール拡張
Firestoreの`users`コレクションに`authProvider`フィールド追加

```typescript
interface UserProfile {
  // 既存フィールド
  authProvider: 'email' | 'google' | 'apple' | 'line' | 'twitter';
  socialProfiles?: {
    google?: { /* Google profile data */ };
    apple?: { /* Apple profile data */ };
    line?: { /* LINE profile data */ };
    twitter?: { /* Twitter profile data */ };
  };
}
```

## セキュリティ考慮事項

1. **OAuth 2.0 フロー**: 各プロバイダーの推奨フローに従う
2. **トークン管理**: リフレッシュトークンの安全な保存
3. **プライバシー**: Apple Sign-In の匿名メール機能対応
4. **アカウントリンク**: 同一メールの複数プロバイダー対応

## 参考ドキュメント

- [Firebase Authentication - Google](https://firebase.google.com/docs/auth/ios/google-signin)
- [Firebase Authentication - Apple](https://firebase.google.com/docs/auth/ios/apple)
- [LINE Developers](https://developers.line.biz/ja/docs/line-login/)
- [Twitter Developer Platform](https://developer.twitter.com/en/docs/authentication/overview)

## 実装優先度

Phase 1での実装順序：
1. **Google Sign-In** - 最も簡単、広く使われている
2. **Apple Sign-In** - iOS必須要件
3. **LINE Login** - ターゲットユーザー層に人気
4. **Twitter/X** - K-POPコミュニティで重要

---

**更新日**: 2025-11-11
**ステータス**: Phase 0完了後に実装予定
