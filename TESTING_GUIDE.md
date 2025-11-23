# マルチポイントシステム テストガイド

## 📋 テスト準備

### 1. rewardSettings初期化（本番環境）

Firebaseコンソールから直接データを投入する方法：

**手順**:
1. Firebase Console → Firestore Database を開く
2. `rewardSettings` コレクションを作成（存在しない場合）
3. 以下の8つのドキュメントを追加：

#### ドキュメント一覧

| ドキュメントID | basePoints | description | isActive |
|---|---|---|---|
| `task_completion` | 50 | 外部投票タスク完了 | true |
| `daily_login_base` | 10 | デイリーログイン基本報酬 | true |
| `daily_login_streak_7` | 5 | 7日連続ログインボーナス | true |
| `daily_login_streak_14` | 10 | 14日連続ログインボーナス | true |
| `daily_login_streak_30` | 20 | 30日連続ログインボーナス | true |
| `community_post` | 5 | 投稿作成報酬 | true |
| `community_like` | 1 | いいね獲得報酬 | true |
| `community_comment` | 2 | コメント投稿報酬 | true |

各ドキュメントに `updatedAt: Timestamp(現在時刻)` も追加してください。

---

## 🧪 テストシナリオ

### Phase 1: 投票システムテスト（executeVote）

#### 準備
1. `inAppVotes` コレクションにテスト投票を作成：
```json
{
  "id": "test_vote_001",
  "title": "テスト投票",
  "requiredPoints": 10,
  "status": "active",
  "choices": [
    {"choiceId": "choice1", "label": "選択肢1", "voteCount": 0},
    {"choiceId": "choice2", "label": "選択肢2", "voteCount": 0}
  ]
}
```

2. テストユーザーにポイント付与：
```
users/{userId}
  premiumPoints: 100
  regularPoints: 500
  isPremium: false (または true)
```

#### テストケース1: 赤ポイントのみで投票

**条件**:
- isPremium: true
- premiumPoints: 100
- requiredPoints: 10
- pointSelection: "premium"

**期待結果**:
- premiumPoints: 100 → 90 (-10P)
- regularPoints: 変化なし
- voteRecords作成: `premiumPointsUsed: 10, regularPointsUsed: 0`
- pointTransactions作成: `pointType: "premium", points: -10`

**実行方法**:
```bash
curl -X POST "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/executeVote" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "voteId": "test_vote_001",
    "choiceId": "choice1",
    "voteCount": 1,
    "pointSelection": "premium"
  }'
```

#### テストケース2: 青ポイントのみで投票（非会員=5倍レート）

**条件**:
- isPremium: false
- regularPoints: 500
- requiredPoints: 10
- pointSelection: "regular"

**期待結果**:
- premiumPoints: 変化なし
- regularPoints: 500 → 450 (-50P = 10P × 5倍)
- voteRecords作成: `premiumPointsUsed: 0, regularPointsUsed: 50`

#### テストケース3: 自動選択（赤優先→青補完）

**条件**:
- isPremium: false
- premiumPoints: 5
- regularPoints: 500
- requiredPoints: 10
- pointSelection: "auto"

**期待結果**:
- premiumPoints: 5 → 0 (-5P)
- regularPoints: 500 → 475 (-25P = (10-5)P × 5倍)
- voteRecords作成: `premiumPointsUsed: 5, regularPointsUsed: 25`

#### テストケース4: 複数票投票

**条件**:
- voteCount: 3
- requiredPoints: 10
- pointSelection: "premium"

**期待結果**:
- premiumPoints: 100 → 70 (-30P = 10P × 3票)
- choices[0].voteCount: 0 → 3

#### テストケース5: ポイント不足エラー

**条件**:
- premiumPoints: 5
- requiredPoints: 10
- pointSelection: "premium"

**期待結果**:
- HTTP 400エラー
- エラーメッセージ: "赤ポイントが不足しています"

---

### Phase 2: タスク完了報酬テスト（updateTaskStatus）

#### テストケース1: 非会員ユーザーのタスク完了

**準備**:
```
users/{userId}
  isPremium: false
  regularPoints: 0

users/{userId}/tasks/{taskId}
  isCompleted: false
```

**実行**:
```bash
curl -X PATCH "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/updateTaskStatus" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "taskId": "task_001",
    "isCompleted": true
  }'
```

**期待結果**:
- regularPoints: 0 → 50 (+50P)
- pointTransactions作成: `pointType: "regular", points: 50, type: "task_completion"`

#### テストケース2: 会員ユーザーのタスク完了

**条件**:
- isPremium: true

**期待結果**:
- premiumPoints: 0 → 50 (+50P)
- pointType: "premium"

---

### Phase 3: コミュニティ報酬テスト

#### 3-1: 投稿作成報酬（createPost）

**実行**:
```bash
curl -X POST "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/createPost" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "type": "image",
    "content": {"text": "テスト投稿", "images": ["https://example.com/image.jpg"]},
    "biasIds": ["bias_001"]
  }'
```

**期待結果**:
- isPremium=true → premiumPoints +5P
- isPremium=false → regularPoints +5P
- pointTransactions作成: `type: "community_post"`

#### 3-2: いいね報酬（likePost）

**重要**: 報酬は投稿者に付与されます（いいねした人ではない）

**実行**:
```bash
curl -X POST "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/likePost" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "postId": "post_001"
  }'
```

**期待結果**:
- **投稿者**のポイント +1P（投稿者のisPremiumに応じて赤/青）
- pointTransactions作成: `type: "community_like"`

#### 3-3: コメント報酬（createComment）

**重要**: 報酬は投稿者に付与されます（コメントした人ではない）

**実行**:
```bash
curl -X POST "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/createComment" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "postId": "post_001",
    "text": "テストコメント"
  }'
```

**期待結果**:
- **投稿者**のポイント +2P
- pointTransactions作成: `type: "community_comment"`

---

### Phase 4: デイリーログインテスト（dailyLogin）

#### テストケース1: 初回ログイン

**準備**:
```
users/{userId}
  lastLoginDate: null
  loginStreak: 0
```

**実行**:
```bash
curl -X POST "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/dailyLogin" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN"
```

**期待結果**:
- ポイント +10P（基本報酬のみ）
- loginStreak: 1
- lastLoginDate: 今日の日付

#### テストケース2: 7日連続ログイン

**準備**:
```
users/{userId}
  lastLoginDate: 昨日の日付
  loginStreak: 6
```

**期待結果**:
- ポイント +15P（基本10P + 7日ボーナス5P）
- loginStreak: 7

#### テストケース3: 14日連続ログイン

**準備**:
- loginStreak: 13

**期待結果**:
- ポイント +20P（基本10P + 14日ボーナス10P）

#### テストケース4: 30日連続ログイン

**準備**:
- loginStreak: 29

**期待結果**:
- ポイント +30P（基本10P + 30日ボーナス20P）

#### テストケース5: 同日再ログイン

**準備**:
- lastLoginDate: 今日の日付（すでにログイン済み）

**期待結果**:
- ポイント付与なし（+0P）
- レスポンス: `isFirstTimeToday: false`

---

### Phase 5: 統合テスト

#### 5-1: マルチポイント残高確認

**シナリオ**: 会員ユーザーが各種活動を行う

1. 投稿作成 → premiumPoints +5P
2. タスク完了 → premiumPoints +50P
3. デイリーログイン → premiumPoints +10P
4. 合計 → premiumPoints: +65P

**確認**:
- Firestore `users/{userId}` で `premiumPoints` が正しく累積
- `pointTransactions` に3件のトランザクション記録

#### 5-2: 会員/非会員切り替え

**シナリオ**:
1. isPremium: false で投稿作成 → regularPoints +5P
2. isPremium: true に変更（サブスク課金）
3. タスク完了 → premiumPoints +50P

**確認**:
- 各ポイントが独立して管理されている
- 過去のregularPointsは保持されている

---

### Phase 6: 動的報酬設定テスト

#### テストケース1: 報酬ポイント変更

**手順**:
1. Firestore Console → `rewardSettings/task_completion`
2. `basePoints: 50` → `basePoints: 100` に変更
3. タスク完了を実行

**期待結果**:
- ポイント +100P（変更後の値が適用される）

#### テストケース2: 報酬無効化

**手順**:
1. `rewardSettings/community_post` の `isActive: true` → `false`
2. 投稿作成を実行

**期待結果**:
- ポイント付与なし（+0P）
- ログ: "Reward is inactive: community_post"

---

## 📊 検証チェックリスト

### ポイント計算
- [ ] 赤ポイント: 会員のみ獲得、1P=1票
- [ ] 青ポイント: 全員獲得、非会員5P=1票、会員1P=1票
- [ ] 自動選択: 赤優先→青補完の順序

### トランザクション記録
- [ ] pointTransactionsに全取引が記録
- [ ] pointType（premium/regular）が正しく記録
- [ ] 報酬/消費の両方が記録される

### エラーハンドリング
- [ ] ポイント不足時の適切なエラーメッセージ
- [ ] 無効な投票への投票拒否
- [ ] 重複投票防止

### 動的設定
- [ ] rewardSettings変更が即座に反映
- [ ] isActive=falseで報酬停止
- [ ] 設定不在時のデフォルト値使用

---

## 🐛 トラブルシューティング

### ポイントが付与されない
1. Cloud Functions のログを確認: Firebase Console → Functions → Logs
2. `rewardSettings` の `isActive` を確認
3. `basePoints` が0でないか確認

### 計算が合わない
1. `voteRecords` の `premiumPointsUsed` / `regularPointsUsed` を確認
2. `memberMultiplier` が正しく適用されているか確認（非会員=5倍）
3. `pointTransactions` の合計と残高を照合

### 報酬設定が反映されない
1. rewardSettings の更新が完了しているか確認
2. Cloud Functions が最新版にデプロイされているか確認
3. キャッシュの可能性（Firebase再起動）

---

## 📝 テスト記録テンプレート

```markdown
### テスト実行日: YYYY-MM-DD

#### 投票システム
- [ ] ケース1: 赤ポイントのみ
- [ ] ケース2: 青ポイントのみ
- [ ] ケース3: 自動選択
- [ ] ケース4: 複数票
- [ ] ケース5: ポイント不足

#### 報酬システム
- [ ] タスク完了報酬（会員/非会員）
- [ ] 投稿作成報酬
- [ ] いいね報酬
- [ ] コメント報酬

#### デイリーログイン
- [ ] 初回ログイン
- [ ] 7日連続
- [ ] 14日連続
- [ ] 30日連続

#### 動的設定
- [ ] 報酬ポイント変更
- [ ] 報酬無効化

**発見された問題**:
-

**改善点**:
-
```
