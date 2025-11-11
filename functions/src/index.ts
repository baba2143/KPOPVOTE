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

// Community functions (Phase 0+)
export { getCommunityPosts } from "./community/getCommunityPosts";
export { getReportedPosts } from "./community/getReportedPosts";
export { deleteCommunityPost } from "./community/deleteCommunityPost";
export { getCommunityStats } from "./community/getCommunityStats";

// Placeholder function for testing
import * as functions from "firebase-functions";

export const helloWorld = functions.https.onRequest((request, response) => {
  response.json({ message: "K-VOTE COLLECTOR API is running!" });
});
