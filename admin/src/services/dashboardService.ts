import {
  collection,
  query,
  where,
  getDocs,
  onSnapshot,
  Unsubscribe
} from 'firebase/firestore';
import { db } from '../config/firebase';

export interface DashboardStats {
  totalUsers: number;
  activeVotes: number;
  totalIdols: number;
  communityPosts: number;
}

export interface TrendData {
  date: string;
  count: number;
}

/**
 * Get dashboard statistics
 */
export const getStatistics = async (): Promise<DashboardStats> => {
  try {
    // Get total users
    const usersSnapshot = await getDocs(collection(db, 'users'));
    const totalUsers = usersSnapshot.size;

    // Get active votes
    const votesQuery = query(
      collection(db, 'inAppVotes'),
      where('status', '==', 'active')
    );
    const votesSnapshot = await getDocs(votesQuery);
    const activeVotes = votesSnapshot.size;

    // Get total idols
    const idolsSnapshot = await getDocs(collection(db, 'idolMasters'));
    const totalIdols = idolsSnapshot.size;

    // Get community posts
    const postsSnapshot = await getDocs(collection(db, 'communityPosts'));
    const communityPosts = postsSnapshot.size;

    return {
      totalUsers,
      activeVotes,
      totalIdols,
      communityPosts,
    };
  } catch (error) {
    console.error('Error getting statistics:', error);
    throw error;
  }
};

/**
 * Subscribe to real-time statistics updates
 */
export const subscribeToStatistics = (
  callback: (stats: DashboardStats) => void
): Unsubscribe => {
  let stats: Partial<DashboardStats> = {};
  let unsubscribers: Unsubscribe[] = [];

  // Subscribe to users
  const usersUnsubscribe = onSnapshot(collection(db, 'users'), (snapshot) => {
    stats.totalUsers = snapshot.size;
    if (isComplete(stats)) callback(stats as DashboardStats);
  });
  unsubscribers.push(usersUnsubscribe);

  // Subscribe to active votes
  const votesQuery = query(
    collection(db, 'inAppVotes'),
    where('status', '==', 'active')
  );
  const votesUnsubscribe = onSnapshot(votesQuery, (snapshot) => {
    stats.activeVotes = snapshot.size;
    if (isComplete(stats)) callback(stats as DashboardStats);
  });
  unsubscribers.push(votesUnsubscribe);

  // Subscribe to idols
  const idolsUnsubscribe = onSnapshot(collection(db, 'idolMasters'), (snapshot) => {
    stats.totalIdols = snapshot.size;
    if (isComplete(stats)) callback(stats as DashboardStats);
  });
  unsubscribers.push(idolsUnsubscribe);

  // Subscribe to community posts
  const postsUnsubscribe = onSnapshot(collection(db, 'communityPosts'), (snapshot) => {
    stats.communityPosts = snapshot.size;
    if (isComplete(stats)) callback(stats as DashboardStats);
  });
  unsubscribers.push(postsUnsubscribe);

  // Return unsubscribe function
  return () => {
    unsubscribers.forEach(unsub => unsub());
  };
};

/**
 * Check if all statistics are loaded
 */
function isComplete(stats: Partial<DashboardStats>): boolean {
  return (
    stats.totalUsers !== undefined &&
    stats.activeVotes !== undefined &&
    stats.totalIdols !== undefined &&
    stats.communityPosts !== undefined
  );
}

/**
 * Get vote trend data for the last 30 days
 */
export const getVoteTrend = async (): Promise<TrendData[]> => {
  try {
    const snapshot = await getDocs(collection(db, 'voteRecords'));
    const records = snapshot.docs.map(doc => ({
      ...doc.data(),
      id: doc.id,
    }));

    // Group by date
    const trendMap = new Map<string, number>();
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    records.forEach((record: any) => {
      const timestamp = record.votedAt?.toDate?.() || record.createdAt?.toDate?.();
      if (timestamp && timestamp >= thirtyDaysAgo) {
        const dateStr = timestamp.toISOString().split('T')[0];
        trendMap.set(dateStr, (trendMap.get(dateStr) || 0) + 1);
      }
    });

    // Convert to array and sort
    const trendData: TrendData[] = Array.from(trendMap.entries())
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return trendData;
  } catch (error) {
    console.error('Error getting vote trend:', error);
    return [];
  }
};

/**
 * Get user growth data for the last 30 days
 */
export const getUserGrowth = async (): Promise<TrendData[]> => {
  try {
    const snapshot = await getDocs(collection(db, 'users'));
    const users = snapshot.docs.map(doc => ({
      ...doc.data(),
      id: doc.id,
    }));

    // Group by date
    const growthMap = new Map<string, number>();
    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    users.forEach((user: any) => {
      const timestamp = user.createdAt?.toDate?.();
      if (timestamp && timestamp >= thirtyDaysAgo) {
        const dateStr = timestamp.toISOString().split('T')[0];
        growthMap.set(dateStr, (growthMap.get(dateStr) || 0) + 1);
      }
    });

    // Convert to array and sort
    const growthData: TrendData[] = Array.from(growthMap.entries())
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return growthData;
  } catch (error) {
    console.error('Error getting user growth:', error);
    return [];
  }
};
