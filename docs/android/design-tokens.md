# デザイントークン（Material 3 適応）

iOS 版 `Constants.swift` から抽出したカラーパレットを Material 3 の `ColorScheme` にマッピングする。

## カラーパレット

### iOS から抽出（Constants.swift）

| 用途 | iOS 定数 | Hex |
|------|---------|-----|
| Primary Blue | `primaryBlue` | `#1976D2` |
| Primary Pink | `primaryPink` | `#E91E63` |
| Background Dark | `backgroundDark` | `#0A1628` |
| Card Dark | `cardDark` | `#1A2744` |
| Accent Pink | `accentPink` | `#FF1F8F` |
| Accent Blue | `accentBlue` | `#00D4FF` |
| Background Light | `background` | `#F5F5F5` |
| Text Gray | `textGray` | `#9CA3AF` |
| Gradient Pink | `gradientPink` | `#FF1F8F` |
| Gradient Blue | `gradientBlue` | `#00D4FF` |
| Gradient Purple | `gradientPurple` | `#7C3AED` |
| Status Urgent | `statusUrgent` | `#EF4444` |

### Material 3 マッピング（ダークモード基準）

KPOPVOTE は **ダークモードをデフォルト**とする（iOS 版の主要配色が暗い背景 + ネオンアクセント）。

| M3 Role | Dark | Light |
|---------|------|-------|
| `primary` | `#FF1F8F`（Accent Pink） | `#E91E63` |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` |
| `primaryContainer` | `#7C3AED`（Gradient Purple） | `#FCE4EC` |
| `onPrimaryContainer` | `#FFFFFF` | `#1A1A1A` |
| `secondary` | `#00D4FF`（Accent Blue） | `#1976D2` |
| `onSecondary` | `#0A1628` | `#FFFFFF` |
| `tertiary` | `#7C3AED`（Gradient Purple） | `#7C3AED` |
| `background` | `#0A1628`（Background Dark） | `#F5F5F5` |
| `onBackground` | `#FFFFFF` | `#000000` |
| `surface` | `#1A2744`（Card Dark） | `#FFFFFF` |
| `onSurface` | `#FFFFFF` | `#1A1A1A` |
| `surfaceVariant` | `#243555` | `#E0E0E0` |
| `onSurfaceVariant` | `#9CA3AF`（Text Gray） | `#616161` |
| `error` | `#EF4444`（Status Urgent） | `#EF4444` |
| `onError` | `#FFFFFF` | `#FFFFFF` |
| `outline` | `#374151` | `#BDBDBD` |

### カスタムカラー（Material 3 の枠外）

ブランド固有のグラデーションは `CustomColors` data class でテーマに追加：

```kotlin
@Immutable
data class KpopvoteCustomColors(
    val gradientStart: Color,     // #FF1F8F
    val gradientMiddle: Color,    // #7C3AED
    val gradientEnd: Color,       // #00D4FF
    val statusPending: Color,     // #2196F3
    val statusCompleted: Color,   // #4CAF50
    val statusExpired: Color,     // #F44336
)
```

## タイポグラフィ

iOS 版 `Typography`（Constants.swift）:

| iOS | サイズ | Material 3 ロール |
|-----|-------|------------------|
| `titleSize` | 24pt | `headlineSmall` |
| `headlineSize` | 18pt | `titleLarge` |
| `bodySize` | 16pt | `bodyLarge` |
| `captionSize` | 14pt | `bodyMedium` |

Android は Roboto 標準。将来的に Noto Sans JP への差し替えを検討（v1.1+）。

## スペーシング

iOS 版 `Spacing`:

| iOS | サイズ | Compose |
|-----|-------|---------|
| `small` | 8dp | `Spacing.small = 8.dp` |
| `medium` | 16dp | `Spacing.medium = 16.dp` |
| `large` | 24dp | `Spacing.large = 24.dp` |
| `extraLarge` | 32dp | `Spacing.xl = 32.dp` |

## 形状（Shapes）

Material 3 `Shapes` のデフォルトから:

| ロール | 角丸 |
|-------|-----|
| `extraSmall` | 4dp |
| `small` | 8dp |
| `medium` | 12dp |
| `large` | 16dp |
| `extraLarge` | 20dp |

カードやボタンは `medium`（12dp）を基本とする（iOS SwiftUI のデフォルト角丸と揃える）。

## Dynamic Color

Android 12+ の Dynamic Color（壁紙連動）は **無効化** する。ブランドカラー（ピンク/ブルー）を固定。
