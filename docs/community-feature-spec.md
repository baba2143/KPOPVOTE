# K-VOTE COLLECTOR コミュニティ機能 要件定義書

**作成日**: 2025-11-15
**バージョン**: 1.0
**ステータス**: 要件定義完了

---

## 📋 目次

1. [概要](#概要)
2. [コア機能](#コア機能)
3. [詳細仕様](#詳細仕様)
4. [データモデル](#データモデル)
5. [API設計](#api設計)
6. [UI/UXフロー](#uiuxフロー)
7. [技術仕様](#技術仕様)
8. [実装計画](#実装計画)

---

## 概要

### 目的
同じK-POPアイドルを推すファン同士が交流し、投票活動を共有・促進できるコミュニティ機能を提供する。

### コアバリュー
1. **推し別コミュニティ**: 同じアイドルのファン同士を繋ぐ
2. **投票促進**: 投票への参加を呼びかけ、投票活動を可視化
3. **エンゲージメント**: いいね、フォロー、共有によるユーザー間の繋がり

### 技術方針
- **スケーラビリティ重視**: 将来的なユーザー増加を見越した設計
- **Firebaseベース**: Firestore, Cloud Functions, Firebase Storageを活用
- **段階的実装**: MVP → Phase 2 の段階的リリース

---

## コア機能

### 1. 推し別コミュニティ交流

#### 1.1 ユーザー発見
- **おすすめユーザー表示**
  - 同じ推しアイドルを持つユーザーを自動的に推薦
  - アルゴリズム: 推しの一致度、投票活動の活発さ、フォロワー数
  - 表示場所: コミュニティタブ内「おすすめユーザー」セクション

- **ユーザー検索機能**
  - ユーザー名、推しアイドル名での検索
  - フィルター: 推しアイドル、投票参加数、フォロワー数
  - 検索結果: ユーザーカード形式で表示

#### 1.2 フォロー機能
- ユーザーをフォロー/アンフォロー
- フォロー中ユーザー一覧、フォロワー一覧の表示
- フォロー数、フォロワー数の表示
- フォローすると相手に通知

#### 1.3 いいね機能
- 投稿（投票共有、画像投稿）にいいねボタン
- いいね数の表示
- 誰がいいねしたかを表示（タップでユーザー一覧）
- いいねすると投稿者に通知

---

### 2. 投票共有・呼びかけ

#### 2.1 アプリ内投票共有
**投稿として共有**
- 投票詳細画面に「共有」ボタン
- 共有方法:
  - シンプル共有: 投票カードのみ投稿
  - コメント付き共有: 投票カード + 自分のコメント（例: 「みんな参加して!」）
- 投稿先: コミュニティフィード（推し別タイムライン）
- 投稿には「投票共有」タグが自動付与

**投稿フォーマット**
```
[ユーザー名] さんが投票をシェアしました

[投票カード]
- カバー画像
- 投票タイトル
- 期間
- 必要ポイント
- 現在の投票数

[ユーザーコメント] (オプション)
「この投票めっちゃ推し!みんな参加して〜!」

[いいね] [コメント] [投票詳細を見る]
```

#### 2.2 外部SNS共有
**画像カード生成**
- 投票情報を視覚的に魅力的な画像カードとして生成
- 含まれる情報:
  - カバー画像（背景）
  - 投票タイトル
  - 開催期間
  - QRコード（アプリへの直リンク）
  - K-VOTE COLLECTORロゴ

**カスタムメッセージ**
- ユーザーが自由にメッセージを編集可能
- デフォルトテンプレート: 「【投票タイトル】に参加しよう! K-VOTE COLLECTORで投票受付中 📱」

**対応SNS**
- Twitter/X
- Instagram (ストーリーズ対応)
- LINE
- システムシェアシート（その他のアプリ）

---

### 3. マイ投票タブ

#### 3.1 投票履歴表示
- **表示場所**: メインタブバーに「マイ投票」タブを追加
- **表示内容**:
  - 参加済み投票リスト
  - 各投票の情報:
    - 投票タイトル
    - カバー画像
    - 参加日時
    - 投票した選択肢
    - ポイント使用数
    - 投票ステータス（開催中/終了）

#### 3.2 フィルター・ソート
- **フィルター**:
  - すべて / 開催中 / 終了済み
  - 推しアイドル別
  - 期間指定

- **ソート**:
  - 投票日時（新しい順/古い順）
  - ポイント使用数（多い順/少ない順）

#### 3.3 投票履歴の共有
**コミュニティ投稿として共有**
- 「マイ投票を共有」ボタン
- 共有内容の選択:
  - 投票リストのみ
  - 投票内容 + 選択した選択肢
  - 投票内容 + 選択肢 + コメント

**プライバシー設定**
- ユーザーが共有する情報を選択可能:
  - [ ] 投票タイトルのみ
  - [ ] 投票した選択肢も表示
  - [ ] 使用ポイント数も表示

**投稿フォーマット例**
```
[ユーザー名] の今月の投票活動

✅ 11月生まれのイケメン投票
   → NAYEON に投票 (0pt)

✅ K-POP ダンス対決
   → 未投票

参加投票数: 2 / 使用ポイント: 0pt

[いいね] [コメント]
```

---

## 詳細仕様

### コミュニティフィード

#### タイムライン種別
1. **推し別タイムライン** (デフォルト)
   - 自分の推しアイドルと同じユーザーの投稿を表示
   - 複数の推しがいる場合は、すべての推しの投稿を統合表示

2. **フォロータイムライン**
   - フォロー中ユーザーの投稿のみ表示
   - タブ切り替えで表示

#### 投稿タイプ
1. **投票共有投稿**
   - 投票カード + オプションでコメント
   - 「投票詳細を見る」ボタンで投票画面へ遷移

2. **画像投稿**
   - 2-4枚の画像 + テキスト
   - ファイルサイズ: 各5MB以下
   - 自動リサイズ・圧縮

3. **マイ投票共有投稿**
   - 投票履歴の可視化投稿
   - 統計情報（参加数、ポイント数）含む

#### リアクション
- **いいね**: ハートアイコン、いいね数表示
- **コメント**: 投稿へのコメント、コメント数表示
- **共有**: 外部SNSへの再共有

---

## データモデル

### Firestore コレクション構造

#### 1. `users` コレクション
```typescript
{
  uid: string;                    // Firebase Auth UID
  email: string;
  displayName: string;
  photoURL?: string;              // プロフィール画像URL
  biasIds: string[];              // 推しアイドルIDの配列
  points: number;                 // 保有ポイント
  followingCount: number;         // フォロー中ユーザー数
  followersCount: number;         // フォロワー数
  postsCount: number;             // 投稿数
  isPrivate: boolean;             // プライベートアカウント設定
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### 2. `posts` コレクション
```typescript
{
  id: string;
  userId: string;                 // 投稿者UID
  type: 'vote_share' | 'image' | 'my_votes';
  content: {
    text?: string;                // 投稿テキスト
    images?: string[];            // 画像URL配列 (最大4枚)
    voteId?: string;              // 共有する投票ID
    voteSnapshot?: InAppVote;     // 投票情報のスナップショット
    myVotes?: {                   // マイ投票共有用
      voteId: string;
      title: string;
      selectedChoiceId?: string;
      selectedChoiceLabel?: string;
      pointsUsed: number;
      votedAt: Timestamp;
    }[];
  };
  biasIds: string[];              // 関連する推しアイドルID
  likesCount: number;
  commentsCount: number;
  sharesCount: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### 3. `posts/{postId}/likes` サブコレクション
```typescript
{
  userId: string;
  createdAt: Timestamp;
}
```

#### 4. `posts/{postId}/comments` サブコレクション
```typescript
{
  id: string;
  userId: string;
  text: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### 5. `follows` コレクション
```typescript
{
  id: string;                     // `${followerId}_${followingId}`
  followerId: string;             // フォローする側
  followingId: string;            // フォローされる側
  createdAt: Timestamp;
}
```

#### 6. `notifications` コレクション
```typescript
{
  id: string;
  userId: string;                 // 通知受信者
  type: 'like' | 'comment' | 'follow' | 'vote_share';
  fromUserId: string;             // 通知の発生元ユーザー
  postId?: string;
  voteId?: string;
  message: string;
  isRead: boolean;
  createdAt: Timestamp;
}
```

#### 7. `voteHistory` コレクション
```typescript
{
  id: string;
  userId: string;
  voteId: string;
  choiceId: string;
  choiceLabel: string;
  pointsUsed: number;
  createdAt: Timestamp;
}
```

---

## API設計

### Cloud Functions

#### 1. 投稿関連

**`createPost`**
```typescript
// POST /api/posts
interface CreatePostRequest {
  type: 'vote_share' | 'image' | 'my_votes';
  content: {
    text?: string;
    images?: File[];      // 画像ファイル
    voteId?: string;
    includeMyVotes?: boolean;
  };
}

interface CreatePostResponse {
  postId: string;
  post: Post;
}
```

**`getPosts`**
```typescript
// GET /api/posts?timeline=bias|follow&lastPostId=xxx&limit=20
interface GetPostsRequest {
  timeline: 'bias' | 'follow';
  biasIds?: string[];     // bias timeline用
  lastPostId?: string;    // ページネーション
  limit: number;
}

interface GetPostsResponse {
  posts: Post[];
  hasMore: boolean;
}
```

**`likePost`**
```typescript
// POST /api/posts/{postId}/like
interface LikePostResponse {
  liked: boolean;
  likesCount: number;
}
```

**`commentOnPost`**
```typescript
// POST /api/posts/{postId}/comments
interface CommentOnPostRequest {
  text: string;
}

interface CommentOnPostResponse {
  commentId: string;
  comment: Comment;
}
```

#### 2. フォロー関連

**`followUser`**
```typescript
// POST /api/users/{userId}/follow
interface FollowUserResponse {
  following: boolean;
  followersCount: number;
}
```

**`getRecommendedUsers`**
```typescript
// GET /api/users/recommended?biasId=xxx&limit=10
interface GetRecommendedUsersRequest {
  biasId?: string;
  limit: number;
}

interface GetRecommendedUsersResponse {
  users: UserProfile[];
}
```

**`searchUsers`**
```typescript
// GET /api/users/search?q=xxx&biasId=xxx
interface SearchUsersRequest {
  query: string;
  biasId?: string;
  limit: number;
}

interface SearchUsersResponse {
  users: UserProfile[];
}
```

#### 3. 投票履歴関連

**`getMyVotes`**
```typescript
// GET /api/votes/my?status=all|active|ended&sort=date|points
interface GetMyVotesRequest {
  status: 'all' | 'active' | 'ended';
  sort: 'date' | 'points';
}

interface GetMyVotesResponse {
  votes: {
    vote: InAppVote;
    choiceId: string;
    choiceLabel: string;
    pointsUsed: number;
    votedAt: Timestamp;
  }[];
}
```

#### 4. 外部共有関連

**`generateShareImage`**
```typescript
// POST /api/votes/{voteId}/share-image
interface GenerateShareImageRequest {
  customMessage?: string;
}

interface GenerateShareImageResponse {
  imageUrl: string;        // 生成された画像のURL
  message: string;         // 共有メッセージ
}
```

#### 5. 通知関連

**`getNotifications`**
```typescript
// GET /api/notifications?unreadOnly=false&limit=50
interface GetNotificationsRequest {
  unreadOnly: boolean;
  limit: number;
}

interface GetNotificationsResponse {
  notifications: Notification[];
  unreadCount: number;
}
```

**`markNotificationAsRead`**
```typescript
// PUT /api/notifications/{notificationId}/read
interface MarkNotificationAsReadResponse {
  success: boolean;
}
```

---

## UI/UXフロー

### 画面構成

#### 1. コミュニティタブ
```
┌─────────────────────────┐
│ K-VOTE COLLECTOR        │
├─────────────────────────┤
│ 📱 推し別 | フォロー中   │ ← タブ切り替え
├─────────────────────────┤
│ 👤 おすすめユーザー     │
│ [ユーザーカード×3]      │
├─────────────────────────┤
│ 📝 タイムライン         │
│                         │
│ [投票共有投稿]          │
│ - カバー画像            │
│ - タイトル              │
│ - [投票詳細を見る]      │
│ ❤️ 12  💬 3             │
│                         │
│ [画像投稿]              │
│ - 画像×4                │
│ - テキスト              │
│ ❤️ 25  💬 8             │
│                         │
│ [マイ投票共有投稿]      │
│ - 投票リスト            │
│ - 統計情報              │
│ ❤️ 8   💬 2             │
│                         │
└─────────────────────────┘
[🏠] [投票] [+] [マイ投票] [コミュニティ]
```

#### 2. マイ投票タブ
```
┌─────────────────────────┐
│ マイ投票                │
├─────────────────────────┤
│ [共有] [フィルター]      │
├─────────────────────────┤
│ 📊 統計                 │
│ 参加投票: 15  ポイント: 45pt │
├─────────────────────────┤
│ すべて | 開催中 | 終了   │
├─────────────────────────┤
│ ✅ 11月生まれのイケメン投票 │
│    NAYEON に投票 (0pt)   │
│    2025/11/15           │
│                         │
│ ✅ K-POP ダンス対決      │
│    未投票               │
│    2025/11/10           │
│                         │
└─────────────────────────┘
```

#### 3. 投票詳細画面（共有ボタン追加）
```
┌─────────────────────────┐
│ 投票詳細          [×]   │
├─────────────────────────┤
│ [カバー画像]            │
│                         │
│ 11月生まれのイケメン投票│
│ 期間: 11/15 - 11/15    │
│ 必要: 0pt  総投票: 1票  │
├─────────────────────────┤
│ [投票先を選択]          │
│ ○ NAYEON  1票          │
│ ○ YUTA    0票          │
├─────────────────────────┤
│ [投票する (0pt消費)]    │
│                         │
│ [📤 共有]               │ ← 新規追加
│ ├ アプリ内で共有        │
│ └ SNSでシェア           │
└─────────────────────────┘
```

### 操作フロー

#### A. 投票をアプリ内で共有
1. 投票詳細画面で「共有」ボタンをタップ
2. 「アプリ内で共有」を選択
3. モーダル表示:
   - コメント入力欄（オプション）
   - 「投稿」ボタン
4. 投稿完了 → コミュニティフィードに表示
5. フォロワーに通知送信

#### B. 投票をSNSでシェア
1. 投票詳細画面で「共有」ボタンをタップ
2. 「SNSでシェア」を選択
3. 画像カード生成中...
4. システムシェアシート表示
5. SNS選択 → 投稿

#### C. マイ投票を共有
1. マイ投票タブで「共有」ボタンをタップ
2. 共有設定モーダル表示:
   - [ ] 投票タイトルのみ
   - [ ] 投票した選択肢も表示
   - [ ] 使用ポイント数も表示
   - コメント入力欄
3. 「投稿」ボタン
4. コミュニティフィードに表示

#### D. ユーザーをフォロー
1. おすすめユーザーカードをタップ
2. ユーザープロフィール画面表示
3. 「フォロー」ボタンをタップ
4. フォロー完了 → 相手に通知

#### E. 投稿にいいね
1. フィード上の投稿のハートアイコンをタップ
2. いいね追加 → アニメーション
3. 投稿者に通知送信
4. いいね数更新

---

## 技術仕様

### Firebase/Firestore設計

#### セキュリティルール

**`users` コレクション**
```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}
```

**`posts` コレクション**
```javascript
match /posts/{postId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null &&
                   request.resource.data.userId == request.auth.uid;
  allow update, delete: if request.auth.uid == resource.data.userId;

  match /likes/{likeId} {
    allow read: if request.auth != null;
    allow create: if request.auth != null;
    allow delete: if request.auth.uid == likeId;
  }

  match /comments/{commentId} {
    allow read: if request.auth != null;
    allow create: if request.auth != null;
    allow update, delete: if request.auth.uid == resource.data.userId;
  }
}
```

**`follows` コレクション**
```javascript
match /follows/{followId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null &&
                   followId == request.auth.uid + '_' + request.resource.data.followingId;
  allow delete: if request.auth.uid == resource.data.followerId;
}
```

#### インデックス

```javascript
// posts コレクション
- biasIds (配列) + createdAt (降順)
- userId + createdAt (降順)

// follows コレクション
- followerId + createdAt (降順)
- followingId + createdAt (降順)

// notifications コレクション
- userId + isRead + createdAt (降順)

// voteHistory コレクション
- userId + createdAt (降順)
- voteId + createdAt (降順)
```

### ストレージ構造

```
Firebase Storage
├── posts/
│   ├── {userId}/
│   │   ├── {postId}/
│   │   │   ├── image_0.jpg
│   │   │   ├── image_1.jpg
│   │   │   └── ...
│   │   └── ...
│   └── ...
├── share-images/
│   ├── {voteId}/
│   │   └── share_card.png
│   └── ...
└── profile-images/
    ├── {userId}.jpg
    └── ...
```

### Cloud Functions設計

#### トリガー関数

**`onPostCreated`**
- トリガー: `posts` ドキュメント作成時
- 処理:
  - 投稿者のフォロワーに通知送信
  - 投稿者の postsCount をインクリメント
  - 投票共有の場合、投票の sharesCount をインクリメント

**`onLikeCreated`**
- トリガー: `posts/{postId}/likes` ドキュメント作成時
- 処理:
  - 投稿の likesCount をインクリメント
  - 投稿者に通知送信（自分の投稿には送信しない）

**`onCommentCreated`**
- トリガー: `posts/{postId}/comments` ドキュメント作成時
- 処理:
  - 投稿の commentsCount をインクリメント
  - 投稿者に通知送信（自分の投稿には送信しない）

**`onFollowCreated`**
- トリガー: `follows` ドキュメント作成時
- 処理:
  - フォロワーの followingCount をインクリメント
  - フォローされたユーザーの followersCount をインクリメント
  - フォローされたユーザーに通知送信

**`onFollowDeleted`**
- トリガー: `follows` ドキュメント削除時
- 処理:
  - フォロワーの followingCount をデクリメント
  - フォローされたユーザーの followersCount をデクリメント

### スケーラビリティ戦略

#### パフォーマンス最適化

1. **ページネーション**
   - タイムライン: 1回あたり20件取得
   - Cursor-based pagination (lastPostId使用)

2. **キャッシュ戦略**
   - ユーザープロフィール: クライアント側で30分キャッシュ
   - 投稿画像: CDN経由で配信、ブラウザキャッシュ有効

3. **画像最適化**
   - アップロード時に自動リサイズ (最大1080px)
   - WebP形式への変換
   - サムネイル生成 (300px)

4. **複合クエリの削減**
   - 投稿にbiasIds配列を持たせ、推し別フィルタリングを1クエリで実現
   - voteSnapshot で投票情報のスナップショットを保存し、JOINクエリ不要化

#### コスト最適化

1. **Firestore読み取り削減**
   - リアルタイムリスナーの使用を最小限に
   - タイムライン: Pull-to-Refresh + ページネーション
   - 通知: 定期ポーリング (30秒間隔) → Push通知への移行検討

2. **Storage転送量削減**
   - 画像の適切な圧縮とリサイズ
   - CDN活用
   - サムネイル利用

3. **Cloud Functions実行回数削減**
   - バッチ処理の活用
   - 不要なトリガー関数の削除

---

## 実装計画

### フェーズ1: MVP (Minimum Viable Product)

**目標**: 基本的なコミュニティ機能を提供し、ユーザーフィードバックを収集

#### 実装範囲

**1週目: データ基盤構築**
- [ ] Firestoreコレクション作成
- [ ] セキュリティルール設定
- [ ] インデックス作成
- [ ] Cloud Functions基本構造

**2週目: 投稿機能**
- [ ] 投票共有投稿機能
  - [ ] 投票詳細画面に「共有」ボタン追加
  - [ ] シンプル共有 (投票カードのみ)
  - [ ] コメント付き共有
- [ ] 投稿一覧表示 (推し別タイムライン)
- [ ] いいね機能
- [ ] コメント機能

**3週目: フォロー機能**
- [ ] ユーザープロフィール画面
- [ ] フォロー/アンフォロー機能
- [ ] おすすめユーザー表示
- [ ] ユーザー検索機能

**4週目: マイ投票タブ**
- [ ] 投票履歴表示
- [ ] フィルター・ソート機能
- [ ] マイ投票共有機能 (基本版)

**5週目: 通知機能**
- [ ] アプリ内通知
- [ ] 通知一覧画面
- [ ] 通知バッジ表示

**6週目: テスト・調整**
- [ ] 統合テスト
- [ ] パフォーマンステスト
- [ ] バグ修正
- [ ] UI/UX調整

#### MVPの成功指標
- コミュニティ投稿数: 100投稿/日
- アクティブユーザー数: 50人/日
- 投票共有からの投票参加率: 10%以上

---

### フェーズ2: 機能拡張

**目標**: ユーザーフィードバックを元に機能を拡張し、エンゲージメントを向上

#### 追加実装範囲

**1. 外部SNS共有**
- [ ] 画像カード生成機能
  - [ ] デザインテンプレート作成
  - [ ] QRコード生成
  - [ ] Cloud Functionsでの画像生成
- [ ] システムシェアシート統合
- [ ] Twitter/X, Instagram, LINE対応

**2. 画像投稿機能**
- [ ] 複数枚画像アップロード (2-4枚)
- [ ] 画像編集機能 (トリミング、フィルター)
- [ ] 画像最適化処理

**3. フォロータイムライン**
- [ ] タブ切り替えUI
- [ ] フォロー中ユーザーの投稿フィルタリング
- [ ] パフォーマンス最適化

**4. プッシュ通知**
- [ ] Firebase Cloud Messaging統合
- [ ] 通知種別ごとの設定
- [ ] 通知ON/OFF設定

**5. 高度な投稿機能**
- [ ] 投稿編集機能
- [ ] 投稿削除機能
- [ ] 報告機能
- [ ] ブロック機能

**6. 統計・分析**
- [ ] 投票活動の統計グラフ
- [ ] 推し別の参加状況
- [ ] ポイント使用履歴グラフ

#### Phase 2の成功指標
- 外部SNS共有数: 50回/日
- 画像投稿数: 30投稿/日
- プッシュ通知開封率: 30%以上
- DAU (Daily Active Users): 100人

---

## 付録

### 用語集

- **推し**: お気に入りのK-POPアイドル
- **bias**: 推しの英語表現
- **いいね**: 投稿への好意的なリアクション
- **フォロー**: 特定のユーザーの投稿を継続的に見るための登録
- **タイムライン**: 投稿が時系列で表示される画面
- **フィード**: タイムラインと同義
- **MVP**: Minimum Viable Product（実用最小限の製品）

### 参考資料

- Firebase公式ドキュメント: https://firebase.google.com/docs
- Firestore データモデリングベストプラクティス
- iOS SwiftUI開発ガイド
- K-POPファンコミュニティ事例研究

---

## 変更履歴

| バージョン | 日付 | 変更内容 | 担当者 |
|----------|------|---------|--------|
| 1.0 | 2025-11-15 | 初版作成 | - |

---

**以上**
