# K-VOTE COLLECTOR 開発コマンド

## プロジェクト状態

⚠️ **現在**: Phase 0（企画・設計段階）  
📝 実装コードはまだ存在しません

## タスク管理コマンド

### タスク一括作成
```bash
cd /Users/makotobaba/Desktop/KPOPVOTE
./sc-task-commands.sh
```

Phase 0の全タスク（8タスク）を一括作成します。

### タスク管理
```bash
/sc:task list              # タスク一覧表示
/sc:task create "タスク名"  # 新規タスク作成
/sc:task update "タスクID"  # タスク更新
```

## プロジェクトドキュメント

### 主要ドキュメント確認
```bash
# プロジェクト概要
open "KPOP VOTE.md"

# データベース設計
open "DBスキーマ設計案.txt"

# 開発計画
open "初期バックエンド開発指示書.txt"

# タスク管理計画
open "タスク管理計画.md"

# UI設計
open "アプリUIイメージ.png"
```

## Phase 0開始時のセットアップ（予定）

### Firebase環境構築
```bash
# Firebase CLI インストール（未実施）
npm install -g firebase-tools

# Firebaseログイン
firebase login

# プロジェクト初期化
firebase init

# Functions選択時
cd functions
npm install
```

### Cloud Functions開発
```bash
# Functions デプロイ
firebase deploy --only functions

# 特定の関数のみデプロイ
firebase deploy --only functions:functionName

# Functions ログ確認
firebase functions:log

# ローカルエミュレーター起動
firebase emulators:start
```

### Firestore管理
```bash
# Firestore ルールデプロイ
firebase deploy --only firestore:rules

# Firestore インデックスデプロイ
firebase deploy --only firestore:indexes
```

## Phase 1開始時のセットアップ（予定）

### iOS開発環境
```bash
# CocoaPods初期化
cd ios
pod init

# 依存関係インストール
pod install

# Xcodeプロジェクト開く
open KVoteCollector.xcworkspace
```

### Xcode ビルド・実行
```bash
# シミュレーターでビルド
xcodebuild -workspace KVoteCollector.xcworkspace \
           -scheme KVoteCollector \
           -destination 'platform=iOS Simulator,name=iPhone 15'

# テスト実行
xcodebuild test -workspace KVoteCollector.xcworkspace \
                -scheme KVoteCollector \
                -destination 'platform=iOS Simulator,name=iPhone 15'
```

## バージョン管理

### Git基本操作
```bash
# 状態確認
git status

# ブランチ作成
git checkout -b feature/task-name

# コミット
git add .
git commit -m "feat: 機能説明"

# プッシュ
git push origin feature/task-name
```

### Git推奨フロー
1. Phase 0用ブランチ: `feature/phase0-*`
2. Phase 1用ブランチ: `feature/phase1-*`
3. バグ修正: `fix/bug-description`

## システムコマンド（macOS）

### ファイル操作
```bash
ls -la                    # ファイル一覧（詳細）
cd [ディレクトリ]          # ディレクトリ移動
pwd                       # 現在のディレクトリ表示
mkdir [ディレクトリ名]     # ディレクトリ作成
rm [ファイル名]           # ファイル削除
```

### 検索
```bash
find . -name "*.js"       # JavaScript ファイル検索
grep -r "検索文字列" .    # テキスト検索
```

### プロセス管理
```bash
ps aux | grep node        # Node.js プロセス確認
kill -9 [PID]            # プロセス強制終了
```

## 開発フェーズ別チェックリスト

### Phase 0完了条件
- [ ] Firebase環境設定完了
- [ ] 認証API実装・動作確認
- [ ] 推し設定API実装・動作確認
- [ ] タスク管理API実装・動作確認
- [ ] OGP取得プロトタイプ実装・評価
- [ ] APIドキュメント作成

### Phase 1完了条件
- [ ] iOS プロジェクト初期化
- [ ] Firebase SDK 統合
- [ ] 基本UI実装（ホーム・タスク一覧・登録）
- [ ] API連携実装
- [ ] テスト実装・合格
- [ ] App Store 提出準備

## トラブルシューティング

### Firebase関連
```bash
# Firebase 認証状態確認
firebase projects:list

# エミュレーター再起動
firebase emulators:start --only firestore,functions

# キャッシュクリア
rm -rf node_modules .firebase
npm install
```

### iOS関連
```bash
# CocoaPods キャッシュクリア
pod cache clean --all
pod deintegrate
pod install

# DerivedData 削除
rm -rf ~/Library/Developer/Xcode/DerivedData

# シミュレーター リセット
xcrun simctl erase all
```

## 参考リンク

- [Firebase Documentation](https://firebase.google.com/docs)
- [Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Documentation](https://docs.swift.org/swift-book/)

## ワークフロー管理

### 実装ワークフロー確認
```bash
# 全体ワークフロー
open implementation_workflow.md

# Phase 0ワークフロー（バックエンド）
open phase0_workflow.md

# Phase 0+ワークフロー（管理画面）
open phase0plus_workflow.md

# Phase 1ワークフロー（iOS）
open phase1_workflow.md
```

### ワークフロー実行
```bash
# Phase 0開始
# Day 1: Firebase環境構築
firebase init

# Day 3: 認証API開発開始
cd functions && npm install

# Week 2: タスク管理API開発
# （phase0_workflow.mdを参照）

# Phase 0+開始（管理画面）
npx create-react-app admin --template typescript

# Phase 1開始（iOS）
# Xcodeで新規プロジェクト作成
```

## 次のステップ

1. **今すぐできること**:
   - タスク作成: `./sc-task-commands.sh`
   - ワークフロー確認: `open implementation_workflow.md`
   - ドキュメント確認・レビュー

2. **Phase 0開始時**:
   - Firebase環境構築
   - Cloud Functions開発環境セットアップ
   - 認証API実装

3. **Phase 1開始時**:
   - iOS開発環境構築
   - Xcodeプロジェクト作成
   - SwiftUI基本画面実装
