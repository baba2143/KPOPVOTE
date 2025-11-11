# Git ブランチ戦略

## ブランチ構造

```
main (production)
  ├─ develop (development)
  │   ├─ feature/phase0-week2-tasks
  │   ├─ feature/phase0plus-admin
  │   └─ feature/phase1-ios
  └─ release/v0.1.0
```

## ブランチ種類

### 永続ブランチ
- **main**: 本番環境デプロイ済みの安定版
  - デプロイ済みのコードのみ
  - 直接コミット禁止
  - タグ付けで各バージョン管理

- **develop**: 開発統合ブランチ
  - 次のリリース準備用
  - feature ブランチのマージ先
  - リリース前の統合テスト環境

### 一時ブランチ

#### Feature ブランチ
**命名規則**: `feature/[phase]-[description]`

例:
- `feature/phase0-week2-tasks` - Phase 0 Week 2 タスク管理API
- `feature/phase0plus-admin` - Phase 0+ 管理画面
- `feature/phase1-ios` - Phase 1 iOSアプリ

**ワークフロー**:
```bash
# 新機能開始
git checkout develop
git pull origin develop
git checkout -b feature/phase0-week2-tasks

# 作業中のコミット
git add .
git commit -m "feat: タスク登録API実装"

# 完了後、develop にマージ
git checkout develop
git merge feature/phase0-week2-tasks
git push origin develop
```

#### Release ブランチ
**命名規則**: `release/v[version]`

例:
- `release/v0.1.0` - Phase 0 リリース
- `release/v0.2.0` - Phase 0+ リリース
- `release/v1.0.0` - Phase 1 リリース

**ワークフロー**:
```bash
# リリース準備開始
git checkout develop
git checkout -b release/v0.1.0

# バージョン番号更新、ドキュメント整備
git commit -m "chore: prepare release v0.1.0"

# main にマージしてタグ付け
git checkout main
git merge release/v0.1.0
git tag -a v0.1.0 -m "Phase 0 バックエンド基盤リリース"
git push origin main --tags

# develop にもマージ
git checkout develop
git merge release/v0.1.0
```

#### Hotfix ブランチ
**命名規則**: `hotfix/[description]`

例:
- `hotfix/auth-token-expiry` - 認証トークン有効期限修正
- `hotfix/firestore-rules` - セキュリティルール緊急修正

**ワークフロー**:
```bash
# 本番の緊急修正
git checkout main
git checkout -b hotfix/auth-token-expiry

# 修正作業
git commit -m "fix: 認証トークン有効期限を24時間に延長"

# main と develop 両方にマージ
git checkout main
git merge hotfix/auth-token-expiry
git tag -a v0.1.1 -m "Hotfix: 認証トークン有効期限修正"

git checkout develop
git merge hotfix/auth-token-expiry
```

## バージョニング戦略

### セマンティックバージョニング: `MAJOR.MINOR.PATCH`

- **MAJOR (v1.0.0)**: Phase完了、メジャーリリース
  - v1.0.0: Phase 1 完了（iOSアプリ）

- **MINOR (v0.1.0)**: Phase内の大きな機能追加
  - v0.1.0: Phase 0 完了（バックエンド基盤）
  - v0.2.0: Phase 0+ 完了（Web管理画面）

- **PATCH (v0.1.1)**: バグ修正、小規模改善
  - v0.1.1: Phase 0 の軽微な修正

## コミットメッセージ規約

### Conventional Commits

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type
- **feat**: 新機能
- **fix**: バグ修正
- **docs**: ドキュメント変更
- **style**: コードスタイル（機能に影響なし）
- **refactor**: リファクタリング
- **test**: テスト追加・修正
- **chore**: ビルドプロセス、補助ツール変更

### 例

```
feat(auth): ユーザー登録API実装

POST /register エンドポイントを追加
- Firebase Authentication連携
- Firestoreにユーザープロフィール作成
- バリデーション機能実装

Closes #123
```

```
fix(firestore): セキュリティルールの認証チェック修正

未認証ユーザーがアクセスできる問題を修正
- isAuthenticated() 関数の条件を強化
- テストケース追加

Fixes #456
```

## Phase別ブランチ戦略

### Phase 0 (現在)
```
main (v0.0.0)
  └─ develop
      └─ feature/phase0-week2-tasks (進行中)
```

### Phase 0 完了時
```
main (v0.1.0)
  └─ develop
      └─ feature/phase0plus-admin (次フェーズ)
```

### Phase 1 開始時
```
main (v0.2.0)
  └─ develop
      ├─ feature/phase1-ios-mvvm
      ├─ feature/phase1-social-auth
      └─ feature/phase1-push-notification
```

## マージ戦略

### Feature → Develop
- **マージ方法**: Squash merge（履歴を整理）
- **タイミング**: 機能完成時
- **条件**: ビルド成功、テスト合格

### Develop → Main
- **マージ方法**: Merge commit（履歴を保持）
- **タイミング**: Phase完了時
- **条件**: 完全な統合テスト合格

### Hotfix → Main/Develop
- **マージ方法**: Merge commit
- **タイミング**: 緊急修正完了時
- **条件**: 最小限のテスト確認

## 推奨ワークフロー

### 日常開発
```bash
# 1. 最新のdevelopを取得
git checkout develop
git pull origin develop

# 2. featureブランチ作成
git checkout -b feature/phase0-week2-tasks

# 3. 実装とコミット（こまめに）
git add .
git commit -m "feat(task): タスク登録API実装"

# 4. 定期的にdevelopと同期
git fetch origin develop
git rebase origin/develop

# 5. 完成後プッシュ
git push origin feature/phase0-week2-tasks

# 6. GitHub でPull Request作成
# 7. レビュー後、developにマージ
```

### リリース準備
```bash
# 1. リリースブランチ作成
git checkout develop
git checkout -b release/v0.1.0

# 2. バージョン更新
# package.json, README.md などを更新

# 3. 最終確認とコミット
git commit -m "chore: prepare release v0.1.0"

# 4. mainにマージしてタグ
git checkout main
git merge release/v0.1.0
git tag -a v0.1.0 -m "Phase 0 バックエンド基盤リリース"
git push origin main --tags

# 5. developに反映
git checkout develop
git merge release/v0.1.0
```

---

**最終更新**: 2025-11-11
**現在のフェーズ**: Phase 0 Week 1 完了 → Week 2 開始
