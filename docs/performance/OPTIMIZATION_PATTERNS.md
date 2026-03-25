# パフォーマンス最適化パターン

## 調査結果サマリー（2026-02-19）

このドキュメントは、KPOPVOTE パフォーマンス調査で特定された問題と推奨される解決パターンをまとめたものです。

---

## Tier 1: Critical - 即座に対応すべき問題

### 1. フォロワー通知のN+1パターン（createPost.ts）

**問題**: フォロワー1000人 → 1000回のDB読み取り + 1000回のFCM呼び出し

**解決策**: Pub/Sub非同期化

```typescript
// Before (BAD)
async function notifyFollowers(postId: string, authorId: string) {
  const followers = await db.collection('follows')
    .where('followingId', '==', authorId).get();

  // N+1: 各フォロワーの通知設定を個別取得
  for (const follower of followers.docs) {
    const settings = await db.collection('users')
      .doc(follower.data().followerId)
      .get(); // ← N回のDB読み取り

    if (settings.data()?.notificationsEnabled) {
      await sendFCM(follower.data().followerId, ...); // ← N回のFCM
    }
  }
}

// After (GOOD) - Pub/Subで非同期化
// createPost.ts
import { PubSub } from "@google-cloud/pubsub";
const pubsub = new PubSub();

async function createPost(req, res) {
  // ... 投稿作成処理 ...

  // 通知はPub/Subで非同期処理（レスポンスをブロックしない）
  const topic = pubsub.topic('new-post-notifications');
  await topic.publishMessage({
    json: { postId, authorId, postTitle }
  });

  res.status(200).json({ success: true, data: post });
}

// notifyNewPostSubscriber.ts (別のCloud Function)
export const notifyNewPostSubscriber = functions.pubsub
  .topic('new-post-notifications')
  .onPublish(async (message) => {
    const { postId, authorId } = message.json;

    // バッチ処理で効率化
    const followers = await db.collection('follows')
      .where('followingId', '==', authorId).get();

    const followerIds = followers.docs.map(d => d.data().followerId);

    // db.getAll でバッチ取得
    const userRefs = followerIds.map(id => db.collection('users').doc(id));
    const userDocs = await db.getAll(...userRefs);

    const enabledUsers = userDocs
      .filter(doc => doc.exists && doc.data()?.notificationsEnabled)
      .map(doc => doc.id);

    // FCMもバッチ送信（最大500件/バッチ）
    const tokens = await getTokensForUsers(enabledUsers);
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title: 'New Post', body: '...' }
    });
  });
```

### 2. フォロー中タイムラインの10件制限（getPosts.ts）

**問題**: FirestoreのIN句制限（10件）により、11人目以降の投稿が表示されない

**解決策**: バッチクエリまたはユーザーフィード非正規化

```typescript
// Solution A: バッチクエリ（小〜中規模向け）
async function getFollowingPosts(userId: string, limit: number) {
  const follows = await db.collection('follows')
    .where('followerId', '==', userId).get();

  const followingIds = follows.docs.map(d => d.data().followingId);

  if (followingIds.length === 0) return [];

  // 10件ずつのバッチでクエリ実行
  const batches = [];
  for (let i = 0; i < followingIds.length; i += 10) {
    const batch = followingIds.slice(i, i + 10);
    batches.push(
      db.collection('posts')
        .where('userId', 'in', batch)
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get()
    );
  }

  const results = await Promise.all(batches);

  // メモリ内でマージ＆ソート
  const allPosts = results
    .flatMap(snap => snap.docs)
    .sort((a, b) => b.data().createdAt.toMillis() - a.data().createdAt.toMillis())
    .slice(0, limit);

  return allPosts;
}

// Solution B: ユーザーフィード非正規化（大規模向け）
// 投稿作成時にフォロワーのフィードにも書き込む
async function createPost(authorId: string, postData: any) {
  const postRef = db.collection('posts').doc();
  const batch = db.batch();

  batch.set(postRef, postData);

  // フォロワーのフィードに書き込み（ファンアウト）
  const followers = await db.collection('follows')
    .where('followingId', '==', authorId).get();

  for (const follower of followers.docs) {
    const feedRef = db.collection('userFeeds')
      .doc(follower.data().followerId)
      .collection('posts')
      .doc(postRef.id);

    batch.set(feedRef, {
      postId: postRef.id,
      authorId,
      createdAt: postData.createdAt,
    });
  }

  await batch.commit();
}
```

### 3. フォローアクティビティのN並列クエリ（getFollowingActivity.ts）

**問題**: 100人フォロー → 100個のFirestoreクエリ

**解決策**: 集約コレクション + 定期更新

```typescript
// Before (BAD)
async function getFollowingActivity(userId: string) {
  const follows = await db.collection('follows')
    .where('followerId', '==', userId).get();

  // N個の並列クエリ（非常に高コスト）
  const activities = await Promise.all(
    follows.docs.map(f =>
      db.collection('posts')
        .where('userId', '==', f.data().followingId)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get()
    )
  );

  return activities.flatMap(snap => snap.docs);
}

// After (GOOD) - 集約コレクション
// scheduled/updateUserActivity.ts（定期バッチ）
export const updateUserActivity = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const users = await db.collection('users')
      .where('hasFollowers', '==', true).get();

    const batch = db.batch();

    for (const user of users.docs) {
      const latestPost = await db.collection('posts')
        .where('userId', '==', user.id)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();

      if (!latestPost.empty) {
        const activityRef = db.collection('userActivity').doc(user.id);
        batch.set(activityRef, {
          userId: user.id,
          latestPostId: latestPost.docs[0].id,
          latestPostAt: latestPost.docs[0].data().createdAt,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }

    await batch.commit();
  });

// getFollowingActivity.ts
async function getFollowingActivity(userId: string, limit: number) {
  const follows = await db.collection('follows')
    .where('followerId', '==', userId).get();

  const followingIds = follows.docs.map(d => d.data().followingId);

  // 1回のクエリで全フォロー中ユーザーのアクティビティ取得
  const activityRefs = followingIds.map(id =>
    db.collection('userActivity').doc(id)
  );

  const activities = await db.getAll(...activityRefs);

  return activities
    .filter(doc => doc.exists)
    .sort((a, b) => b.data()!.latestPostAt.toMillis() - a.data()!.latestPostAt.toMillis())
    .slice(0, limit);
}
```

---

## Tier 2: High Priority - 次スプリントで対応

### 4. トレンドスコアの事前計算（getTrending.ts）

**問題**: 200件をメモリでソート（アプリケーションソート）

```typescript
// Before (BAD)
async function getTrending(limit: number, period: string) {
  const threshold = getThreshold(period);

  // 200件全取得
  const collections = await db.collection('collections')
    .where('visibility', '==', 'public')
    .where('createdAt', '>=', threshold)
    .limit(200)
    .get();

  // メモリ内でスコア計算＆ソート（高コスト）
  const scored = collections.docs.map(doc => ({
    ...doc.data(),
    trendingScore: calculateScore(doc.data()),
  }));

  scored.sort((a, b) => b.trendingScore - a.trendingScore);

  return scored.slice(0, limit);
}

// After (GOOD) - 事前計算
// scheduled/updateTrendingScores.ts
export const updateTrendingScores = functions.pubsub
  .schedule('every 15 minutes')
  .onRun(async () => {
    const collections = await db.collection('collections')
      .where('visibility', '==', 'public')
      .get();

    const batch = db.batch();

    for (const doc of collections.docs) {
      const score = calculateTrendingScore(doc.data());
      batch.update(doc.ref, { trendingScore: score });
    }

    await batch.commit();
  });

// getTrending.ts
async function getTrending(limit: number) {
  // インデックスでソート済みのデータを取得
  return db.collection('collections')
    .where('visibility', '==', 'public')
    .orderBy('trendingScore', 'desc')
    .limit(limit)
    .get();
}
```

### 5. コレクション保存時の再フェッチ削除（saveCollection.ts）

```typescript
// Before (BAD)
async function saveCollection(collectionId: string, userId: string) {
  const collectionRef = db.collection('collections').doc(collectionId);

  await collectionRef.update({
    saveCount: admin.firestore.FieldValue.increment(1),
  });

  // 再フェッチ（不要）
  const updated = await collectionRef.get();

  return { saveCount: updated.data()?.saveCount };
}

// After (GOOD)
async function saveCollection(collectionId: string, userId: string) {
  const collectionRef = db.collection('collections').doc(collectionId);

  // トランザクションで現在の値を取得し、+1を返す
  const newCount = await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(collectionRef);
    const currentCount = doc.data()?.saveCount || 0;
    const newCount = currentCount + 1;

    transaction.update(collectionRef, {
      saveCount: newCount,
    });

    return newCount;
  });

  return { saveCount: newCount };
}
```

### 6. 推し設定の差分更新（setBias.ts）

**実装済み**: 上記の `setBias.ts` 修正を参照

---

## Tier 3: Recommended - 改善推奨

### 7. iOS側キャッシュ層

```swift
// VoteListViewModel.swift
class VoteListViewModel: ObservableObject {
    @Published var votes: [Vote] = []

    private let cache = NSCache<NSString, VoteListCache>()
    private let cacheExpiry: TimeInterval = 300 // 5分

    func fetchVotes(forceRefresh: Bool = false) async {
        let cacheKey = "voteList" as NSString

        // キャッシュチェック
        if !forceRefresh,
           let cached = cache.object(forKey: cacheKey),
           Date().timeIntervalSince(cached.timestamp) < cacheExpiry {
            self.votes = cached.votes
            return
        }

        // API呼び出し
        let newVotes = try await api.fetchVotes()

        // キャッシュ更新
        let cacheEntry = VoteListCache(votes: newVotes, timestamp: Date())
        cache.setObject(cacheEntry, forKey: cacheKey)

        self.votes = newVotes
    }
}
```

### 8. Admin一括操作の待機時間最適化

```typescript
// Before (BAD)
async function replaceGroups(newGroups: Group[]) {
  await deleteAllGroups();

  // 固定待機時間（非効率）
  await sleep(3000);

  // リトライループ
  for (let i = 0; i < 3; i++) {
    const remaining = await countGroups();
    if (remaining === 0) break;
    await sleep(2000);
  }

  await createGroups(newGroups);
}

// After (GOOD)
async function replaceGroups(newGroups: Group[]) {
  // 削除完了をポーリングで確認（指数バックオフ）
  await deleteAllGroups();

  let delay = 500;
  const maxDelay = 5000;

  while (true) {
    const remaining = await countGroups();
    if (remaining === 0) break;

    await sleep(delay);
    delay = Math.min(delay * 1.5, maxDelay);
  }

  // バッチサイズを増やす（Firestoreは500件/バッチまで可能）
  const BATCH_SIZE = 100; // 5 → 100
  for (let i = 0; i < newGroups.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = newGroups.slice(i, i + BATCH_SIZE);

    for (const group of chunk) {
      const ref = db.collection('groups').doc();
      batch.set(ref, group);
    }

    await batch.commit();
  }
}
```

---

## 検証チェックリスト

修正後は以下で確認:

- [ ] Cloud Functions: Firebase Console → Functions → ログでレイテンシ確認
- [ ] iOS: Xcode Instruments → Network profiling
- [ ] Admin: Chrome DevTools → Network tab
- [ ] Firestore: Firebase Console → Usage → 読み取り/書き込み数の変化

---

## 参照

- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Cloud Functions Tips](https://firebase.google.com/docs/functions/tips)
- [FCM Batch Messaging](https://firebase.google.com/docs/cloud-messaging/send-message#send-messages-to-multiple-devices)
