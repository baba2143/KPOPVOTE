/**
 * Sharded Counter for Idol Ranking Votes
 *
 * Firestore has a limit of ~1 write/sec per document.
 * This distributes writes across NUM_SHARDS sub-documents to allow
 * up to NUM_SHARDS concurrent writes per entity.
 *
 * Structure:
 *   idolRankingVotes/{entityType}_{entityId}/shards/shard_0..9
 *   Each shard: { weeklyVotes: number, allTimeVotes: number, updatedAt: timestamp }
 *
 * The parent document (idolRankingVotes/{entityType}_{entityId}) holds the
 * aggregated totals and entity metadata. It is updated periodically by a
 * scheduled aggregation function.
 */

import * as admin from "firebase-admin";

export const NUM_SHARDS = 10;
const COLLECTION = "idolRankingVotes";

/**
 * Get the shards subcollection reference for an entity.
 */
function getShardsRef(
  db: admin.firestore.Firestore,
  voteDocId: string
): admin.firestore.CollectionReference {
  return db.collection(COLLECTION).doc(voteDocId).collection("shards");
}

/**
 * Initialize shard sub-documents for a new entity.
 * Should be called when a new idolRankingVotes document is created.
 *
 * @param db - Firestore instance
 * @param voteDocId - The parent document ID (e.g. "individual_abc123")
 * @param initialWeeklyVotes - Initial weekly votes to put in shard_0 (default 0)
 * @param initialAllTimeVotes - Initial allTime votes to put in shard_0 (default 0)
 */
export async function initializeShards(
  db: admin.firestore.Firestore,
  voteDocId: string,
  initialWeeklyVotes: number = 0,
  initialAllTimeVotes: number = 0
): Promise<void> {
  const shardsRef = getShardsRef(db, voteDocId);
  const batch = db.batch();

  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = shardsRef.doc(`shard_${i}`);
    batch.set(shardRef, {
      weeklyVotes: i === 0 ? initialWeeklyVotes : 0,
      allTimeVotes: i === 0 ? initialAllTimeVotes : 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
}

/**
 * Increment a random shard's vote counts within a transaction.
 * This is the core write-distribution mechanism.
 *
 * @param transaction - Active Firestore transaction
 * @param db - Firestore instance
 * @param voteDocId - The parent document ID
 * @param incrementAmount - How much to increment (default 1)
 */
export function incrementShardInTransaction(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  voteDocId: string,
  incrementAmount: number = 1
): void {
  const shardIndex = Math.floor(Math.random() * NUM_SHARDS);
  const shardRef = getShardsRef(db, voteDocId).doc(`shard_${shardIndex}`);

  transaction.update(shardRef, {
    weeklyVotes: admin.firestore.FieldValue.increment(incrementAmount),
    allTimeVotes: admin.firestore.FieldValue.increment(incrementAmount),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Read all shards and aggregate the total vote counts.
 * Used by the scheduled aggregation function.
 *
 * @param db - Firestore instance
 * @param voteDocId - The parent document ID
 * @returns Aggregated weeklyVotes and allTimeVotes
 */
export async function getAggregatedCounts(
  db: admin.firestore.Firestore,
  voteDocId: string
): Promise<{ weeklyVotes: number; allTimeVotes: number }> {
  const shardsSnapshot = await getShardsRef(db, voteDocId).get();

  let weeklyVotes = 0;
  let allTimeVotes = 0;

  shardsSnapshot.docs.forEach((doc) => {
    const data = doc.data();
    weeklyVotes += data.weeklyVotes || 0;
    allTimeVotes += data.allTimeVotes || 0;
  });

  return { weeklyVotes, allTimeVotes };
}

/**
 * Reset weekly votes across all shards for an entity.
 * Used by the weekly reset scheduled function.
 *
 * @param db - Firestore instance
 * @param voteDocId - The parent document ID
 */
export async function resetWeeklyVotesInShards(
  db: admin.firestore.Firestore,
  voteDocId: string
): Promise<void> {
  const shardsSnapshot = await getShardsRef(db, voteDocId).get();
  const batch = db.batch();

  shardsSnapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {
      weeklyVotes: 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
}

/**
 * Check if shards exist for a given entity.
 */
export async function shardsExist(
  db: admin.firestore.Firestore,
  voteDocId: string
): Promise<boolean> {
  const snapshot = await getShardsRef(db, voteDocId).limit(1).get();
  return !snapshot.empty;
}
