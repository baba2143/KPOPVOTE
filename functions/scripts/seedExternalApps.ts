/**
 * Seed script for External App Masters
 *
 * Usage:
 *   npx ts-node scripts/seedExternalApps.ts
 *
 * Requirements:
 *   - Firebase Admin SDK initialized
 *   - Service account credentials
 */

import * as admin from "firebase-admin";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Initial external app master data
const externalApps = [
  {
    appId: "idol-champ",
    appName: "IDOL CHAMP",
    appUrl: "https://www.idolchamp.com",
    iconUrl: "https://firebasestorage.googleapis.com/v0/b/kpopvote-9de2b.appspot.com/o/app-icons%2Fidol_champ.png?alt=media",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    appId: "mnet-plus",
    appName: "Mnet Plus",
    appUrl: "https://www.mnetplus.world",
    iconUrl: "https://firebasestorage.googleapis.com/v0/b/kpopvote-9de2b.appspot.com/o/app-icons%2Fmnet_plus.png?alt=media",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
  {
    appId: "mubeat",
    appName: "MUBEAT",
    appUrl: "https://www.mubeat.io",
    iconUrl: "https://firebasestorage.googleapis.com/v0/b/kpopvote-9de2b.appspot.com/o/app-icons%2Fmubeat.png?alt=media",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  },
];

async function seedExternalApps() {
  console.log("🚀 Starting external app master seeding...");

  try {
    for (const app of externalApps) {
      const { appId, ...appData } = app;

      // Check if app already exists
      const docRef = db.collection("externalAppMasters").doc(appId);
      const doc = await docRef.get();

      if (doc.exists) {
        console.log(`⚠️  External app "${app.appName}" (${appId}) already exists, skipping...`);
      } else {
        await docRef.set(appData);
        console.log(`✅ Created external app "${app.appName}" (${appId})`);
      }
    }

    console.log("\n✨ External app master seeding completed successfully!");
    console.log(`📊 Total apps: ${externalApps.length}`);

  } catch (error) {
    console.error("❌ Error seeding external apps:", error);
    process.exit(1);
  }

  process.exit(0);
}

// Run the seed script
seedExternalApps();
