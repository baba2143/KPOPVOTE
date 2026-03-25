/**
 * Batch utility functions for Firestore operations
 * Firestore's getAll() has a limit of 10 documents, so we batch in groups of 10
 */

import * as admin from "firebase-admin";

/**
 * Batch get documents from a collection by IDs
 * Handles Firestore's 10 document limit per getAll() call
 *
 * @param db - Firestore database instance
 * @param collection - Collection name
 * @param ids - Array of document IDs to fetch
 * @returns Map of document ID to DocumentSnapshot
 */
export async function batchGetDocs(
  db: admin.firestore.Firestore,
  collection: string,
  ids: string[]
): Promise<Map<string, admin.firestore.DocumentSnapshot>> {
  if (ids.length === 0) return new Map();

  const results = new Map<string, admin.firestore.DocumentSnapshot>();
  const uniqueIds = [...new Set(ids)]; // Remove duplicates

  // Batch in groups of 10 (Firestore limit)
  for (let i = 0; i < uniqueIds.length; i += 10) {
    const batch = uniqueIds.slice(i, i + 10);
    const refs = batch.map((id) => db.collection(collection).doc(id));
    const docs = await db.getAll(...refs);
    docs.forEach((doc) => results.set(doc.id, doc));
  }

  return results;
}

/**
 * Batch get documents by full document paths
 * Useful for fetching documents from different collections or with complex IDs
 *
 * @param db - Firestore database instance
 * @param refs - Array of DocumentReferences
 * @returns Map of document ID to DocumentSnapshot
 */
export async function batchGetDocsByRefs(
  db: admin.firestore.Firestore,
  refs: admin.firestore.DocumentReference[]
): Promise<Map<string, admin.firestore.DocumentSnapshot>> {
  if (refs.length === 0) return new Map();

  const results = new Map<string, admin.firestore.DocumentSnapshot>();
  const uniqueRefs = [...new Map(refs.map((ref) => [ref.path, ref])).values()]; // Remove duplicates

  // Batch in groups of 10 (Firestore limit)
  for (let i = 0; i < uniqueRefs.length; i += 10) {
    const batch = uniqueRefs.slice(i, i + 10);
    const docs = await db.getAll(...batch);
    docs.forEach((doc) => results.set(doc.id, doc));
  }

  return results;
}
