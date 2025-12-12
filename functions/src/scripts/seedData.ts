/**
 * KPOPVOTE Seed Data Script
 * App Store審査用のダミーデータを生成
 *
 * 実行方法:
 * cd functions
 * npx ts-node src/scripts/seedData.ts
 */

import * as admin from "firebase-admin";
import { v4 as uuidv4 } from "uuid";

// Firebase Admin初期化
// サービスアカウントキーがある場合はそれを使用、なければADCを使用
const initializeFirebase = () => {
  try {
    const serviceAccount = require("../../serviceAccountKey.json");
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log("Initialized with service account key");
  } catch {
    // サービスアカウントキーがない場合はADCを使用
    admin.initializeApp({
      projectId: "kpopvote-9de2b",
    });
    console.log("Initialized with Application Default Credentials");
  }
};
initializeFirebase();

const db = admin.firestore();

// ==================== データ定義 ====================

// プロフィール画像 (Unsplash Free)
const profileImages = [
  "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&h=200&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200&h=200&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=200&h=200&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200&h=200&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&h=200&fit=crop&crop=face",
  "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&h=200&fit=crop&crop=face",
];

// 投稿用画像 (コンサート、音楽関連)
const postImages = [
  "https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=600&h=600&fit=crop",
  "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=600&h=600&fit=crop",
  "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&h=600&fit=crop",
  "https://images.unsplash.com/photo-1501612780327-45045538702b?w=600&h=600&fit=crop",
  "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&h=600&fit=crop",
  "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&h=600&fit=crop",
  "https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=600&h=600&fit=crop",
  "https://images.unsplash.com/photo-1506157786151-b8491531f063?w=600&h=600&fit=crop",
];

// ダミーユーザー定義
const dummyUsers = [
  {
    displayName: "하늘 (ハヌル)",
    username: "haneul_kpop",
    bio: "BTSとSEVENTEENが大好き💜 毎日投票頑張ってます！",
    biasIds: ["bts", "seventeen"],
  },
  {
    displayName: "美咲",
    username: "misaki_oshi",
    bio: "NCT推し🌹 日本からK-POP応援中",
    biasIds: ["nct"],
  },
  {
    displayName: "수진 (スジン)",
    username: "sujin_vote",
    bio: "ストレイキッズのファン🖤 毎日投票するよ",
    biasIds: ["straykids"],
  },
  {
    displayName: "さくら",
    username: "sakura_kfan",
    bio: "IVEとNewJeans推し🎀 推し活最高！",
    biasIds: ["ive", "newjeans"],
  },
  {
    displayName: "민지 (ミンジ)",
    username: "minji_kpop",
    bio: "BLACKPINK Forever💗",
    biasIds: ["blackpink"],
  },
  {
    displayName: "ゆい",
    username: "yui_seventeen",
    bio: "セブチカラット💎",
    biasIds: ["seventeen"],
  },
  {
    displayName: "지은 (ジウン)",
    username: "jieun_army",
    bio: "방탄 사랑해💜 Army since 2017",
    biasIds: ["bts"],
  },
  {
    displayName: "れな",
    username: "rena_kpop",
    bio: "aespa MY推し🦋",
    biasIds: ["aespa"],
  },
];

// コミュニティ投稿テキスト
const postTexts = [
  "今日のBTS投票完了しました！みんなも投票してね💜",
  "SEVENTEENのコンサート最高だった🎤✨ 感動で泣いた",
  "IVEの新曲やばすぎる…リピートが止まらない🎵",
  "NewJeansのMV見た？あのダンスすごい！",
  "今週の投票まとめました！みんなで頑張ろう💪",
  "NCTのライブ配信見ながら投票中📱",
  "ストレイキッズのカムバック楽しみすぎる🖤",
  "BLACKPINKのグッズ届いた！可愛すぎ💗",
  "aespaのワールドツアー当選した人いる？🦋",
  "推し活って最高だよね…毎日が楽しい",
  "今日も推しに投票できて幸せ✨",
  "K-POPファンの皆さん、今日も頑張りましょう！",
  "アルバム予約完了！早く届かないかな📀",
  "ファンミーティングの感想シェアします💕",
  "推しの誕生日おめでとう🎂🎉",
  "今月の投票目標達成！来月も頑張る💪",
];

// コレクション定義
const collections = [
  {
    title: "今週のBTS投票まとめ",
    description: "今週参加できるBTS関連の投票をまとめました！ARMYの皆さん一緒に頑張りましょう💜",
    tags: ["BTS", "投票", "ARMY", "まとめ"],
    taskCount: 5,
  },
  {
    title: "SEVENTEEN応援コレクション",
    description: "カラット必見！SEVENTEENの投票リストです💎",
    tags: ["SEVENTEEN", "カラット", "投票"],
    taskCount: 4,
  },
  {
    title: "IVE推し活リスト",
    description: "DIVE向けの投票タスク集🩷",
    tags: ["IVE", "DIVE", "推し活"],
    taskCount: 3,
  },
  {
    title: "K-POP投票初心者ガイド",
    description: "初めての方におすすめの投票をまとめました！一緒に推し活始めましょう✨",
    tags: ["初心者", "ガイド", "投票", "おすすめ"],
    taskCount: 6,
  },
];

// コメントテンプレート
const comments = [
  "素敵な投稿ありがとう💕",
  "私も同じ推しです！",
  "投票頑張りましょう💪",
  "最高ですね✨",
  "共感します！",
  "情報ありがとうございます🙏",
  "私も参加します！",
  "一緒に応援しましょう💜",
];

// ==================== ユーティリティ関数 ====================

function randomDate(daysAgo: number): Date {
  const date = new Date();
  date.setDate(date.getDate() - Math.floor(Math.random() * daysAgo));
  date.setHours(Math.floor(Math.random() * 24));
  date.setMinutes(Math.floor(Math.random() * 60));
  return date;
}

function randomElement<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomElements<T>(arr: T[], count: number): T[] {
  const shuffled = [...arr].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
}

// ==================== メイン処理 ====================

async function seedUsers(): Promise<string[]> {
  console.log("Creating dummy users...");
  const userIds: string[] = [];
  const now = admin.firestore.Timestamp.now();

  for (let i = 0; i < dummyUsers.length; i++) {
    const user = dummyUsers[i];
    const uid = `seed_user_${i + 1}_${uuidv4().slice(0, 8)}`;
    userIds.push(uid);

    const userData = {
      uid,
      email: `${user.username}@seed.kpopvote.app`,
      displayName: user.displayName,
      photoURL: profileImages[i],
      bio: user.bio,
      points: Math.floor(Math.random() * 500) + 100,
      premiumPoints: Math.floor(Math.random() * 100),
      regularPoints: Math.floor(Math.random() * 300) + 50,
      biasIds: user.biasIds,
      followingCount: 0,
      followersCount: 0,
      postsCount: 0,
      isPrivate: false,
      isSuspended: false,
      isSeedData: true,
      createdAt: now,
      updatedAt: now,
    };

    await db.collection("users").doc(uid).set(userData);
    console.log(`  Created user: ${user.displayName} (${uid})`);
  }

  return userIds;
}

async function seedPosts(userIds: string[]): Promise<string[]> {
  console.log("Creating community posts...");
  const postIds: string[] = [];

  for (let i = 0; i < 16; i++) {
    const userId = userIds[i % userIds.length];
    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.data()!;

    const postId = `seed_post_${i + 1}_${uuidv4().slice(0, 8)}`;
    postIds.push(postId);

    const createdAt = randomDate(14); // 過去14日以内

    // 投稿タイプを決定
    let type: string;
    let content: Record<string, unknown>;

    if (i < 8) {
      // 画像投稿
      type = "image";
      content = {
        text: postTexts[i],
        images: [postImages[i % postImages.length]],
      };
    } else if (i < 12) {
      // 投票シェア
      type = "my_votes";
      content = {
        text: postTexts[i],
        myVotes: [
          {
            id: uuidv4(),
            voteId: `sample_vote_${i}`,
            title: "サンプル投票",
            pointsUsed: Math.floor(Math.random() * 50) + 10,
            votedAt: createdAt.toISOString(),
          },
        ],
      };
    } else if (i < 14) {
      // コレクションシェア
      type = "collection";
      content = {
        text: postTexts[i],
        collectionId: `seed_collection_${i - 12}`,
        collectionTitle: collections[i - 12]?.title || "コレクション",
      };
    } else {
      // グッズ交換
      type = "goods_trade";
      content = {
        text: "グッズ交換希望です！",
        goodsTrade: {
          idolId: userData.biasIds[0] || "bts",
          idolName: "推し",
          groupName: "グループ",
          goodsImageUrl: postImages[i % postImages.length],
          goodsTags: ["トレカ", "交換"],
          goodsName: "トレーディングカード",
          tradeType: i % 2 === 0 ? "want" : "offer",
          condition: "excellent",
          description: "綺麗な状態です",
          status: "available",
        },
      };
    }

    const postData = {
      id: postId,
      userId,
      user: {
        uid: userId,
        displayName: userData.displayName,
        photoURL: userData.photoURL,
        username: userData.email?.split("@")[0] || "",
      },
      type,
      content,
      biasIds: userData.biasIds || [],
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      isReported: false,
      reportCount: 0,
      isSeedData: true,
      createdAt: admin.firestore.Timestamp.fromDate(createdAt),
      updatedAt: admin.firestore.Timestamp.fromDate(createdAt),
    };

    await db.collection("posts").doc(postId).set(postData);

    // ユーザーの投稿数を更新
    await db.collection("users").doc(userId).update({
      postsCount: admin.firestore.FieldValue.increment(1),
    });

    console.log(`  Created post: ${postId} (type: ${type})`);
  }

  return postIds;
}

async function seedCollections(userIds: string[]): Promise<string[]> {
  console.log("Creating collections...");
  const collectionIds: string[] = [];

  for (let i = 0; i < collections.length; i++) {
    const collection = collections[i];
    const userId = userIds[i % userIds.length];
    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.data()!;

    const collectionId = `seed_collection_${i + 1}_${uuidv4().slice(0, 8)}`;
    collectionIds.push(collectionId);

    const createdAt = randomDate(30);

    // ダミータスクを生成
    const tasks = [];
    for (let j = 0; j < collection.taskCount; j++) {
      tasks.push({
        taskId: uuidv4(),
        title: `投票タスク ${j + 1}`,
        url: "https://example.com/vote",
        deadline: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)),
        externalAppId: "idol_champ",
        externalAppName: "アイドルチャンプ",
        orderIndex: j,
      });
    }

    const collectionData = {
      collectionId,
      creatorId: userId,
      creatorName: userData.displayName,
      creatorAvatarUrl: userData.photoURL,
      title: collection.title,
      description: collection.description,
      coverImage: postImages[i % postImages.length],
      tags: collection.tags,
      tasks,
      taskCount: collection.taskCount,
      visibility: "public",
      likeCount: Math.floor(Math.random() * 20),
      saveCount: Math.floor(Math.random() * 15),
      viewCount: Math.floor(Math.random() * 100) + 20,
      commentCount: 0,
      isSeedData: true,
      createdAt: admin.firestore.Timestamp.fromDate(createdAt),
      updatedAt: admin.firestore.Timestamp.fromDate(createdAt),
    };

    await db.collection("collections").doc(collectionId).set(collectionData);
    console.log(`  Created collection: ${collection.title}`);
  }

  return collectionIds;
}

async function seedFollows(userIds: string[]): Promise<void> {
  console.log("Creating follow relationships...");

  // 相互フォロー (DMテスト用)
  const mutualPairs = [
    [0, 1],
    [2, 3],
    [4, 5],
    [6, 7],
  ];

  for (const [i, j] of mutualPairs) {
    const followerId = userIds[i];
    const followingId = userIds[j];

    // i -> j
    await createFollow(followerId, followingId);
    // j -> i
    await createFollow(followingId, followerId);

    console.log(`  Mutual follow: ${i} <-> ${j}`);
  }

  // 片方向フォロー
  const oneWayPairs = [
    [0, 2], [0, 4], [1, 3], [1, 5],
    [2, 6], [3, 7], [4, 0], [5, 1],
  ];

  for (const [i, j] of oneWayPairs) {
    await createFollow(userIds[i], userIds[j]);
    console.log(`  One-way follow: ${i} -> ${j}`);
  }
}

async function createFollow(followerId: string, followingId: string): Promise<void> {
  const followId = `${followerId}_${followingId}`;
  const now = admin.firestore.Timestamp.now();

  await db.collection("follows").doc(followId).set({
    id: followId,
    followerId,
    followingId,
    isSeedData: true,
    createdAt: now,
  });

  // カウンター更新
  await db.collection("users").doc(followerId).update({
    followingCount: admin.firestore.FieldValue.increment(1),
  });
  await db.collection("users").doc(followingId).update({
    followersCount: admin.firestore.FieldValue.increment(1),
  });
}

async function seedLikesAndComments(userIds: string[], postIds: string[]): Promise<void> {
  console.log("Adding likes and comments...");

  for (const postId of postIds) {
    // ランダムに2-5人がいいね
    const likers = randomElements(userIds, Math.floor(Math.random() * 4) + 2);

    for (const likerId of likers) {
      const likeId = `${postId}_${likerId}`;
      await db.collection("postLikes").doc(likeId).set({
        id: likeId,
        postId,
        userId: likerId,
        isSeedData: true,
        createdAt: admin.firestore.Timestamp.now(),
      });
    }

    // 投稿のいいね数を更新
    await db.collection("posts").doc(postId).update({
      likesCount: likers.length,
    });

    // 50%の確率で1-3コメント追加
    if (Math.random() > 0.5) {
      const commentCount = Math.floor(Math.random() * 3) + 1;
      const commenters = randomElements(userIds, commentCount);

      for (const commenterId of commenters) {
        const commenterDoc = await db.collection("users").doc(commenterId).get();
        const commenterData = commenterDoc.data()!;

        const commentId = uuidv4();
        await db.collection("comments").doc(commentId).set({
          id: commentId,
          postId,
          userId: commenterId,
          text: randomElement(comments),
          user: {
            uid: commenterId,
            displayName: commenterData.displayName,
            photoURL: commenterData.photoURL,
          },
          isSeedData: true,
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        });
      }

      // 投稿のコメント数を更新
      await db.collection("posts").doc(postId).update({
        commentsCount: commentCount,
      });
    }

    console.log(`  Added interactions to post: ${postId}`);
  }
}

// ==================== クリーンアップ関数 ====================

async function cleanupSeedData(): Promise<void> {
  console.log("Cleaning up seed data...");

  const collections = ["users", "posts", "collections", "follows", "postLikes", "comments"];

  for (const col of collections) {
    const snapshot = await db.collection(col).where("isSeedData", "==", true).get();

    if (snapshot.empty) {
      console.log(`  No seed data in ${col}`);
      continue;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    console.log(`  Deleted ${snapshot.size} documents from ${col}`);
  }

  console.log("Cleanup complete!");
}

// ==================== メイン実行 ====================

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (args.includes("--cleanup")) {
    await cleanupSeedData();
    process.exit(0);
  }

  console.log("=== KPOPVOTE Seed Data Script ===\n");

  try {
    // 1. ユーザー作成
    const userIds = await seedUsers();
    console.log(`\nCreated ${userIds.length} users\n`);

    // 2. 投稿作成
    const postIds = await seedPosts(userIds);
    console.log(`\nCreated ${postIds.length} posts\n`);

    // 3. コレクション作成
    const collectionIds = await seedCollections(userIds);
    console.log(`\nCreated ${collectionIds.length} collections\n`);

    // 4. フォロー関係作成
    await seedFollows(userIds);
    console.log("\nCreated follow relationships\n");

    // 5. いいね・コメント追加
    await seedLikesAndComments(userIds, postIds);
    console.log("\nAdded likes and comments\n");

    console.log("=== Seed data creation complete! ===");
    console.log("\nTo cleanup seed data, run: npx ts-node src/scripts/seedData.ts --cleanup");
  } catch (error) {
    console.error("Error seeding data:", error);
    process.exit(1);
  }

  process.exit(0);
}

main();
