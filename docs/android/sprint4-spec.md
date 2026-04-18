# Sprint 4 Spec: Votes (v1.0 MVP Final Sprint)

## Overview

Sprint 4 is the final v1.0 MVP sprint for the KPOPVOTE Android port. It delivers the full Votes feature parity with iOS: In-App Vote execution (with App Check bot protection), ranking view, vote discovery, and user-owned Vote Collections (create / edit / save / share-to-community / add-to-tasks). This sprint integrates with existing Cloud Functions unchanged and completes the six-tab bottom navigation that Sprint 3 prepared. IAP (point purchase) remains explicitly out of scope and is deferred to v2.0.

Estimated total: **110-135h** across 6 phases. Target: 65-80 new/modified files, 45-60 new unit tests on top of the existing 51.

---

## 1. Requirements Re-Confirmation

### 1.1 iOS feature inventory (source of truth)

From `VoteService.swift`, `CollectionService.swift`, `Views/Vote/*`, `Views/Votes/*`:

**In-App Vote (Vote/)**
- Featured votes fetch (HOME promotion strip) — `listInAppVotes?featured=true`
- Vote list with status filter (upcoming/active/ended) — `listInAppVotes?status=`
- Vote detail with choices, user points, daily vote remaining — `getInAppVoteDetail?voteId=`
- Execute vote with `voteId`, `choiceId`, `voteCount`, `pointSelection` (default `"auto"`) — `executeVote` + **App Check token**
- Ranking view — `getRanking?voteId=`
- Error handling: alreadyVoted / insufficientPoints / voteNotActive / dailyLimitReached

**Vote Collections (Votes/)**
- Discover: paginated list with `sortBy=latest|popular|trending`, tag filter, search — `collections`, `searchCollections`
- Trending collections (24h/7d/30d) — `trendingCollections`
- Saved collections (user's bookmarks) — `savedCollections`
- My Collections (user-authored) — `myCollections`
- Collection detail — `collections/{id}` (returns collection + isSaved/isLiked/isOwner/isFollowingCreator)
- Toggle save — `collections/{id}/save`
- Add-all-to-tasks — `collections/{id}/add-to-tasks`
- Add-single-to-tasks — `collections/{id}/tasks/{taskId}/add`
- Share to community — `collections/{id}/share-to-community` (biasIds + text)
- Update collection — `PUT collections/{id}` (title, description, coverImage URL, tags, tasks[{taskId, orderIndex}], visibility)
- Delete collection — `DELETE collections/{id}`
- Create collection: standard POST (cover image uploaded to Storage first → URL embedded in body)

### 1.2 Android v1.0 scope

**Included (Sprint 4)**
- All In-App Vote screens (list/detail/ranking) + execute with App Check
- VotesTabView with 3 tabs: Discover / Saved / My Collections
- Collection list + detail + save toggle + add-to-tasks (bulk and single)
- Create / Edit / Delete collection (cover image upload via Storage)
- Share collection to community (minimal flow — no post feed UI; we only POST and show success)
- Integration into HOME (featured votes strip)

**Deferred / explicitly excluded**
- IAP / point purchase (v2.0)
- Community timeline feed (only the share-POST endpoint is called; feed UI is out of scope for v1.0)
- Deep link handling for `https://kpopvote-9de2b.web.app/vote/{id}` (v2.0; share uses `ACTION_SEND` plain-text only)
- Follower-only visibility edge cases beyond the enum passthrough
- Liked-collections (isLiked is read-only; no like toggle endpoint is wired in v1.0 — iOS does not expose a toggle either)

### 1.3 Success criteria

- [ ] User can discover, open, and vote in an active In-App Vote; App Check token attaches in release builds
- [ ] All 4 business errors (alreadyVoted / insufficientPoints / voteNotActive / dailyLimitReached) render localized messages
- [ ] Ranking screen displays top-N with correct vote counts
- [ ] User can create a collection with a cover image, edit it, and delete it
- [ ] User can save / unsave any collection and see it in the Saved tab
- [ ] User can add all tasks from a collection to their own TASKS list (duplicates skipped)
- [ ] Share-to-community returns 201 and shows success toast
- [ ] HOME featured votes strip renders and navigates to VoteDetail
- [ ] 95+ total unit tests green (51 existing + ~45 new)
- [ ] All screens have dark-theme parity with existing Tasks screens

---

## 2. Implementation Phase Breakdown

### Phase 1 — Data Models + Repositories (20-25h)

**Goal**: Parity with iOS VoteService + CollectionService at the data layer. No UI.

Deliverables:
- Kotlinx-serialization data classes for all Vote/Collection DTOs
- `VoteRepository` + `VoteRepositoryImpl` with 5 methods
- `CollectionRepository` + `CollectionRepositoryImpl` with 11 methods
- `CollectionCoverImageRepository` (Firebase Storage upload)
- `AppCheckTokenProvider` wrapper (DEBUG returns null, release calls Play Integrity)
- New `ApiPaths` entries
- Hilt bindings in `RepositoryModule.kt`

Exit: unit tests for all repos with fake `FunctionsClient` (~20 tests).

### Phase 2 — In-App Vote UI (20-25h)

**Goal**: Full vote execution flow end-to-end.

Deliverables:
- `VoteListScreen` (with status filter chips) + `VoteListViewModel`
- `VoteDetailScreen` (choices, points, vote button, daily remaining) + `VoteDetailViewModel`
- `VoteCastBottomSheet` (choice confirm + voteCount stepper)
- `VoteRankingScreen` + `VoteRankingViewModel`
- Error dialogs for 4 Vote-specific business errors
- Navigation entries (`voteList`, `voteDetail/{voteId}`, `voteRanking/{voteId}`)

Exit: manual run in emulator; unit tests for 3 ViewModels (~12 tests).

### Phase 3 — Votes Tab Container + Discover (18-22h)

**Goal**: Tabbed Votes screen wired to bottom nav slot 3.

Deliverables:
- `VotesTabScreen` (3 segments: Discover / Saved / MyCollections)
- `DiscoverScreen` + `DiscoverViewModel` with search, sort (`latest|popular|trending`), tag chips, pagination
- `SavedCollectionsScreen` + `SavedCollectionsViewModel`
- `MyCollectionsScreen` + `MyCollectionsViewModel`
- `CollectionCard` composable (shared)
- Navigation entry `collections` (tab root)

Exit: unit tests for 3 ViewModels (~10 tests).

### Phase 4 — Collection Detail + Actions (18-22h)

**Goal**: View + save + add-to-tasks + share.

Deliverables:
- `CollectionDetailScreen` (cover, title, description, tag row, creator strip, task list, action buttons) + `CollectionDetailViewModel`
- Save toggle UI (bookmark icon with optimistic update)
- Add-all-to-tasks button + `AddToTasksResultDialog` (shows added/skipped counts)
- Add-single-to-tasks per task row
- `ShareCollectionBottomSheet` (bias multi-select + text field, POST then toast)
- Navigation entry `collectionDetail/{collectionId}`

Exit: unit tests for ViewModel + dialog logic (~8 tests).

### Phase 5 — Create / Edit / Delete Collection (16-20h)

**Goal**: User authoring flow.

Deliverables:
- `CreateCollectionScreen` + `CreateCollectionViewModel`
  - Title (1-50), description (0-500), tags (0-10), visibility (enum), task picker (reuse Tasks list), cover image picker (system photo picker → `CollectionCoverImageRepository` upload)
- `EditCollectionScreen` (same UI, prefilled) sharing the same ViewModel with mode flag
- Delete confirmation dialog in `CollectionDetailScreen` when `isOwner`
- Drag-reorder of tasks in collection (min: arrow up/down; drag is stretch)
- Navigation entries `collectionCreate`, `collectionEdit/{collectionId}`

Exit: unit tests for ViewModel form validation + mode switching (~8 tests).

### Phase 6 — HOME integration + Polish + Test Sweep (12-15h)

**Goal**: Featured votes strip on HOME + error polish + test backfill.

Deliverables:
- Featured votes horizontal strip in `HomeScreen` (Sprint 3 already has the placeholder)
- `HomeViewModel` extension to load featured votes in parallel with active tasks
- String resource pass for all new error messages (ja + en)
- `AppError` extension mapping in a single `VoteErrorMapper` helper
- CI green (ktlint + detekt + tests)
- README section update for Sprint 4

Exit: 95+ total unit tests, app runs end-to-end on a physical device.

---

## 3. Data Model Definitions

All models live under `com.kpopvote.collector.data.model`. All use `@Serializable` with `kotlinx.serialization`, matching iOS JSON field names exactly.

### 3.1 In-App Vote models (`InAppVote.kt`)

```kotlin
@Serializable
data class InAppVote(
    val voteId: String,
    val title: String,
    val description: String? = null,
    val coverImageUrl: String? = null,
    val status: VoteStatus,              // upcoming | active | ended
    val startAt: String,                 // ISO-8601
    val endAt: String,
    val choices: List<VoteChoice> = emptyList(),
    val totalVotes: Long = 0,
    val featured: Boolean = false,
    val pointCost: Int = 1,
    val userDailyLimit: Int? = null,
    val userDailyVotes: Int? = null,
    val userDailyRemaining: Int? = null,
    val userPoints: Int? = null,
)

@Serializable
enum class VoteStatus {
    @SerialName("upcoming") UPCOMING,
    @SerialName("active")   ACTIVE,
    @SerialName("ended")    ENDED,
}

@Serializable
data class VoteChoice(
    val choiceId: String,
    val idolId: String? = null,
    val groupId: String? = null,
    val displayName: String,
    val imageUrl: String? = null,
    val voteCount: Long = 0,
)

@Serializable
data class VoteListData(val votes: List<InAppVote>, val count: Int)
```

### 3.2 Vote execute models (`VoteExecute.kt`)

```kotlin
@Serializable
data class VoteExecuteBody(
    val voteId: String,
    val choiceId: String,
    val voteCount: Int = 1,
    val pointSelection: String = "auto",
)

@Serializable
data class VoteExecuteResult(
    val voteId: String,
    val choiceId: String,
    val voteCount: Int,
    @SerialName("totalPointsDeducted") val pointsDeducted: Int,
    val userDailyVotes: Int? = null,
    val userDailyRemaining: Int? = null,
)
```

### 3.3 Ranking models (`VoteRanking.kt`)

```kotlin
@Serializable
data class VoteRanking(
    val voteId: String,
    val rankings: List<RankingEntry>,
    val totalVotes: Long,
    val updatedAt: String,
)

@Serializable
data class RankingEntry(
    val rank: Int,
    val choiceId: String,
    val displayName: String,
    val imageUrl: String? = null,
    val voteCount: Long,
    val percentage: Double,
)
```

### 3.4 Collection models (`VoteCollection.kt`)

```kotlin
@Serializable
data class VoteCollection(
    val collectionId: String,
    val ownerId: String,
    val ownerName: String? = null,
    val ownerAvatarUrl: String? = null,
    val title: String,
    val description: String = "",
    val coverImage: String? = null,
    val tags: List<String> = emptyList(),
    val tasks: List<CollectionTaskRef> = emptyList(),
    val visibility: CollectionVisibility = CollectionVisibility.PUBLIC,
    val saveCount: Int = 0,
    val likeCount: Int = 0,
    val createdAt: String,
    val updatedAt: String,
)

@Serializable
data class CollectionTaskRef(
    val taskId: String,
    val orderIndex: Int,
    val snapshot: VoteTask? = null,   // server may inline the task snapshot
)

@Serializable
enum class CollectionVisibility {
    @SerialName("public")    PUBLIC,
    @SerialName("followers") FOLLOWERS,
    @SerialName("private")   PRIVATE,
}

@Serializable
data class CollectionsListData(
    val collections: List<VoteCollection>,
    val pagination: PaginationInfo,
)

@Serializable
data class PaginationInfo(
    val currentPage: Int,
    val totalPages: Int,
    val totalCount: Int,
    val hasNext: Boolean,
)

@Serializable
data class CollectionDetailData(
    val collection: VoteCollection,
    val isSaved: Boolean,
    val isLiked: Boolean,
    val isOwner: Boolean,
    val isFollowingCreator: Boolean,
)

@Serializable
data class TrendingData(val collections: List<VoteCollection>, val period: String)

@Serializable
data class SaveData(val saved: Boolean, val saveCount: Int)

@Serializable
data class AddToTasksData(
    val addedCount: Int,
    val skippedCount: Int,
    val totalCount: Int,
    val addedTaskIds: List<String>,
)

@Serializable
data class AddSingleTaskData(
    val taskId: String,
    val alreadyAdded: Boolean,
    val message: String,
)

@Serializable
data class ShareCollectionData(val postId: String, val collectionId: String)

@Serializable
data class CollectionWriteBody(
    val title: String,
    val description: String,
    val coverImage: String? = null,
    val tags: List<String>,
    val tasks: List<CollectionTaskWrite>,
    val visibility: String,
)

@Serializable
data class CollectionTaskWrite(val taskId: String, val orderIndex: Int)

@Serializable
data class ShareCollectionBody(val biasIds: List<String>, val text: String = "")
```

### 3.5 Sort / filter enums

```kotlin
enum class CollectionSortOption(val apiValue: String) {
    LATEST("latest"), POPULAR("popular"), TRENDING("trending"), RELEVANCE("relevance"),
}

enum class TrendingPeriod(val apiValue: String) {
    LAST_24H("24h"), LAST_7D("7d"), LAST_30D("30d"),
}
```

---

## 4. Repository Interfaces

### 4.1 `VoteRepository`

```kotlin
interface VoteRepository {
    suspend fun fetchFeaturedVotes(): Result<List<InAppVote>>
    suspend fun fetchVotes(status: VoteStatus? = null): Result<List<InAppVote>>
    suspend fun fetchVoteDetail(voteId: String): Result<InAppVote>
    suspend fun executeVote(
        voteId: String,
        choiceId: String,
        voteCount: Int = 1,
        pointSelection: String = "auto",
    ): Result<VoteExecuteResult>
    suspend fun fetchRanking(voteId: String): Result<VoteRanking>
}
```

Implementation notes:
- `executeVote` obtains App Check token via `AppCheckTokenProvider` and passes it as a **new** `xAppCheckToken` parameter on `FunctionsClient.post`. This is the first caller needing that header; extend `FunctionsClient` accordingly (see §8).
- All exceptions go through `toAppError()`; then `VoteErrorMapper.map(response.code, body)` refines a Server(400) into Vote-specific AppError subclasses (see §9).

### 4.2 `CollectionRepository`

```kotlin
interface CollectionRepository {
    suspend fun getCollections(
        page: Int = 1,
        limit: Int = 20,
        sortBy: CollectionSortOption = CollectionSortOption.LATEST,
        tags: List<String>? = null,
    ): Result<CollectionsListData>

    suspend fun searchCollections(
        query: String,
        page: Int = 1,
        limit: Int = 20,
        sortBy: CollectionSortOption = CollectionSortOption.RELEVANCE,
        tags: List<String>? = null,
    ): Result<CollectionsListData>

    suspend fun getTrendingCollections(
        period: TrendingPeriod = TrendingPeriod.LAST_7D,
        limit: Int = 10,
    ): Result<List<VoteCollection>>

    suspend fun getCollectionDetail(collectionId: String): Result<CollectionDetailData>
    suspend fun getSavedCollections(page: Int = 1, limit: Int = 20): Result<CollectionsListData>
    suspend fun getMyCollections(page: Int = 1, limit: Int = 20): Result<CollectionsListData>

    suspend fun toggleSave(collectionId: String): Result<SaveData>
    suspend fun addAllToTasks(collectionId: String): Result<AddToTasksData>
    suspend fun addSingleToTasks(collectionId: String, taskId: String): Result<AddSingleTaskData>
    suspend fun shareToCommunity(
        collectionId: String,
        biasIds: List<String>,
        text: String? = null,
    ): Result<ShareCollectionData>

    suspend fun createCollection(body: CollectionWriteBody): Result<VoteCollection>
    suspend fun updateCollection(collectionId: String, body: CollectionWriteBody): Result<VoteCollection>
    suspend fun deleteCollection(collectionId: String): Result<Unit>
}
```

### 4.3 `CollectionCoverImageRepository`

```kotlin
interface CollectionCoverImageRepository {
    /**
     * Uploads local Uri to Firebase Storage under
     *   collections/{userId}/{uuid}.{ext}
     * Returns the public download URL usable as `coverImage` in create/update bodies.
     */
    suspend fun uploadCoverImage(localUri: Uri, contentType: String = "image/jpeg"): Result<String>

    /** Best-effort deletion when replacing an image. Swallows failures. */
    suspend fun deleteCoverImage(downloadUrl: String)
}
```

Implementation uses `FirebaseStorage.getInstance().reference.child(path).putFile(uri).await()`. MIME inferred via `ContentResolver.getType()`.

---

## 5. ViewModel Designs

All ViewModels follow the Sprint 3 pattern: `StateFlow<UiState>` sealed class or data class; `viewModelScope.launch`; Hilt `@HiltViewModel`.

### 5.1 `VotesTabsViewModel`
- Holds `selectedTab: StateFlow<VotesTab>` (DISCOVER / SAVED / MY_COLLECTIONS)
- Forwards selection changes to child ViewModels via a `SharedFlow<TabRefreshEvent>` so inactive tabs skip work

### 5.2 `DiscoverViewModel`
- State: `DiscoverUiState(isLoading, items, selectedTags, sortOption, searchQuery, errorMessage, hasNext, currentPage)`
- Actions: `onSearchChanged(String)` (debounced 350ms), `onTagToggle(String)`, `onSortChange(CollectionSortOption)`, `loadNextPage()`, `refresh()`
- Debounce via `flow.debounce(350).distinctUntilChanged().flatMapLatest`
- Switches between `getCollections` and `searchCollections` based on `searchQuery.isNotBlank()`

### 5.3 `SavedCollectionsViewModel` / `MyCollectionsViewModel`
- Near-identical pagination state; parameterized on the repo method it calls
- Consider extracting a `PagedCollectionsViewModel<T>` base to deduplicate

### 5.4 `VoteListViewModel`
- State: `VoteListUiState(isLoading, votes, statusFilter, errorMessage)`
- Actions: `setStatus(VoteStatus?)`, `refresh()`

### 5.5 `VoteDetailViewModel`
- Constructor: `SavedStateHandle` (reads `voteId`)
- State: `VoteDetailUiState(isLoading, vote, selectedChoiceId, voteCount, isVoting, errorMessage, lastResult)`
- Actions: `load()`, `selectChoice(String)`, `incVoteCount()`, `decVoteCount()`, `confirmVote()`, `dismissError()`
- On `confirmVote()` success: refreshes detail + emits one-shot `VoteSuccessEvent` via `Channel<VoteEvent>`

### 5.6 `VoteRankingViewModel`
- State: `VoteRankingUiState(isLoading, ranking, errorMessage)`
- Pull-to-refresh wired to `refresh()`

### 5.7 `CollectionDetailViewModel`
- State: `CollectionDetailUiState(isLoading, detail, isToggleSaving, isAdding, errorMessage, addResult, shareSuccess)`
- Actions: `load()`, `toggleSave()` (optimistic), `addAllToTasks()`, `addSingleTask(taskId)`, `share(biasIds, text)`, `delete()`
- Owner-only actions gated via `detail.isOwner`

### 5.8 `CreateCollectionViewModel` (reused for edit)
- Constructor: `SavedStateHandle` with optional `collectionId` → switches `Mode.CREATE` / `Mode.EDIT`
- State: `CollectionFormUiState(title, description, tags, selectedTaskIds, taskOrder, coverImageUri, coverImageRemoteUrl, visibility, isSubmitting, validationErrors, submitResult)`
- Validation rules (mirror iOS):
  - title: 1..50 chars trimmed
  - description: 0..500 chars
  - tags: size 0..10, each trimmed non-empty, unique case-insensitive
  - tasks: 1..50 entries (enforced client-side; server also validates)
- On submit: uploads cover image if local Uri present → builds `CollectionWriteBody` → `createCollection` or `updateCollection`

---

## 6. Navigation Routes

Extend `NavRoutes.kt`:

```kotlin
const val VOTES_TAB = "votes"                              // bottom nav slot 3
const val VOTE_LIST = "voteList"                           // "すべての投票" entry from HOME
const val VOTE_DETAIL = "voteDetail/{voteId}"
const val VOTE_RANKING = "voteRanking/{voteId}"
const val COLLECTION_DETAIL = "collectionDetail/{collectionId}"
const val COLLECTION_CREATE = "collectionCreate"
const val COLLECTION_EDIT = "collectionEdit/{collectionId}"
```

Argument builders:
```kotlin
fun voteDetail(voteId: String) = "voteDetail/$voteId"
fun voteRanking(voteId: String) = "voteRanking/$voteId"
fun collectionDetail(id: String) = "collectionDetail/$id"
fun collectionEdit(id: String) = "collectionEdit/$id"
```

Wire composables in `KpopVoteNavHost.kt`, using `hiltViewModel()` + `navBackStackEntry.arguments` for path params.

---

## 7. App Check Play Integrity Integration

### 7.1 Module setup
- Add `implementation("com.google.firebase:firebase-appcheck-playintegrity:18.x")` in `app/build.gradle.kts`
- Add `debugImplementation("com.google.firebase:firebase-appcheck-debug:18.x")` for emulator

### 7.2 Initialization
In `KpopVoteApp.onCreate()` (after `FirebaseApp.initializeApp`):
```kotlin
val providerFactory = if (BuildConfig.DEBUG) {
    DebugAppCheckProviderFactory.getInstance()
} else {
    PlayIntegrityAppCheckProviderFactory.getInstance()
}
FirebaseAppCheck.getInstance().installAppCheckProviderFactory(providerFactory)
```

### 7.3 `AppCheckTokenProvider`
```kotlin
@Singleton
class AppCheckTokenProvider @Inject constructor() {
    suspend fun getToken(forceRefresh: Boolean = false): String? {
        if (BuildConfig.DEBUG) return null              // matches iOS DEBUG skip
        return runCatching {
            FirebaseAppCheck.getInstance().getAppCheckToken(forceRefresh).await().token
        }.getOrElse {
            Timber.w(it, "AppCheck token fetch failed")
            null
        }
    }
}
```

### 7.4 Attachment point
Only `executeVote` attaches `X-Firebase-AppCheck`. `FunctionsClient.post()` gains an optional `extraHeaders: Map<String, String>` parameter; `VoteRepositoryImpl.executeVote` passes `mapOf("X-Firebase-AppCheck" to token)` when non-null.

### 7.5 Backend coordination
- No Cloud Functions change needed; existing `executeVote` already validates the header.
- Debug tokens must be registered in Firebase Console under App Check → Apps → Android → Debug tokens for the emulator to work in release-behavior testing.

---

## 8. FunctionsClient Extensions

Current `FunctionsClient` supports `get(path, serializer, query)` and `post(path, bodyJson, serializer)`. Sprint 4 needs:

1. **Optional extra headers on POST** — for `X-Firebase-AppCheck`
2. **PUT support** — for `updateCollection`
3. **DELETE support** — for `deleteCollection`

Proposed signatures:
```kotlin
suspend fun <R : Any> post(
    path: String,
    bodyJson: String,
    dataSerializer: KSerializer<R>,
    extraHeaders: Map<String, String> = emptyMap(),
): R

suspend fun <R : Any> put(
    path: String,
    bodyJson: String,
    dataSerializer: KSerializer<R>,
): R

suspend fun delete(path: String)              // envelope-only, no data
```

New `ApiPaths` entries:
```kotlin
// In-App Vote
const val LIST_IN_APP_VOTES   = "listInAppVotes"
const val GET_IN_APP_VOTE     = "getInAppVoteDetail"
const val EXECUTE_VOTE        = "executeVote"
const val GET_RANKING         = "getRanking"

// Collections
const val COLLECTIONS          = "collections"                          // also used for GET list, POST create
const val SEARCH_COLLECTIONS   = "searchCollections"
const val TRENDING_COLLECTIONS = "trendingCollections"
const val MY_COLLECTIONS       = "myCollections"
const val SAVED_COLLECTIONS    = "savedCollections"
// Dynamic subpaths built inline:
//   "$COLLECTIONS/$id"
//   "$COLLECTIONS/$id/save"
//   "$COLLECTIONS/$id/add-to-tasks"
//   "$COLLECTIONS/$id/tasks/$taskId/add"
//   "$COLLECTIONS/$id/share-to-community"
```

Keep the existing `AppError` normalization; the new methods call the same `execute()` internal.

---

## 9. AppError Extensions

Sprint 3 defined `AppError.Network / Unauthorized / Server / Validation / Auth / Unknown`. Sprint 4 adds vote-business errors as a new sealed subfamily, kept separate from HTTP `Server` so UI can pattern-match cleanly.

```kotlin
sealed class AppError : Throwable() {
    // ... existing ...

    sealed class Vote : AppError() {
        object AlreadyVoted : Vote() {
            override val message = "既に投票済みです"
        }
        object InsufficientPoints : Vote() {
            override val message = "ポイントが不足しています"
        }
        object NotActive : Vote() {
            override val message = "この投票は開催されていません"
        }
        data class DailyLimitReached(override val message: String) : Vote()
        object AppCheckFailed : Vote() {
            override val message = "端末の検証に失敗しました。時間をおいて再度お試しください。"
        }
    }

    sealed class Collection : AppError() {
        object NotOwner : Collection() {
            override val message = "このコレクションを編集する権限がありません"
        }
        data class QuotaExceeded(override val message: String) : Collection()
    }
}
```

### Error mapping helper
```kotlin
internal object VoteErrorMapper {
    fun refine(error: Throwable): AppError = when (error) {
        is AppError.Server if error.code == 400 -> when {
            error.message.contains("Already voted", ignoreCase = true) -> AppError.Vote.AlreadyVoted
            error.message.contains("Insufficient points", ignoreCase = true) -> AppError.Vote.InsufficientPoints
            error.message.contains("not active", ignoreCase = true) -> AppError.Vote.NotActive
            error.message.contains("投票上限") || error.message.contains("投票数制限") ->
                AppError.Vote.DailyLimitReached(error.message)
            else -> error
        }
        else -> error.toAppError()
    }
}
```

Call in `VoteRepositoryImpl.executeVote` via `.recoverCatching { throw VoteErrorMapper.refine(it) }`.

---

## 10. Unit Test Plan

Target: **~45 new tests**, pushing the suite past 95 total.

| Area | File | Test count | Key scenarios |
|------|------|-----------:|---------------|
| VoteRepository | `VoteRepositoryImplTest.kt` | 10 | featured/status filters, detail parsing, execute success, each of 4 business errors, App Check header attached, App Check null in DEBUG |
| CollectionRepository | `CollectionRepositoryImplTest.kt` | 12 | list pagination, search, trending, save toggle, add-all (addedCount>0, skippedCount>0), add-single (alreadyAdded=true), share 201, update, delete, visibility enum roundtrip |
| CollectionCoverImageRepository | `CollectionCoverImageRepositoryTest.kt` | 2 | success returns downloadUrl, failure → AppError.Network |
| VoteListViewModel | `VoteListViewModelTest.kt` | 3 | initial load, status filter change refetches, error state |
| VoteDetailViewModel | `VoteDetailViewModelTest.kt` | 6 | load success, selectChoice updates state, incVoteCount caps at `userDailyRemaining`, confirmVote success, each of 4 errors surfaced |
| VoteRankingViewModel | `VoteRankingViewModelTest.kt` | 2 | load success, refresh |
| DiscoverViewModel | `DiscoverViewModelTest.kt` | 4 | debounced search switches API, sort change resets page, tag toggle, loadNextPage appends |
| CollectionDetailViewModel | `CollectionDetailViewModelTest.kt` | 4 | toggle save optimistic + rollback on error, addAll shows result, share success, delete only when owner |
| CreateCollectionViewModel | `CreateCollectionViewModelTest.kt` | 5 | title validation min/max, tags unique+max-10, task count 1..50, edit mode prefill, cover image upload flow |
| AppError / VoteErrorMapper | `VoteErrorMapperTest.kt` | 4 | 4 Japanese/English error message branches |

All ViewModel tests use `runTest { }` with `StandardTestDispatcher`; repository tests use a fake `FunctionsClient` that returns predefined `Result`s, matching the Sprint 3 pattern.

---

## 11. Risks

| ID | Risk | Severity | Likelihood | Mitigation |
|----|------|:-:|:-:|------------|
| R1 | App Check Play Integrity rejects debug builds on emulator, blocking `executeVote` | High | High | `DebugAppCheckProviderFactory` in `BuildConfig.DEBUG`; register emulator debug tokens in Console. Provide `--allow-insecure-execute` dev flag to skip header entirely. |
| R2 | Cover image upload to Firebase Storage fails silently, breaking create/edit | High | Medium | Upload must complete before form submit; show blocking progress indicator; on failure, keep form state and surface AppError.Network. Do NOT commit to backend with missing URL. |
| R3 | iOS uses Japanese substring matching (e.g. `"投票上限"`) to detect daily-limit errors; backend changes wording → Android misclassifies | High | Medium | Mirror exact strings in `VoteErrorMapper`; add integration smoke test; open a ticket to move to server-side error codes in v1.1. |
| R4 | `VoteExecuteResult.pointsDeducted` uses JSON key `totalPointsDeducted` (not `pointsDeducted`) — easy to miss | Medium | High | Test asserts field mapping; code review checklist item. Already captured in §3.2. |
| R5 | Collection `tasks` field sometimes arrives as `[{taskId, orderIndex}]` (no snapshot) and sometimes inlined — dual shapes | Medium | Medium | Model `snapshot: VoteTask?` nullable; deserialize gracefully; fetch full task detail lazily if snapshot missing. |
| R6 | Pagination `hasNext` can disagree with `currentPage == totalPages` on edge cases (empty results, offset race) | Medium | Low | Use `hasNext` exclusively as source of truth; do not derive from page numbers. |
| R7 | `sortBy=trending` + unrelated tag filter may return empty; users interpret as bug | Low | Medium | Empty state copy: "該当するコレクションがありません。タグまたは並び順を変更してください。" |
| R8 | `toggleSave` optimistic update diverges from server state when network flakes mid-flight | Medium | Medium | On error, rollback `isSaved` and `saveCount` to pre-click values; show transient snackbar. Store pre-click snapshot in ViewModel. |
| R9 | `addAllToTasks` may add >50 items crossing user task quota (if any server cap) | Medium | Low | Show `AddToTasksData.skippedCount` clearly; if error is quota, map to `AppError.Collection.QuotaExceeded`. |
| R10 | `shareToCommunity` requires at least one `biasId`; empty submissions 400 | Medium | Medium | Disable submit button until ≥1 bias selected; inline validation label. |
| R11 | Deleting a collection while it is visible in `MyCollectionsScreen` causes stale state | Low | Medium | Invalidate `MyCollectionsViewModel` cache via a `SharedFlow<CollectionEvent.Deleted>` emitted after delete success. |
| R12 | HOME featured-votes fetch failure cascades into blocking the whole HOME refresh | High | Low | Wrap in independent `async { }` within `HomeViewModel.refresh()`; swallow errors into an empty list + log; never fail the Tasks half of the screen. |
| R13 | Create/Edit with 50 task items makes the task picker UI laggy | Low | Medium | Use `LazyColumn` + stable keys; limit task picker filtered list to 100 items with search. |
| R14 | Cover image orientation/metadata EXIF rotation differs Android vs iOS | Low | Medium | Use `ImageDecoder` + `setPostProcessor` for API 28+; fallback to `BitmapFactory` with EXIF normalization for older devices. |
| R15 | `visibility=followers` not meaningfully testable without follower data, risking UI confusion | Low | Medium | Keep enum passthrough; show helper text "フォロワーのみ閲覧できます (ベータ)"; defer UX polish to v1.1. |

---

## 12. New / Changed File List

### New files (~55)

**Data layer (~18)**
- `data/model/InAppVote.kt`
- `data/model/VoteExecute.kt`
- `data/model/VoteRanking.kt`
- `data/model/VoteCollection.kt`
- `data/model/CollectionEnums.kt` (sort options, trending period, visibility)
- `data/api/VoteApiPaths.kt` (or extend `ApiPaths.kt`)
- `data/repository/VoteRepository.kt`
- `data/repository/VoteRepositoryImpl.kt`
- `data/repository/CollectionRepository.kt`
- `data/repository/CollectionRepositoryImpl.kt`
- `data/repository/CollectionCoverImageRepository.kt`
- `data/repository/CollectionCoverImageRepositoryImpl.kt`
- `data/repository/VoteErrorMapper.kt`
- `core/appcheck/AppCheckTokenProvider.kt`
- `core/common/events/VoteEvent.kt`
- `core/common/events/CollectionEvent.kt`

**UI — Vote (~10)**
- `ui/vote/VoteListScreen.kt`
- `ui/vote/VoteListViewModel.kt`
- `ui/vote/VoteDetailScreen.kt`
- `ui/vote/VoteDetailViewModel.kt`
- `ui/vote/VoteRankingScreen.kt`
- `ui/vote/VoteRankingViewModel.kt`
- `ui/vote/components/VoteCard.kt`
- `ui/vote/components/VoteChoiceRow.kt`
- `ui/vote/components/VoteCastBottomSheet.kt`
- `ui/vote/components/RankingRow.kt`

**UI — Votes/Collections (~20)**
- `ui/votes/VotesTabScreen.kt`
- `ui/votes/VotesTabsViewModel.kt`
- `ui/votes/discover/DiscoverScreen.kt`
- `ui/votes/discover/DiscoverViewModel.kt`
- `ui/votes/saved/SavedCollectionsScreen.kt`
- `ui/votes/saved/SavedCollectionsViewModel.kt`
- `ui/votes/mine/MyCollectionsScreen.kt`
- `ui/votes/mine/MyCollectionsViewModel.kt`
- `ui/votes/detail/CollectionDetailScreen.kt`
- `ui/votes/detail/CollectionDetailViewModel.kt`
- `ui/votes/detail/ShareCollectionBottomSheet.kt`
- `ui/votes/detail/AddToTasksResultDialog.kt`
- `ui/votes/form/CreateCollectionScreen.kt`
- `ui/votes/form/CreateCollectionViewModel.kt`
- `ui/votes/form/TaskPickerBottomSheet.kt`
- `ui/votes/form/CoverImagePickerLauncher.kt`
- `ui/votes/components/CollectionCard.kt`
- `ui/votes/components/TagChipRow.kt`
- `ui/votes/components/SortPicker.kt`
- `ui/votes/components/PagingLoadMoreTrigger.kt`

**Tests (~12)**
- `test/.../repository/VoteRepositoryImplTest.kt`
- `test/.../repository/CollectionRepositoryImplTest.kt`
- `test/.../repository/CollectionCoverImageRepositoryTest.kt`
- `test/.../repository/VoteErrorMapperTest.kt`
- `test/.../ui/vote/VoteListViewModelTest.kt`
- `test/.../ui/vote/VoteDetailViewModelTest.kt`
- `test/.../ui/vote/VoteRankingViewModelTest.kt`
- `test/.../ui/votes/DiscoverViewModelTest.kt`
- `test/.../ui/votes/SavedCollectionsViewModelTest.kt`
- `test/.../ui/votes/MyCollectionsViewModelTest.kt`
- `test/.../ui/votes/CollectionDetailViewModelTest.kt`
- `test/.../ui/votes/CreateCollectionViewModelTest.kt`

### Modified files (~12)

- `app/build.gradle.kts` — add `firebase-appcheck-playintegrity` + debug variant
- `KpopVoteApp.kt` — install App Check provider factory
- `data/api/ApiPaths.kt` — add Vote/Collection endpoints
- `data/api/FunctionsClient.kt` — add `extraHeaders`, `put()`, `delete()`
- `core/common/AppError.kt` — add `Vote` and `Collection` sealed subtypes
- `di/RepositoryModule.kt` — bind new repositories
- `di/AppModule.kt` — provide `AppCheckTokenProvider`, `FirebaseStorage`
- `ui/navigation/NavRoutes.kt` — add 6 routes
- `ui/navigation/KpopVoteNavHost.kt` — wire composables
- `ui/home/HomeScreen.kt` — add featured votes strip
- `ui/home/HomeViewModel.kt` — parallel load featured votes
- `res/values/strings.xml` + `res/values-ja/strings.xml` — new strings for all Vote/Collection UI

---

## 13. Total Effort Estimate

| Phase | Low | High | Notes |
|-------|----:|----:|-------|
| Phase 1 — Data + Repositories | 20h | 25h | Most DTOs straightforward; App Check wiring + FunctionsClient extensions add complexity |
| Phase 2 — In-App Vote UI | 20h | 25h | VoteDetail is the most complex Compose screen in the sprint |
| Phase 3 — Votes Tab + Discover | 18h | 22h | Pagination + search debounce + tag chips |
| Phase 4 — Collection Detail + Actions | 18h | 22h | Share sheet + bias multi-select adds UI work |
| Phase 5 — Create/Edit/Delete Collection | 16h | 20h | Storage upload + form validation + task picker |
| Phase 6 — HOME integration + Polish + Tests | 12h | 15h | Test backfill + string resources + CI |
| Buffer (integration issues, App Check tuning, emulator flakes) | 6h | 8h | — |
| **Total** | **110h** | **137h** | Within the 100-140h target band |

Recommended sequencing: Phase 1 and Phase 2 can overlap partially once VoteRepository is stable. Phase 5 should not start until Phase 4 is merged (CollectionDetail read path must exist before edit write path is tested). Phase 6 is the final polish pass before release candidate tagging.
