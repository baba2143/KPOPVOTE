# Android 版アーキテクチャ設計

## 設計方針

**MVVM + Clean Architecture 軽量版** を採用する。

- iOS 版の Service 層 (33クラス) → Android の Repository 層に 1:1 マッピング
- ViewModel は UI 状態を `StateFlow` で公開、Compose が購読
- UseCase は**複雑な業務ロジックがある場合のみ**導入（不要な層を作らない）

## レイヤー構造

```
┌─────────────────────────────────────────┐
│  UI Layer (Jetpack Compose)             │
│  - Screens / Components / Theme         │
└─────────────────────────────────────────┘
              ▲              │
              │ StateFlow    │ Events
              │              ▼
┌─────────────────────────────────────────┐
│  Presentation Layer (ViewModel)         │
│  - StateFlow<UiState>                   │
│  - Event handling                       │
└─────────────────────────────────────────┘
              ▲              │
              │ Flow<Result> │ suspend fn
              │              ▼
┌─────────────────────────────────────────┐
│  Domain Layer (optional)                │
│  - UseCase (業務ロジックがある場合のみ) │
│  - Domain Model                         │
└─────────────────────────────────────────┘
              ▲              │
              │ Result<T>    │ suspend fn
              │              ▼
┌─────────────────────────────────────────┐
│  Data Layer (Repository)                │
│  - Repository (iOS Service と 1:1)      │
│  - DataSource (Firebase Functions SDK)  │
│  - DTO ↔ Domain Model 変換              │
└─────────────────────────────────────────┘
              ▲              │
              │              ▼
┌─────────────────────────────────────────┐
│  External (Firebase / Play Services)    │
└─────────────────────────────────────────┘
```

## パッケージ構造

```
com.kpopvote.collector/
├── KpopvoteApplication.kt
├── MainActivity.kt
├── di/
│   ├── AppModule.kt             # Application-wide bindings
│   ├── FirebaseModule.kt        # Firebase SDK provides
│   ├── NetworkModule.kt         # HTTP / Functions client
│   └── RepositoryModule.kt      # Repository bindings
├── core/
│   ├── auth/                    # AuthState / Token 管理
│   ├── network/                 # FunctionsClient / Result型
│   ├── storage/                 # Firebase Storage ラッパー
│   ├── datastore/               # Preferences 永続化
│   ├── analytics/               # Analytics / Crashlytics ラッパー
│   └── common/                  # 拡張関数 / 日付 / 画像ユーティリティ
├── domain/
│   ├── model/                   # User / Task / Vote / ...
│   └── usecase/                 # (必要時のみ)
├── data/
│   ├── repository/              # Repository 実装
│   ├── datasource/              # Firebase 直接呼び出し
│   └── dto/                     # Callable レスポンス型
├── ui/
│   ├── theme/
│   │   ├── Color.kt
│   │   ├── Theme.kt
│   │   ├── Type.kt
│   │   └── Shape.kt
│   ├── components/              # 共通 Composable
│   ├── auth/
│   │   ├── login/
│   │   │   ├── LoginScreen.kt
│   │   │   ├── LoginViewModel.kt
│   │   │   └── LoginUiState.kt
│   │   └── register/
│   ├── home/
│   ├── tasks/
│   ├── votes/
│   ├── profile/
│   └── ...
├── navigation/
│   ├── NavGraph.kt
│   ├── Routes.kt
│   └── Destinations.kt
└── notifications/
    └── KpopvoteMessagingService.kt
```

## 状態管理パターン

### ViewModel で StateFlow を公開

```kotlin
data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val isSuccess: Boolean = false,
)

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()

    fun onEmailChange(email: String) { ... }
    fun onPasswordChange(password: String) { ... }
    fun onLoginClick() { ... }
}
```

### Compose で collectAsStateWithLifecycle

```kotlin
@Composable
fun LoginScreen(viewModel: LoginViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    // ...
}
```

## Repository パターン

```kotlin
interface AuthRepository {
    val authState: StateFlow<AuthState>
    suspend fun signInWithEmail(email: String, password: String): Result<Unit>
    suspend fun signUpWithEmail(email: String, password: String): Result<Unit>
    suspend fun signInWithGoogle(idToken: String): Result<Unit>
    suspend fun signOut()
    suspend fun getIdToken(forceRefresh: Boolean = false): String?
}
```

## エラーハンドリング

共通 `Result<T>` 型を `kotlin.Result` で統一。失敗時は `AppError` sealed class でラップ：

```kotlin
sealed class AppError : Throwable() {
    object NetworkError : AppError()
    object Unauthorized : AppError()
    data class Server(val code: Int, override val message: String) : AppError()
    data class Validation(override val message: String) : AppError()
    data class Unknown(override val cause: Throwable) : AppError()
}
```

## テスト戦略

- **ViewModel**: `MainDispatcherRule` + `turbine` で StateFlow テスト
- **Repository**: モック可能なインターフェース + Fake 実装
- **UI**: Compose UI Test (`createComposeRule()`)
- **E2E**: v1.0 リリース前に主要フロー 20+ ケースを自動化

## iOS との対応

| 概念 | iOS (Swift) | Android (Kotlin) |
|------|------------|------------------|
| 非同期 | `async/await` | `suspend fun` + Coroutines |
| 状態 | `@Published` / `@StateObject` | `StateFlow` / `MutableStateFlow` |
| 宣言的UI | SwiftUI `View` | Compose `@Composable` |
| DI | プロパティ手動 | Hilt |
| ナビゲーション | `NavigationStack` | `NavHost` / Navigation Compose |
| 設定永続化 | `UserDefaults` | DataStore Preferences |

詳細な Service→Repository マッピングは [`ios-android-parity.md`](./ios-android-parity.md) 参照。
