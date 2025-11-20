/**
 * Seed test users for search and discovery feature testing
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const seedTestUsers = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const db = admin.firestore();
    const batch = db.batch();

    // Get existing idol IDs from database
    const idolsSnapshot = await db.collection("idols").limit(10).get();
    const idolIds = idolsSnapshot.docs.map((doc) => doc.id);

    if (idolIds.length === 0) {
      res.status(400).json({
        success: false,
        error: "No idols found. Please create idols first.",
      });
      return;
    }

    // Create 10 test users with different biases
    const testUsers = [
      {
        id: "test_user_1",
        displayName: "ミナ",
        photoURL: "https://via.placeholder.com/150",
        bio: "K-POP大好き！",
        selectedIdols: [idolIds[0], idolIds[1]],
        followersCount: 15,
        followingCount: 20,
        postsCount: 5,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "test_user_2",
        displayName: "ユリ",
        photoURL: "https://via.placeholder.com/150",
        bio: "毎日投票してます！",
        selectedIdols: [idolIds[0], idolIds[2]],
        followersCount: 30,
        followingCount: 25,
        postsCount: 12,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "test_user_3",
        displayName: "サクラ",
        photoURL: "https://via.placeholder.com/150",
        bio: "新人です！よろしく",
        selectedIdols: [idolIds[1], idolIds[2]],
        followersCount: 8,
        followingCount: 15,
        postsCount: 3,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "test_user_4",
        displayName: "ハナ",
        photoURL: "https://via.placeholder.com/150",
        bio: "K-POP最高！",
        selectedIdols: [idolIds[0]],
        followersCount: 50,
        followingCount: 40,
        postsCount: 25,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "test_user_5",
        displayName: "アヤ",
        photoURL: "https://via.placeholder.com/150",
        bio: "推し活楽しい",
        selectedIdols: [idolIds[1], idolIds[3] || idolIds[1]],
        followersCount: 22,
        followingCount: 18,
        postsCount: 8,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    ];

    // Add users to batch
    testUsers.forEach((user) => {
      const userRef = db.collection("users").doc(user.id);
      batch.set(userRef, user);
    });

    // Create some test posts
    const now = new Date();
    const testPosts = [
      {
        userId: "test_user_1",
        content: "今日のライブ最高だった！",
        biasId: idolIds[0],
        biasName: "Idol Name",
        createdAt: new Date(now.getTime() - 2 * 60 * 60 * 1000), // 2 hours ago
        likesCount: 5,
        commentsCount: 2,
      },
      {
        userId: "test_user_2",
        content: "新曲リリース楽しみ！",
        biasId: idolIds[0],
        biasName: "Idol Name",
        createdAt: new Date(now.getTime() - 5 * 60 * 60 * 1000), // 5 hours ago
        likesCount: 10,
        commentsCount: 3,
      },
      {
        userId: "test_user_4",
        content: "みんな投票しよう！",
        biasId: idolIds[1],
        biasName: "Idol Name 2",
        createdAt: new Date(now.getTime() - 1 * 60 * 60 * 1000), // 1 hour ago
        likesCount: 15,
        commentsCount: 5,
      },
    ];

    testPosts.forEach((post) => {
      const postRef = db.collection("posts").doc();
      batch.set(postRef, post);
    });

    // Commit batch
    await batch.commit();

    res.json({
      success: true,
      message: `Created ${testUsers.length} test users and ${testPosts.length} test posts`,
      users: testUsers.map((u) => ({
        id: u.id,
        displayName: u.displayName,
      })),
    });
  } catch (error) {
    console.error("Error seeding test users:", error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
