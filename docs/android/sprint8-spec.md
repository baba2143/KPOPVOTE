# Sprint 8 Spec — Push 通知 + 観測性（v1.0 MVP 完了）

**期間**: 2026-04-18 〜 2026-04-19 (実績 ≈13-19h) / **前提**: Sprint 1-7 完了、backend の `POST /registerFcmToken` / `POST /unregisterFcmToken` / FCM helper は既に稼働 / **iOS 参照**: `Services/PushNotificationManager.swift`, `Services/AnalyticsService.swift`, `Services/CrashlyticsManager.swift`, `functions/src/utils/fcmHelper.ts`

## 1. スコープ

### 1.1 含める（MVP v1.0 必須）
| # | 機能 | iOS 対応 | 備考 |
|---|------|---------|------|
| A | **FCM トークン登録パイプライン** | `PushNotificationManager.onUserLogin/onUserLogout` | `/registerFcmToken` と `/unregisterFcmToken` を叩く薄い Repository。`deviceId` は DataStore で UUID 永続化 |
| B | **FirebaseMessagingService** | iOS `didReceiveRemoteNotification` | 前景通知 + トークン更新。`@AndroidEntryPoint` で Hilt 注入 |
| C | **POST_NOTIFICATIONS 権限 (Android 13+)** | iOS `UNUserNotificationCenter.requestAuthorization` | `ActivityResultContracts.RequestPermission` で起動時に 1 回要求 |
| D | **ログインライフサイクル連携** | iOS `AuthStateListener → pushNotificationManager` | `AuthStateHolder` の `StateFlow` を購読して register / unregister を自動実行 |
| E | **通知タップの Deep Link** | iOS `UNUserNotificationCenterDelegate` | `type == "vote"` のみ `Route.VoteDetail(voteId)` に遷移。その他 iOS タイプは Home にフォールバック |
| F | **Analytics (基本イベントのみ)** | `AnalyticsService.logEvent` | `task_created` / `task_updated` / `vote_executed` / `collection_saved` / `screen_view` を統一 key で送信 |
| G | **Crashlytics user id** | `CrashlyticsManager.setUser` | 認証状態遷移に合わせて `setUserId(uid)` / `setUserId("")` |
| H | **Performance Tracer 基盤** | iOS 未使用（Android 先行） | `trace(name) { block }` の薄い wrapper。既定では未呼び出し（v1.1 で各 ViewModel に配線） |

### 1.2 v1.1 以降へ延期
- **FCM トピック購読**: iOS 側も未使用（確認済み）。`type` 別のサイレント通知や共通トピックが必要になった時点で追加
- **通知設定 UI / DataStore**: タイプ別 ON/OFF のトグル。今回は OS 権限 + グローバル有効のみ
- **リッチ通知（画像/アクション）**: v1.0 は `notification.title + body` のみ
- **Deep Link for community/DM**: v1.1 で `post_detail` / `dm_thread` ルートを追加後に実装
- **Performance の本格配線**: 主要画面の読み込み時間や投票確定時の SLA ターゲット決定後

## 2. アーキテクチャ

```
┌─────────────────────────────────────┐
│ AuthStateHolder.authState (StateFlow)│
└──────────────┬──────────────────────┘
        ┌──────┴───────┐
  ┌─────▼────────┐ ┌───▼───────────────┐
  │ FcmLifecycle │ │ CrashlyticsUser    │
  │ Observer     │ │ Observer           │
  └─────┬────────┘ └───┬────────────────┘
        │              │
  ┌─────▼──────┐  ┌────▼─────────┐   ┌──────────────┐
  │ FcmToken   │  │ Crashlytics  │   │ Analytics    │
  │ Repository │  │ setUserId    │   │ setUserId    │
  └─────┬──────┘  └──────────────┘   └──────────────┘
        │                                   ▲
        ▼                                   │
  functions/                                │
  registerFcmToken                    AnalyticsLogger
  unregisterFcmToken                 (ViewModels から呼ぶ)

┌────────────────────────────────────────────┐
│ KpopvoteMessagingService (onMessageReceived)│
│   └─ NotificationPresenter.show()           │
│       └─ NotificationCompat + PendingIntent │
│           └─ MainActivity.onNewIntent       │
│               └─ DeepLinkIntent.fromBundle  │
│                   └─ NavGraph.navigate      │
└────────────────────────────────────────────┘
```

## 3. 主要コンポーネント

### 3.1 FCM トークン
- `data/model/FcmToken.kt` — `RegisterFcmTokenBody(token, deviceId, platform="android")`, `UnregisterFcmTokenBody(deviceId)` と Functions のレスポンスデータ
- `data/local/DeviceIdDataStore.kt` — `preferencesDataStore("fcm_prefs")` + `fcm_device_id` キー。初回 `getOrCreate()` で UUID を永続化（iOS の `identifierForVendor` 相当）
- `data/repository/FcmTokenRepository` — `register(token)` / `unregister()` の 2 メソッドのみ。`client.postIgnoringData(path, bodyJson, emptyMap())` で Cloud Functions を叩く
- `data/api/ApiPaths.kt` に `REGISTER_FCM_TOKEN = "registerFcmToken"` / `UNREGISTER_FCM_TOKEN = "unregisterFcmToken"` を追加

### 3.2 メッセージング
- `notifications/NotificationChannelManager.kt` — SDK 26+ で `default` チャンネルを作成（`CHANNEL_ID = "default"`、`IMPORTANCE_DEFAULT`）。`functions/src/utils/fcmHelper.ts` の `android.notification.channel_id = "default"` と一致
- `notifications/NotificationPayload.kt` — backend の `data` マップから抽出する pure-JVM データクラス。`""` を `null` として扱い、`stableNotificationId()` で deterministic な Int ID を返す（pure-JVM テスト対応）
- `notifications/NotificationPresenter.kt` — `NotificationCompat.Builder` + `PendingIntent` で MainActivity を起動。`EXTRA_NOTIFICATION_TYPE` / `EXTRA_VOTE_ID` 等を Bundle にパック
- `notifications/KpopvoteMessagingService.kt` — `@AndroidEntryPoint class ... : FirebaseMessagingService()`。`onNewToken` は `authStateHolder.currentUid != null` を確認してから `@ApplicationScope appScope.launch { fcmTokenRepository.register(token) }` を実行。`onMessageReceived` は `notificationPresenter.show(message)` に委譲

### 3.3 権限 / ライフサイクル
- `core/notifications/NotificationPermissionController.kt` — `object` で `PERMISSION = Manifest.permission.POST_NOTIFICATIONS`, `isGranted(context)`, `requiresRuntimeRequest()`（SDK 33+）
- `core/auth/FcmLifecycleObserver.kt` — `@Singleton`。`authState.distinctUntilChanged { old, new -> old::class == new::class }` を購読。`Authenticated` で token を fetch して register、`Unauthenticated` で unregister。`FcmTokenFetcher` は `fun interface` で抽象化し、`DefaultFcmTokenFetcher` が `FirebaseMessaging.getInstance().token.await()` を呼ぶ（unit test 容易化）
- `core/auth/CrashlyticsUserObserver.kt` — 上と同じパターンで `crashlytics.setUserId(state.uid)` と `analyticsLogger.setUserId(state.uid)` を同時に実行
- `MainActivity` — `registerForActivityResult(ActivityResultContracts.RequestPermission())` + `requestNotificationPermissionIfNeeded()` を `onCreate` で呼ぶ
- `KpopvoteApplication` — `notificationChannelManager.ensureDefaultChannel()`, `fcmLifecycleObserver.start()`, `crashlyticsUserObserver.start()` を `onCreate` で起動

### 3.4 Deep Link
- `navigation/DeepLinkIntent.kt` — `sealed interface` + companion の `resolve(type, voteId)`。`type == "vote"` かつ `voteId.isNotEmpty()` のみ `OpenVote(voteId)`。既知 iOS 種別（follow/like/comment/mention/dm/system/sameBiasFans）は `OpenHome`、未知は `null`
- `MainActivity` — `MutableStateFlow<DeepLinkIntent?>` を持ち、`onCreate` / `onNewIntent` で `DeepLinkIntent.fromBundle(intent?.extras)` を流し込む
- `navigation/NavGraph.kt` — `initialDeepLink` を引数に取り、`LaunchedEffect(authState, initialDeepLink)` で認証後に `navigate(Route.VoteDetail(voteId))` を実行

### 3.5 観測性
- `core/analytics/Events.kt` — イベント名定数（`TASK_CREATED`, `VOTE_EXECUTED`, `COLLECTION_SAVED`, `SCREEN_VIEW`）+ パラメータキー
- `core/analytics/AnalyticsLogger.kt` — `FirebaseAnalytics` の薄い `@Singleton` wrapper。`logEvent(name, params)` / `logScreenView(screenName, screenClass)` / `setUserId(uid?)`。param の型は String/Int/Long/Double/Float/Boolean のみ Bundle 化、他は `toString()` にフォールバック、`null` は drop
- `core/performance/PerformanceTracer.kt` — `suspend fun <T> trace(name, block: suspend Trace.() -> T): T` wrapper。`try/finally` で例外時も `stop()` 保証

### 3.6 ViewModel への埋め込み
- `VoteDetailViewModel.confirmVote()` 成功時 → `Events.VOTE_EXECUTED` with `{ vote_id, vote_count }`
- `AddEditTaskViewModel.submit()` 成功時 → `Events.TASK_CREATED` / `Events.TASK_UPDATED` with `{ task_id }`
- `CollectionDetailViewModel.toggleSave()` 成功時（saved = true のみ）→ `Events.COLLECTION_SAVED` with `{ collection_id }`

## 4. DI

`di/FirebaseModule.kt` に `@Provides @Singleton` を追加:
- `FirebaseMessaging`（既存）、`FirebaseAnalytics`、`FirebasePerformance`、`FirebaseCrashlytics`
- `FcmTokenFetcher` は `DefaultFcmTokenFetcher(messaging)` を返す（デフォルト引数を使うと Hilt が解決に失敗するため `@Provides` 経由に統一）

`di/RepositoryModule.kt` に `abstract fun bindFcmTokenRepository(impl: FcmTokenRepositoryImpl): FcmTokenRepository` を追加。

## 5. Manifest 変更

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<service android:name=".notifications.KpopvoteMessagingService" android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="default" />
```

## 6. テスト

20 件の unit test を追加（`app/src/test/kotlin/`）:

- `data/repository/FcmTokenRepositoryImplTest` — `client.postIgnoringData` を直接モック。register / unregister / 失敗ラップ / deviceId 永続化 / platform="android" 確認（5件）
- `notifications/NotificationPayloadTest` — `fromDataMap` と `stableNotificationId` の pure-JVM テスト（5件）
- `core/auth/FcmLifecycleObserverTest` — `StandardTestDispatcher` + `MutableStateFlow<AuthState>` で Authenticated/Unauthenticated/Loading/token fetch 失敗（4件）
- `navigation/DeepLinkIntentTest` — `resolve(type, voteId)` の全分岐（6件）
- `core/analytics/AnalyticsLoggerTest` — `FirebaseAnalytics.logEvent` 転送、`setUserId(null)` 許容、`toBundle` 型分岐（5件）
- `core/auth/CrashlyticsUserObserverTest` — 認証遷移で両 sink に setUserId されるか（3件）
- `core/performance/PerformanceTracerTest` — 成功時と例外時で `start` / `stop` が 1 回ずつ呼ばれる（2件）

### 6.1 テスト設計上の注意
- `Bundle` を含む型は `isReturnDefaultValues = true` の制約で中身を検証できない → `AnalyticsLogger` は「FirebaseAnalytics.logEvent が正しい event 名で呼ばれる」こと + `toBundle()` がクラッシュしないことのみ確認。中身のアサーションが必要になったら Robolectric を導入する
- `FcmTokenRepositoryImpl` は内部で `client.postIgnoringData` を呼ぶため、mockk は外側の `client.post` をモックしても反映されない。直接呼ばれる extension を mock する

## 7. iOS parity 差分

| 項目 | iOS | Android | 理由 |
|------|-----|---------|------|
| トピック購読 | 未使用 | 未使用 | 確認済み |
| Device ID | `identifierForVendor` (UUID) | DataStore に UUID 永続化 | Android に同等 API なし |
| Channel ID | なし（iOS は category） | `"default"`（backend と一致） | Android 8+ 必須 |
| 権限要求 | 初回 launch 時 | 初回 launch 時（SDK 33+ のみ実行） | プラットフォーム要件 |
| Crashlytics user id sign out | `setUser("")` | `setUserId("")` | iOS と同じ空文字 |
| Analytics sign out | `setUserId(nil)` | `setUserId(null)` | SDK 差異なし |

## 8. 残課題（v1.1）

- 通知タイプ別の設定 UI（`notifications/NotificationPreferencesDataStore.kt` 追加予定）
- Community/DM/Post ルート追加後の DeepLink 拡張
- Performance Tracer の ViewModel 配線（`VoteDetailViewModel.load`, `AddEditTaskViewModel.submit`, `CollectionDetailViewModel.load`）
- E2E テスト（Firebase Test Lab）で実際の通知配送を検証
