# ポイント課金システム仕様書

**K-VOTE COLLECTOR - Monetization System Specification**

作成日: 2025-01-20
バージョン: 1.0
実装方式: 通常版+プロモ版（アプローチ2）

---

## 📋 目次

1. [システム概要](#システム概要)
2. [App Store Connect 商品設定](#app-store-connect-商品設定)
3. [Backend API仕様](#backend-api仕様)
4. [Firestore データ設計](#firestore-データ設計)
5. [iOS実装仕様](#ios実装仕様)
6. [プロモーション機能](#プロモーション機能)
7. [運用ガイド](#運用ガイド)
8. [実装スケジュール](#実装スケジュール)

---

## システム概要

### 目的
アプリ内投票機能で使用するポイントシステムと、収益化基盤の構築。

### 収益化戦略
1. **サブスクリプション（月額¥550）**
   - 安定した継続収益
   - 毎月ポイント自動付与（初月1,200P、以降600P/月）
   - プレミアム会員特典（今後拡張）

2. **消費型ポイント購入（5種類）**
   - ¥330（300P）〜 ¥5,500（6,500P）
   - 高額ほどお得率アップ（最大23%）
   - プロモ版で期間限定2倍キャンペーン対応

### 実装アプローチ
**通常版+プロモ版方式（アプローチ2）**

- **通常版**: 常時販売する基本商品（5種類）
- **プロモ版**: 週末2倍など期間限定商品（5種類、同価格で2倍ポイント）
- **切り替え**: サーバー側のFirestore設定で表示商品を制御
- **メリット**: シンプルな実装、即座のプロモ切り替え、審査不要

---

## App Store Connect 商品設定

### 合計11商品

#### 1. サブスクリプション（1商品）

```yaml
Product ID: com.kpopvote.premium.monthly
Type: Auto-Renewable Subscription
Subscription Group: Premium Membership
Reference Name: Premium Monthly Subscription
Price: ¥550/月
Subscription Duration: 1 Month

Localization (ja):
  Display Name: プレミアム会員（月額）
  Description: |
    毎月600ポイント自動付与！
    初月は特別に1,200ポイントプレゼント🎁

    【会員特典】
    ✨ 毎月600P自動付与
    🎁 初月ボーナス1,200P
    ⭐ 限定機能（今後追加予定）

    自動更新されます。いつでもキャンセル可能。

Settings:
  - Family Sharing: 無効
  - Introductory Offer: なし
  - Review Information: 必須（スクリーンショット + テスト手順）
```

**ポイント付与ルール:**
- 初回購読: 1,200P
- 毎月更新: 600P（Cloud Schedulerで自動付与）

#### 2. 消費型ポイント - 通常版（5商品）

| Product ID | Reference Name | Display Name (ja) | Price | Points | お得率 |
|-----------|----------------|------------------|-------|--------|--------|
| com.kpopvote.points.330 | 300 Points | 300ポイント | ¥330 | 300P | - |
| com.kpopvote.points.550 | 550 Points | 550ポイント | ¥550 | 550P | 9% |
| com.kpopvote.points.1200 | 1200 Points | 1,200ポイント | ¥1,100 | 1,200P | 16% |
| com.kpopvote.points.3800 | 3800 Points | 3,800ポイント | ¥3,300 | 3,800P | 21% |
| com.kpopvote.points.6500 | 6500 Points | 6,500ポイント | ¥5,500 | 6,500P | 23% |

**各商品の共通設定:**
```yaml
Type: Consumable
Cleared for Sale: はい
Availability: 全ての国・地域

Description Template:
  "{points}ポイントを購入できます。
  投票やコミュニティ機能で使用できます。"
```

#### 3. 消費型ポイント - プロモ版（5商品）

| Product ID | Reference Name | Display Name (ja) | Price | Points | 倍率 |
|-----------|----------------|------------------|-------|--------|------|
| com.kpopvote.points.330.bonus | 600 Points Bonus | 600ポイント（2倍パック） | ¥330 | 600P | 2倍 |
| com.kpopvote.points.550.bonus | 1100 Points Bonus | 1,100ポイント（2倍パック） | ¥550 | 1,100P | 2倍 |
| com.kpopvote.points.1200.bonus | 2400 Points Bonus | 2,400ポイント（2倍パック） | ¥1,100 | 2,400P | 2倍 |
| com.kpopvote.points.3800.bonus | 7600 Points Bonus | 7,600ポイント（2倍パック） | ¥3,300 | 7,600P | 2倍 |
| com.kpopvote.points.6500.bonus | 13000 Points Bonus | 13,000ポイント（2倍パック） | ¥5,500 | 13,000P | 2倍 |

**各商品の共通設定:**
```yaml
Type: Consumable
Cleared for Sale: はい
Availability: 全ての国・地域

Description Template:
  "期間限定2倍！{points}ポイントを特別価格で。
  投票やコミュニティ機能で使用できます。"
```

---

## Backend API仕様

### API一覧

```
functions/src/
├── points/
│   ├── getPoints.ts              ✨ 新規
│   ├── getPointHistory.ts        ✨ 新規
│   └── verifyPurchase.ts         ✨ 新規
├── subscription/
│   ├── verifySubscription.ts     ✨ 新規
│   ├── checkSubscriptionStatus.ts ✨ 新規
│   └── grantMonthlyPoints.ts     ✨ 新規
├── iap/
│   └── getActiveProducts.ts      ✨ 新規
└── admin/
    └── grantPoints.ts            ✅ 既存
```

---

### 1. getPoints.ts

**エンドポイント:** `GET /api/getPoints`

**認証:** Firebase ID Token必須

**レスポンス:**
```typescript
{
  success: true,
  data: {
    points: 1500,
    isPremium: true,
    lastUpdated: "2025-01-20T10:00:00Z"
  }
}
```

**実装:**
```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const getPoints = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "GET") {
    res.status(405).json({ success: false, error: "Method not allowed" });
    return;
  }

  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ success: false, error: "Unauthorized" });
      return;
    }

    const token = authHeader.split("Bearer ")[1];
    const decodedToken = await admin.auth().verifyIdToken(token);
    const uid = decodedToken.uid;

    const db = admin.firestore();
    const userDoc = await db.collection("users").doc(uid).get();

    if (!userDoc.exists) {
      res.status(404).json({ success: false, error: "User not found" });
      return;
    }

    const userData = userDoc.data()!;

    res.status(200).json({
      success: true,
      data: {
        points: userData.points || 0,
        isPremium: userData.isPremium || false,
        lastUpdated: userData.updatedAt?.toDate().toISOString() || null,
      }
    });
  } catch (error) {
    console.error("Get points error:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
});
```

---

### 2. getPointHistory.ts

**エンドポイント:** `GET /api/getPointHistory?limit=20`

**認証:** Firebase ID Token必須

**クエリパラメータ:**
- `limit` (optional): 取得件数（デフォルト: 20、最大: 100）
- `offset` (optional): スキップ件数（ページネーション用）

**レスポンス:**
```typescript
{
  success: true,
  data: {
    transactions: [
      {
        id: "txn_123",
        points: 1200,
        type: "subscription_first",
        reason: "プレミアム会員初月特典",
        createdAt: "2025-01-20T10:00:00Z"
      },
      {
        id: "txn_124",
        points: -100,
        type: "vote",
        reason: "投票：Best Idol 2025",
        createdAt: "2025-01-19T15:30:00Z"
      }
    ],
    totalCount: 45
  }
}
```

**実装:**
```typescript
export const getPointHistory = functions.https.onRequest(async (req, res) => {
  // ... 認証処理 ...

  const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
  const offset = parseInt(req.query.offset as string) || 0;

  const db = admin.firestore();

  // トランザクション取得
  const transactionsSnapshot = await db
    .collection("pointTransactions")
    .where("userId", "==", uid)
    .orderBy("createdAt", "desc")
    .limit(limit)
    .offset(offset)
    .get();

  const transactions = transactionsSnapshot.docs.map(doc => {
    const data = doc.data();
    return {
      id: doc.id,
      points: data.points,
      type: data.type,
      reason: data.reason,
      createdAt: data.createdAt?.toDate().toISOString() || null,
    };
  });

  // 総件数取得
  const countSnapshot = await db
    .collection("pointTransactions")
    .where("userId", "==", uid)
    .count()
    .get();

  res.status(200).json({
    success: true,
    data: {
      transactions,
      totalCount: countSnapshot.data().count,
    }
  });
});
```

---

### 3. verifyPurchase.ts

**エンドポイント:** `POST /api/verifyPurchase`

**認証:** Firebase ID Token必須

**リクエストボディ:**
```typescript
{
  transactionId: "2000000123456789",
  productId: "com.kpopvote.points.1200"
}
```

**レスポンス:**
```typescript
{
  success: true,
  data: {
    pointsGranted: 1200,
    transactionId: "2000000123456789",
    productId: "com.kpopvote.points.1200"
  }
}
```

**実装:**
```typescript
export const verifyPurchase = functions.https.onRequest(async (req, res) => {
  // ... 認証処理 ...

  const { transactionId, productId } = req.body;

  const db = admin.firestore();

  // 重複購入チェック
  const existingPurchase = await db
    .collection("purchaseRecords")
    .where("transactionId", "==", transactionId)
    .limit(1)
    .get();

  if (!existingPurchase.empty) {
    res.status(400).json({ success: false, error: "Already processed" });
    return;
  }

  // 商品設定取得
  const productDoc = await db
    .collection("productConfigurations")
    .doc(productId)
    .get();

  if (!productDoc.exists) {
    res.status(404).json({ success: false, error: "Product not found" });
    return;
  }

  const productData = productDoc.data()!;
  const points = productData.points;

  // Apple Receipt検証（実際の実装ではApp Store Server APIを使用）
  // const isValid = await verifyAppleReceipt(receipt);
  // if (!isValid) { ... }

  // トランザクション処理
  await db.runTransaction(async (transaction) => {
    const userRef = db.collection("users").doc(uid);

    // ポイント付与
    transaction.update(userRef, {
      points: admin.firestore.FieldValue.increment(points),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 購入記録
    const purchaseRef = db.collection("purchaseRecords").doc();
    transaction.set(purchaseRef, {
      userId: uid,
      productId,
      transactionId,
      points,
      purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ポイント履歴
    const txnRef = db.collection("pointTransactions").doc();
    transaction.set(txnRef, {
      userId: uid,
      points,
      type: "purchase",
      reason: `ポイント購入: ${productData.displayName}`,
      productId,
      transactionId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  res.status(200).json({
    success: true,
    data: {
      pointsGranted: points,
      transactionId,
      productId,
    }
  });
});
```

---

### 4. verifySubscription.ts

**エンドポイント:** `POST /api/verifySubscription`

**認証:** Firebase ID Token必須

**リクエストボディ:**
```typescript
{
  transactionId: "2000000123456789",
  productId: "com.kpopvote.premium.monthly",
  originalTransactionId: "1000000123456789"
}
```

**レスポンス:**
```typescript
{
  success: true,
  data: {
    pointsGranted: 1200,  // 初回は1200P、更新は600P
    isFirstMonth: true,
    subscriptionId: "sub_abc123"
  }
}
```

**実装:**
```typescript
export const verifySubscription = functions.https.onRequest(async (req, res) => {
  // ... 認証処理 ...

  const { transactionId, productId, originalTransactionId } = req.body;

  const db = admin.firestore();

  // 初回購読かチェック
  const existingSubSnapshot = await db
    .collection("subscriptions")
    .where("userId", "==", uid)
    .where("productId", "==", productId)
    .limit(1)
    .get();

  const isFirstMonth = existingSubSnapshot.empty;
  const points = isFirstMonth ? 1200 : 600;

  // トランザクション処理
  await db.runTransaction(async (transaction) => {
    const userRef = db.collection("users").doc(uid);

    // ポイント付与
    transaction.update(userRef, {
      points: admin.firestore.FieldValue.increment(points),
      isPremium: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // サブスク記録更新 or 作成
    if (isFirstMonth) {
      const subRef = db.collection("subscriptions").doc();
      transaction.set(subRef, {
        userId: uid,
        productId,
        originalTransactionId,
        currentTransactionId: transactionId,
        status: "active",
        isFirstMonth: true,
        firstMonthGrantedAt: admin.firestore.FieldValue.serverTimestamp(),
        totalPointsGranted: points,
        purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
        nextRenewalDate: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // +30日
        ),
        autoRenewStatus: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      const subRef = existingSubSnapshot.docs[0].ref;
      const subData = existingSubSnapshot.docs[0].data();

      transaction.update(subRef, {
        currentTransactionId: transactionId,
        lastMonthlyGrantedAt: admin.firestore.FieldValue.serverTimestamp(),
        totalPointsGranted: admin.firestore.FieldValue.increment(points),
        nextRenewalDate: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        ),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // ポイント履歴
    const txnRef = db.collection("pointTransactions").doc();
    transaction.set(txnRef, {
      userId: uid,
      points,
      type: isFirstMonth ? "subscription_first" : "subscription_monthly",
      reason: isFirstMonth ? "プレミアム会員初月特典" : "プレミアム会員月次特典",
      productId,
      transactionId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  res.status(200).json({
    success: true,
    data: {
      pointsGranted: points,
      isFirstMonth,
      subscriptionId: existingSubSnapshot.empty ? "new" : existingSubSnapshot.docs[0].id,
    }
  });
});
```

---

### 5. grantMonthlyPoints.ts (Cloud Scheduler)

**実行スケジュール:** 毎日 02:00 JST

**Cloud Scheduler設定:**
```bash
gcloud scheduler jobs create pubsub grant-monthly-points \
  --schedule="0 2 * * *" \
  --time-zone="Asia/Tokyo" \
  --topic="grant-monthly-points" \
  --message-body='{"action":"grant_monthly_points"}'
```

**実装:**
```typescript
export const grantMonthlyPoints = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    const db = admin.firestore();
    const today = admin.firestore.Timestamp.now();

    // 本日が更新日のサブスクを検索
    const subsSnapshot = await db
      .collection("subscriptions")
      .where("status", "==", "active")
      .where("autoRenewStatus", "==", true)
      .get();

    const batch = db.batch();
    let grantedCount = 0;

    for (const subDoc of subsSnapshot.docs) {
      const subData = subDoc.data();
      const nextRenewalDate = subData.nextRenewalDate;

      // 更新日チェック（日付のみ比較）
      if (nextRenewalDate.toDate().toDateString() === today.toDate().toDateString()) {
        const userId = subData.userId;
        const points = 600;

        // ポイント付与
        const userRef = db.collection("users").doc(userId);
        batch.update(userRef, {
          points: admin.firestore.FieldValue.increment(points),
        });

        // サブスク記録更新
        batch.update(subDoc.ref, {
          lastMonthlyGrantedAt: admin.firestore.FieldValue.serverTimestamp(),
          totalPointsGranted: admin.firestore.FieldValue.increment(points),
          nextRenewalDate: admin.firestore.Timestamp.fromDate(
            new Date(nextRenewalDate.toDate().getTime() + 30 * 24 * 60 * 60 * 1000)
          ),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // ポイント履歴
        const txnRef = db.collection("pointTransactions").doc();
        batch.set(txnRef, {
          userId,
          points,
          type: "subscription_monthly",
          reason: "プレミアム会員月次特典（自動付与）",
          productId: subData.productId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        grantedCount++;
      }
    }

    await batch.commit();

    console.log(`✅ Granted monthly points to ${grantedCount} users`);
    return null;
  });
```

---

### 6. getActiveProducts.ts

**エンドポイント:** `GET /api/getActiveProducts`

**認証:** 不要（公開API）

**レスポンス:**
```typescript
{
  success: true,
  data: {
    products: [
      {
        productId: "com.kpopvote.points.330",
        points: 300,
        priceJPY: 330,
        displayName: "300ポイント",
        bonusPercentage: 0
      },
      // ... 他の商品
    ],
    isPromoActive: false,
    promoName: null,
    promoEndTime: null
  }
}
```

**実装:**
```typescript
export const getActiveProducts = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "GET") {
    res.status(405).json({ success: false, error: "Method not allowed" });
    return;
  }

  try {
    const db = admin.firestore();

    // 表示設定取得
    const configDoc = await db.collection("appConfig").doc("store_display").get();
    const config = configDoc.data()!;

    const now = admin.firestore.Timestamp.now();

    // プロモ期間中かチェック
    const isPromoActive =
      config.activeProductSet === "promo" &&
      now >= config.promoStartDate &&
      now <= config.promoEndDate;

    // 表示する商品IDリスト
    const productIds = isPromoActive ?
      [
        "com.kpopvote.points.330.bonus",
        "com.kpopvote.points.550.bonus",
        "com.kpopvote.points.1200.bonus",
        "com.kpopvote.points.3800.bonus",
        "com.kpopvote.points.6500.bonus",
      ] :
      [
        "com.kpopvote.points.330",
        "com.kpopvote.points.550",
        "com.kpopvote.points.1200",
        "com.kpopvote.points.3800",
        "com.kpopvote.points.6500",
      ];

    // 商品詳細情報取得
    const productsSnapshot = await db
      .collection("productConfigurations")
      .where("productId", "in", productIds)
      .get();

    const products = productsSnapshot.docs.map(doc => doc.data());

    res.status(200).json({
      success: true,
      data: {
        products,
        isPromoActive,
        promoName: isPromoActive ? config.promoName : null,
        promoEndTime: isPromoActive ? config.promoEndDate.toDate().toISOString() : null,
      }
    });
  } catch (error) {
    console.error("Get active products error:", error);
    res.status(500).json({ success: false, error: "Internal server error" });
  }
});
```

---

## Firestore データ設計

### コレクション構造

```
/users/{userId}
/pointTransactions/{transactionId}
/productConfigurations/{productId}
/purchaseRecords/{purchaseId}
/subscriptions/{subscriptionId}
/appConfig/store_display
```

---

### 1. users コレクション

**既存フィールド:**
```typescript
{
  uid: string,
  email: string,
  displayName: string,
  photoURL: string,
  myBias: BiasSettings[],
  createdAt: Timestamp,
  updatedAt: Timestamp,
  points: number  // ✅ 既存
}
```

**追加フィールド:**
```typescript
{
  isPremium: boolean,  // ✨ 新規 - プレミアム会員状態
}
```

---

### 2. pointTransactions コレクション

**既存コレクション（拡張）:**
```typescript
{
  userId: string,
  points: number,  // 正: 獲得、負: 消費
  type: string,    // purchase, subscription_first, subscription_monthly, vote, grant, deduct
  reason: string,
  productId?: string,       // ✨ 新規 - 購入商品ID
  transactionId?: string,   // ✨ 新規 - App Store Transaction ID
  voteId?: string,          // 投票消費時
  grantedBy?: string,       // 管理者付与時
  createdAt: Timestamp
}
```

**インデックス:**
- `userId` + `createdAt` (desc)
- `userId` + `type`

---

### 3. productConfigurations コレクション

**ドキュメントID:** Product ID

```typescript
{
  productId: "com.kpopvote.points.330",
  productType: "consumable",  // or "subscription"
  points: 300,
  priceJPY: 330,
  displayName: "300ポイント",
  bonusPercentage: 0,  // お得率（通常版は0）
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**初期データ投入例:**
```typescript
// 通常版
{
  productId: "com.kpopvote.points.330",
  productType: "consumable",
  points: 300,
  priceJPY: 330,
  displayName: "300ポイント",
  bonusPercentage: 0,
  isActive: true,
}

// プロモ版
{
  productId: "com.kpopvote.points.330.bonus",
  productType: "consumable",
  points: 600,
  priceJPY: 330,
  displayName: "600ポイント（2倍パック）",
  bonusPercentage: 100,  // 2倍 = 100%お得
  isActive: true,
}

// サブスクリプション
{
  productId: "com.kpopvote.premium.monthly",
  productType: "subscription",
  points: 600,  // 月次付与ポイント
  priceJPY: 550,
  displayName: "プレミアム会員（月額）",
  bonusPercentage: 0,
  isActive: true,
}
```

---

### 4. purchaseRecords コレクション

```typescript
{
  userId: string,
  productId: string,
  transactionId: string,  // App Store Transaction ID（一意）
  points: number,
  purchaseDate: Timestamp,
  createdAt: Timestamp
}
```

**インデックス:**
- `userId` + `purchaseDate` (desc)
- `transactionId` (unique)

---

### 5. subscriptions コレクション

```typescript
{
  userId: string,
  productId: "com.kpopvote.premium.monthly",
  originalTransactionId: string,  // 購読の一意ID
  currentTransactionId: string,   // 最新の更新Transaction ID
  status: "active" | "expired" | "cancelled",

  // ポイント付与履歴
  isFirstMonth: boolean,
  firstMonthGrantedAt: Timestamp,
  lastMonthlyGrantedAt: Timestamp,
  totalPointsGranted: number,  // 累計付与ポイント

  // 日付管理
  purchaseDate: Timestamp,
  expiresDate: Timestamp,
  nextRenewalDate: Timestamp,  // 次回更新日（Cloud Scheduler用）

  // 自動更新設定
  autoRenewStatus: boolean,

  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**インデックス:**
- `userId` + `status`
- `status` + `autoRenewStatus` + `nextRenewalDate` (Cloud Scheduler用)
- `originalTransactionId` (unique)

---

### 6. appConfig/store_display ドキュメント

```typescript
{
  activeProductSet: "normal" | "promo",
  promoStartDate: Timestamp,
  promoEndDate: Timestamp,
  promoName: "週末2倍キャンペーン",
  updatedAt: Timestamp,
  updatedBy: string  // Admin UID
}
```

**初期データ:**
```typescript
{
  activeProductSet: "normal",
  promoStartDate: null,
  promoEndDate: null,
  promoName: null,
  updatedAt: Timestamp.now(),
  updatedBy: "system"
}
```

---

## iOS実装仕様

### ファイル構成

```
ios/KPOPVOTE/KPOPVOTE/
├── Services/
│   ├── PointsService.swift           ✨ 新規
│   ├── StoreKitManager.swift         ✨ 新規
│   ├── PurchaseService.swift         ✨ 新規
│   └── SubscriptionManager.swift     ✨ 新規
├── ViewModels/
│   ├── PointsViewModel.swift         ✨ 新規
│   ├── StoreViewModel.swift          ✨ 新規
│   └── SubscriptionViewModel.swift   ✨ 新規
├── Views/
│   ├── Points/
│   │   ├── PointsShopView.swift          ✨ 新規
│   │   ├── ProductCardView.swift         ✨ 新規
│   │   ├── SubscriptionCardView.swift    ✨ 新規
│   │   └── PointsHistoryView.swift       ✨ 新規
│   └── Premium/
│       └── PremiumBenefitsView.swift     ✨ 新規
└── Models/
    ├── PointTransaction.swift        ✨ 新規
    ├── ProductConfiguration.swift    ✨ 新規
    └── Subscription.swift            ✨ 新規
```

---

### 主要実装

#### StoreKitManager.swift

```swift
import StoreKit
import FirebaseAuth

@MainActor
class StoreKitManager: ObservableObject {
    @Published var consumableProducts: [Product] = []
    @Published var subscriptionProducts: [Product] = []
    @Published var isPremium = false
    @Published var isPromoActive = false
    @Published var promoName: String?

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func loadProducts() async {
        do {
            // 1. サーバーから表示商品ID取得
            let activeProductsResponse = try await fetchActiveProducts()
            isPromoActive = activeProductsResponse.isPromoActive
            promoName = activeProductsResponse.promoName

            let consumableIDs = activeProductsResponse.products.map { $0.productId }
            let subscriptionID = "com.kpopvote.premium.monthly"

            // 2. StoreKitで商品情報取得
            let allProducts = try await Product.products(for: consumableIDs + [subscriptionID])

            // 3. 分類
            consumableProducts = allProducts.filter { consumableIDs.contains($0.id) }
            subscriptionProducts = allProducts.filter { $0.id == subscriptionID }

            // 4. サブスク状態確認
            await checkSubscriptionStatus()

            print("✅ Loaded \(allProducts.count) products (Promo: \(isPromoActive))")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    func purchaseConsumable(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // サーバーで検証
            try await verifyPurchaseWithServer(transaction)

            await transaction.finish()

        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    func purchaseSubscription() async throws {
        guard let product = subscriptionProducts.first else {
            throw StoreError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            try await verifySubscriptionWithServer(transaction)

            await transaction.finish()
            await checkSubscriptionStatus()

        case .userCancelled:
            break
        case .pending:
            break
        @unknown default:
            break
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkSubscriptionStatus() async {
        guard let subscription = subscriptionProducts.first else { return }

        do {
            let statuses = try await subscription.subscription?.status ?? []

            for status in statuses {
                switch status.state {
                case .subscribed, .inGracePeriod:
                    isPremium = true
                    return
                default:
                    break
                }
            }

            isPremium = false
        } catch {
            print("❌ Subscription status check failed: \(error)")
        }
    }
}

enum StoreError: Error {
    case productNotFound
    case failedVerification
    case authenticationFailed
    case verificationFailed
}
```

---

## プロモーション機能

### 週末2倍キャンペーン運用

#### プロモ開始手順

**金曜日 20:00**

1. Firebase Consoleにアクセス
2. Firestore → `appConfig` → `store_display` ドキュメントを開く
3. フィールドを更新:

```typescript
{
  activeProductSet: "promo",  // "normal" から "promo" に変更
  promoStartDate: Timestamp.fromDate(new Date("2025-01-24T20:00:00+09:00")),
  promoEndDate: Timestamp.fromDate(new Date("2025-01-27T23:59:59+09:00")),
  promoName: "週末2倍キャンペーン",
  updatedAt: Timestamp.now(),
  updatedBy: "admin_uid"
}
```

4. 保存
5. **即座に全ユーザーに反映される**（アプリ再起動不要）

#### プロモ終了手順

**月曜日 00:00**

1. Firebase Console → `appConfig/store_display` を開く
2. フィールドを更新:

```typescript
{
  activeProductSet: "normal",  // "promo" から "normal" に戻す
  promoStartDate: null,
  promoEndDate: null,
  promoName: null,
  updatedAt: Timestamp.now(),
  updatedBy: "admin_uid"
}
```

3. 保存

---

### プロモバナー表示

**iOS側での表示例:**

```swift
struct PromoBannerView: View {
    let promoName: String
    let endTime: Date

    var body: some View {
        HStack {
            Image(systemName: "gift.fill")
                .foregroundColor(.pink)

            VStack(alignment: .leading, spacing: 4) {
                Text("🎁 \(promoName)")
                    .font(.headline)
                    .foregroundColor(.pink)

                Text("残り \(timeRemaining)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.pink.opacity(0.1))
        .cornerRadius(12)
    }

    private var timeRemaining: String {
        let interval = endTime.timeIntervalSinceNow
        let hours = Int(interval) / 3600
        return "\(hours)時間"
    }
}
```

---

## 運用ガイド

### 日常運用

#### ポイント付与確認
```bash
# Cloud Schedulerログ確認
gcloud logging read "resource.type=cloud_scheduler_job AND resource.labels.job_id=grant-monthly-points" --limit 10

# 手動実行（テスト用）
gcloud scheduler jobs run grant-monthly-points
```

#### ユーザーサポート

**ポイント未付与の問い合わせ:**
1. Firebase Console → Firestore
2. `pointTransactions` コレクションで `userId` 検索
3. 該当トランザクション確認
4. 未付与の場合、`admin/grantPoints` APIで手動付与

**サブスク状態確認:**
1. `subscriptions` コレクションで `userId` 検索
2. `status`, `nextRenewalDate` 確認

---

### トラブルシューティング

#### ケース1: 購入完了したがポイント未付与

**原因:** レシート検証失敗 or サーバーエラー

**対処:**
1. `purchaseRecords` コレクションで `transactionId` 検索
2. 記録がない → レシート検証失敗
3. Firebase Functions ログ確認:
```bash
firebase functions:log --only verifyPurchase
```
4. 手動付与（必要に応じて）

#### ケース2: プロモ商品が表示されない

**原因:** `appConfig/store_display` 設定ミス or iOS側キャッシュ

**対処:**
1. Firestore設定確認
2. iOS側でアプリ再起動
3. `getActiveProducts` APIレスポンス確認

#### ケース3: サブスク月次ポイント未付与

**原因:** Cloud Scheduler実行失敗 or 日付判定ミス

**対処:**
1. Cloud Schedulerログ確認
2. `subscriptions` コレクションで `nextRenewalDate` 確認
3. 手動でCloud Scheduler実行:
```bash
gcloud scheduler jobs run grant-monthly-points
```

---

### テスト方法（Sandbox環境）

#### App Store Connect Sandbox設定

1. **Sandbox Testerアカウント作成**
   - App Store Connect → Users and Access → Sandbox Testers
   - 新規Testerアカウント作成（例: `test@example.com`）

2. **iOS実機/シミュレータ設定**
   - Settings → App Store → Sandbox Account
   - 作成したTesterアカウントでサインイン

3. **テスト購入実行**
   - アプリ起動 → ポイントショップ
   - 商品購入 → Sandboxダイアログで承認
   - ポイント付与確認

#### テストシナリオ

**消費型ポイント購入:**
1. 通常版商品購入（300P）
2. ポイント残高確認: 300P
3. ポイント履歴確認: 「ポイント購入: 300ポイント」

**プロモ商品購入:**
1. Firestore設定変更（`activeProductSet: "promo"`）
2. アプリ再読み込み
3. プロモ版商品購入（600P）
4. ポイント残高確認: 600P

**サブスクリプション:**
1. プレミアム会員購入
2. ポイント確認: 1,200P（初月）
3. `subscriptions` コレクション確認: `isFirstMonth: true`
4. 翌月更新シミュレーション（Sandboxでは数分後）
5. ポイント確認: 1,200P + 600P = 1,800P

---

## 実装スケジュール

### Phase 0: ポイントシステム基盤（1-2日）

**Backend:**
- [ ] `getPoints.ts` 実装
- [ ] `getPointHistory.ts` 実装
- [ ] Cloud Functions デプロイ

**iOS:**
- [ ] `PointsService.swift` 実装
- [ ] `PointsViewModel.swift` 実装
- [ ] `PointsHistoryView.swift` 実装
- [ ] `ProfileView.swift` にポイント表示追加

**テスト:**
- [ ] ポイント取得API動作確認
- [ ] ポイント履歴取得確認
- [ ] UI表示確認

---

### Phase 1A: 消費型IAP（2-3日）

**App Store Connect:**
- [ ] 消費型商品10個登録（通常版5 + プロモ版5）
- [ ] 価格設定、ローカライズ設定
- [ ] 審査提出（初回のみ）

**Backend:**
- [ ] `verifyPurchase.ts` 実装
- [ ] `getActiveProducts.ts` 実装
- [ ] `productConfigurations` コレクション初期データ投入
- [ ] `appConfig/store_display` ドキュメント作成
- [ ] Cloud Functions デプロイ

**iOS:**
- [ ] `StoreKitManager.swift` 実装（消費型のみ）
- [ ] `PurchaseService.swift` 実装
- [ ] `StoreViewModel.swift` 実装
- [ ] `PointsShopView.swift` 実装
- [ ] `ProductCardView.swift` 実装

**テスト:**
- [ ] Sandbox購入テスト（通常版）
- [ ] レシート検証動作確認
- [ ] ポイント付与確認
- [ ] プロモ切り替えテスト（通常版 ↔ プロモ版）

---

### Phase 1B: サブスクリプション（2-3日）

**App Store Connect:**
- [ ] サブスクリプション商品1個登録
- [ ] Subscription Group作成
- [ ] 価格設定、特典説明
- [ ] 審査提出

**Backend:**
- [ ] `verifySubscription.ts` 実装
- [ ] `checkSubscriptionStatus.ts` 実装
- [ ] `grantMonthlyPoints.ts` 実装
- [ ] Cloud Scheduler設定
- [ ] Cloud Functions デプロイ

**iOS:**
- [ ] `SubscriptionManager.swift` 実装
- [ ] `SubscriptionViewModel.swift` 実装
- [ ] `SubscriptionCardView.swift` 実装
- [ ] `PremiumBenefitsView.swift` 実装
- [ ] `StoreKitManager.swift` にサブスク処理追加

**テスト:**
- [ ] Sandboxサブスク購入テスト
- [ ] 初月1,200P付与確認
- [ ] 更新時600P付与確認（Sandboxで自動更新）
- [ ] `subscriptions` コレクション確認

---

### Phase 2: 統合テスト＆調整（1日）

**統合テスト:**
- [ ] 全パターン購入テスト
  - [ ] 消費型5種類（通常版）
  - [ ] 消費型5種類（プロモ版）
  - [ ] サブスクリプション
- [ ] プロモ切り替え動作確認
- [ ] エラーハンドリング確認
  - [ ] ネットワークエラー
  - [ ] レシート検証失敗
  - [ ] 重複購入チェック

**UI/UX調整:**
- [ ] ローディング状態の表示
- [ ] エラーメッセージの表示
- [ ] 購入成功時のフィードバック
- [ ] プロモバナーのデザイン調整

**ドキュメント:**
- [ ] 運用手順書最終確認
- [ ] トラブルシューティングガイド更新

---

### 完成目標日

**Phase 0:** Day 1-2
**Phase 1A:** Day 3-5
**Phase 1B:** Day 6-8
**Phase 2:** Day 9

**合計: 9日間**

---

## 付録

### ポイント消費例（投票機能との連携）

**既存の `executeVote` API（functions/src/inAppVote/executeVote.ts）:**

```typescript
// Lines 69-74: ポイント残高チェック
const userPoints = userData.points || 0;
if (userPoints < voteData.requiredPoints) {
  res.status(400).json({ success: false, error: "Insufficient points" });
  return;
}

// Lines 95-97: ポイント消費
transaction.update(userRef, {
  points: admin.firestore.FieldValue.increment(-voteData.requiredPoints),
});

// Lines 117-128: 投票履歴作成
const voteHistoryRef = db.collection("voteHistory").doc();
transaction.set(voteHistoryRef, {
  id: voteHistoryRef.id,
  userId: uid,
  voteId,
  voteTitle: voteData.title,
  selectedChoiceId: choiceId,
  selectedChoiceLabel: choices[choiceIndex].label,
  pointsUsed: voteData.requiredPoints,
  votedAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

**ポイント消費フロー:**
1. ユーザーが投票実行
2. `executeVote` API: ポイント残高チェック
3. 不足している場合: エラー → ポイント購入画面へ誘導
4. 十分な場合: ポイント消費 → 投票実行

---

### プレミアム会員特典（今後の拡張）

**現在:**
- 毎月600P自動付与
- 初月1,200Pボーナス

**将来の拡張案:**
- 限定投票への参加権
- 投票時のポイント消費20%割引
- プレミアム限定コミュニティ投稿
- プレミアム会員バッジ表示
- 広告非表示

---

## まとめ

本仕様書に基づき、K-VOTE COLLECTORのポイント課金システムを実装することで：

✅ **収益化基盤の確立**
✅ **柔軟なプロモーション運用**
✅ **シンプルで保守しやすい実装**
✅ **スケーラブルなアーキテクチャ**

を実現します。

---

**次のステップ:**
1. App Store Connect商品登録
2. Phase 0実装開始
3. 段階的なテスト・デプロイ
