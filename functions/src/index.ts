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

// Idol Ranking functions
export { idolRankingVote } from "./idolRanking/vote";
export { idolRankingGetRanking } from "./idolRanking/getRanking";
export { idolRankingGetDailyLimit } from "./idolRanking/getDailyLimit";

// Scheduled functions
export { resetWeeklyIdolRanking } from "./scheduled/resetWeeklyIdolRanking";

// Placeholder function for testing
import * as functions from "firebase-functions";

export const helloWorld = functions.https.onRequest((request, response) => {
  response.json({ message: "K-VOTE COLLECTOR API is running!" });
});
