# 📱 Phase 1: iOSアプリ開発ワークフロー

## 概要
**期間**: 3ヶ月（12週間）
**目標**: iOS MVP版のApp Storeリリース
**技術**: Swift, SwiftUI, Firebase SDK
**チーム**: iOSエンジニア × 2-3, QAエンジニア × 1, プロダクトマネージャー × 1

---

## Month 1: 基盤構築と基本機能 (Week 1-4)

### Week 1-2: プロジェクト初期化
**Day 1-3**: Xcodeプロジェクト作成
- SwiftUI プロジェクト初期化
- Firebase SDK統合（CocoaPods/SPM）
- プロジェクト構造設計（MVVM）

**Day 4-10**: 認証画面実装
- ログイン画面（SwiftUI）
- 新規登録画面
- Firebase Authentication統合
- バリデーション実装

**成果物**: 認証機能完成

---

### Week 3-4: ホーム画面・タスク一覧
**Day 11-15**: ホームダッシュボード
- ダッシュボードUI実装
- 緊急タスク表示
- コミュニティ最新投稿表示

**Day 16-20**: タスク一覧画面
- タスク一覧表示（List + ForEach）
- 推しフィルター機能
- ソート機能
- プルトゥリフレッシュ

**成果物**: ホーム・タスク一覧画面

---

## Month 2: コア機能実装 (Week 5-8)

### Week 5-6: タスク登録・詳細
**Day 21-30**: タスク管理機能
- タスク登録フォーム
- URL入力・検証
- OGP画像表示
- タスク詳細画面
- ステータス更新機能

**成果物**: タスク管理機能完成

---

### Week 7-8: プロファイル・推し設定
**Day 31-40**: プロファイル機能
- プロファイル画面
- 推し設定画面（マルチセレクト）
- ポイント表示
- 設定画面

**成果物**: プロファイル機能完成

---

## Month 3: 追加機能・仕上げ (Week 9-12)

### Week 9-10: Votesタブ（Community/Discover）機能 🆕
**Day 41-45**: コレクション発見機能
- Votesタブ画面実装
- トレンドコレクション一覧表示
- 検索機能（タイトル、タグ、クリエイター）
- コレクション詳細画面
- 一括タスク追加機能

**Day 46-50**: マイコレクション作成機能
- マイコレクション画面（作成済み/保存済み）
- コレクション作成フォーム
  - タイトル、説明入力
  - タグ選択（最大10個）
  - タスク選択（自分のタスクから）
  - 公開範囲設定（public/followers/private）
- コレクション保存機能
- コレクション共有機能

**API統合**:
- `GET /api/collections` - コレクション一覧取得
- `GET /api/collections/search` - 検索
- `GET /api/collections/trending` - トレンド取得
- `POST /api/collections` - コレクション作成
- `POST /api/collections/:id/save` - 保存
- `POST /api/collections/:id/add-to-tasks` - 一括タスク追加

**成果物**: Votes/Community/Discover機能完成
**詳細仕様**: `docs/votes-community-feature-spec.md` 参照

---

### Week 11: 通知・最適化
**Day 51-55**: 通知とパフォーマンス
- プッシュ通知実装（FCM）
- パフォーマンス最適化
- メモリリーク修正
- アクセシビリティ対応

**成果物**: 通知・最適化完了

---

### Week 12: テスト・リリース準備
**Day 56-60**: リリース準備
- 統合テスト実施
- ベータテスト（TestFlight）
- バグ修正
- App Store申請準備
  - スクリーンショット作成
  - アプリ説明文作成
  - プライバシーポリシー
- App Store申請

**成果物**: App Store申請完了

---

## 完了基準
- [ ] 全画面実装完了
- [ ] API連携動作確認
- [ ] ユニット・UIテスト合格
- [ ] App Store審査合格
- [ ] iOS MVP リリース

---

## 主要コンポーネント構成

```
KVoteCollector/
├── App/
│   └── KVoteCollectorApp.swift
├── Models/
│   ├── User.swift
│   ├── Task.swift
│   ├── VoteCollection.swift         # 🆕 コレクションモデル
│   ├── CommunityPost.swift
│   └── Vote.swift
├── Views/
│   ├── Auth/
│   ├── Home/
│   ├── Votes/                       # 🆕 Votesタブ
│   │   ├── VotesListView.swift     # コレクション一覧
│   │   ├── CollectionDetailView.swift
│   │   ├── CreateCollectionView.swift
│   │   └── MyCollectionsView.swift
│   ├── Tasks/
│   ├── Community/
│   └── Profile/
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── TaskViewModel.swift
│   ├── CollectionViewModel.swift    # 🆕 コレクション管理
│   └── UserViewModel.swift
└── Services/
    ├── FirebaseService.swift
    ├── AuthService.swift
    ├── TaskService.swift
    └── CollectionService.swift      # 🆕 コレクションAPI
```

---

## API統合チェックリスト

### 認証・ユーザー管理
- [ ] `/auth/register` - ユーザー登録
- [ ] `/auth/login` - ログイン
- [ ] `/user/setBias` - 推し設定
- [ ] `/user/getBias` - 推し取得

### タスク管理
- [ ] `/task/register` - タスク登録
- [ ] `/task/getUserTasks` - タスク取得
- [ ] `/task/fetchOGP` - OGP取得
- [ ] `/task/updateStatus` - ステータス更新

### コレクション管理 🆕
- [ ] `GET /api/collections` - コレクション一覧取得
- [ ] `GET /api/collections/search` - 検索
- [ ] `GET /api/collections/trending` - トレンド取得
- [ ] `GET /api/collections/:id` - 詳細取得
- [ ] `POST /api/collections` - 作成
- [ ] `PUT /api/collections/:id` - 更新
- [ ] `DELETE /api/collections/:id` - 削除
- [ ] `POST /api/collections/:id/save` - 保存
- [ ] `POST /api/collections/:id/add-to-tasks` - 一括タスク追加

---

**最終更新**: 2025-01-13
**作成者**: Claude Code
**バージョン**: 1.0
