# FanCard 機能設計書

**作成日**: 2026-04-08
**ステータス**: 設計中
**優先度**: 最優先

---

## 1. 概要

### 1.1 コンセプト
K-POPファン向けの「推し活名刺」機能。ユーザーが自分の推し情報やSNSリンクをまとめた公開プロフィールページを作成し、SNS等でシェアできる。

### 1.2 参考サービス
- [lit.link](https://lit.link/) - リンクまとめサービス

### 1.3 主なユースケース
1. X (Twitter) のプロフィールにリンクを貼る
2. ファン同士の自己紹介として共有
3. 推しへの愛を表現するページとして

---

## 2. 機能要件

### 2.1 MVP機能（Phase 1）

| 機能 | 説明 | 優先度 |
|------|------|--------|
| プロフィール表示 | 名前、自己紹介、アイコン | 必須 |
| 推しメンバー表示 | myBias連携 | 必須 |
| リンクブロック | 任意のURL + タイトル | 必須 |
| MVリンク | YouTube埋め込み/サムネイル | 必須 |
| SNSリンク | X, Instagram等のリンク | 必須 |
| ヘッダー画像 | カスタム背景画像 | 必須 |
| 公開URL | `/{username}` でアクセス可能 | 必須 |
| OGP対応 | SNSシェア時のプレビュー | 必須 |

### 2.2 追加機能（Phase 2）

| 機能 | 説明 | 優先度 |
|------|------|--------|
| テーマ切り替え | 複数デザインテンプレート | 中 |
| カラーカスタマイズ | アクセントカラー変更 | 中 |
| ブロック並び替え | ドラッグ&ドロップ | 中 |
| アクセス解析 | 閲覧数カウント | 低 |
| QRコード生成 | シェア用QRコード | 低 |

---

## 3. データモデル（Firestore）

### 3.1 コレクション構成

```
firestore/
├── fanCards/
│   └── {odDisplayName}/     # URL用の一意ID（小文字英数字 + ハイフン）
│       └── FanCard document
│
└── users/
    └── {userId}/
        └── fanCardId: string  # 所有するFanCardへの参照
```

### 3.2 FanCard ドキュメント

```typescript
interface FanCard {
  // === 識別子 ===
  odDisplayName: string;      // URL用ID（例: "jimin-love-97"）
  userId: string;             // 所有者のUID

  // === プロフィール ===
  displayName: string;        // 表示名（最大30文字）
  bio: string;                // 自己紹介（最大200文字）
  profileImageUrl: string;    // アイコン画像URL
  headerImageUrl: string;     // ヘッダー画像URL

  // === デザイン設定 ===
  theme: FanCardTheme;

  // === コンテンツ ===
  blocks: FanCardBlock[];     // 最大20ブロック

  // === 公開設定 ===
  isPublic: boolean;          // 公開/非公開

  // === 統計 ===
  viewCount: number;          // 閲覧数

  // === メタ情報 ===
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface FanCardTheme {
  template: 'default' | 'cute' | 'cool' | 'elegant' | 'dark';
  backgroundColor: string;    // HEX色コード
  primaryColor: string;       // アクセントカラー
  fontFamily: 'default' | 'rounded' | 'serif';
}
```

### 3.3 ブロック定義

```typescript
type FanCardBlock =
  | BiasBlock
  | LinkBlock
  | MVLinkBlock
  | SNSBlock
  | TextBlock
  | ImageBlock;

// 基底インターフェース
interface BaseBlock {
  id: string;                 // ブロック固有ID（UUID）
  order: number;              // 表示順序
  isVisible: boolean;         // 表示/非表示
}

// 推しメンバーブロック
interface BiasBlock extends BaseBlock {
  type: 'bias';
  data: {
    showFromMyBias: boolean;  // myBiasから自動取得
    customBias?: {            // カスタム設定の場合
      artistId: string;
      artistName: string;
      memberId?: string;
      memberName?: string;
    }[];
  };
}

// リンクブロック
interface LinkBlock extends BaseBlock {
  type: 'link';
  data: {
    title: string;            // リンクタイトル（最大50文字）
    url: string;              // URL
    iconUrl?: string;         // カスタムアイコン
    backgroundColor?: string; // ボタン背景色
  };
}

// MVリンクブロック
interface MVLinkBlock extends BaseBlock {
  type: 'mvLink';
  data: {
    title: string;            // MV名
    youtubeUrl: string;       // YouTube URL
    thumbnailUrl?: string;    // サムネイル（自動取得）
    artistName?: string;      // アーティスト名
  };
}

// SNSリンクブロック
interface SNSBlock extends BaseBlock {
  type: 'sns';
  data: {
    platform: 'x' | 'instagram' | 'tiktok' | 'youtube' | 'threads' | 'other';
    username: string;         // ユーザー名（@なし）
    url: string;              // プロフィールURL
  };
}

// テキストブロック
interface TextBlock extends BaseBlock {
  type: 'text';
  data: {
    content: string;          // テキスト内容（最大500文字）
    alignment: 'left' | 'center' | 'right';
  };
}

// 画像ブロック
interface ImageBlock extends BaseBlock {
  type: 'image';
  data: {
    imageUrl: string;         // 画像URL
    caption?: string;         // キャプション
    linkUrl?: string;         // クリック時のリンク先
  };
}
```

### 3.4 インデックス設計

```javascript
// firestore.indexes.json に追加
{
  "indexes": [
    {
      "collectionGroup": "fanCards",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isPublic", "order": "ASCENDING" },
        { "fieldPath": "viewCount", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "fanCards",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

---

## 4. API設計

### 4.1 エンドポイント一覧

| メソッド | エンドポイント | 説明 | 認証 |
|---------|---------------|------|------|
| POST | `/fancard/create` | FanCard作成 | 必須 |
| GET | `/fancard/get` | 自分のFanCard取得 | 必須 |
| GET | `/fancard/getByOdDisplayName` | 公開ページ用取得 | 不要 |
| PUT | `/fancard/update` | FanCard更新 | 必須 |
| DELETE | `/fancard/delete` | FanCard削除 | 必須 |
| POST | `/fancard/checkOdDisplayName` | URL名の重複チェック | 必須 |
| POST | `/fancard/incrementViewCount` | 閲覧数カウント | 不要 |
| POST | `/fancard/uploadImage` | 画像アップロード | 必須 |

### 4.2 API詳細

#### POST /fancard/create
FanCardを新規作成する。

**リクエスト**
```typescript
{
  odDisplayName: string;      // URL用ID（必須、一意）
  displayName: string;        // 表示名
  bio?: string;               // 自己紹介
  theme?: FanCardTheme;       // テーマ設定
}
```

**レスポンス**
```typescript
{
  success: true,
  data: {
    fanCard: FanCard
  }
}
```

**エラー**
- 400: odDisplayName が無効（形式エラー）
- 409: odDisplayName が既に使用されている
- 401: 認証エラー

---

#### GET /fancard/get
ログインユーザーの FanCard を取得する。

**レスポンス**
```typescript
{
  success: true,
  data: {
    fanCard: FanCard | null,
    hasFanCard: boolean
  }
}
```

---

#### GET /fancard/getByOdDisplayName
公開ページ表示用。認証不要。

**クエリパラメータ**
```
?odDisplayName=jimin-love-97
```

**レスポンス**
```typescript
{
  success: true,
  data: {
    fanCard: FanCard        // isPublic: true の場合のみ
  }
}
```

**エラー**
- 404: FanCard が存在しない、または非公開

---

#### PUT /fancard/update
FanCard を更新する。

**リクエスト**
```typescript
{
  displayName?: string;
  bio?: string;
  profileImageUrl?: string;
  headerImageUrl?: string;
  theme?: FanCardTheme;
  blocks?: FanCardBlock[];
  isPublic?: boolean;
}
```

**レスポンス**
```typescript
{
  success: true,
  data: {
    fanCard: FanCard
  }
}
```

---

#### POST /fancard/checkOdDisplayName
URL名の使用可否をチェックする。

**リクエスト**
```typescript
{
  odDisplayName: string;
}
```

**レスポンス**
```typescript
{
  success: true,
  data: {
    available: boolean,
    suggestion?: string     // 使用不可の場合の代替案
  }
}
```

---

## 5. Web フロントエンド設計

### 5.1 技術スタック

| 項目 | 技術 |
|------|------|
| フレームワーク | Next.js 14 (App Router) |
| スタイリング | Tailwind CSS |
| ホスティング | Vercel |
| OGP生成 | next/og (Vercel OG) |

### 5.2 ディレクトリ構成

```
KPOPVOTE/web/fancard/
├── src/
│   ├── app/
│   │   ├── [username]/
│   │   │   ├── page.tsx          # 公開ページ
│   │   │   └── opengraph-image.tsx  # OGP画像生成
│   │   ├── layout.tsx
│   │   └── page.tsx              # トップページ（リダイレクト）
│   │
│   ├── components/
│   │   ├── FanCard/
│   │   │   ├── FanCardView.tsx   # メインコンポーネント
│   │   │   ├── BiasBlock.tsx
│   │   │   ├── LinkBlock.tsx
│   │   │   ├── MVLinkBlock.tsx
│   │   │   ├── SNSBlock.tsx
│   │   │   ├── TextBlock.tsx
│   │   │   └── ImageBlock.tsx
│   │   └── common/
│   │       ├── Header.tsx
│   │       └── Footer.tsx
│   │
│   ├── lib/
│   │   ├── firebase.ts           # Firebase初期化
│   │   └── api.ts                # API呼び出し
│   │
│   ├── types/
│   │   └── fancard.ts            # 型定義
│   │
│   └── styles/
│       └── themes/               # テーマ別スタイル
│
├── public/
│   └── images/
│
├── next.config.js
├── tailwind.config.js
├── tsconfig.json
└── package.json
```

### 5.3 ページ仕様

#### 公開ページ (`/[username]`)

**URL例**: `https://kpopvote-fancard.vercel.app/jimin-love-97`

**機能**:
- FanCard の公開表示
- OGP メタタグ生成（動的）
- 閲覧数カウント
- レスポンシブデザイン

**OGP出力例**:
```html
<meta property="og:title" content="jimin-love-97のFanCard" />
<meta property="og:description" content="BTSジミン推し💜｜2019年〜" />
<meta property="og:image" content="https://kpopvote-fancard.vercel.app/api/og/jimin-love-97" />
<meta property="og:url" content="https://kpopvote-fancard.vercel.app/jimin-love-97" />
<meta name="twitter:card" content="summary_large_image" />
```

---

## 6. iOSアプリ編集画面設計

### 6.1 画面遷移

```
Profile Tab
└── FanCard セクション
    ├── [FanCardがない場合]
    │   └── 「FanCardを作成」ボタン
    │       └── FanCard作成画面
    │
    └── [FanCardがある場合]
        ├── プレビューカード
        ├── 「編集」ボタン → FanCard編集画面
        └── 「シェア」ボタン → シェアシート
```

### 6.2 編集画面の構成

```
┌─────────────────────────────────────┐
│ ← FanCard編集            [プレビュー] │
├─────────────────────────────────────┤
│                                     │
│ ■ 基本情報                          │
│ ┌─────────────────────────────────┐ │
│ │ URL: fancard.vercel.app/        │ │
│ │ [        username        ]      │ │
│ │ ※変更不可（作成時のみ設定）        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 表示名                          │ │
│ │ [    ジミンペン🐥           ]   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 自己紹介                        │ │
│ │ [    2019年からBTS推し...   ]   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ■ 画像                              │
│ ┌──────────┐ ┌──────────┐          │
│ │ アイコン  │ │ ヘッダー  │          │
│ │  [変更]  │ │  [変更]  │          │
│ └──────────┘ └──────────┘          │
│                                     │
│ ■ デザイン                          │
│ ┌─────────────────────────────────┐ │
│ │ テーマ: [Default ▼]            │ │
│ │ カラー: [💜 Purple]            │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ■ ブロック                          │
│ ┌─────────────────────────────────┐ │
│ │ ≡ 推しメンバー            [編集]│ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ≡ MVリンク: Filter        [編集]│ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ≡ X (@username)           [編集]│ │
│ └─────────────────────────────────┘ │
│                                     │
│ [+ ブロックを追加]                   │
│                                     │
│ ■ 公開設定                          │
│ ┌─────────────────────────────────┐ │
│ │ 公開する                [ON/OFF]│ │
│ └─────────────────────────────────┘ │
│                                     │
│        [保存する]                    │
│                                     │
└─────────────────────────────────────┘
```

---

## 7. 実装フェーズ

### Phase 1: 基盤構築（5日間）

| 日 | タスク |
|----|--------|
| 1 | Firestore スキーマ実装、型定義 |
| 2 | バックエンドAPI実装（create, get, update） |
| 3 | Next.js プロジェクト初期化、基本レイアウト |
| 4 | 公開ページ実装（データ取得、表示） |
| 5 | OGP 動的生成実装 |

### Phase 2: ブロック実装（4日間）

| 日 | タスク |
|----|--------|
| 6 | BiasBlock, LinkBlock 実装 |
| 7 | MVLinkBlock（YouTube埋め込み）実装 |
| 8 | SNSBlock, TextBlock, ImageBlock 実装 |
| 9 | テーマ切り替え実装 |

### Phase 3: iOS編集画面（5日間）

| 日 | タスク |
|----|--------|
| 10-11 | 基本情報・画像編集画面 |
| 12-13 | ブロック追加・編集・並び替え |
| 14 | プレビュー・シェア機能 |

### Phase 4: 仕上げ（3日間）

| 日 | タスク |
|----|--------|
| 15 | UIブラッシュアップ |
| 16 | テスト・バグ修正 |
| 17 | Vercel デプロイ・動作確認 |

---

## 8. セキュリティ考慮事項

### 8.1 Firestore ルール

```javascript
// firestore.rules に追加
match /fanCards/{odDisplayName} {
  // 公開カードは誰でも読み取り可能
  allow read: if resource.data.isPublic == true;

  // 所有者のみ全操作可能
  allow read, write: if request.auth != null
    && request.auth.uid == resource.data.userId;

  // 新規作成は認証ユーザーのみ
  allow create: if request.auth != null
    && request.resource.data.userId == request.auth.uid;
}
```

### 8.2 バリデーション

- odDisplayName: 小文字英数字とハイフンのみ、3〜30文字
- displayName: 1〜30文字
- bio: 最大200文字
- blocks: 最大20個
- 画像: 最大5MB、jpg/png/gif/webp

### 8.3 レート制限

- 画像アップロード: 1分に5回まで
- FanCard更新: 1分に10回まで
- 閲覧数カウント: 同一IP/ユーザーは1時間に1回

---

## 9. 今後の拡張案

### 9.1 Phase 3以降の機能案

| 機能 | 説明 |
|------|------|
| カスタムドメイン | 独自ドメイン設定（kvote.link等） |
| アナリティクス | 詳細なアクセス解析 |
| テンプレートマーケット | ユーザー作成テンプレート共有 |
| プレミアム機能 | 追加テーマ、広告非表示 |
| Spotify連携 | 音楽プレイヤー埋め込み |
| イベントカレンダー連携 | 参加予定イベント表示 |

---

## 10. 参考資料

- [lit.link](https://lit.link/) - 参考サービス
- [Vercel OG Image Generation](https://vercel.com/docs/functions/og-image-generation)
- [Next.js App Router](https://nextjs.org/docs/app)

---

## 変更履歴

| 日付 | 変更内容 |
|------|---------|
| 2026-04-08 | 初版作成 |
