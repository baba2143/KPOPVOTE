# Community Functions

このディレクトリには、コミュニティ機能（投稿、フォロー、タイムラインなど）の実装が含まれます。

## パフォーマンス要件

実装時は以下のパフォーマンスパターンに従ってください:

### 1. createPost - 投稿作成

**必須パターン**:
- フォロワー通知は**Pub/Sub非同期化**必須
- N+1クエリを避けるため、通知は別のCloud Functionで処理
- レスポンスは投稿作成完了時点で返却（通知完了を待たない）

```typescript
// Good: Pub/Subで非同期通知
await pubsub.topic('new-post-notifications').publishMessage({
  json: { postId, authorId }
});
res.status(200).json({ success: true });

// Bad: 同期的にフォロワー通知
for (const follower of followers) {
  await sendNotification(follower); // レスポンスをブロック
}
```

### 2. getPosts - タイムライン取得

**必須パターン**:
- FirestoreのIN句制限（10件）を考慮
- 10件を超えるフォローがある場合はバッチクエリを使用
- `db.getAll()` でN+1を回避

```typescript
// Good: バッチクエリ
const batches = [];
for (let i = 0; i < followingIds.length; i += 10) {
  batches.push(query.where('userId', 'in', followingIds.slice(i, i + 10)).get());
}
const results = await Promise.all(batches);

// Bad: 単一IN句（11件目以降が無視される）
const posts = await db.collection('posts')
  .where('userId', 'in', followingIds) // 10件制限あり！
  .get();
```

### 3. getFollowingActivity - フォロー中アクティビティ

**必須パターン**:
- N個の並列クエリを避ける
- `userActivity` 集約コレクションを使用
- 定期バッチでアクティビティを事前計算

## ファイル構成

```
community/
├── createPost.ts           # 投稿作成
├── getPosts.ts             # タイムライン取得
├── getFollowingActivity.ts # フォロー中アクティビティ
├── likePost.ts             # いいね
├── followUser.ts           # フォロー
└── README.md               # このファイル
```

## 関連ドキュメント

- [パフォーマンス最適化パターン](/docs/performance/OPTIMIZATION_PATTERNS.md)
