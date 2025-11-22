//
// index.ts
// K-VOTE COLLECTOR - Collections API Router
//

import { Router } from "express";
import { getCollections } from "./getCollections";
import { searchCollections } from "./searchCollections";
import { getTrending } from "./getTrending";
import { getCollectionDetail } from "./getCollectionDetail";
import { createCollection } from "./createCollection";
import { updateCollection } from "./updateCollection";
import { deleteCollection } from "./deleteCollection";
import { saveCollection } from "./saveCollection";
import { addToTasks } from "./addToTasks";
import { getSavedCollections } from "./getSavedCollections";
import { getMyCollections } from "./getMyCollections";
import { shareToCoommunity } from "./shareToCoommunity";
import { authMiddleware } from "../../middleware/auth";

const router = Router();

// Public routes
router.get("/", getCollections); // GET /api/collections
router.get("/search", searchCollections); // GET /api/collections/search
router.get("/trending", getTrending); // GET /api/collections/trending
router.get("/:collectionId", getCollectionDetail); // GET /api/collections/:id

// Protected routes (require authentication)
router.post("/", authMiddleware, createCollection); // POST /api/collections
router.put("/:collectionId", authMiddleware, updateCollection); // PUT /api/collections/:id
router.delete("/:collectionId", authMiddleware, deleteCollection); // DELETE /api/collections/:id
router.post("/:collectionId/save", authMiddleware, saveCollection); // POST /api/collections/:id/save
router.post("/:collectionId/add-to-tasks", authMiddleware, addToTasks); // POST /api/collections/:id/add-to-tasks
// POST /api/collections/:id/share-to-community
router.post("/:collectionId/share-to-community", authMiddleware, shareToCoommunity);

// User collection routes
router.get("/users/me/saved", authMiddleware, getSavedCollections); // GET /api/collections/users/me/saved
router.get("/users/me/created", authMiddleware, getMyCollections); // GET /api/collections/users/me/created

export default router;
