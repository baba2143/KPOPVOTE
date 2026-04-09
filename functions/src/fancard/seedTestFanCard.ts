/**
 * Seed test FanCard data
 * Run with: npx ts-node src/fancard/seedTestFanCard.ts
 */

import * as admin from "firebase-admin";
import * as path from "path";

// Initialize Firebase Admin with service account
const serviceAccountPath = path.join(__dirname, "../../serviceAccountKey.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
  });
}

const db = admin.firestore();

async function seedTestFanCard() {
  const testFanCard = {
    odDisplayName: "jimin-love",
    userId: "test-user-001",
    displayName: "ジミンペン🐥",
    bio: "2019年からBTS推し💜\nジミンのダンスと笑顔が大好き！\n一緒に推し活しましょう✨",
    profileImageUrl: "",
    headerImageUrl: "",
    theme: {
      template: "elegant",
      backgroundColor: "#faf5ff",
      primaryColor: "#9333ea",
      fontFamily: "default",
    },
    blocks: [
      {
        id: "block-1",
        type: "bias",
        order: 1,
        isVisible: true,
        data: {
          showFromMyBias: false,
          customBias: [
            {
              artistId: "bts",
              artistName: "BTS",
              memberId: "jimin",
              memberName: "ジミン",
            },
            {
              artistId: "seventeen",
              artistName: "SEVENTEEN",
              memberId: "woozi",
              memberName: "ウジ",
            },
          ],
        },
      },
      {
        id: "block-2",
        type: "mvLink",
        order: 2,
        isVisible: true,
        data: {
          title: "Filter - BTS (방탄소년단)",
          youtubeUrl: "https://www.youtube.com/watch?v=sWuYspuN6U8",
          thumbnailUrl: "https://img.youtube.com/vi/sWuYspuN6U8/hqdefault.jpg",
          artistName: "BTS",
        },
      },
      {
        id: "block-3",
        type: "mvLink",
        order: 3,
        isVisible: true,
        data: {
          title: "Dynamite - BTS (방탄소년단)",
          youtubeUrl: "https://www.youtube.com/watch?v=gdZLi9oWNZg",
          thumbnailUrl: "https://img.youtube.com/vi/gdZLi9oWNZg/hqdefault.jpg",
          artistName: "BTS",
        },
      },
      {
        id: "block-4",
        type: "link",
        order: 4,
        isVisible: true,
        data: {
          title: "🗳️ 投票アプリまとめ",
          url: "https://example.com/vote-apps",
          backgroundColor: "#ec4899",
        },
      },
      {
        id: "block-5",
        type: "sns",
        order: 5,
        isVisible: true,
        data: {
          platform: "x",
          username: "jimin_fan_2019",
          url: "https://twitter.com/jimin_fan_2019",
        },
      },
      {
        id: "block-6",
        type: "sns",
        order: 6,
        isVisible: true,
        data: {
          platform: "instagram",
          username: "jimin.love.forever",
          url: "https://instagram.com/jimin.love.forever",
        },
      },
      {
        id: "block-7",
        type: "text",
        order: 7,
        isVisible: true,
        data: {
          content: "💜 ARMY Forever 💜\n投票やストリーミング、一緒に頑張りましょう！",
          alignment: "center",
        },
      },
    ],
    isPublic: true,
    viewCount: 0,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  try {
    // Create the FanCard document
    await db.collection("fanCards").doc(testFanCard.odDisplayName).set(testFanCard);
    console.log(`✅ Test FanCard created: ${testFanCard.odDisplayName}`);
    console.log(`🔗 URL: https://fancard-p4nxxtmx7-switchmedias-projects.vercel.app/${testFanCard.odDisplayName}`);
  } catch (error) {
    console.error("❌ Error creating test FanCard:", error);
  }

  process.exit(0);
}

seedTestFanCard();
