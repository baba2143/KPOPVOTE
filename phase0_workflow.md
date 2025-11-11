# 🔧 Phase 0: バックエンド基盤構築ワークフロー

## 概要

**期間**: 2週間（10営業日）
**目標**: Firebase基盤とMVPコア機能のAPI確立
**戦略**: systematic（体系的アプローチ）
**チーム**: バックエンドエンジニア × 2、インフラエンジニア × 1

---

## 📅 Week 1: 基盤構築と認証の確立

### Day 1-2: Firebase環境構築（B1.1）

#### Day 1: Firebase プロジェクト初期化

**担当**: インフラエンジニア

**タスク**:
1. **Firebaseプロジェクト作成**
   ```bash
   # Firebase Console でプロジェクト作成
   # プロジェクト名: kvote-collector-production
   # プロジェクトID: kvote-collector
   ```

2. **Firebase CLI インストール・初期化**
   ```bash
   # Firebase CLI インストール
   npm install -g firebase-tools

   # ログイン
   firebase login

   # プロジェクト初期化
   cd /path/to/KPOPVOTE
   firebase init

   # 選択項目:
   # - Functions (Node.js)
   # - Firestore
   # - Hosting
   # - Storage
   ```

3. **Cloud Functions プロジェクト構造作成**
   ```bash
   cd functions
   npm install typescript @types/node --save-dev
   npm install firebase-functions firebase-admin express cors
   npm install --save-dev @types/express @types/cors
   ```

**成果物**:
- `firebase.json`
- `.firebaserc`
- `functions/package.json`
- `functions/tsconfig.json`

---

#### Day 2: Firestore データベース・セキュリティルール

**担当**: バックエンドエンジニア1

**タスク**:
1. **Firestoreデータベース有効化**
   - Firebase Console で Firestore 有効化
   - リージョン選択: `asia-northeast1`（東京）
   - モード: Production

2. **セキュリティルール作成**
   ```javascript
   // firestore.rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {

       // ユーザーコレクション
       match /users/{userId} {
         // 認証済みユーザーは自分のデータのみ読み書き可能
         allow read, write: if request.auth != null && request.auth.uid == userId;

         // 管理者は全ユーザーデータ閲覧可能
         allow read: if request.auth.token.admin == true;

         // タスクサブコレクション
         match /tasks/{taskId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
       }

       // コミュニティ投稿
       match /communityPosts/{postId} {
         // 全員閲覧可、認証済みユーザーのみ作成可
         allow read: if request.auth != null;
         allow create: if request.auth != null;
         // 作成者のみ更新・削除可
         allow update, delete: if request.auth != null &&
                                  request.auth.uid == resource.data.authorId;
       }

       // 独自投票
       match /inAppVotes/{voteId} {
         allow read: if request.auth != null;
         // 管理者のみ作成・更新・削除可
         allow write: if request.auth.token.admin == true;
       }
     }
   }
   ```

3. **インデックス定義**
   ```json
   // firestore.indexes.json
   {
     "indexes": [
       {
         "collectionGroup": "tasks",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "targetMembers", "arrayConfig": "CONTAINS" },
           { "fieldPath": "deadline", "order": "ASCENDING" }
         ]
       },
       {
         "collectionGroup": "tasks",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "isCompleted", "order": "ASCENDING" },
           { "fieldPath": "deadline", "order": "ASCENDING" }
         ]
       }
     ]
   }
   ```

4. **初期コレクション作成テスト**
   ```bash
   # Firestore Emulator起動
   firebase emulators:start --only firestore

   # セキュリティルールテスト実行
   npm run test:rules
   ```

**成果物**:
- `firestore.rules`
- `firestore.indexes.json`
- セキュリティルールテスト結果

**Day 1-2完了基準**:
- [ ] Firebaseプロジェクト作成完了
- [ ] Cloud Functions初期化完了
- [ ] Firestoreデータベース有効化
- [ ] セキュリティルール設定・テスト合格
- [ ] インデックス設定完了

---

### Day 3-4: ユーザー認証API実装（B1.2）

**担当**: バックエンドエンジニア1

#### Day 3: ユーザー登録API

**タスク**:
1. **プロジェクト構造作成**
   ```
   functions/src/
   ├── auth/
   │   ├── register.ts
   │   └── login.ts
   ├── middleware/
   │   └── authMiddleware.ts
   ├── utils/
   │   ├── validators.ts
   │   └── response.ts
   └── index.ts
   ```

2. **ユーザー登録API実装**
   ```typescript
   // functions/src/auth/register.ts
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';
   import { validateEmail, validatePassword } from '../utils/validators';

   export const register = functions.https.onCall(async (data, context) => {
     const { email, password, username } = data;

     // バリデーション
     if (!validateEmail(email)) {
       throw new functions.https.HttpsError(
         'invalid-argument',
         'Invalid email format'
       );
     }

     if (!validatePassword(password)) {
       throw new functions.https.HttpsError(
         'invalid-argument',
         'Password must be at least 8 characters'
       );
     }

     try {
       // Firebase Authでユーザー作成
       const userRecord = await admin.auth().createUser({
         email,
         password,
         displayName: username,
       });

       // Firestoreにユーザー情報保存
       await admin.firestore().collection('users').doc(userRecord.uid).set({
         username,
         email,
         profileImageUrl: '',
         registeredAt: admin.firestore.FieldValue.serverTimestamp(),
         myBias: [],
         points: 1000, // 初期ポイント
       });

       return {
         success: true,
         userId: userRecord.uid,
         message: 'User registered successfully',
       };
     } catch (error) {
       if (error.code === 'auth/email-already-exists') {
         throw new functions.https.HttpsError(
           'already-exists',
           'Email already registered'
         );
       }
       throw new functions.https.HttpsError('internal', error.message);
     }
   });
   ```

3. **バリデーター実装**
   ```typescript
   // functions/src/utils/validators.ts
   export function validateEmail(email: string): boolean {
     const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
     return emailRegex.test(email);
   }

   export function validatePassword(password: string): boolean {
     return password.length >= 8;
   }

   export function validateUsername(username: string): boolean {
     return username.length >= 2 && username.length <= 50;
   }
   ```

4. **ユニットテスト作成**
   ```typescript
   // functions/test/auth/register.test.ts
   import { expect } from 'chai';
   import * as admin from 'firebase-admin';
   import { register } from '../../src/auth/register';

   describe('User Registration', () => {
     it('should register user successfully', async () => {
       const result = await register({
         email: 'test@example.com',
         password: 'password123',
         username: 'TestUser',
       }, {} as any);

       expect(result.success).to.be.true;
       expect(result.userId).to.exist;
     });

     it('should reject invalid email', async () => {
       try {
         await register({
           email: 'invalid-email',
           password: 'password123',
           username: 'TestUser',
         }, {} as any);
         expect.fail('Should have thrown error');
       } catch (error) {
         expect(error.code).to.equal('invalid-argument');
       }
     });
   });
   ```

---

#### Day 4: ログインAPI・認証ミドルウェア

**タスク**:
1. **ログインAPI実装**
   ```typescript
   // functions/src/auth/login.ts
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';

   export const login = functions.https.onCall(async (data, context) => {
     const { email, password } = data;

     // Firebase Admin SDK では直接パスワード認証できないため、
     // クライアント側でFirebase Auth SDK使用を推奨
     // ここではカスタムトークン発行のみ実装

     try {
       // メールアドレスからユーザー取得
       const userRecord = await admin.auth().getUserByEmail(email);

       // カスタムトークン発行
       const customToken = await admin.auth().createCustomToken(userRecord.uid);

       return {
         success: true,
         customToken,
         userId: userRecord.uid,
       };
     } catch (error) {
       throw new functions.https.HttpsError(
         'unauthenticated',
         'Invalid credentials'
       );
     }
   });
   ```

2. **認証ミドルウェア実装**
   ```typescript
   // functions/src/middleware/authMiddleware.ts
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';

   export async function verifyAuth(context: functions.https.CallableContext) {
     if (!context.auth) {
       throw new functions.https.HttpsError(
         'unauthenticated',
         'User must be authenticated'
       );
     }
     return context.auth.uid;
   }

   export async function verifyAdmin(context: functions.https.CallableContext) {
     if (!context.auth || !context.auth.token.admin) {
       throw new functions.https.HttpsError(
         'permission-denied',
         'Admin permission required'
       );
     }
     return context.auth.uid;
   }
   ```

3. **index.tsに登録**
   ```typescript
   // functions/src/index.ts
   import * as admin from 'firebase-admin';
   admin.initializeApp();

   export { register, login } from './auth';
   ```

4. **統合テスト**
   ```bash
   # エミュレーター起動
   firebase emulators:start --only functions,auth,firestore

   # Postmanでテスト実行
   # POST https://us-central1-kvote-collector.cloudfunctions.net/register
   # POST https://us-central1-kvote-collector.cloudfunctions.net/login
   ```

**Day 3-4完了基準**:
- [ ] `/auth/register` API実装完了
- [ ] `/auth/login` API実装完了
- [ ] バリデーション実装完了
- [ ] ユニットテスト合格
- [ ] 統合テスト合格

---

### Day 5: 推し設定API実装（B1.3）

**担当**: バックエンドエンジニア2

**タスク**:
1. **推し設定API実装**
   ```typescript
   // functions/src/user/setBias.ts
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';
   import { verifyAuth } from '../middleware/authMiddleware';

   export const setBias = functions.https.onCall(async (data, context) => {
     const userId = await verifyAuth(context);
     const { myBias } = data;

     // バリデーション
     if (!Array.isArray(myBias) || myBias.length === 0) {
       throw new functions.https.HttpsError(
         'invalid-argument',
         'myBias must be a non-empty array'
       );
     }

     // 最大10名まで
     if (myBias.length > 10) {
       throw new functions.https.HttpsError(
         'invalid-argument',
         'Maximum 10 bias members allowed'
       );
     }

     try {
       await admin.firestore().collection('users').doc(userId).update({
         myBias,
         updatedAt: admin.firestore.FieldValue.serverTimestamp(),
       });

       return {
         success: true,
         myBias,
       };
     } catch (error) {
       throw new functions.https.HttpsError('internal', error.message);
     }
   });
   ```

2. **推し取得API実装**
   ```typescript
   // functions/src/user/getBias.ts
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';
   import { verifyAuth } from '../middleware/authMiddleware';

   export const getBias = functions.https.onCall(async (data, context) => {
     const userId = await verifyAuth(context);

     try {
       const userDoc = await admin.firestore()
         .collection('users')
         .doc(userId)
         .get();

       if (!userDoc.exists) {
         throw new functions.https.HttpsError('not-found', 'User not found');
       }

       const userData = userDoc.data();
       return {
         success: true,
         myBias: userData?.myBias || [],
       };
     } catch (error) {
       throw new functions.https.HttpsError('internal', error.message);
     }
   });
   ```

3. **ユニットテスト**
   ```typescript
   // functions/test/user/bias.test.ts
   describe('Bias Management', () => {
     it('should set bias successfully', async () => {
       const result = await setBias({
         myBias: ['Jimin', 'V', 'Jungkook'],
       }, mockContext);

       expect(result.success).to.be.true;
       expect(result.myBias).to.have.lengthOf(3);
     });

     it('should reject empty array', async () => {
       try {
         await setBias({ myBias: [] }, mockContext);
         expect.fail('Should have thrown error');
       } catch (error) {
         expect(error.code).to.equal('invalid-argument');
       }
     });
   });
   ```

4. **デプロイ・動作確認**
   ```bash
   # デプロイ
   firebase deploy --only functions:setBias,functions:getBias

   # Postman テスト
   ```

**Day 5完了基準**:
- [ ] `/user/setBias` API実装完了
- [ ] `/user/getBias` API実装完了
- [ ] バリデーション実装完了
- [ ] ユニットテスト合格
- [ ] デプロイ成功

**Week 1完了基準**:
- ✅ Firebase環境構築完了
- ✅ Firestore設定完了
- ✅ 認証API実装完了
- ✅ 推し設定API実装完了
- ✅ 全ユニットテスト合格

---

## 📅 Week 2: タスク管理APIの確立とOGP処理

### Day 6-7: タスク登録・取得API実装（B2.1, B2.2）

#### Day 6: タスク登録API

**担当**: バックエンドエンジニア1

**タスク**:
1. **タスク登録API実装**
   ```typescript
   // functions/src/task/register.ts
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';
   import { verifyAuth } from '../middleware/authMiddleware';

   interface TaskData {
     originalUrl: string;
     voteName: string;
     externalAppName: string;
     targetMembers: string[];
     deadline: string; // ISO 8601 format
     userMemo?: string;
   }

   export const registerTask = functions.https.onCall(async (data: TaskData, context) => {
     const userId = await verifyAuth(context);

     // バリデーション
     if (!data.originalUrl || !data.voteName || !data.targetMembers) {
       throw new functions.https.HttpsError(
         'invalid-argument',
         'Required fields missing'
       );
     }

     // URL形式チェック
     try {
       new URL(data.originalUrl);
     } catch {
       throw new functions.https.HttpsError('invalid-argument', 'Invalid URL format');
     }

     // 締め切りが過去でないかチェック
     const deadlineDate = new Date(data.deadline);
     if (deadlineDate < new Date()) {
       throw new functions.https.HttpsError(
         'invalid-argument',
         'Deadline must be in the future'
       );
     }

     try {
       const taskRef = await admin.firestore()
         .collection('users').doc(userId)
         .collection('tasks').add({
           originalUrl: data.originalUrl,
           voteName: data.voteName,
           externalAppName: data.externalAppName,
           targetMembers: data.targetMembers,
           deadline: admin.firestore.Timestamp.fromDate(deadlineDate),
           ogpImageUrl: '', // OGP取得は別API
           isCompleted: false,
           statusNote: 'notVoted',
           userMemo: data.userMemo || '',
           createdAt: admin.firestore.FieldValue.serverTimestamp(),
         });

       return {
         success: true,
         taskId: taskRef.id,
       };
     } catch (error) {
       throw new functions.https.HttpsError('internal', error.message);
     }
   });
   ```

2. **ユニットテスト**

---

#### Day 7: タスク取得API

**担当**: バックエンドエンジニア1

**タスク**:
1. **タスク取得API実装**
   ```typescript
   // functions/src/task/getUserTasks.ts
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';
   import { verifyAuth } from '../middleware/authMiddleware';

   interface GetTasksQuery {
     sortBy?: 'deadline' | 'createdAt';
     order?: 'asc' | 'desc';
     filterBias?: string;
     includeCompleted?: boolean;
   }

   export const getUserTasks = functions.https.onCall(async (data: GetTasksQuery, context) => {
     const userId = await verifyAuth(context);

     const { sortBy = 'deadline', order = 'asc', filterBias, includeCompleted = false } = data;

     try {
       let query = admin.firestore()
         .collection('users').doc(userId)
         .collection('tasks') as admin.firestore.Query;

       // フィルター: 完了済みタスク
       if (!includeCompleted) {
         query = query.where('isCompleted', '==', false);
       }

       // フィルター: 推しメンバー
       if (filterBias) {
         query = query.where('targetMembers', 'array-contains', filterBias);
       }

       // ソート
       query = query.orderBy(sortBy, order);

       const snapshot = await query.get();

       const tasks = snapshot.docs.map(doc => ({
         taskId: doc.id,
         ...doc.data(),
       }));

       return {
         success: true,
         tasks,
         count: tasks.length,
       };
     } catch (error) {
       throw new functions.https.HttpsError('internal', error.message);
     }
   });
   ```

2. **統合テスト実施**

**Day 6-7完了基準**:
- [ ] `/task/register` API実装完了
- [ ] `/task/getUserTasks` API実装完了
- [ ] フィルター・ソート機能動作確認
- [ ] ユニットテスト合格

---

### Day 8-9: OGP取得プロトタイプ開発（B2.3）

**担当**: バックエンドエンジニア2

#### Day 8: OGPパーサー実装

**タスク**:
1. **OGPライブラリ導入**
   ```bash
   cd functions
   npm install cheerio axios
   npm install --save-dev @types/cheerio
   ```

2. **OGPパーサー実装**
   ```typescript
   // functions/src/utils/ogpParser.ts
   import axios from 'axios';
   import * as cheerio from 'cheerio';

   export interface OGPData {
     title: string;
     image: string;
     url: string;
   }

   export async function fetchOGP(url: string): Promise<OGPData> {
     try {
       const response = await axios.get(url, {
         timeout: 10000,
         headers: {
           'User-Agent': 'Mozilla/5.0 (compatible; KVoteBot/1.0)',
         },
       });

       const $ = cheerio.load(response.data);

       const title = $('meta[property="og:title"]').attr('content') ||
                     $('title').text() ||
                     'No title';

       const image = $('meta[property="og:image"]').attr('content') || '';

       return {
         title,
         image,
         url,
       };
     } catch (error) {
       console.error('OGP fetch error:', error);
       throw new Error(`Failed to fetch OGP: ${error.message}`);
     }
   }
   ```

3. **リトライロジック実装**
   ```typescript
   // functions/src/utils/retry.ts
   export async function retryOperation<T>(
     operation: () => Promise<T>,
     maxRetries: number = 3,
     delay: number = 1000
   ): Promise<T> {
     for (let attempt = 1; attempt <= maxRetries; attempt++) {
       try {
         return await operation();
       } catch (error) {
         if (attempt === maxRetries) {
           throw error;
         }
         await new Promise(resolve => setTimeout(resolve, delay * attempt));
       }
     }
     throw new Error('Retry failed');
   }
   ```

---

#### Day 9: OGP取得API・テスト

**タスク**:
1. **OGP取得API実装**
   ```typescript
   // functions/src/task/fetchOGP.ts
   import * as functions from 'firebase-functions';
   import { fetchOGP } from '../utils/ogpParser';
   import { retryOperation } from '../utils/retry';
   import { verifyAuth } from '../middleware/authMiddleware';

   export const fetchTaskOGP = functions.https.onCall(async (data, context) => {
     await verifyAuth(context);
     const { url } = data;

     if (!url) {
       throw new functions.https.HttpsError('invalid-argument', 'URL required');
     }

     try {
       const ogpData = await retryOperation(() => fetchOGP(url), 3, 1000);

       return {
         success: true,
         ogpData,
       };
     } catch (error) {
       return {
         success: false,
         error: error.message,
         ogpData: {
           title: '',
           image: '',
           url,
         },
       };
     }
   });
   ```

2. **投票サイト別テスト**
   ```bash
   # テストスクリプト
   # test-ogp.sh

   SITES=(
     "https://idolchamp.com/vote"
     "https://mnetplus.world/vote"
     "https://mubeat.page.link/vote"
   )

   for site in "${SITES[@]}"; do
     echo "Testing: $site"
     # Postmanでテスト実行
   done
   ```

3. **成功率測定**
   - 各サイトから10回ずつOGP取得
   - 成功率計算
   - レスポンス時間計測

**Day 8-9完了基準**:
- [ ] OGPパーサー実装完了
- [ ] リトライロジック実装完了
- [ ] `/task/fetchOGP` API実装完了
- [ ] 投票サイト別テスト実施
- [ ] 成功率 > 90% 確認
- [ ] 平均レスポンス時間 < 3秒 確認

---

### Day 10: ステータス更新API・統合テスト（B2.4）

**担当**: バックエンドエンジニア1 + 2

**タスク**:
1. **ステータス更新API実装**
   ```typescript
   // functions/src/task/updateStatus.ts
   import * as functions from 'firebase-functions';
   import * as admin from 'firebase-admin';
   import { verifyAuth } from '../middleware/authMiddleware';

   interface UpdateStatusData {
     taskId: string;
     isCompleted?: boolean;
     statusNote?: 'notVoted' | 'pointShortage' | 'completed';
     userMemo?: string;
   }

   export const updateTaskStatus = functions.https.onCall(async (data: UpdateStatusData, context) => {
     const userId = await verifyAuth(context);
     const { taskId, isCompleted, statusNote, userMemo } = data;

     if (!taskId) {
       throw new functions.https.HttpsError('invalid-argument', 'taskId required');
     }

     try {
       const taskRef = admin.firestore()
         .collection('users').doc(userId)
         .collection('tasks').doc(taskId);

       const taskDoc = await taskRef.get();
       if (!taskDoc.exists) {
         throw new functions.https.HttpsError('not-found', 'Task not found');
       }

       const updateData: any = {
         updatedAt: admin.firestore.FieldValue.serverTimestamp(),
       };

       if (isCompleted !== undefined) updateData.isCompleted = isCompleted;
       if (statusNote) updateData.statusNote = statusNote;
       if (userMemo !== undefined) updateData.userMemo = userMemo;

       await taskRef.update(updateData);

       return {
         success: true,
         taskId,
       };
     } catch (error) {
       throw new functions.https.HttpsError('internal', error.message);
     }
   });
   ```

2. **統合テスト実施**
   ```typescript
   // functions/test/integration/taskFlow.test.ts
   describe('Task Management Flow', () => {
     it('should complete full task lifecycle', async () => {
       // 1. ユーザー登録
       const registerResult = await register(mockUserData, mockContext);
       const userId = registerResult.userId;

       // 2. 推し設定
       await setBias({ myBias: ['Jimin'] }, mockContext);

       // 3. タスク登録
       const taskResult = await registerTask(mockTaskData, mockContext);
       const taskId = taskResult.taskId;

       // 4. タスク取得
       const tasks = await getUserTasks({}, mockContext);
       expect(tasks.tasks).to.have.lengthOf(1);

       // 5. OGP取得
       const ogpResult = await fetchTaskOGP({ url: mockTaskData.originalUrl }, mockContext);
       expect(ogpResult.success).to.be.true;

       // 6. ステータス更新
       const updateResult = await updateTaskStatus({
         taskId,
         isCompleted: true,
         statusNote: 'completed',
       }, mockContext);
       expect(updateResult.success).to.be.true;
     });
   });
   ```

3. **APIドキュメント作成**
   ```markdown
   # K-VOTE COLLECTOR API Documentation

   ## Authentication

   ### POST /auth/register
   - Description: Register new user
   - Request Body: { email, password, username }
   - Response: { success, userId }

   ### POST /auth/login
   - Description: User login
   - Request Body: { email, password }
   - Response: { success, customToken, userId }

   ## User Management

   ### POST /user/setBias
   - Description: Set user's bias members
   - Auth Required: Yes
   - Request Body: { myBias: string[] }
   - Response: { success, myBias }

   ### GET /user/getBias
   - Description: Get user's bias members
   - Auth Required: Yes
   - Response: { success, myBias }

   ## Task Management

   ### POST /task/register
   - Description: Register new voting task
   - Auth Required: Yes
   - Request Body: { originalUrl, voteName, externalAppName, targetMembers, deadline, userMemo }
   - Response: { success, taskId }

   ### GET /task/getUserTasks
   - Description: Get user's tasks
   - Auth Required: Yes
   - Query Parameters: { sortBy, order, filterBias, includeCompleted }
   - Response: { success, tasks, count }

   ### POST /task/fetchOGP
   - Description: Fetch OGP data from URL
   - Auth Required: Yes
   - Request Body: { url }
   - Response: { success, ogpData }

   ### PATCH /task/updateStatus
   - Description: Update task status
   - Auth Required: Yes
   - Request Body: { taskId, isCompleted, statusNote, userMemo }
   - Response: { success, taskId }
   ```

4. **Postmanコレクション作成**

5. **本番環境デプロイ**
   ```bash
   # 全Functions デプロイ
   firebase deploy --only functions

   # Firestore ルール・インデックスデプロイ
   firebase deploy --only firestore:rules,firestore:indexes
   ```

**Day 10完了基準**:
- [ ] `/task/updateStatus` API実装完了
- [ ] 統合テスト100%合格
- [ ] APIドキュメント完成
- [ ] Postmanコレクション作成完了
- [ ] 本番環境デプロイ成功
- [ ] 本番環境動作確認完了

---

## ✅ Phase 0完了チェックリスト

### コード品質
- [ ] 全APIエンドポイント実装完了
- [ ] TypeScript型定義適切
- [ ] エラーハンドリング適切
- [ ] バリデーション適切
- [ ] ログ出力適切

### テスト
- [ ] ユニットテストカバレッジ > 80%
- [ ] 統合テスト100%合格
- [ ] セキュリティルールテスト合格
- [ ] OGP取得成功率 > 90%

### ドキュメント
- [ ] APIドキュメント完成
- [ ] Postmanコレクション作成完了
- [ ] README更新

### デプロイ
- [ ] Firebase本番環境デプロイ成功
- [ ] 全APIエンドポイント動作確認
- [ ] セキュリティルール動作確認

### ハンドオフ準備
- [ ] iOS開発チームへの説明資料作成
- [ ] テストアカウント提供
- [ ] Firebase設定ファイル提供（GoogleService-Info.plist）
- [ ] API仕様書共有

---

## 📊 トラブルシューティング

### よくある問題

**問題**: Firebase Functions デプロイエラー
- **原因**: Node.js バージョン不一致
- **解決**: `functions/package.json` の `engines` 確認

**問題**: OGP取得タイムアウト
- **原因**: 外部サイト応答遅延
- **解決**: タイムアウト延長、リトライ回数増加

**問題**: Firestore セキュリティルールエラー
- **原因**: ルール構文エラー
- **解決**: `firebase emulators:start` でローカルテスト

---

## 🚀 次のステップ

Phase 0完了後:
- **Phase 0+**: 管理画面開発（並行可能）
- **Phase 1**: iOSアプリ開発
- **コミュニティAPI**: Phase 1と並行開発可能

---

**最終更新**: 2025-11-11
**作成者**: Claude Code
**バージョン**: 1.0
