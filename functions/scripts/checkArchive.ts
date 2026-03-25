/**
 * Check Archive Data in Firestore
 */

import * as admin from "firebase-admin";

admin.initializeApp({
  projectId: "kpopvote-9de2b",
});

const db = admin.firestore();

async function main() {
  console.log("🔍 Checking idolRankingArchives collection...\n");

  const archivesSnapshot = await db.collection("idolRankingArchives").get();

  if (archivesSnapshot.empty) {
    console.log("❌ No archives found in idolRankingArchives collection");
  } else {
    console.log(`✅ Found ${archivesSnapshot.size} archive(s):\n`);

    archivesSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      console.log(`Document ID: ${doc.id}`);
      console.log(`  archiveId: ${data.archiveId}`);
      console.log(`  archiveType: ${data.archiveType}`);
      console.log(`  year: ${data.year}`);
      console.log(`  month: ${data.month}`);
      console.log(`  individual count: ${data.rankings?.individual?.length || 0}`);
      console.log(`  group count: ${data.rankings?.group?.length || 0}`);
      console.log("");
    });
  }

  process.exit(0);
}

main().catch(console.error);
