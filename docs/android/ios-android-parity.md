# iOS ↔ Android 機能対応表

iOS 版 KPOPVOTE（`ios/KPOPVOTE/`）の構成要素を Android 版（`android/app/`）にどうマッピングするかを一覧化する。Sprint 実装時の参照表。

## Service → Repository

| iOS Service | Android Repository | パッケージ | 実装スプリント |
|-------------|--------------------|-----------|---------------|
| `AuthService` | `AuthRepository` | `data.repository` | **Sprint 1 ✅** |
| `UserService` | `UserRepository` | `data.repository` | **Sprint 2 ✅** |
| `OGPService` | `OgpRepository` | `data.repository` | Sprint 3 |
| `TaskService` | `TaskRepository` | `data.repository` | Sprint 3 |
| `MasterDataService` (idol/group/externalApp) | `MasterDataRepository` | `data.repository` | **Sprint 2 ✅** |
| `BiasService` | `BiasRepository` | `data.repository` | **Sprint 2 ✅** |
| `VoteService` / `VoteCreationService` / `VoteRankingService` | `VoteRepository` (集約) | `data.repository` | Sprint 4 |
| `CommunityService` / `PostService` / `CommentService` / `LikeService` | `CommunityRepository` | `data.repository` | Sprint 5 |
| `FollowService` / `UserSearchService` | `SocialRepository` | `data.repository` | Sprint 5 |
| `DMService` / `ConversationService` | `MessagingRepository` | `data.repository` | Sprint 5 |
| `FancardService` | `FancardRepository` | `data.repository` | Sprint 6 |
| `IdolRankingService` | `RankingRepository` | `data.repository` | Sprint 6 |
| `PointsService` / `PointsHistoryService` | `PointsRepository` | `data.repository` | Sprint 6 |
| `InviteCodeService` | `InviteRepository` | `data.repository` | Sprint 7 |
| `NotificationSettingsService` | `NotificationSettingsRepository` | `data.repository` | Sprint 7 |
| `ReportService` (MV watch) | `ReportRepository` | `data.repository` | Sprint 5 |
| `PushNotificationService` | `FcmTokenRepository` + `KpopvoteMessagingService` | `data.repository` / `notifications` | Sprint 7 |
| `StorageService` | `StorageRepository` | `data.repository` | **Sprint 2 ✅** |
| `AdminService` / `SuspendService` / `LogService` / `ScheduledNotificationService` | `AdminRepository` 群 | `data.repository` | v1.2 (Sprint 7 残り) |
| `IAPManager` (StoreKit 2) | **v2.0 送り** — 実装しない | — | v2.0 |

## View → Screen

| iOS View | Compose Screen | パッケージ | スプリント |
|----------|---------------|-----------|-----------|
| `LoginView` | `LoginScreen` | `ui.auth.login` | **Sprint 1 ✅** |
| `SignUpView` / `RegisterView` | `RegisterScreen` | `ui.auth.register` | **Sprint 1 ✅** |
| `ContentView` (ルート) | `KpopvoteNavHost` | `navigation` | **Sprint 1 ✅** |
| `MainTabView` | `MainTabScreen` (Sprint 3) | `ui.main` | Sprint 3 |
| `HomeView` | `HomeScreen` | `ui.home` | Sprint 3 |
| `TaskListView` | `TaskListScreen` | `ui.tasks` | Sprint 3 |
| `TaskDetailView` | `TaskDetailScreen` | `ui.tasks` | Sprint 3 |
| `AddTaskView` | `AddTaskScreen` | `ui.tasks` | Sprint 3 |
| `VotesTabView` (Discover/Saved/My) | `VotesTabsScreen` (Pager) | `ui.votes` | Sprint 4 |
| `VoteDetailView` | `VoteDetailScreen` | `ui.votes` | Sprint 4 |
| `VoteRankingView` | `VoteRankingScreen` | `ui.votes` | Sprint 4 |
| `CollectionDetailView` | `CollectionDetailScreen` | `ui.votes` | Sprint 4 |
| `CommunityFeedView` | `CommunityFeedScreen` | `ui.community` | Sprint 5 |
| `PostDetailView` | `PostDetailScreen` | `ui.community` | Sprint 5 |
| `DMListView` | `ConversationListScreen` | `ui.dm` | Sprint 5 |
| `DMThreadView` | `ThreadScreen` | `ui.dm` | Sprint 5 |
| `FanCardPreviewView` / `FanCardEditorView` | `FancardScreen` / `FancardEditorScreen` | `ui.fancard` | Sprint 6 |
| `ProfileView` | `ProfileScreen` | `ui.profile` | Sprint 7 |
| `SettingsView` | `SettingsScreen` | `ui.settings` | Sprint 7 |
| `StoreView` (IAP) | **v2.0 送り** | — | v2.0 |
| `AdminView` | `AdminScreen` | `ui.admin` | v1.2 |

## プラットフォーム API 対応

| iOS | Android | 備考 |
|-----|---------|------|
| `async/await` | `suspend fun` + Coroutines | |
| `@Published` / `@StateObject` | `StateFlow` / `MutableStateFlow` | |
| SwiftUI `@Binding` | `State` hoisting パターン | |
| `NavigationStack` | `NavHost` / Navigation Compose | type-safe Route sealed interface |
| `UserDefaults` | DataStore Preferences | |
| Core Data | Room（必要時のみ、Sprint 2 までは不要） | |
| `URLSession` | OkHttp + Kotlinx Serialization | iOS と同じ HTTP onRequest を `Authorization: Bearer <idToken>` で直叩き（`FunctionsClient`） |
| StoreKit 2 | **非採用（v2.0）** | |
| Sign in with Apple | 非採用（v1） | Android で UX が限定的 |
| `GIDSignIn` | Credential Manager + Google ID | 旧 `GoogleSignInClient` は使用しない |
| APNs + FCM | FCM のみ | |
| App Check (DeviceCheck) | App Check (Play Integrity) | |
| `Kingfisher` | Coil 3 | |
| SPM | Gradle Version Catalog (`libs.versions.toml`) | |
| `Info.plist` | `AndroidManifest.xml` + `buildConfigField` | |

## Firestore コレクション（共有）

両プラットフォームから同じ Firestore を参照する。スキーマ変更はしない。

| コレクション | iOS でのアクセス | Android でのアクセス |
|-------------|-----------------|---------------------|
| `users/{uid}` | `FirestoreService` 経由 | `UserRepository` 経由 |
| `users/{uid}/tasks/{taskId}` | 同上 | `TaskRepository` 経由 |
| `communityPosts/{postId}` | `CommunityService` | `CommunityRepository` |
| `communityPosts/{postId}/comments/{commentId}` | 同上 | 同上 |
| `inAppVotes/{voteId}` | `VoteService` | `VoteRepository` |
| `inAppVotes/{voteId}/candidates/{id}` | 同上 | 同上 |
| `inAppVotes/{voteId}/userVotes/{uid}` | 同上 | 同上 |
| `directMessages/{convId}/messages/{msgId}` | `DMService` | `MessagingRepository` |
| `purchases` / `subscriptions` | `IAPManager` | **v2.0 送り**（Android 側書き込みなし） |
| `pointTransactions` | `PointsService` | `PointsRepository`（読み取りのみ） |
| `fcmTokens` or `users/{uid}/fcmTokens` | `PushNotificationService` | `FcmTokenRepository`（`platform: "android"` 付与） |

## Cloud Functions エンドポイント

iOS 版 `Constants.API` に定義されているエンドポイントをすべて共有。一覧は `ios/KPOPVOTE/Utilities/Constants.swift` を参照。

Android 側では `FunctionsClient`（Sprint 2 で実装 ✅）に HTTP onRequest 呼び出しを集約する。`data/api/ApiPaths.kt` にエンドポイント定数、`data/api/ApiEnvelope.kt` に共通レスポンス `{ success, data }` を定義。

## 共有バックエンド接続情報

- **Firebase Project ID**: `kpopvote-9de2b`
- **Functions Region**: `us-central1`
- **Bundle ID / Application ID**: `com.kpopvote.collector`（iOS/Android 共通）
- **Functions Base URL**: `https://us-central1-kpopvote-9de2b.cloudfunctions.net`
