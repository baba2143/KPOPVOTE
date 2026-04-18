# Sprint 3 仕様：Tasks + Home + MainTab

**期間目安**: 90–120h
**依存**: Sprint 1（基盤 + Auth）✅ / Sprint 2（FunctionsClient + マスターデータ + Bias + Storage）✅
**参照 iOS**: `ios/KPOPVOTE/KPOPVOTE/Services/TaskService.swift`, `ExternalAppService.swift`, `Models/Task.swift`, `ViewModels/HomeViewModel.swift`, `ViewModels/TasksListViewModel.swift`, `ViewModels/TaskRegistrationViewModel.swift`, `Views/MainTabView.swift`, `Views/Task/TaskRegistrationView.swift`

---

## 1. スコープ

### 実装する
- ドメインモデル `VoteTask`（iOS 名称を踏襲）＋ `TaskStatus` / `CoverImageSource` enum
- `TaskRepository`（HTTP: `getUserTasks` / `registerTask` / `updateTask` / `updateTaskStatus` / `deleteTask`）
- `TaskCoverImageRepository`（Firebase Storage 直接アップロード `task-cover-images/{uid}/{uuid}.jpg`）
- `OgpRepository` **スタブのみ**（`fetchTaskOGP` エンドポイントは iOS で未使用。Android でも Sprint 3 では UI 非接続）
- `MainTabScreen`：5 タブ（Home / Ranking / Votes / Community / Profile）＋ フローティング + ボタン
  - Sprint 3 で実装するのは Home と Profile（プレースホルダ維持、既存）、他は「Coming soon」プレースホルダ
- `HomeScreen`：参加中タスクのカルーセル、Bias カード、Points プレースホルダ、Featured Votes プレースホルダ
- `TaskListScreen`：3 タブ（Active / Archive / Completed）セグメントピッカー、プルリフレッシュ
- `TaskDetailScreen`（編集フロー）＝ `AddTaskScreen` の edit モード兼用
- `AddTaskScreen`：タイトル / URL / 期日 / 外部アプリ / 対象メンバー（Bias 選択）/ カバー画像
- `BiasSelectionBottomSheet`（メンバー選択用、マスターデータから引く）
- Navigation: NavGraph 拡張（Home → TaskList / AddTask、TaskList → TaskDetail、全画面から + ボタン → AddTask）

### 実装しない（意図的）
- Featured votes 実データ取得（Sprint 4 で実装、Home 側は空の placeholder で OK）
- Community feed / Ranking 実データ（Sprint 5 / 6）
- Profile 実装（Sprint 7）
- 共有時 +5P の `shareTask` 呼び出し（Sprint 6 Points 実装時に）
- OGP UI プレビュー（iOS 側も未使用のため見送り）
- Realtime Firestore listener（iOS が HTTP one-shot に統一しているため同じ方針）

---

## 2. ドメインモデル

### `VoteTask`（`data/model/VoteTask.kt`）
```kotlin
@Serializable
data class VoteTask(
    @SerialName("taskId") val id: String,
    val userId: String,
    val title: String,
    val url: String,
    @SerialName("deadline") val deadlineIso: String,          // ISO8601 with fractional seconds
    val status: TaskStatus = TaskStatus.PENDING,
    @SerialName("targetMembers") val biasIds: List<String> = emptyList(),
    val externalAppId: String? = null,
    val externalAppName: String? = null,
    val externalAppIconUrl: String? = null,
    val coverImage: String? = null,
    val coverImageSource: CoverImageSource? = null,
    @SerialName("createdAt") val createdAtIso: String? = null,
    @SerialName("updatedAt") val updatedAtIso: String? = null,
)
```
- `deadlineMillis: Long?`（拡張プロパティ）— `Instant.parse(deadlineIso).toEpochMilli()` を nullable で
- `isExpired: Boolean` — `deadlineMillis < now && status !in {COMPLETED, ARCHIVED}`
- `timeRemaining: String` — `"3日"` / `"2時間"` / `"期限切れ"`（i18n は後回し）
- `statusColor(colorScheme): Color` — 期限切れ赤 / pending ピンク / completed 緑 / archived グレー

### Enum
```kotlin
@Serializable
enum class TaskStatus {
    @SerialName("pending") PENDING,
    @SerialName("completed") COMPLETED,
    @SerialName("expired") EXPIRED,
    @SerialName("archived") ARCHIVED,
}

@Serializable
enum class CoverImageSource {
    @SerialName("externalApp") EXTERNAL_APP,
    @SerialName("userUpload") USER_UPLOAD,
}
```

### レスポンス DTO
```kotlin
@Serializable data class TaskListData(val tasks: List<VoteTask>, val count: Int = 0)
```

---

## 3. Repository

### `TaskRepository`（`data/repository/TaskRepository.kt`）
```kotlin
interface TaskRepository {
    suspend fun getUserTasks(isCompleted: Boolean? = null): Result<List<VoteTask>>
    suspend fun getActiveTasks(): Result<List<VoteTask>>                  // isCompleted=false + !expired + !archived
    suspend fun registerTask(input: TaskInput): Result<VoteTask>
    suspend fun updateTask(taskId: String, input: TaskInput): Result<VoteTask>
    suspend fun markCompleted(taskId: String): Result<Int?>               // returns pointsGranted
    suspend fun deleteTask(taskId: String): Result<Unit>
}

data class TaskInput(
    val title: String,
    val url: String,
    val deadlineIso: String,
    val biasIds: List<String> = emptyList(),
    val externalAppId: String? = null,
    val coverImage: String? = null,
    val coverImageSource: CoverImageSource? = null,
)
```
- 実装: `FunctionsClient.get/post` を使う。`TaskInput` は JSON body に直接エンコード（`targetMembers` 名で送信する点は `@SerialName` で吸収）
- `markCompleted` レスポンスは `{ pointsGranted: Int? }` を期待（iOS と同じ）

### `TaskCoverImageRepository`（`data/repository/TaskCoverImageRepository.kt`）
```kotlin
interface TaskCoverImageRepository {
    suspend fun upload(bytes: ByteArray): Result<String>     // returns download URL
}
```
- 実装は `StorageRepository` を薄くラップし、パスだけ固定：`task-cover-images/{uid}/{uuid}.jpg`
- 圧縮（JPEG quality 80）は **呼び出し側（ViewModel 層）** で行う（`android.graphics.Bitmap` に依存するため Repository は pure bytes のみ扱う）

### `OgpRepository`（`data/repository/OgpRepository.kt`）— スタブ
```kotlin
interface OgpRepository {
    suspend fun fetchOgp(url: String): Result<OgpMetadata>   // calls fetchTaskOGP, returns AppError.Server("not implemented") on iOS parity
}
@Serializable data class OgpMetadata(val title: String?, val description: String?, val imageUrl: String?)
```
- Sprint 3 では実装するが UI 非接続。Sprint 4 以降で Add Task 画面のプレビュー機能として使う可能性を残す
- エンドポイントは `ApiPaths.FETCH_TASK_OGP = "fetchTaskOGP"` として定数化

---

## 4. ViewModel

### `HomeViewModel`（`ui/home/HomeViewModel.kt`）
```kotlin
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val taskRepository: TaskRepository,
    private val biasRepository: BiasRepository,
    private val masterDataRepository: MasterDataRepository,
) : ViewModel() {
    data class UiState(
        val activeTasks: List<VoteTask> = emptyList(),
        val bias: List<BiasSettings> = emptyList(),
        val isLoading: Boolean = false,
        val error: AppError? = null,
    )
    val state: StateFlow<UiState>
    fun refresh()
    fun completeTask(taskId: String)       // 楽観的 UI 更新 → markCompleted → 失敗時再読込
}
```

### `TaskListViewModel`（`ui/tasks/TaskListViewModel.kt`）
- `allTasks: StateFlow<List<VoteTask>>`
- `derived`: `activeTasks` / `archivedTasks` / `completedTasks`
- `selectedSegment: StateFlow<TaskListSegment>`（ACTIVE / ARCHIVE / COMPLETED）
- `loadAll()` / `completeTask(taskId)` / `deleteTask(taskId)` / `refresh()`
- Sprint 6 の `shareTask` 前提の「共有+5P」ボタンは Sprint 3 では **非表示 or disabled**

### `AddEditTaskViewModel`（`ui/tasks/AddEditTaskViewModel.kt`）
- `SavedStateHandle` で `taskId: String?` を受け取り編集モード判定
- `UiState`: title / url / deadlineMillis / selectedMemberIds / selectedMemberNames / externalApps / selectedAppId / selectedCoverBitmap / coverImageUrl / coverImageSource / isLoading / error
- 検証ロジック: `isFormValid`
- メンバー名解決: `masterDataRepository.refreshIdols()` + `refreshGroups()` の Success 状態を参照して id→name マップを作る
- 外部アプリ選択時: `defaultCoverImageUrl` を自動設定
- submit: `if (selectedCoverBitmap != null && coverImageUrl == null) upload()` → `registerTask` or `updateTask`

---

## 5. UI 層

### `MainTabScreen`（`ui/main/MainTabScreen.kt`）
- `Scaffold` + `NavigationBar`（Material 3）
- 5 項目: Home / Ranking / Votes / Community / Profile
- アイコンは Material Icons（`Icons.Filled.Home` / `EmojiEvents` / `BarChart` / `Forum` / `Person`）
- フローティング `+` ボタン: `FloatingActionButton`（bottom-right）で `AddTaskScreen` へ遷移
  - Sprint 3 はタスク作成のみ。iOS のメニュー展開は Sprint 4 以降で追加
- 現在選択タブを `rememberSaveable` で保持
- 各タブの Content は `NavHost` 内の nested graph（iOS の `TabView` 相当）

### `HomeScreen`
- トップバー: アプリロゴ + 通知アイコン（Sprint 7）＋ Points バッジ（Sprint 6）
- セクション 1: 「参加中の推し投票」— LazyRow の `TaskCard`（横スクロール、最大 5 件表示 + "一覧を見る"）
- セクション 2: 「あなたの推し」— Bias 一覧（なければ "推し設定へ" CTA）
- セクション 3: 「注目の投票」— プレースホルダ（Sprint 4）
- プルリフレッシュ: `PullToRefreshBox`
- 空状態: 「進行中のタスクはありません」

### `TaskListScreen`
- `SegmentedButton`（`SingleChoiceSegmentedButtonRow`）で 3 タブ切替
- `LazyColumn` で `TaskCard` 縦リスト
- スワイプ削除（`SwipeToDismissBox`）— Active / Archive タブのみ
- カード長押し or メニューから「完了」/「削除」/「編集」

### `AddEditTaskScreen`
- スクロール可能 `Column`
- TextField（タイトル）、TextField（URL、keyboardType=Uri）
- `DateTimePicker`（Compose Material 3 `DatePickerDialog` + `TimePickerDialog`）
- 外部アプリ選択: `ExposedDropdownMenuBox`
- 対象メンバー: チップ表示 + 「メンバーを選択」→ `BiasSelectionBottomSheet`
- カバー画像:
  - 表示: `AsyncImage`（Coil 3）
  - 選択: `rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia)`
  - 圧縮: `BitmapFactory.decodeStream` → `Bitmap.compress(JPEG, 80, out)`
- Submit ボタン（グラデーション pink→purple、disabled 管理）

### `BiasSelectionBottomSheet`
- `ModalBottomSheet`
- `MasterDataRepository` の `idols`/`groups` StateFlow を Collect
- ユーザーの Bias 設定（`BiasRepository`）から初期選択 ID セット
- 検索バー + リスト（チェックボックス選択）

---

## 6. Navigation

### `navigation/Routes.kt` 拡張
```kotlin
sealed interface Route {
    @Serializable data object Main : Route
    @Serializable data object Home : Route
    @Serializable data object TaskList : Route
    @Serializable data class AddTask(val taskId: String? = null) : Route   // edit mode if taskId != null
    @Serializable data object Login : Route
    @Serializable data object Register : Route
    // ... 既存
}
```

### 画面遷移
- Login → Main（既存、Sprint 1）
- Main 内で tab 切替（Home / Tasks / Votes / Community / Profile）
- Home の「一覧を見る」→ Tasks タブ切替
- 任意画面 + ボタン → AddTask（task_id=null）
- TaskList のカードタップ → AddTask（task_id=xxx、編集モード）

---

## 7. 依存関係の追加

`libs.versions.toml` に：
```toml
coil = "3.0.4"                         # 画像ロード
accompanist-permissions = "0.36.0"    # （使用する場合のみ）
activity-compose = "1.9.3"            # PhotoPicker 用（既存バージョン確認）
```
```toml
[libraries]
coil-compose = { module = "io.coil-kt.coil3:coil-compose", version.ref = "coil" }
coil-network-okhttp = { module = "io.coil-kt.coil3:coil-network-okhttp", version.ref = "coil" }
```

---

## 8. テスト計画

### Repository テスト
- `TaskRepositoryImplTest`
  - `getUserTasks` 成功: 複数タスクデコード確認
  - `getUserTasks` isCompleted=true の query パラメタ付与
  - `registerTask` body の `targetMembers` マッピング
  - `markCompleted` で `pointsGranted` 取得
  - `deleteTask` 成功 / 404 → AppError.Server(404)
- `OgpRepositoryImplTest`
  - 成功時 OgpMetadata 返却
  - 未実装時 AppError.Server 握り潰し

### ViewModel テスト（`StandardTestDispatcher` + `turbine`）
- `HomeViewModelTest`
  - 初期 Idle → refresh で Loading → Success
  - `completeTask` で楽観的 UI 更新
  - エラー時 error 状態
- `TaskListViewModelTest`
  - `allTasks` → `activeTasks` / `archivedTasks` / `completedTasks` の派生
  - ソート順（Active=deadline asc、Archive=deadline desc、Completed=updatedAt desc）
- `AddEditTaskViewModelTest`
  - 新規モードの初期値
  - 編集モードで既存タスクの値プリセット
  - `isFormValid` 判定（URL / deadline / title の境界）
  - 外部アプリ選択で `coverImageUrl` 自動セット

### UI テスト（Sprint 3 では省略可）
- `MainTabScreen` のタブ切替は compose-ui-test 軽く 1 ケースだけ

---

## 9. ファイル一覧（予定）

### 新規
- `data/model/VoteTask.kt`（＋ `TaskStatus` / `CoverImageSource` / `TaskListData`）
- `data/model/OgpMetadata.kt`
- `data/repository/TaskRepository.kt` / `TaskRepositoryImpl.kt`
- `data/repository/TaskCoverImageRepository.kt` / `Impl`
- `data/repository/OgpRepository.kt` / `Impl`
- `ui/main/MainTabScreen.kt` / `MainTabViewModel.kt`（選択タブ管理）
- `ui/home/HomeScreen.kt` / `HomeViewModel.kt` / `HomeUiState.kt`
- `ui/home/components/TaskCarouselCard.kt`
- `ui/tasks/TaskListScreen.kt` / `TaskListViewModel.kt`
- `ui/tasks/AddEditTaskScreen.kt` / `AddEditTaskViewModel.kt`
- `ui/tasks/BiasSelectionBottomSheet.kt`
- `ui/tasks/components/TaskCard.kt` / `CoverImagePicker.kt` / `DateTimePicker.kt`
- `core/util/IsoDate.kt`（ISO8601 ⇆ epoch millis の変換ユーティリティ）
- `core/util/ImageCompress.kt`（JPEG 80 圧縮）
- テスト 3 ファイル（Repository 2 / ViewModel 3 → 計 5）

### 修正
- `navigation/Routes.kt`（Main / TaskList / AddTask 追加）
- `navigation/NavGraph.kt`（nested graph for tabs）
- `di/RepositoryModule.kt`（`@Binds` 4 つ追加: Task / TaskCover / Ogp + 既存）
- `gradle/libs.versions.toml`（Coil 3 追加）
- `app/build.gradle.kts`（Coil 依存追加）
- `docs/android/README.md`（Sprint 3 完了反映）
- `docs/android/ios-android-parity.md`（TaskRepo / HomeScreen / TaskListScreen 等 ✅）

---

## 10. 受入条件

- `./gradlew :app:testDebugUnitTest` → Sprint 2 テスト 19 + Sprint 3 新規テスト全て PASS
- Home → + → AddTask → 戻ると Home のタスクリストに反映（楽観更新 or refresh）
- TaskList の Active タブでスワイプ削除可能
- AddTask で URL 無効時にエラー表示、有効になると Submit ボタン有効化
- 外部アプリを選択すると `coverImage` に `defaultCoverImageUrl` が自動で入る
- 画像ピッカーで選択 → アップロード → `coverImage` に Storage URL が入る
- 編集モードで既存タスクの全フィールドが初期表示される
- iOS 版とバックエンド API 契約が完全一致（`targetMembers` 名、ISO8601、エンベロープ `{success, data}`）

---

## 11. リスク & 不確実性

| # | リスク | 対応 |
|---|--------|------|
| R1 | `deadline` シリアライズ形式のズレ（iOS: `ISO8601DateFormatter` with fractional seconds） | `java.time.Instant.parse()` を使用。ms 精度を保持して送信 |
| R2 | タスクのカバー画像圧縮でメモリ枯渇（10MB 画像） | PhotoPicker から InputStream を取得 → `BitmapFactory.Options.inSampleSize` でダウンサンプル |
| R3 | `markCompleted` のレスポンス形式が `{ pointsGranted: Int? }` か `{ data: { pointsGranted: Int? } }` か未確認 | iOS の実装を再確認（`GetUserTasksResponse` と同じく data エンベロープあり想定） |
| R4 | OGP は iOS 未使用 → Android で実装しても検証できない | スタブ実装に留め、Sprint 4 で実運用テスト |
| R5 | Coil 3 は安定版リリース直後、破壊変更の可能性 | バージョン固定 `3.0.4`、migration guide 参照 |
| R6 | Firebase Storage の security rules を iOS と共有 | rules の読み書き条件が Android uid でも通ることを setup-guide で明記 |
