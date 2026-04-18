# Sprint 7 Spec — Profile (v1.0 MVP 最終ピース)

**期間**: 2026-04-19 〜 (推定 8-12h) / **前提**: Sprint 1-4 完了, `UserRepository.updateProfile` は Sprint 2 時点で実装済み / **iOS 参照**: `Views/Profile/*`, `ViewModels/UserProfileViewModel.swift`, `ProfileEditViewModel.swift`, `Services/ProfileService.swift`, `Services/PointsService.swift`(invite), `Services/ImageUploadService.swift`(profile photo)

## 1. スコープ

### 1.1 含める(MVP v1.0 必須)
| # | 画面 / 機能 | iOS 対応 | 備考 |
|---|-----------|---------|------|
| P1 | **ProfileScreen**(Profile タブ実体化) | `MainTabView.ProfileView:660` | 表示名/メール/写真/ポイント/推し設定へのリンク/サインアウト/招待コード表示 |
| P2 | **ProfileEditScreen** | `ProfileEditView.swift` | 表示名(1-30)、自己紹介(0-150)、プロフィール写真 |
| P3 | **BiasSettingsScreen**(推し選択) | `Views/Bias/BiasSettingsView.swift` | マスターデータから groups/idols を選択、`updateProfile(biasIds=…)` で保存 |
| P4 | **InviteCodeScreen**(自分のコード表示 + 他人のコード入力) | `PointsService.generateInviteCode` / `applyInviteCode` | `generateInviteCode` は GET でも POST でも受付、`applyInviteCode` は一度だけ成功 |
| P5 | **About / 規約リンク**(アプリバージョン + 外部 Web リンク) | `AboutView.swift`, `PrivacyPolicyView.swift`, `TermsOfServiceView.swift` | Intent.ACTION_VIEW でブラウザ起動、画面は作らない |

### 1.2 v1.1 以降へ延期
- Follow/Follower 一覧(Sprint 5 Community 依存)
- ブロックユーザー管理(Community 依存)
- 通知設定(Sprint 8 Push 依存)
- リンクアカウント / アカウント削除(deleteAccount API はあるが MVP は非必須)
- ライセンス画面(OSS ライセンス、自動生成ツール導入を v1.1 で検討)

## 2. データモデル

新規モデルは最小限。既存 `User` モデル(Sprint 2)で足りる。

### 2.1 招待コード(`data/model/InviteCode.kt` — 新規)
```kotlin
@Serializable
data class GenerateInviteCodeData(
    val inviteCode: String,
    val inviteLink: String,
)

@Serializable
data class ApplyInviteCodeData(
    val success: Boolean,
    val inviterDisplayName: String? = null,
)
```

### 2.2 AppError 追加
```kotlin
sealed class Invite : AppError() {
    object AlreadyApplied : Invite() { override val message = "招待コードは既に適用されています" }
    object SelfInvite : Invite() { override val message = "自分の招待コードは使えません" }
    data class NotFound(override val message: String) : Invite()
}
```
`InviteErrorMapper` で 400 → Invite.* にマップ(`VoteErrorMapper` と同じパターン)。

## 3. データ層追加

### 3.1 `InviteRepository` / `InviteRepositoryImpl` (新規)
```kotlin
interface InviteRepository {
    suspend fun generateInviteCode(): Result<GenerateInviteCodeData>
    suspend fun applyInviteCode(code: String): Result<ApplyInviteCodeData>
}
```
実装は `FunctionsClient` 経由。エンドポイント:
- `POST /generateInviteCode` (body なし)
- `POST /applyInviteCode` (`{"inviteCode": "ABC123"}`)

### 3.2 `ProfileImageRepository` (新規)
`CollectionCoverImageRepository` と同じパターン:
```kotlin
interface ProfileImageRepository {
    suspend fun upload(bytes: ByteArray): Result<String> // returns download URL
}
```
Storage path: `profiles/{uid}/profile.jpg`(固定ファイル名で上書き、iOS と同じ)。圧縮は既存 `ImageCompress.compressUri` を流用、プロフィール用は 400x400 square にリサイズ。

### 3.3 `ApiPaths` 拡張
```kotlin
const val GENERATE_INVITE_CODE = "/generateInviteCode"
const val APPLY_INVITE_CODE = "/applyInviteCode"
// UPDATE_USER_PROFILE は Sprint 2 時点で追加済みのはず - 要確認
```

## 4. Navigation 追加

```kotlin
@Serializable data object ProfileEdit : Route
@Serializable data object BiasSettings : Route
@Serializable data object InviteCode : Route
```

`MainTabScreen` の `ProfilePlaceholderTab` を `ProfileScreen` に置き換え、上記 3 画面は `rootNavController.navigate` で到達。

## 5. Phase 分割

### Phase 1 — Data 層 (3-4h)
1.1 `InviteCode.kt` モデル + `AppError.Invite.*`
1.2 `InviteErrorMapper` + テスト(4 branches)
1.3 `InviteRepository` / `InviteRepositoryImpl` + テスト(4)
1.4 `ProfileImageRepository` + テスト(2)
1.5 Hilt `RepositoryModule` bind 追加

### Phase 2 — ProfileScreen + ProfileEdit (3-4h)
2.1 `ProfileViewModel` — User / inviteCode / loading / error を束ねる `refresh()`
2.2 `ProfileScreen` UI (avatar, displayName, email, points, rows: 推し設定 / 招待コード / プロフィール編集 / 利用規約 / プライバシー / ログアウト)
2.3 `ProfileEditViewModel` (title/bio/photo、validation、submit)
2.4 `ProfileEditScreen` UI(PickVisualMedia で写真、TextField ×2、保存ボタン)
2.5 NavGraph 配線

### Phase 3 — BiasSettings + InviteCode (2-3h)
3.1 `BiasSettingsViewModel` — マスターデータ取得 + 現在の bias ロード + toggle + save
3.2 `BiasSettingsScreen` UI(FilterChip でグループ選択、その下に idols を expand)
3.3 `InviteCodeViewModel` — generateInviteCode 取得 + applyInviteCode submit
3.4 `InviteCodeScreen` UI(自分のコードをコピー可能テキスト、他人のコード入力欄)
3.5 About 行は `rememberLauncher` で外部ブラウザへ
3.6 Intent で他アプリに共有可能な `inviteLink`(Sprint 4 の `shareToCommunity` と同パターン)

### Phase 4 — Tests + Polish (2-3h)
4.1 `ProfileViewModelTest` (4-5)
4.2 `ProfileEditViewModelTest` (5-6) — validation、photo upload、submit
4.3 `BiasSettingsViewModelTest` (3-4)
4.4 `InviteCodeViewModelTest` (3-4) — generate キャッシュ、apply 成功/失敗
4.5 コンパイル + `testDebugUnitTest` 全 green
4.6 README Sprint 7 セクション更新

**想定テスト追加**: ~20 本 → 累計 ~153 本

## 6. リスク

| ID | リスク | 重大度 | 対策 |
|----|-------|:-:|-----|
| R1 | `updateUserProfile` レスポンスの `User` モデル shape が Android 側と不一致(`selectedIdols` vs `biasIds`、`createdAt` が number かも) | High | 既存 `User.kt`(Sprint 2)と突き合わせて必要なら `@SerialName` 追加、統合テストで確定 |
| R2 | プロフィール写真 2MB 上限 — 未圧縮大画像で `AppError.Storage.FileTooLarge` が出る | Medium | `ImageCompress` で事前圧縮、送信前に `bytes.size > 2_000_000` を validation エラーに |
| R3 | `applyInviteCode` が失敗理由を文字列で返す(自分のコード / 存在しない / 既適用) | Medium | `InviteErrorMapper` で iOS の文言パターンを模倣、ユーザー向けは `AppError.Invite.*` に正規化 |
| R4 | Bias 更新後 `HomeViewModel` のキャッシュが古いまま表示 | Low | `updateProfile` 成功時に `BiasRepository.getBias()` を再フェッチするか、HOME 側の pull-to-refresh で対応(v1.0 は後者) |
| R5 | プロフィール写真の Firebase Storage rules が `profiles/{uid}/…` を許可していない場合 403 | Medium | iOS が動いている前提で rules は既に OK と仮定、初回実機テストで確認 |

## 7. 新規 / 変更ファイル一覧(想定 ~20 ファイル)

**データ層**
- `data/model/InviteCode.kt`
- `data/repository/InviteRepository.kt`, `InviteRepositoryImpl.kt`
- `data/repository/InviteErrorMapper.kt`
- `data/repository/ProfileImageRepository.kt`
- `core/common/AppError.kt`(Invite 追加)
- `data/api/ApiPaths.kt`(invite パス追加)
- `di/RepositoryModule.kt`(bind 追加)

**UI 層**
- `ui/profile/ProfileScreen.kt`, `ProfileViewModel.kt`
- `ui/profile/edit/ProfileEditScreen.kt`, `ProfileEditViewModel.kt`
- `ui/profile/bias/BiasSettingsScreen.kt`, `BiasSettingsViewModel.kt`
- `ui/profile/invite/InviteCodeScreen.kt`, `InviteCodeViewModel.kt`
- `ui/main/MainTabScreen.kt`(Profile tab を実体化)
- `navigation/Routes.kt`, `NavGraph.kt`

**テスト**
- `test/.../InviteErrorMapperTest.kt`
- `test/.../InviteRepositoryImplTest.kt`
- `test/.../ProfileImageRepositoryTest.kt`
- `test/.../ProfileViewModelTest.kt`
- `test/.../ProfileEditViewModelTest.kt`
- `test/.../BiasSettingsViewModelTest.kt`
- `test/.../InviteCodeViewModelTest.kt`

## 8. Exit 条件
- **150+ ユニットテスト**全 green
- `assembleDebug` 成功
- `MainTabScreen` Profile タブから 4 画面に遷移でき、各画面が実デバイスで動作
- iOS の機能パリティ: 表示名/Bio/写真/推し/招待コード を編集・表示できる
