/**
 * Seed Community Test Data
 *
 * Creates test users, follows, and posts for Community feature testing
 *
 * Usage:
 *   curl -X POST https://us-central1-kpopvote-9de2b.cloudfunctions.net/seedCommunityData \
 *     -H "Content-Type: application/json"
 */

import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Test users data
const testUsers = [
  {
    uid: "test-user-1",
    email: "test1@kpopvote.com",
    password: "testpass123",
    displayName: "YUTAファン",
    biasIds: ["YUTA"], // NCT YUTA
  },
  {
    uid: "test-user-2",
    email: "test2@kpopvote.com",
    password: "testpass123",
    displayName: "K-POPラバー",
    biasIds: ["YUTA", "MARK"], // Multiple biases
  },
  {
    uid: "test-user-3",
    email: "test3@kpopvote.com",
    password: "testpass123",
    displayName: "コミュニティ太郎",
    biasIds: ["MARK"],
  },
];

// Follow relationships (follower -> following)
const followRelationships = [
  { followerId: "test-user-1", followingId: "test-user-2" },
  { followerId: "test-user-1", followingId: "test-user-3" },
  { followerId: "test-user-2", followingId: "test-user-1" },
  { followerId: "test-user-3", followingId: "test-user-1" },
  { followerId: "test-user-3", followingId: "test-user-2" },
];

// Test posts data
const testPosts = [
  // Image posts
  {
    userId: "test-user-1",
    type: "image" as const,
    content: {
      text: "NCT 127の新曲、めちゃくちゃかっこいい！🔥\nYUTAのパフォーマンスが最高でした✨",
      images: [
        "https://via.placeholder.com/400x300.png?text=NCT+127+Performance",
      ],
    },
    biasIds: ["YUTA"],
  },
  {
    userId: "test-user-2",
    type: "image" as const,
    content: {
      text: "今日のコンサート、最高の思い出になりました💚\nファンの皆さんと一緒に応援できて幸せ！",
      images: [
        "https://via.placeholder.com/400x300.png?text=Concert+Photo",
      ],
    },
    biasIds: ["YUTA", "MARK"],
  },
  {
    userId: "test-user-1",
    type: "image" as const,
    content: {
      text: "練習風景のビハインドが公開されました！\n努力している姿に感動😭",
      images: [
        "https://via.placeholder.com/400x300.png?text=Behind+The+Scenes",
      ],
    },
    biasIds: ["YUTA"],
  },
  {
    userId: "test-user-3",
    type: "image" as const,
    content: {
      text: "MARKの新しいヘアスタイル、めっちゃ似合ってる！🔥\n次のカムバックが楽しみすぎる！",
      images: [
        "https://via.placeholder.com/400x300.png?text=New+Hair+Style",
      ],
    },
    biasIds: ["MARK"],
  },
  {
    userId: "test-user-2",
    type: "image" as const,
    content: {
      text: "K-POPの魅力について語らせてください💕\nダンス、歌、ビジュアル全てが完璧！",
      images: null,
    },
    biasIds: ["YUTA", "MARK"],
  },
  // Vote share posts (referencing existing InAppVote)
  {
    userId: "test-user-1",
    type: "vote_share" as const,
    content: {
      voteId: "vote-placeholder-1", // Will be updated to actual vote ID
      voteSnapshot: null, // Will be populated from actual vote
    },
    biasIds: ["YUTA"],
  },
  {
    userId: "test-user-2",
    type: "vote_share" as const,
    content: {
      voteId: "vote-placeholder-2",
      voteSnapshot: null,
    },
    biasIds: ["YUTA", "MARK"],
  },
  // My votes posts
  {
    userId: "test-user-3",
    type: "my_votes" as const,
    content: {
      text: "今月の投票活動まとめ！頑張りました💪",
      myVotes: [], // Will be populated from voteHistory
    },
    biasIds: ["MARK"],
  },
];

export const seedCommunityData = onRequest(
  {
    region: "us-central1",
    cors: true,
  },
  async (req, res) => {
    try {
      // CORS preflight
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      // Only allow POST
      if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
      }

      logger.info("Starting community data seeding...");

      const db = admin.firestore();
      const auth = admin.auth();
      const results = {
        users: [] as Array<{ uid: string; email: string; status: string }>,
        follows: 0,
        posts: 0,
      };

      // Step 1: Create test users
      logger.info("Creating test users...");
      for (const user of testUsers) {
        try {
          try {
            // Try to get existing user
            await auth.getUser(user.uid);
            logger.info(`User ${user.email} already exists`);
            results.users.push({
              uid: user.uid,
              email: user.email,
              status: "exists",
            });
          } catch (error) {
            // Create new user
            await auth.createUser({
              uid: user.uid,
              email: user.email,
              password: user.password,
              displayName: user.displayName,
            });
            logger.info(`Created user ${user.email}`);
            results.users.push({
              uid: user.uid,
              email: user.email,
              status: "created",
            });
          }

          // Create or update Firestore user profile
          const userRef = db.collection("users").doc(user.uid);
          await userRef.set({
            email: user.email,
            displayName: user.displayName,
            photoURL: null,
            followingCount: 0,
            followersCount: 0,
            postsCount: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          // Set bias
          const biasRef = db.collection("bias").doc(user.uid);
          await biasRef.set({
            selectedIdols: user.biasIds,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
        } catch (error) {
          logger.error(`Error creating user ${user.email}:`, error);
        }
      }

      // Step 2: Create follow relationships
      logger.info("Creating follow relationships...");
      for (const follow of followRelationships) {
        const followRef = db.collection("follows").doc();
        await followRef.set({
          followerId: follow.followerId,
          followingId: follow.followingId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update counts (use set with merge to handle non-existent documents)
        await db.collection("users").doc(follow.followerId).set({
          followingCount: admin.firestore.FieldValue.increment(1),
        }, { merge: true });
        await db.collection("users").doc(follow.followingId).set({
          followersCount: admin.firestore.FieldValue.increment(1),
        }, { merge: true });

        results.follows++;
      }

      // Step 3: Get actual vote data for vote_share posts
      logger.info("Fetching vote data...");
      const votesSnapshot = await db.collection("inAppVotes")
        .where("status", "==", "active")
        .limit(2)
        .get();

      const actualVotes = votesSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Step 4: Create posts
      logger.info("Creating posts...");
      for (const post of testPosts) {
        let postContent: Record<string, unknown> = post.content;

        // Update vote_share posts with actual vote data
        if (post.type === "vote_share" && actualVotes.length > 0) {
          const voteIndex = results.posts % actualVotes.length;
          const vote = actualVotes[voteIndex] as Record<string, unknown>;
          postContent = {
            voteId: vote.id,
            voteSnapshot: {
              voteId: vote.id,
              title: vote.title,
              description: vote.description,
              coverImageUrl: vote.coverImageUrl || null,
              choices: vote.choices || [],
              startDate: vote.startDate,
              endDate: vote.endDate,
              requiredPoints: vote.requiredPoints,
              status: vote.status,
              totalVotes: vote.totalVotes || 0,
              isFeatured: vote.isFeatured || false,
            },
          };
        }

        // Update my_votes posts with actual vote history
        if (post.type === "my_votes") {
          const historySnapshot = await db.collection("voteHistory")
            .where("userId", "==", post.userId)
            .limit(3)
            .get();

          if (!historySnapshot.empty) {
            postContent = {
              ...post.content,
              myVotes: historySnapshot.docs.map((doc) => {
                const data = doc.data();
                return {
                  id: doc.id,
                  voteId: data.voteId,
                  title: data.voteTitle || "投票",
                  selectedChoiceId: data.selectedChoiceId || null,
                  selectedChoiceLabel: data.selectedChoiceLabel || null,
                  pointsUsed: data.pointsUsed,
                  votedAt: data.votedAt?.toDate().toISOString() || new Date().toISOString(),
                };
              }),
            } as Record<string, unknown>;
          }
        }

        const postRef = db.collection("posts").doc();
        await postRef.set({
          id: postRef.id,
          userId: post.userId,
          type: post.type,
          content: postContent,
          biasIds: post.biasIds,
          likesCount: Math.floor(Math.random() * 50), // Random likes 0-50
          commentsCount: Math.floor(Math.random() * 20), // Random comments 0-20
          sharesCount: 0,
          isReported: false,
          reportCount: 0,
          createdAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000) // Random within last 7 days
          ),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update user's postsCount (use set with merge)
        await db.collection("users").doc(post.userId).set({
          postsCount: admin.firestore.FieldValue.increment(1),
        }, { merge: true });

        results.posts++;
      }

      logger.info("Community data seeding completed successfully");

      res.status(200).json({
        success: true,
        message: "Community data seeding completed",
        results: {
          users: results.users,
          followsCreated: results.follows,
          postsCreated: results.posts,
        },
      });
    } catch (error) {
      logger.error("Error seeding community data:", error);
      res.status(500).json({
        success: false,
        error: "Failed to seed community data",
        details: error instanceof Error ? error.message : String(error),
      });
    }
  }
);
