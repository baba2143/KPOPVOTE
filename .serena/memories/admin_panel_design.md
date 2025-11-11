# K-VOTE COLLECTOR 管理画面設計仕様

## 概要

管理画面は、K-VOTE COLLECTORのバックオフィス機能を提供するWebベースの管理システムです。
モバイルアプリと同じFirebaseエコシステム上に構築され、管理者がコンテンツ管理、ユーザー管理、システム監視を実行します。

---

## Web技術スタック

### フロントエンド

| 技術 | 選定 | 理由 |
|------|------|------|
| **フレームワーク** | React / Vue.js | モジュラリティが高く、複雑な管理画面UIの構築に適している |
| **UIライブラリ** | Material UI (MUI) / Ant Design | フォーム・テーブル等の管理画面コンポーネントを迅速に実装可能 |
| **状態管理** | Redux / Pinia | 複雑なデータフローと状態管理 |
| **データ視覚化** | Chart.js / Recharts | ダッシュボードのグラフ・統計表示 |

### バックエンド接続

| 技術 | 選定 | 理由 |
|------|------|------|
| **API** | Cloud Functions API | 管理者認証を必須とし、セキュリティを担保 |
| **認証** | Firebase Admin Auth | 管理者専用の認証・権限管理 |
| **ホスティング** | Firebase Hosting | Firebaseとのネイティブ連携、簡単デプロイ |

### 開発環境

```bash
# React版の場合
npx create-react-app kvote-admin --template typescript
npm install @mui/material @emotion/react @emotion/styled
npm install firebase chart.js react-chartjs-2

# Vue.js版の場合
npm create vue@latest kvote-admin
npm install ant-design-vue firebase chart.js vue-chartjs
```

---

## 画面構成

### グローバルナビゲーション（左側固定サイドバー）

```
┌─────────────────┬────────────────────────────────┐
│                 │                                │
│  K-VOTE         │         コンテンツエリア        │
│  ADMIN          │                                │
│                 │                                │
├─────────────────┤                                │
│ 🏠 ダッシュボード│                                │
├─────────────────┤                                │
│ 📊 コンテンツ管理│                                │
│   ├ 独自投票    │                                │
│   └ コミュニティ│                                │
├─────────────────┤                                │
│ 📝 マスター管理 │                                │
│   ├ アイドル    │                                │
│   └ 外部アプリ  │                                │
├─────────────────┤                                │
│ 👥 ユーザー管理 │                                │
├─────────────────┤                                │
│ 📋 システムログ │                                │
├─────────────────┤                                │
│ ⚙️ 設定         │                                │
└─────────────────┴────────────────────────────────┘
```

---

## 主要画面の詳細設計

### A. ダッシュボード（Home）

**目的**: サービスの健全性を一目で把握

#### 表示項目

1. **ユーザー統計**
   - 新規登録ユーザー数（日次/週次/月次）
   - アクティブユーザー数（DAU/WAU/MAU）
   - ユーザー増加グラフ

2. **タスク統計**
   - タスク登録総数
   - 完了タスク数
   - 投票サイト別タスク分布（円グラフ）

3. **投票統計**
   - アクティブな独自投票数
   - 総投票数（リアルタイム）
   - 人気投票ランキング

4. **システムヘルス**
   - エラーログサマリー（直近24時間）
   - API応答時間（平均）
   - OGP取得成功率

#### UI実装ポイント

```tsx
// React + MUI の例
import { Grid, Card, CardContent, Typography } from '@mui/material';
import { Line, Pie } from 'react-chartjs-2';

function Dashboard() {
  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={6} lg={3}>
        <Card>
          <CardContent>
            <Typography variant="h6">新規ユーザー</Typography>
            <Typography variant="h3">1,234</Typography>
            <Typography color="success">↑ 12% vs 先週</Typography>
          </CardContent>
        </Card>
      </Grid>
      
      <Grid item xs={12} md={8}>
        <Card>
          <CardContent>
            <Typography variant="h6">ユーザー増加トレンド</Typography>
            <Line data={userGrowthData} />
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
}
```

---

### B. 独自投票管理

**目的**: アプリ内独自投票の作成・管理・結果確認

#### 機能一覧

1. **投票一覧表示**
   - ステータス別フィルター（進行中/終了）
   - 作成日時、終了日時、投票数表示
   - リアルタイム更新

2. **新規投票作成**
   - 投票タイトル入力
   - 候補者選択（マスターデータから）
   - 投票期間設定
   - 投票コスト設定（ポイント）

3. **投票詳細・編集**
   - リアルタイムランキング表示
   - 候補者別投票数グラフ
   - 投票終了/削除機能

#### UI実装ポイント

```tsx
// 新規投票作成フォーム
import { Button, TextField, DatePicker, Autocomplete } from '@mui/material';

function CreateVoteForm() {
  return (
    <form>
      <TextField 
        label="投票タイトル" 
        placeholder="例: 今週のベストパフォーマンス"
        fullWidth 
      />
      
      <Autocomplete
        multiple
        options={idolMasterData}
        getOptionLabel={(option) => option.name}
        renderInput={(params) => (
          <TextField {...params} label="候補者選択" />
        )}
      />
      
      <DatePicker label="投票開始日時" />
      <DatePicker label="投票終了日時" />
      
      <TextField 
        type="number" 
        label="投票コスト（ポイント）" 
        defaultValue={10}
      />
      
      <Button variant="contained" color="primary">
        投票を作成
      </Button>
    </form>
  );
}
```

#### データテーブル（投票一覧）

```tsx
import { DataGrid } from '@mui/x-data-grid';

const columns = [
  { field: 'id', headerName: 'ID', width: 100 },
  { field: 'title', headerName: '投票タイトル', width: 300 },
  { field: 'status', headerName: 'ステータス', width: 120 },
  { field: 'endDate', headerName: '終了日時', width: 180 },
  { field: 'totalVotes', headerName: '総投票数', width: 120 },
  { 
    field: 'actions', 
    headerName: '操作', 
    width: 200,
    renderCell: (params) => (
      <>
        <Button onClick={() => viewDetails(params.row.id)}>詳細</Button>
        <Button onClick={() => editVote(params.row.id)}>編集</Button>
        <Button onClick={() => deleteVote(params.row.id)} color="error">削除</Button>
      </>
    )
  },
];

<DataGrid rows={votes} columns={columns} pageSize={25} />
```

---

### C. マスターデータ管理

**目的**: アイドル/メンバー情報、外部アプリマスターの管理

#### C-1. アイドルマスター管理

**データ構造**:
```typescript
interface IdolMaster {
  id: string;
  name: string;           // メンバー名（例: "Jimin", "Hyunjin"）
  groupName: string;      // グループ名（例: "BTS", "Stray Kids"）
  profileImageUrl: string;
  debutDate: Date;
  isActive: boolean;      // アクティブ状態
  createdAt: Date;
}
```

**機能**:
- アイドル/メンバー一覧表示
- 新規登録フォーム
- 編集・削除
- グループ別フィルター
- 名前検索

#### C-2. 外部アプリマスター管理

**データ構造**:
```typescript
interface ExternalAppMaster {
  id: string;
  appName: string;        // 例: "IDOL CHAMP", "Mnet Plus"
  appUrl: string;
  iconUrl: string;
  isActive: boolean;
  createdAt: Date;
}
```

**機能**:
- 外部アプリ一覧表示
- 新規登録フォーム
- 編集・削除
- OGP取得テスト機能

#### UI実装ポイント

```tsx
// マスターデータ管理テーブル
import { DataGrid, GridToolbar } from '@mui/x-data-grid';

function MasterDataTable() {
  return (
    <>
      <Button 
        variant="contained" 
        startIcon={<AddIcon />}
        onClick={openCreateDialog}
      >
        新規追加
      </Button>
      
      <DataGrid
        rows={masterData}
        columns={columns}
        components={{ Toolbar: GridToolbar }}
        filterModel={filterModel}
        onFilterModelChange={setFilterModel}
      />
    </>
  );
}
```

---

### D. コミュニティ監視

**目的**: 不適切投稿の検出・削除、コミュニティの健全性維持

#### 機能一覧

1. **報告された投稿の優先表示**
   - 不適切報告があった投稿を最上部に強調表示
   - 報告理由の表示（スパム/暴言/不適切コンテンツ）
   - 報告回数の表示

2. **投稿の確認・削除**
   - 投稿内容のプレビュー
   - 画像の確認
   - ユーザー情報の確認
   - 削除ボタン（警告付き）

3. **統計情報**
   - 日次投稿数
   - 報告数推移
   - 削除数推移

#### UI実装ポイント

```tsx
// 報告された投稿リスト
function ReportedPostsList() {
  return (
    <>
      <Alert severity="warning">
        {reportedPosts.length}件の報告された投稿があります
      </Alert>
      
      {reportedPosts.map(post => (
        <Card key={post.id} sx={{ bgcolor: '#fff3cd', mb: 2 }}>
          <CardContent>
            <Typography variant="h6">
              ⚠️ {post.reportCount}件の報告
            </Typography>
            <Typography>投稿者: {post.authorName}</Typography>
            <Typography>内容: {post.content}</Typography>
            <Chip label={post.reportReason} color="error" />
            
            <ButtonGroup>
              <Button onClick={() => viewDetails(post.id)}>詳細</Button>
              <Button 
                color="error" 
                onClick={() => deletePost(post.id)}
              >
                削除
              </Button>
              <Button onClick={() => dismissReport(post.id)}>
                報告を却下
              </Button>
            </ButtonGroup>
          </CardContent>
        </Card>
      ))}
    </>
  );
}
```

---

### E. ユーザー管理

**目的**: ユーザー情報の検索・閲覧、問題ユーザーの対応

#### 機能一覧

1. **ユーザー検索**
   - ユーザーID検索
   - ユーザー名検索
   - メールアドレス検索
   - 登録日フィルター

2. **ユーザー詳細表示**
   - 基本情報（ID、名前、メール、登録日）
   - 推し設定（myBias）
   - ポイント残高
   - タスク登録状況
   - 投票履歴
   - コミュニティ投稿履歴

3. **ユーザー操作**
   - ポイント付与/減算
   - アカウント停止/復活
   - データエクスポート

#### UI実装ポイント

```tsx
// ユーザー検索バー
import { TextField, InputAdornment } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';

function UserSearch() {
  return (
    <TextField
      fullWidth
      placeholder="ユーザーID、名前、メールで検索"
      InputProps={{
        startAdornment: (
          <InputAdornment position="start">
            <SearchIcon />
          </InputAdornment>
        ),
      }}
      onChange={handleSearch}
    />
  );
}

// ユーザー詳細モーダル
function UserDetailModal({ userId }) {
  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>ユーザー詳細: {user.username}</DialogTitle>
      <DialogContent>
        <Grid container spacing={2}>
          <Grid item xs={6}>
            <Typography variant="subtitle2">ユーザーID</Typography>
            <Typography>{user.id}</Typography>
          </Grid>
          <Grid item xs={6}>
            <Typography variant="subtitle2">登録日</Typography>
            <Typography>{user.registeredAt}</Typography>
          </Grid>
          
          <Grid item xs={12}>
            <Typography variant="subtitle2">推しメンバー</Typography>
            <Stack direction="row" spacing={1}>
              {user.myBias.map(bias => (
                <Chip key={bias} label={bias} />
              ))}
            </Stack>
          </Grid>
          
          <Grid item xs={6}>
            <Typography variant="subtitle2">ポイント残高</Typography>
            <Typography variant="h5">{user.points} pt</Typography>
          </Grid>
          
          <Grid item xs={12}>
            <Typography variant="subtitle2">タスク登録状況</Typography>
            <DataGrid rows={user.tasks} columns={taskColumns} />
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleAddPoints}>ポイント付与</Button>
        <Button color="error" onClick={handleSuspend}>アカウント停止</Button>
      </DialogActions>
    </Dialog>
  );
}
```

---

### F. システムログ

**目的**: エラー監視、API監視、システムヘルスチェック

#### 機能一覧

1. **エラーログ一覧**
   - エラーレベル別フィルター（Critical/Error/Warning）
   - 日時範囲フィルター
   - エラーメッセージ検索

2. **API監視**
   - エンドポイント別成功率
   - 平均応答時間
   - エラー率推移グラフ

3. **OGP取得監視**
   - 外部サイト別成功率
   - タイムアウト発生頻度
   - エラーログ詳細

#### UI実装ポイント

```tsx
// エラーログテーブル
function ErrorLogTable() {
  const columns = [
    { field: 'timestamp', headerName: '日時', width: 180 },
    { 
      field: 'level', 
      headerName: 'レベル', 
      width: 120,
      renderCell: (params) => (
        <Chip 
          label={params.value} 
          color={getLevelColor(params.value)}
          size="small"
        />
      )
    },
    { field: 'message', headerName: 'メッセージ', width: 400 },
    { field: 'endpoint', headerName: 'エンドポイント', width: 200 },
    { 
      field: 'details', 
      headerName: '詳細', 
      width: 100,
      renderCell: (params) => (
        <Button onClick={() => viewDetails(params.row)}>詳細</Button>
      )
    },
  ];
  
  return (
    <DataGrid 
      rows={errorLogs} 
      columns={columns} 
      pageSize={50}
    />
  );
}
```

---

## 認証・セキュリティ

### 管理者認証

```typescript
// Firebase Admin SDK での管理者認証
import { getAuth } from 'firebase-admin/auth';

// 管理者専用カスタムクレーム
await getAuth().setCustomUserClaims(adminUid, { admin: true });

// Cloud Functionsでの権限チェック
export const adminOnlyAPI = functions.https.onCall(async (data, context) => {
  // 管理者チェック
  if (!context.auth?.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      '管理者権限が必要です'
    );
  }
  
  // 管理者操作を実行
  return performAdminOperation(data);
});
```

### セキュリティルール

```javascript
// firestore.rules - 管理画面用
match /adminLogs/{logId} {
  // 管理者のみアクセス可能
  allow read, write: if request.auth.token.admin == true;
}

match /users/{userId} {
  // 管理者は全ユーザーデータ閲覧可能
  allow read: if request.auth.token.admin == true;
  allow write: if request.auth.uid == userId; // ユーザー自身のみ書き込み可
}
```

---

## デプロイ構成

### Firebase Hosting 設定

```json
// firebase.json
{
  "hosting": [
    {
      "target": "app",
      "public": "app/build",
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    },
    {
      "target": "admin",
      "public": "admin/build",
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  ]
}
```

### デプロイコマンド

```bash
# 管理画面ビルド
cd admin
npm run build

# Firebase Hosting デプロイ
firebase deploy --only hosting:admin

# カスタムドメイン設定（オプション）
# admin.kvote-collector.com
```

---

## 開発ロードマップ

### Phase 0+（管理画面追加）

| タスク | 期間 | 優先度 |
|-------|------|--------|
| React/Vue プロジェクト初期化 | 2日 | P1 |
| Firebase Admin SDK 統合 | 1日 | P1 |
| ダッシュボード実装 | 3日 | P1 |
| 独自投票管理実装 | 5日 | P1 |
| マスターデータ管理実装 | 4日 | P2 |
| コミュニティ監視実装 | 3日 | P2 |
| ユーザー管理実装 | 4日 | P2 |
| システムログ実装 | 2日 | P3 |

**合計**: 約3週間（管理画面MVP）

---

## API エンドポイント（管理者専用）

### 独自投票管理API

```typescript
// POST /admin/vote/create - 独自投票作成
{
  title: string;
  candidates: string[];  // メンバーIDリスト
  endDate: timestamp;
  pointCost: number;
}

// PATCH /admin/vote/update - 投票更新
// DELETE /admin/vote/delete - 投票削除
// GET /admin/vote/statistics - 投票統計取得
```

### マスター管理API

```typescript
// POST /admin/master/idol/create - アイドル登録
// PATCH /admin/master/idol/update - アイドル更新
// DELETE /admin/master/idol/delete - アイドル削除

// POST /admin/master/app/create - 外部アプリ登録
// PATCH /admin/master/app/update - 外部アプリ更新
// DELETE /admin/master/app/delete - 外部アプリ削除
```

### コミュニティ監視API

```typescript
// GET /admin/community/reported - 報告された投稿取得
// DELETE /admin/community/delete - 投稿削除
// POST /admin/community/dismissReport - 報告却下
```

### ユーザー管理API

```typescript
// GET /admin/user/search - ユーザー検索
// GET /admin/user/details - ユーザー詳細取得
// PATCH /admin/user/addPoints - ポイント付与
// PATCH /admin/user/suspend - アカウント停止
```

---

## まとめ

管理画面は、K-VOTE COLLECTORの運用を支える重要なバックオフィスシステムです。

**重要ポイント**:
- 📊 **データ視覚化**: ダッシュボードでサービスヘルス確認
- 🔒 **セキュリティ**: 管理者専用認証・権限管理
- ⚡ **効率性**: 直感的なUI、強力な検索・フィルタリング機能
- 🚀 **拡張性**: Firebase Hostingでスケーラブルなデプロイ
