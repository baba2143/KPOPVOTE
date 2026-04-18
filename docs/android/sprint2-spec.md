# Sprint 2 仕様 — コアデータ層 + マスターデータ

**期間目安**: 50〜70h（実装 40〜50h / テスト・レビュー 10〜20h）
**前提**: Sprint 1 完了（Firebase Auth 基盤、Hilt DI、テーマ確立）
**ゴール**: iOS 版で使っている Cloud Functions (HTTP onRequest) を Android から叩ける共通基盤を作り、マスターデータ・推し設定・ユーザープロフィール・画像アップロードの 4 リポジトリを完成させる。

---

## 1. スコープ

### 実装する機能
1. **FunctionsClient** — Firebase ID Token を Bearer で付与する HTTP クライアント抽象（GET/POST/JSON）
2. **ドメインモデル** — `IdolMaster` / `GroupMaster` / `ExternalAppMaster` / `BiasSettings` / `User`
3. **MasterDataRepository** — `listIdols` / `listGroups` / `listExternalApps`（インメモリキャッシュ付き Flow 公開）
4. **BiasRepository** — `getBias` / `setBias`
5. **UserRepository** — `observeCurrentUser`（Firestore realtime）/ `updateProfile`（HTTP）
6. **StorageRepository** — Firebase Storage への画像アップロード + ダウンロード URL 取得
7. **単体テスト** — 4 リポジトリ + FunctionsClient のエラーマッピング

### スコープ外（Sprint 3 以降）
- Tasks / Home / Votes / Community などの UI
- FCM トークン管理（Sprint 7）
- IAP（v2.0 送り）
- Admin 系 API（v1.2）

---

## 2. 技術仕様

### 2.1 HTTP vs Callable の方針

iOS では `URLSession` で `https://us-central1-kpopvote-9de2b.cloudfunctions.net/<name>` を直接叩き `Authorization: Bearer <idToken>` を付けている（`IdolService.swift:37-39` など）。Android も同じ挙動にする。

| ケース | 使うもの |
|--------|---------|
| `register` など既に Callable 化されている関数 | `FirebaseFunctions.getHttpsCallable(...)` |
| `listIdols` / `listGroups` / `listExternalApps` / `getBias` / `setBias` / `updateUserProfile` 等（HTTP onRequest） | **`FunctionsClient`（OkHttp + kotlinx.serialization）** |

> 理由: iOS 側が HTTP onRequest で契約している関数に対して Android から Callable で叩くと署名が違うため 404/CORS 系の問題になる。同じ HTTP エンドポイントに合わせる。

### 2.2 FunctionsClient API

```kotlin
class FunctionsClient {
    suspend inline fun <reified R> get(
        path: String,
        query: Map<String, String> = emptyMap(),
    ): R

    suspend inline fun <reified R> post(
        path: String,
        body: Any?,
    ): R

    // エラーは AppError に変換
    //   HTTP 401  → AppError.Unauthorized
    //   HTTP 4xx  → AppError.Server(code, message)
    //   HTTP 5xx  → AppError.Server(code, message)
    //   IOException → AppError.Network
    //   JSON decode → AppError.Validation
}
```

- **Base URL**: `BuildConfig.FUNCTIONS_BASE_URL`（Sprint 1 で定義済み）
- **認証**: 各呼び出しで `firebaseAuth.currentUser?.getIdToken(false).await()` を取得し `Authorization: Bearer ...` を付与。未ログイン時は `AppError.Unauthorized`
- **タイムアウト**: connect 10s / read 30s（iOS `NetworkConfig.defaultTimeout` 相当）
- **JSON**: `Json { ignoreUnknownKeys = true; encodeDefaults = true }`

### 2.3 共通レスポンスエンベロープ

Cloud Functions は `{ success: true, data: { ... } }` を返す（iOS で確認済み）。共通エンベロープ型を用意し、`data` だけデコードして返す。

```kotlin
@Serializable data class ApiEnvelope<T>(val success: Boolean, val data: T)
```

### 2.4 ドメインモデル

| Android 型 | フィールド | iOS 対応 |
|-----------|-----------|---------|
| `IdolMaster` | `idolId, name, groupName, imageUrl?, createdAt?, updatedAt?` | `IdolMaster.swift` |
| `GroupMaster` | `groupId, name, imageUrl?, createdAt?, updatedAt?` | `GroupMaster.swift` |
| `ExternalAppMaster` | `appId, appName, appUrl, iconUrl?, defaultCoverImageUrl?, createdAt?, updatedAt?` | `ExternalAppMaster.swift` |
| `BiasSettings` | `artistId, artistName, memberIds, memberNames, isGroupLevel=false` | `Bias.swift:BiasSettings` |
| `User` | `uid, email, displayName?, photoURL?, bio?, points=0, biasIds=[], followingCount=0, followersCount=0, postsCount=0, isPrivate=false, isSuspended=false, createdAt, updatedAt` | `User.swift` |

**日付の扱い**:
- HTTP レスポンスの `createdAt`/`updatedAt` は ISO8601 文字列 → `Instant?` に変換
- Firestore Timestamp は `Instant` へ変換（Firestore → `toDate().toInstant()`）
- シリアライズは `String` として保持し、必要に応じて `Instant` へ変換するユーティリティを提供

### 2.5 Repository インターフェース

```kotlin
interface MasterDataRepository {
    val idols: StateFlow<MasterDataCache<IdolMaster>>
    val groups: StateFlow<MasterDataCache<GroupMaster>>
    val externalApps: StateFlow<MasterDataCache<ExternalAppMaster>>
    suspend fun refreshIdols(force: Boolean = false, groupName: String? = null): Result<List<IdolMaster>>
    suspend fun refreshGroups(force: Boolean = false): Result<List<GroupMaster>>
    suspend fun refreshExternalApps(force: Boolean = false): Result<List<ExternalAppMaster>>
}

interface BiasRepository {
    suspend fun getBias(): Result<List<BiasSettings>>
    suspend fun setBias(settings: List<BiasSettings>): Result<Unit>
}

interface UserRepository {
    fun observeCurrentUser(): Flow<User?>                // Firestore snapshot listener
    suspend fun getCurrentUser(): Result<User?>           // 単発取得
    suspend fun updateProfile(
        displayName: String? = null,
        bio: String? = null,
        biasIds: List<String>? = null,
        photoURL: String? = null,
    ): Result<User>
}

interface StorageRepository {
    suspend fun uploadImage(
        bytes: ByteArray,
        path: String,                  // 例: "profiles/{uid}/profile.jpg"
        contentType: String = "image/jpeg",
    ): Result<String>                  // returns download URL
}
```

- `MasterDataCache<T>` は `sealed interface { Idle, Loading, Success(items, fetchedAt), Failure(error) }`
- キャッシュ TTL は **10 分**（iOS 相当の挙動が無いため Android 独自に規定）
- `refresh(force=false)` は TTL 内なら再取得せずキャッシュ値を返す

### 2.6 エラー契約

- 全 Repository は `Result<T>` を返す（失敗時は `AppError`）
- **認証切れ** は `AppError.Unauthorized`（UI 側で再ログイン誘導）
- **ネットワーク** は `AppError.Network`
- **バリデーション** は `AppError.Validation`
- **サーバーエラー** は `AppError.Server(code, message)`

---

## 3. ファイル一覧（新規）

### プロダクション
```
data/
  api/
    FunctionsClient.kt               # HTTP クライアント抽象
    ApiEnvelope.kt                   # { success, data } 共通レスポンス
    ApiPaths.kt                      # エンドポイントパス定数
  model/
    IdolMaster.kt
    GroupMaster.kt
    ExternalAppMaster.kt
    BiasSettings.kt
    User.kt
    MasterDataCache.kt               # sealed cache state
  repository/
    MasterDataRepository.kt
    MasterDataRepositoryImpl.kt
    BiasRepository.kt
    BiasRepositoryImpl.kt
    UserRepository.kt
    UserRepositoryImpl.kt
    StorageRepository.kt
    StorageRepositoryImpl.kt
core/
  common/
    IdTokenProvider.kt               # FirebaseAuth → ID token 取得の抽象（テスト容易化）
di/
  NetworkModule.kt                   # OkHttpClient / Json / FunctionsClient 提供
  RepositoryModule.kt                # Sprint 1 既存に新リポジトリ追加
```

### テスト
```
test/kotlin/.../data/api/
  FunctionsClientTest.kt             # MockWebServer でエラーマッピング確認
test/kotlin/.../data/repository/
  MasterDataRepositoryImplTest.kt    # キャッシュ / 並行リフレッシュ
  BiasRepositoryImplTest.kt          # get/set 挙動
  UserRepositoryImplTest.kt          # updateProfile 正常 + 失敗
```

### 依存追加（libs.versions.toml）
```toml
okhttp = "4.12.0"
mockwebserver = "4.12.0"

okhttp = { module = "com.squareup.okhttp3:okhttp", version.ref = "okhttp" }
okhttp-logging = { module = "com.squareup.okhttp3:logging-interceptor", version.ref = "okhttp" }
mockwebserver = { module = "com.squareup.okhttp3:mockwebserver", version.ref = "mockwebserver" }
```

---

## 4. 受入基準（Acceptance Criteria）

### ビルド
- [ ] `./gradlew :app:assembleDebug` が成功する（Sprint 1 と同様）
- [ ] `./gradlew :app:testDebugUnitTest` が全テスト green

### FunctionsClient
- [ ] ID Token を正しく Bearer ヘッダーに設定
- [ ] 未認証時は `AppError.Unauthorized` を返す
- [ ] 401/5xx HTTP エラーを `AppError.Server` に変換
- [ ] `IOException` を `AppError.Network` に変換
- [ ] JSON デコードエラーを `AppError.Validation` に変換

### MasterDataRepository
- [ ] 初回 `refreshIdols()` で HTTP 呼び出しが走る
- [ ] TTL 内の `refreshIdols()` はキャッシュを返し HTTP を叩かない
- [ ] `refreshIdols(force=true)` は TTL 関係なく再取得
- [ ] 失敗時は `MasterDataCache.Failure` に遷移し、次回 `refresh` で再試行可

### BiasRepository
- [ ] `getBias()` が `GET /getBias` を叩き `List<BiasSettings>` を返す
- [ ] `setBias(...)` が `POST /setBias` で `{ myBias: [...] }` を送る

### UserRepository
- [ ] `observeCurrentUser()` が `users/{uid}` の Firestore snapshot を Flow で出す
- [ ] ログアウト時は `null` を emit
- [ ] `updateProfile(...)` が `POST /updateUserProfile` で任意のフィールドだけ送る

### StorageRepository
- [ ] `uploadImage(bytes, "profiles/{uid}/profile.jpg")` が成功し downloadUrl を返す
- [ ] 未認証時は `AppError.Unauthorized`

### テスト
- [ ] FunctionsClient: 4 ケース以上（成功/401/5xx/network）
- [ ] MasterDataRepository: キャッシュ HIT/MISS を最低 3 ケース
- [ ] BiasRepository / UserRepository: get+set の正常系と失敗系それぞれ最低 1 ケース

---

## 5. 非目標 / 注意事項

- **UI は一切追加しない** — Sprint 3 で Home/Tasks の ViewModel から呼ぶ
- **キャッシュは Room を使わない** — まだ不要。`StateFlow<MasterDataCache<T>>` で十分
- **Retry ロジックは入れない** — iOS 版も入っていないので合わせる。Sprint 7 で必要なら再検討
- **画像リサイズは呼び出し側責務** — iOS の `ImageUploadService` はリサイズも内蔵だが、Android は `StorageRepository` をプレーンなアップローダーにして、UI 層（Sprint 6 以降）で Coil/Bitmap を使ってリサイズする

---

## 6. 工数見積

| タスク | 見積 (h) |
|--------|---------|
| FunctionsClient + ApiEnvelope + テスト | 8〜12 |
| ドメインモデル 5 種 | 3〜5 |
| MasterDataRepository + テスト | 10〜14 |
| BiasRepository + テスト | 4〜6 |
| UserRepository + テスト | 8〜12 |
| StorageRepository + テスト | 4〜6 |
| DI 配線（NetworkModule / RepositoryModule 更新） | 2〜3 |
| ドキュメント更新 | 2〜3 |
| レビュー・バッファ | 8〜10 |
| **合計** | **50〜70** |

---

## 7. Sprint 3 への橋渡し

Sprint 3 で使う前提になる抽象：
- `UserRepository.observeCurrentUser()` → ホーム画面の現在ユーザー表示
- `MasterDataRepository.refreshExternalApps()` → タスク作成画面のアプリ選択
- `MasterDataRepository.refreshIdols/groups()` → 推し設定シート（BiasSelectionSheet）
- `StorageRepository.uploadImage()` → グッズ画像 / プロフィール画像
