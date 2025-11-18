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

// Task functions
export { registerTask } from "./task/registerTask";
export { getUserTasks } from "./task/getUserTasks";
export { fetchTaskOGP } from "./task/fetchTaskOGP";
export { updateTaskStatus } from "./task/updateTaskStatus";

// Admin functions (Phase 0+)
export { setAdmin } from "./admin/setAdmin";
export { verifyAdminAuth } from "./admin/verifyAdminAuth";
export { searchUsers } from "./admin/searchUsers";
export { getUserDetail } from "./admin/getUserDetail";
export { grantPoints } from "./admin/grantPoints";
export { suspendUser } from "./admin/suspendUser";
export { getAdminLogs } from "./admin/getAdminLogs";

// In-App Vote functions (Phase 0+)
export { createInAppVote } from "./inAppVote/createInAppVote";
export { listInAppVotes } from "./inAppVote/listInAppVotes";
export { getInAppVoteDetail } from "./inAppVote/getInAppVoteDetail";
export { updateInAppVote } from "./inAppVote/updateInAppVote";
export { deleteInAppVote } from "./inAppVote/deleteInAppVote";
export { executeVote } from "./inAppVote/executeVote";
export { getRanking } from "./inAppVote/getRanking";

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

// Community functions (Phase 0+)
export { getCommunityPosts } from "./community/getCommunityPosts";
export { getReportedPosts } from "./community/getReportedPosts";
export { deleteCommunityPost } from "./community/deleteCommunityPost";
export { getCommunityStats } from "./community/getCommunityStats";

// Community functions (Phase 1 - Week 2 - Phase 2A)
export { createPost } from "./community/createPost";
export { getPost } from "./community/getPost";
export { getPosts } from "./community/getPosts";
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

// Storage functions (Goods Trade)
export { uploadGoodsImage } from "./storage/uploadGoodsImage";

// Placeholder function for testing
import * as functions from "firebase-functions";

export const helloWorld = functions.https.onRequest((request, response) => {
  response.json({ message: "K-VOTE COLLECTOR API is running!" });
});
