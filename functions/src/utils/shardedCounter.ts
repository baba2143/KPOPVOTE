/**
 * Sharded Counter Utility
 * Distributes write operations across multiple shard documents to overcome
 * Firestore's 1 write/sec/document limit.
 *
 * For high-traffic voting scenarios, this enables ~10x write throughput
 * by distributing votes across 10 shards.
 */

import * as admin from "firebase-admin";

/** Number of shards to distribute writes across */
export const NUM_SHARDS = 10;

/** Shard document data structure */
export interface ShardData {
  /** Vote counts per choice ID */
  choiceVotes: { [choiceId: string]: number };
  /** Total votes in this shard */
  totalVotes: number;
  /** Last update timestamp */
  updatedAt: admin.firestore.FieldValue | admin.firestore.Timestamp;
}

/** Aggregated vote counts from all shards */
export interface AggregatedVoteCounts {
  /** Total votes per choice */
  choiceVotes: { [choiceId: string]: number };
  /** Grand total of all votes */
  totalVotes: number;
}

/**
 * Get a random shard index (0 to NUM_SHARDS-1)
 */
function getRandomShardIndex(): number {
  return Math.floor(Math.random() * NUM_SHARDS);
}

/**
 * Get shard document reference
 * @param db Firestore instance
 * @param voteId Vote document ID
 * @param shardIndex Shard index (0 to NUM_SHARDS-1)
 */
function getShardRef(
  db: admin.firestore.Firestore,
  voteId: string,
  shardIndex: number
): admin.firestore.DocumentReference {
  return db
    .collection("inAppVotes")
    .doc(voteId)
    .collection("shards")
    .doc(`shard_${shardIndex}`);
}

/**
 * Initialize vote shards when creating a new vote
 * Creates NUM_SHARDS shard documents with zero counts for each choice
 *
 * @param db Firestore instance
 * @param voteId Vote document ID
 * @param choiceIds Array of choice IDs to initialize
 */
export async function initializeVoteShards(
  db: admin.firestore.Firestore,
  voteId: string,
  choiceIds: string[]
): Promise<void> {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Initialize choice votes object with zero counts
  const initialChoiceVotes: { [choiceId: string]: number } = {};
  for (const choiceId of choiceIds) {
    initialChoiceVotes[choiceId] = 0;
  }

  // Create all shard documents
  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = getShardRef(db, voteId, i);
    const shardData: ShardData = {
      choiceVotes: { ...initialChoiceVotes },
      totalVotes: 0,
      updatedAt: now,
    };
    batch.set(shardRef, shardData);
  }

  await batch.commit();
  console.log(`✅ [shardedCounter] Initialized ${NUM_SHARDS} shards for vote: ${voteId}`);
}

/**
 * Increment vote count in a random shard (within a transaction)
 * Use this instead of directly updating the parent vote document
 *
 * @param transaction Firestore transaction
 * @param db Firestore instance
 * @param voteId Vote document ID
 * @param choiceId Choice ID to increment
 * @param voteCount Number of votes to add (default: 1)
 * @returns The shard index that was updated
 */
export function incrementVoteShardInTransaction(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  voteId: string,
  choiceId: string,
  voteCount: number = 1
): number {
  const shardIndex = getRandomShardIndex();
  const shardRef = getShardRef(db, voteId, shardIndex);

  // Use FieldValue.increment for atomic updates
  transaction.update(shardRef, {
    [`choiceVotes.${choiceId}`]: admin.firestore.FieldValue.increment(voteCount),
    totalVotes: admin.firestore.FieldValue.increment(voteCount),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return shardIndex;
}

/**
 * Increment vote count in a random shard (non-transactional)
 * Use when you don't need transaction guarantees
 *
 * @param db Firestore instance
 * @param voteId Vote document ID
 * @param choiceId Choice ID to increment
 * @param voteCount Number of votes to add (default: 1)
 * @returns The shard index that was updated
 */
export async function incrementVoteShard(
  db: admin.firestore.Firestore,
  voteId: string,
  choiceId: string,
  voteCount: number = 1
): Promise<number> {
  const shardIndex = getRandomShardIndex();
  const shardRef = getShardRef(db, voteId, shardIndex);

  await shardRef.update({
    [`choiceVotes.${choiceId}`]: admin.firestore.FieldValue.increment(voteCount),
    totalVotes: admin.firestore.FieldValue.increment(voteCount),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return shardIndex;
}

/**
 * Get aggregated vote counts from all shards
 * Use this for real-time ranking or for aggregation jobs
 *
 * @param db Firestore instance
 * @param voteId Vote document ID
 * @returns Aggregated vote counts across all shards
 */
export async function getAggregatedVoteCounts(
  db: admin.firestore.Firestore,
  voteId: string
): Promise<AggregatedVoteCounts> {
  const shardsSnapshot = await db
    .collection("inAppVotes")
    .doc(voteId)
    .collection("shards")
    .get();

  const aggregated: AggregatedVoteCounts = {
    choiceVotes: {},
    totalVotes: 0,
  };

  for (const doc of shardsSnapshot.docs) {
    const data = doc.data() as ShardData;

    // Aggregate total votes
    aggregated.totalVotes += data.totalVotes || 0;

    // Aggregate choice votes
    if (data.choiceVotes) {
      for (const [choiceId, count] of Object.entries(data.choiceVotes)) {
        if (!aggregated.choiceVotes[choiceId]) {
          aggregated.choiceVotes[choiceId] = 0;
        }
        aggregated.choiceVotes[choiceId] += count;
      }
    }
  }

  return aggregated;
}

/**
 * Update parent vote document with aggregated counts from shards
 * Call this from a scheduled function to keep the parent document updated
 *
 * @param db Firestore instance
 * @param voteId Vote document ID
 * @returns The aggregated counts that were written
 */
export async function syncVoteCountsToParent(
  db: admin.firestore.Firestore,
  voteId: string
): Promise<AggregatedVoteCounts | null> {
  const voteRef = db.collection("inAppVotes").doc(voteId);
  const voteDoc = await voteRef.get();

  if (!voteDoc.exists) {
    console.warn(`[shardedCounter] Vote not found: ${voteId}`);
    return null;
  }

  const voteData = voteDoc.data()!;
  const aggregated = await getAggregatedVoteCounts(db, voteId);

  // Update choices array with new vote counts
  const updatedChoices = voteData.choices.map(
    (choice: { choiceId: string; label: string; voteCount: number }) => ({
      ...choice,
      voteCount: aggregated.choiceVotes[choice.choiceId] || 0,
    })
  );

  // Update parent document
  await voteRef.update({
    choices: updatedChoices,
    totalVotes: aggregated.totalVotes,
    lastAggregatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(
    `✅ [shardedCounter] Synced vote counts for ${voteId}: total=${aggregated.totalVotes}`
  );

  return aggregated;
}

/**
 * Check if shards exist for a vote
 * @param db Firestore instance
 * @param voteId Vote document ID
 * @returns true if shards exist
 */
export async function shardsExist(
  db: admin.firestore.Firestore,
  voteId: string
): Promise<boolean> {
  const shardRef = getShardRef(db, voteId, 0);
  const doc = await shardRef.get();
  return doc.exists;
}

// ============================================
// Idol Ranking Sharded Counter
// ============================================

/** Idol ranking shard data structure */
export interface IdolRankingShardData {
  /** Weekly votes in this shard */
  weeklyVotes: number;
  /** Total votes in this shard */
  totalVotes: number;
  /** Last update timestamp */
  updatedAt: admin.firestore.FieldValue | admin.firestore.Timestamp;
}

/** Aggregated idol ranking counts */
export interface AggregatedIdolRankingCounts {
  weeklyVotes: number;
  totalVotes: number;
}

/**
 * Get idol ranking shard reference
 */
function getIdolRankingShardRef(
  db: admin.firestore.Firestore,
  entityId: string,
  shardIndex: number
): admin.firestore.DocumentReference {
  return db
    .collection("idolRankings")
    .doc(entityId)
    .collection("shards")
    .doc(`shard_${shardIndex}`);
}

/**
 * Initialize idol ranking shards
 * @param db Firestore instance
 * @param entityId Entity (idol/group) ID
 */
export async function initializeIdolRankingShards(
  db: admin.firestore.Firestore,
  entityId: string
): Promise<void> {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = getIdolRankingShardRef(db, entityId, i);
    const shardData: IdolRankingShardData = {
      weeklyVotes: 0,
      totalVotes: 0,
      updatedAt: now,
    };
    batch.set(shardRef, shardData);
  }

  await batch.commit();
  console.log(`✅ [shardedCounter] Initialized idol ranking shards for: ${entityId}`);
}

/**
 * Increment idol ranking vote in a random shard (within transaction)
 */
export function incrementIdolRankingShardInTransaction(
  transaction: admin.firestore.Transaction,
  db: admin.firestore.Firestore,
  entityId: string,
  voteCount: number = 1
): number {
  const shardIndex = getRandomShardIndex();
  const shardRef = getIdolRankingShardRef(db, entityId, shardIndex);

  transaction.update(shardRef, {
    weeklyVotes: admin.firestore.FieldValue.increment(voteCount),
    totalVotes: admin.firestore.FieldValue.increment(voteCount),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return shardIndex;
}

/**
 * Get aggregated idol ranking counts from all shards
 */
export async function getAggregatedIdolRankingCounts(
  db: admin.firestore.Firestore,
  entityId: string
): Promise<AggregatedIdolRankingCounts> {
  const shardsSnapshot = await db
    .collection("idolRankings")
    .doc(entityId)
    .collection("shards")
    .get();

  const aggregated: AggregatedIdolRankingCounts = {
    weeklyVotes: 0,
    totalVotes: 0,
  };

  for (const doc of shardsSnapshot.docs) {
    const data = doc.data() as IdolRankingShardData;
    aggregated.weeklyVotes += data.weeklyVotes || 0;
    aggregated.totalVotes += data.totalVotes || 0;
  }

  return aggregated;
}

/**
 * Sync idol ranking counts to parent document
 */
export async function syncIdolRankingCountsToParent(
  db: admin.firestore.Firestore,
  entityId: string
): Promise<AggregatedIdolRankingCounts | null> {
  const rankingRef = db.collection("idolRankings").doc(entityId);
  const rankingDoc = await rankingRef.get();

  if (!rankingDoc.exists) {
    console.warn(`[shardedCounter] Idol ranking not found: ${entityId}`);
    return null;
  }

  const aggregated = await getAggregatedIdolRankingCounts(db, entityId);

  await rankingRef.update({
    weeklyVotes: aggregated.weeklyVotes,
    totalVotes: aggregated.totalVotes,
    lastAggregatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(
    `✅ [shardedCounter] Synced idol ranking for ${entityId}: ` +
    `weekly=${aggregated.weeklyVotes}, total=${aggregated.totalVotes}`
  );

  return aggregated;
}

/**
 * Check if idol ranking shards exist
 */
export async function idolRankingShardsExist(
  db: admin.firestore.Firestore,
  entityId: string
): Promise<boolean> {
  const shardRef = getIdolRankingShardRef(db, entityId, 0);
  const doc = await shardRef.get();
  return doc.exists;
}

/**
 * Reset weekly votes in all shards (for weekly reset job)
 */
export async function resetIdolRankingWeeklyVotes(
  db: admin.firestore.Firestore,
  entityId: string
): Promise<void> {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = getIdolRankingShardRef(db, entityId, i);
    batch.update(shardRef, {
      weeklyVotes: 0,
      updatedAt: now,
    });
  }

  await batch.commit();
  console.log(`✅ [shardedCounter] Reset weekly votes for: ${entityId}`);
}

/**
 * Reset total votes in all shards (for monthly reset job)
 */
export async function resetIdolRankingMonthlyVotes(
  db: admin.firestore.Firestore,
  entityId: string
): Promise<void> {
  const batch = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (let i = 0; i < NUM_SHARDS; i++) {
    const shardRef = getIdolRankingShardRef(db, entityId, i);
    batch.update(shardRef, {
      weeklyVotes: 0,
      totalVotes: 0,
      updatedAt: now,
    });
  }

  await batch.commit();
  console.log(`✅ [shardedCounter] Reset monthly votes for: ${entityId}`);
}
