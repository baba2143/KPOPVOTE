import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Export all Cloud Functions

// Auth functions
export { register } from "./auth/register";
export { login } from "./auth/login";

// User functions
export { setBias } from "./user/setBias";
export { getBias } from "./user/getBias";
export { updateUserProfile } from "./user/updateUserProfile";
export { deleteAccount } from "./user/deleteAccount";
export { getNotificationSettings } from "./user/getNotificationSettings";
export { setNotificationSettings } from "./user/setNotificationSettings";
export { generateInviteCode, applyInviteCode } from "./user/inviteFriend";

// Task functions
export { registerTask } from "./task/registerTask";
export { getUserTasks } from "./task/getUserTasks";
export { fetchTaskOGP } from "./task/fetchTaskOGP";
export { updateTaskStatus } from "./task/updateTaskStatus";
export { updateTask } from "./task/updateTask";
export { deleteTask } from "./task/deleteTask";
export { shareTask } from "./task/shareTask";

// Admin functions (Phase 0+)
export { setAdmin } from "./admin/setAdmin";
export { verifyAdminAuth } from "./admin/verifyAdminAuth";
export { searchUsers } from "./admin/searchUsers";
export { getUserDetail } from "./admin/getUserDetail";
// grantPoints - Phase 1除外（ポイント機能）
export { suspendUser } from "./admin/suspendUser";
export { getAdminLogs } from "./admin/getAdminLogs";

// Reward Settings - Phase 1除外（ポイント機能）
// export { getRewardSettings } from "./admin/getRewardSettings";
// export { updateRewardSetting } from "./admin/updateRewardSetting";

// In-App Vote functions (Phase 0+)
export { createInAppVote } from "./inAppVote/createInAppVote";
export { listInAppVotes } from "./inAppVote/listInAppVotes";
export { getInAppVoteDetail } from "./inAppVote/getInAppVoteDetail";
export { updateInAppVote } from "./inAppVote/updateInAppVote";
export { deleteInAppVote } from "./inAppVote/deleteInAppVote";
export { executeVote } from "./inAppVote/executeVote";
export { getRanking } from "./inAppVote/getRanking";

// Vote processing triggers (Phase 3 - Async processing)
export {
  processVoteCount,
  processIdolRankingVoteCount,
} from "./inAppVote/processVoteCount";

// Master Data functions (Phase 0+)
export { createIdol } from "./master/createIdol";
export { listIdols } from "./master/listIdols";
export { updateIdol } from "./master/updateIdol";
export { deleteIdol } from "./master/deleteIdol";
export { createExternalApp } from "./master/createExternalApp";
export { listExternalApps } from "./master/listExternalApps";
export { updateExternalApp } from "./master/updateExternalApp";
export { deleteExternalApp } from "./master/deleteExternalApp";
export { createGroup } from "./master/createGroup";
export { listGroups } from "./master/listGroups";
export { updateGroup } from "./master/updateGroup";
export { deleteGroup } from "./master/deleteGroup";
export { seedExternalApps } from "./seedExternalApps";
export { seedCommunityData } from "./community/seedCommunityData";
export { fixUserBias } from "./community/fixUserBias";
export { setTestUserBias } from "./community/setTestUserBias";
// seedRewardSettings（新報酬設計で有効化）
export { seedRewardSettings } from "./seeds/seedRewardSettings";

// Community functions (Phase 0+)
export { getCommunityPosts } from "./community/getCommunityPosts";
export { getReportedPosts } from "./community/getReportedPosts";
export { deleteCommunityPost } from "./community/deleteCommunityPost";
export { getCommunityStats } from "./community/getCommunityStats";

// Community functions (Phase 1 - Week 2 - Phase 2A)
export { createPost } from "./community/createPost";
export { getPost } from "./community/getPost";
export { getPosts } from "./community/getPosts";
export { updatePost } from "./community/updatePost";
export { followUser } from "./community/followUser";
export { unfollowUser } from "./community/unfollowUser";

// Community functions (Phase 1 - Week 2 - Phase 2B)
export { likePost } from "./community/likePost";
export { deletePost } from "./community/deletePost";
export { getFollowing } from "./community/getFollowing";
export { getFollowers } from "./community/getFollowers";
export { getRecommendedUsers } from "./community/getRecommendedUsers";
export { getNotifications } from "./community/getNotifications";
export { markNotificationAsRead } from "./community/markNotificationAsRead";
export { getMyVotes } from "./community/getMyVotes";

// Community functions (Comments)
export { createComment } from "./community/createComment";
export { getComments } from "./community/getComments";
export { deleteComment } from "./community/deleteComment";

// Community functions (MV Watch Report)
export { reportMvWatch } from "./community/reportMvWatch";

// Direct Message functions
export { sendDirectMessage } from "./directMessage/sendDirectMessage";
export { getConversations } from "./directMessage/getConversations";
export { getMessages } from "./directMessage/getMessages";
export { markAsRead } from "./directMessage/markAsRead";
export { getDMReports } from "./directMessage/getDMReports";

// Block Reports (Apple App Store Guideline 1.2 compliance)
export { getBlockReports } from "./community/getBlockReports";

// Collection Reports (VOTE reports)
export { getCollectionReports } from "./admin/getCollectionReports";

// Points functions（新報酬設計で有効化）
export { getPoints } from "./points/getPoints";
export { getPointHistory } from "./points/getPointHistory";
// dailyLogin - 廃止（新報酬設計）
// export { dailyLogin } from "./points/dailyLogin";

// IAP functions (Phase 1A - Consumable IAP)
export { verifyPurchase } from "./iap/verifyPurchase";

// IAP functions (Phase 1B - Auto-Renewable Subscription)
export { verifySubscription } from "./iap/verifySubscription";

// Community functions (Search & Discovery)
export { searchUsers as searchCommunityUsers } from "./community/searchUsers";
export { searchPosts } from "./community/searchPosts";
export { getFollowingActivity } from "./community/getFollowingActivity";
export { seedTestUsers } from "./community/seedTestUsers";
export { createTestMutualFollow } from "./community/createTestMutualFollow";
export { getUserProfile } from "./community/getUserProfile";

// Storage functions (Goods Trade)
export { uploadGoodsImage } from "./storage/uploadGoodsImage";

// FCM functions (Push Notifications)
export { registerFcmToken } from "./fcm/registerToken";
export { unregisterFcmToken } from "./fcm/unregisterToken";

// Scheduled functions (Cron jobs)
export { updateVoteStatuses } from "./scheduled/updateVoteStatuses";
export { checkVoteDeadlines } from "./scheduled/checkVoteDeadlines";
export { checkCalendarReminders } from "./scheduled/checkCalendarReminders";
export { checkTaskDeadlines } from "./scheduled/checkTaskDeadlines";

// Scheduled functions (Vote aggregation - Phase 2 Scaling)
export {
  aggregateVoteCounts,
  aggregateVoteCountsManual,
} from "./scheduled/aggregateVoteCounts";
export {
  aggregateIdolRankings,
  aggregateIdolRankingsManual,
} from "./scheduled/aggregateIdolRankings";
export { updateTrendingScores } from "./scheduled/updateTrendingScores";

// Idol Ranking functions
export { idolRankingVote } from "./idolRanking/idolRankingVote";
export { idolRankingGetRanking } from "./idolRanking/idolRankingGetRanking";
export { idolRankingGetDailyLimit } from "./idolRanking/idolRankingGetDailyLimit";

// API Routes (Express) - 遅延読み込みで他関数のコールドスタート改善
import * as functions from "firebase-functions";
import { EXPRESS_API_CONFIG, STANDARD_CONFIG } from "./utils/functionConfig";

// Express アプリをキャッシュ（初回リクエスト時のみ初期化）
let cachedApp: any = null;

/** Expressアプリを遅延初期化して返す（コールドスタート最適化） */
function getExpressApp() {
  if (!cachedApp) {
    /* eslint-disable @typescript-eslint/no-var-requires */
    const express = require("express");
    const collectionsRouter = require("./api/collections").default;
    const calendarRouter = require("./api/calendar").default;
    /* eslint-enable @typescript-eslint/no-var-requires */

    cachedApp = express();
    cachedApp.use(express.json());
    cachedApp.use("/collections", collectionsRouter);
    cachedApp.use("/calendar", calendarRouter);
  }
  return cachedApp;
}

export const api = functions
  .runWith(EXPRESS_API_CONFIG)
  .https.onRequest((req, res) => {
    getExpressApp()(req, res);
  });

// Placeholder function for testing
export const helloWorld = functions
  .runWith(STANDARD_CONFIG)
  .https.onRequest((request, response) => {
    response.json({ message: "K-VOTE COLLECTOR API is running!" });
  });
