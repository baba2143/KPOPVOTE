/**
 * Create test mutual follow relationships for DM testing
 * テスト用に相互フォロー関係を作成
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const createTestMutualFollow = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const { userId, testUserId } = req.body;

    if (!userId) {
      res.status(400).json({
        success: false,
        error: "userId is required",
      });
      return;
    }

    const db = admin.firestore();
    const batch = db.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();

    // Use provided testUserId or default to test_user_1
    const targetTestUserId = testUserId || "test_user_dm";

    // Check if test user exists, create if not
    const testUserRef = db.collection("users").doc(targetTestUserId);
    const testUserDoc = await testUserRef.get();

    if (!testUserDoc.exists) {
      // Create test user for DM testing
      batch.set(testUserRef, {
        id: targetTestUserId,
        displayName: "DMテストユーザー",
        photoURL: "https://via.placeholder.com/150",
        bio: "DM機能テスト用のユーザーです",
        selectedIdols: [],
        followersCount: 1,
        followingCount: 1,
        postsCount: 0,
        createdAt: now,
        updatedAt: now,
      });
    }

    // Create mutual follow: userId -> testUserId
    const follow1Id = `${userId}_${targetTestUserId}`;
    const follow1Ref = db.collection("follows").doc(follow1Id);
    const follow1Doc = await follow1Ref.get();

    if (!follow1Doc.exists) {
      batch.set(follow1Ref, {
        id: follow1Id,
        followerId: userId,
        followingId: targetTestUserId,
        createdAt: now,
      });
    }

    // Create mutual follow: testUserId -> userId
    const follow2Id = `${targetTestUserId}_${userId}`;
    const follow2Ref = db.collection("follows").doc(follow2Id);
    const follow2Doc = await follow2Ref.get();

    if (!follow2Doc.exists) {
      batch.set(follow2Ref, {
        id: follow2Id,
        followerId: targetTestUserId,
        followingId: userId,
        createdAt: now,
      });
    }

    // Update follower/following counts
    const realUserRef = db.collection("users").doc(userId);
    const realUserDoc = await realUserRef.get();

    if (realUserDoc.exists) {
      batch.update(realUserRef, {
        followersCount: admin.firestore.FieldValue.increment(follow2Doc.exists ? 0 : 1),
        followingCount: admin.firestore.FieldValue.increment(follow1Doc.exists ? 0 : 1),
        updatedAt: now,
      });
    }

    if (testUserDoc.exists) {
      batch.update(testUserRef, {
        followersCount: admin.firestore.FieldValue.increment(follow1Doc.exists ? 0 : 1),
        followingCount: admin.firestore.FieldValue.increment(follow2Doc.exists ? 0 : 1),
        updatedAt: now,
      });
    }

    await batch.commit();

    res.json({
      success: true,
      message: "Mutual follow relationship created successfully",
      data: {
        userId,
        testUserId: targetTestUserId,
        follow1Id,
        follow2Id,
      },
    });
  } catch (error) {
    console.error("Error creating test mutual follow:", error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
