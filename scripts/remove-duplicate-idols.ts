/**
 * Remove duplicate idol entries from Firestore
 *
 * Duplicates are identified by name + groupName combination.
 * When duplicates are found, keeps the oldest entry (by createdAt) and deletes newer ones.
 *
 * Usage:
 *   npm run remove-duplicates
 */

import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Initialize Firebase Admin (using Application Default Credentials)
// Make sure you're logged in with: firebase login
admin.initializeApp({
  projectId: 'kpopvote-9de2b',
});

const db = admin.firestore();

interface IdolDoc {
  id: string;
  name: string;
  groupName: string;
  imageUrl?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt?: admin.firestore.Timestamp;
}

async function removeDuplicateIdols() {
  console.log('🔍 Checking for duplicate idols...\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    // Fetch all idols
    const snapshot = await db.collection('idolMasters').get();
    console.log(`📊 Total idols in database: ${snapshot.size}\n`);

    // Group by name + groupName
    const idolGroups = new Map<string, IdolDoc[]>();

    snapshot.forEach((doc) => {
      const data = doc.data();
      const idol: IdolDoc = {
        id: doc.id,
        name: data.name,
        groupName: data.groupName,
        imageUrl: data.imageUrl,
        createdAt: data.createdAt,
        updatedAt: data.updatedAt,
      };

      const key = `${idol.name}_${idol.groupName}`;

      if (!idolGroups.has(key)) {
        idolGroups.set(key, []);
      }
      idolGroups.get(key)!.push(idol);
    });

    // Find duplicates
    const duplicates: { key: string; idols: IdolDoc[] }[] = [];

    idolGroups.forEach((idols, key) => {
      if (idols.length > 1) {
        duplicates.push({ key, idols });
      }
    });

    console.log(`🔎 Found ${duplicates.length} duplicate groups\n`);

    if (duplicates.length === 0) {
      console.log('✅ No duplicates found. Database is clean!\n');
      return;
    }

    // Delete duplicates (keep oldest, delete newer ones)
    let totalDeleted = 0;
    let batch = db.batch();
    let batchCount = 0;

    for (const { key, idols } of duplicates) {
      // Sort by createdAt (oldest first)
      idols.sort((a, b) => a.createdAt.toMillis() - b.createdAt.toMillis());

      const keepIdol = idols[0];
      const deleteIdols = idols.slice(1);

      console.log(`📝 ${key}:`);
      console.log(`  ✅ Keeping: ${keepIdol.id} (created: ${keepIdol.createdAt.toDate().toISOString()})`);

      for (const deleteIdol of deleteIdols) {
        console.log(`  ❌ Deleting: ${deleteIdol.id} (created: ${deleteIdol.createdAt.toDate().toISOString()})`);
        batch.delete(db.collection('idolMasters').doc(deleteIdol.id));
        totalDeleted++;
        batchCount++;

        // Firestore batch limit is 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          console.log(`\n💾 Committed batch (${batchCount} deletions)\n`);
          batch = db.batch(); // Create new batch
          batchCount = 0;
        }
      }
      console.log('');
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`💾 Committed final batch (${batchCount} deletions)\n`);
    }

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 Removal Summary');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`Total duplicate groups: ${duplicates.length}`);
    console.log(`Total duplicates deleted: ${totalDeleted}`);
    console.log(`Remaining unique idols: ${snapshot.size - totalDeleted}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('✨ Done! Refresh the admin panel to see the changes.\n');
  } catch (error: any) {
    console.error('❌ Error removing duplicates:', error.message);
    process.exit(1);
  } finally {
    // Clean up
    await admin.app().delete();
  }
}

// Run the script
removeDuplicateIdols();
