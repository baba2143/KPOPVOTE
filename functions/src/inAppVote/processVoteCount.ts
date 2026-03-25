/**
 * Process Vote Count (Async Firestore Trigger)
 *
 * This function is triggered when a new voteHistory document is created.
 * It updates the sharded counters asynchronously, allowing executeVote
 * to return immediately for faster response times.
 *
 * Benefits:
 * - Faster executeVote response (~100ms vs ~500ms)
 * - Automatic retries on failure via Cloud Functions
 * - Better scalability for high-traffic scenarios
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { VOTE_WRITE_CONFIG } from "../utils/functionConfig";
import {
  incrementVoteShard,
  shardsExist,
} from "../utils/shardedCounter";

interface VoteHistoryData {
  id: string;
  userId: string;
  voteId: string;
  voteTitle: string;
  voteCoverImageUrl?: string;
  selectedChoiceId: string;
  selectedChoiceLabel: string;
  voteCount: number;
  votedAt: admin.firestore.Timestamp;
  // Flag to indicate if this vote has been processed
  processed?: boolean;
}

/**
 * Firestore trigger: Process vote count when voteHistory is created
 */
export const processVoteCount = functions
  .runWith(VOTE_WRITE_CONFIG)
  .firestore.document("voteHistory/{historyId}")
  .onCreate(async (snapshot, context) => {
    const historyId = context.params.historyId;
    const data = snapshot.data() as VoteHistoryData;

    // Skip if already processed (idempotency check)
    if (data.processed) {
      console.log(`[processVoteCount] Already processed: ${historyId}`);
      return null;
    }

    const { voteId, userId, selectedChoiceId, voteCount } = data;

    console.log(
      `[processVoteCount] Processing: historyId=${historyId}, ` +
      `voteId=${voteId}, choiceId=${selectedChoiceId}, count=${voteCount}`
    );

    const db = admin.firestore();

    try {
      // Check if shards exist for this vote
      const useShards = await shardsExist(db, voteId);

      if (useShards) {
        // Update sharded counter (non-transactional for better performance)
        await incrementVoteShard(db, voteId, selectedChoiceId, voteCount);
        console.log(`[processVoteCount] Shard updated for vote: ${voteId}`);
      } else {
        // Legacy vote: update parent document directly
        const voteRef = db.collection("inAppVotes").doc(voteId);
        const voteDoc = await voteRef.get();

        if (voteDoc.exists) {
          const voteData = voteDoc.data()!;
          const choices = voteData.choices;
          const choiceIndex = choices.findIndex(
            (c: { choiceId: string }) => c.choiceId === selectedChoiceId
          );

          if (choiceIndex !== -1) {
            choices[choiceIndex].voteCount += voteCount;
            await voteRef.update({
              choices,
              totalVotes: admin.firestore.FieldValue.increment(voteCount),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`[processVoteCount] Legacy vote updated: ${voteId}`);
          }
        }
      }

      // Update voteRecords (cumulative record per user per vote)
      const voteRecordRef = db.collection("voteRecords").doc(`${voteId}_${userId}`);
      await voteRecordRef.set(
        {
          voteId,
          userId,
          lastChoiceId: selectedChoiceId,
          totalVoteCount: admin.firestore.FieldValue.increment(voteCount),
          lastVotedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Mark as processed (idempotency)
      await snapshot.ref.update({ processed: true });

      console.log(`[processVoteCount] Completed: ${historyId}`);
      return null;
    } catch (error) {
      console.error(`[processVoteCount] Error processing ${historyId}:`, error);
      // Throwing error will trigger Cloud Functions retry
      throw error;
    }
  });

/**
 * Firestore trigger: Process idol ranking vote count
 * Triggered when idolRankingVotes document is created
 *
 * Performance optimization:
 * - Uses useShards flag from vote record to skip shard existence check (-10-20ms)
 * - All count updates are centralized in this trigger
 */
export const processIdolRankingVoteCount = functions
  .runWith(VOTE_WRITE_CONFIG)
  .firestore.document("idolRankingVotes/{voteId}")
  .onCreate(async (snapshot, context) => {
    const voteRecordId = context.params.voteId;
    const data = snapshot.data();

    // Skip if already processed
    if (data.processed) {
      console.log(`[processIdolRankingVoteCount] Already processed: ${voteRecordId}`);
      return null;
    }

    const { entityId, useShards } = data;

    if (!entityId) {
      console.error(`[processIdolRankingVoteCount] Missing entityId: ${voteRecordId}`);
      return null;
    }

    console.log(
      `[processIdolRankingVoteCount] Processing: voteId=${voteRecordId}, entityId=${entityId}, useShards=${useShards}`
    );

    const db = admin.firestore();

    try {
      // Use useShards flag from vote record (set by HTTP function)
      // This avoids redundant shard existence check (-10-20ms per vote)
      // Fallback to shard check only if flag is undefined (for backward compatibility)
      let shouldUseShards = useShards;
      if (shouldUseShards === undefined) {
        const { idolRankingShardsExist } = await import("../utils/shardedCounter");
        shouldUseShards = await idolRankingShardsExist(db, entityId);
        console.log(`[processIdolRankingVoteCount] Fallback shard check: ${shouldUseShards}`);
      }

      if (shouldUseShards) {
        // Use non-transactional update for better performance
        // Random shard selection for distribution
        const shardIndex = Math.floor(Math.random() * 10);
        const shardRef = db
          .collection("idolRankings")
          .doc(entityId)
          .collection("shards")
          .doc(`shard_${shardIndex}`);

        await shardRef.update({
          weeklyVotes: admin.firestore.FieldValue.increment(1),
          totalVotes: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`[processIdolRankingVoteCount] Shard updated for: ${entityId}`);
      } else {
        // Legacy: update parent document directly
        const rankingRef = db.collection("idolRankings").doc(entityId);
        await rankingRef.update({
          weeklyVotes: admin.firestore.FieldValue.increment(1),
          totalVotes: admin.firestore.FieldValue.increment(1),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`[processIdolRankingVoteCount] Legacy ranking updated: ${entityId}`);
      }

      // Mark as processed
      await snapshot.ref.update({ processed: true });

      console.log(`[processIdolRankingVoteCount] Completed: ${voteRecordId}`);
      return null;
    } catch (error) {
      console.error(`[processIdolRankingVoteCount] Error: ${voteRecordId}`, error);
      throw error;
    }
  });
