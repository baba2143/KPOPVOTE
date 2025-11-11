# K-VOTE COLLECTOR プロジェクト構造

## 現在のディレクトリ構造

```
KPOPVOTE/
├── .serena/                      # Serenaプロジェクト設定
│   ├── memories/                 # プロジェクトメモリ
│   ├── project.yml               # Serena設定ファイル
│   └── .gitignore               
│
├── アプリUIイメージ.png           # UIデザイン画像
├── KPOP VOTE.md                  # プロジェクト仕様書
├── DBスキーマ設計案.txt          # Firestoreスキーマ設計
├── 初期バックエンド開発指示書.txt # Phase 0開発計画
├── タスク管理計画.md              # タスク詳細計画
└── sc-task-commands.sh           # タスク一括作成スクリプト
```

## 予定されるプロジェクト構造（実装後）

### Phase 0完了後の構造

```
KPOPVOTE/
├── .serena/
├── functions/                    # Cloud Functions (Node.js)
│   ├── src/
│   │   ├── auth/                # 認証関連
│   │   │   ├── register.ts
│   │   │   └── login.ts
│   │   ├── user/                # ユーザー設定
│   │   │   ├── setBias.ts
│   │   │   └── getBias.ts
│   │   ├── task/                # タスク管理
│   │   │   ├── register.ts
│   │   │   ├── getUserTasks.ts
│   │   │   ├── updateStatus.ts
│   │   │   └── fetchOGP.ts
│   │   ├── utils/               # ユーティリティ
│   │   │   ├── ogpParser.ts
│   │   │   └── validators.ts
│   │   └── index.ts             # エントリーポイント
│   ├── package.json
│   └── tsconfig.json
│
├── firestore.rules               # Firestoreセキュリティルール
├── firestore.indexes.json        # Firestoreインデックス定義
├── firebase.json                 # Firebase設定
├── .firebaserc                  # Firebaseプロジェクト設定
│
├── docs/                        # ドキュメント
│   ├── KPOP VOTE.md
│   ├── DBスキーマ設計案.txt
│   ├── 初期バックエンド開発指示書.txt
│   ├── タスク管理計画.md
│   └── アプリUIイメージ.png
│
└── README.md                    # プロジェクトREADME
```

### Phase 1完了後の構造（iOS追加）

```
KPOPVOTE/
├── functions/                    # バックエンド（上記と同じ）
├── firestore.rules
├── firestore.indexes.json
│
├── ios/                         # iOSアプリ
│   ├── KVoteCollector/
│   │   ├── App/
│   │   │   └── KVoteCollectorApp.swift
│   │   ├── Models/              # データモデル
│   │   │   ├── User.swift
│   │   │   ├── Task.swift
│   │   │   ├── CommunityPost.swift
│   │   │   └── Vote.swift
│   │   ├── Views/               # SwiftUI画面
│   │   │   ├── Home/
│   │   │   │   ├── HomeView.swift
│   │   │   │   └── DashboardCard.swift
│   │   │   ├── Tasks/
│   │   │   │   ├── TaskListView.swift
│   │   │   │   ├── TaskDetailView.swift
│   │   │   │   └── TaskRegistrationView.swift
│   │   │   ├── Community/
│   │   │   │   ├── CommunityView.swift
│   │   │   │   └── PostCard.swift
│   │   │   └── Profile/
│   │   │       ├── ProfileView.swift
│   │   │       └── BiasSettingView.swift
│   │   ├── ViewModels/          # ビジネスロジック
│   │   │   ├── TaskViewModel.swift
│   │   │   ├── UserViewModel.swift
│   │   │   └── CommunityViewModel.swift
│   │   ├── Services/            # API通信
│   │   │   ├── FirebaseService.swift
│   │   │   ├── AuthService.swift
│   │   │   └── TaskService.swift
│   │   ├── Utils/               # ユーティリティ
│   │   │   ├── DateFormatter.swift
│   │   │   └── ImageLoader.swift
│   │   └── Resources/           # リソース
│   │       ├── Assets.xcassets
│   │       └── GoogleService-Info.plist
│   ├── KVoteCollectorTests/
│   ├── Podfile
│   └── KVoteCollector.xcworkspace
│
├── docs/
└── README.md
```

### Phase 2完了後の構造（Android追加）

```
KPOPVOTE/
├── functions/                    # バックエンド
├── ios/                         # iOSアプリ
│
├── android/                     # Androidアプリ
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── java/com/kvotecollector/
│   │   │   │   │   ├── models/
│   │   │   │   │   ├── ui/
│   │   │   │   │   │   ├── home/
│   │   │   │   │   │   ├── tasks/
│   │   │   │   │   │   ├── community/
│   │   │   │   │   │   └── profile/
│   │   │   │   │   ├── viewmodels/
│   │   │   │   │   ├── services/
│   │   │   │   │   └── utils/
│   │   │   │   ├── res/
│   │   │   │   └── AndroidManifest.xml
│   │   │   └── test/
│   │   └── build.gradle
│   ├── build.gradle
│   └── google-services.json
│
├── docs/
└── README.md
```

## ファイル命名規則

### バックエンド（Node.js/TypeScript）
- **ファイル名**: camelCase（例: `fetchOGP.ts`, `getUserTasks.ts`）
- **関数名**: camelCase（例: `registerTask`, `setBias`）
- **定数**: UPPER_SNAKE_CASE（例: `MAX_RETRIES`, `TIMEOUT_MS`）

### iOS（Swift）
- **ファイル名**: PascalCase（例: `TaskListView.swift`, `UserModel.swift`）
- **クラス名**: PascalCase（例: `TaskViewModel`, `FirebaseService`）
- **変数・関数名**: camelCase（例: `fetchTasks()`, `myBiasList`）

### Android（Kotlin）
- **ファイル名**: PascalCase（例: `TaskListActivity.kt`, `UserModel.kt`）
- **クラス名**: PascalCase（例: `TaskViewModel`, `FirebaseService`）
- **変数・関数名**: camelCase（例: `fetchTasks()`, `myBiasList`）

## データベース構造（Firestore）

```
Firestore
├── users/                       # ユーザーコレクション
│   └── {userId}/
│       ├── username: string
│       ├── email: string
│       ├── myBias: string[]
│       ├── points: number
│       └── tasks/               # サブコレクション
│           └── {taskId}/
│               ├── originalUrl: string
│               ├── voteName: string
│               ├── targetMembers: string[]
│               ├── deadline: timestamp
│               ├── ogpImageUrl: string
│               ├── isCompleted: boolean
│               └── ...
│
├── communityPosts/              # コミュニティ投稿
│   └── {postId}/
│       ├── biasMember: string
│       ├── authorId: string
│       ├── content: string
│       ├── likeCount: number
│       └── comments/            # サブコレクション
│
└── inAppVotes/                  # アプリ内独自投票
    └── {voteId}/
        ├── title: string
        ├── status: string
        ├── endDate: timestamp
        ├── candidates/          # サブコレクション
        └── userVotes/           # サブコレクション
```

## コード組織原則

### モジュラー設計
- 機能ごとにディレクトリ分割
- 単一責任原則（SRP）遵守
- 依存性注入（DI）パターン活用

### レイヤー構造
1. **Presentation Layer**: UI/View
2. **Business Logic Layer**: ViewModel/Presenter
3. **Data Layer**: Service/Repository
4. **Network Layer**: API Client

### 共通ユーティリティ
- 日付フォーマット処理
- 画像ロード・キャッシュ
- バリデーション
- エラーハンドリング

## 開発優先順位

### Phase 0（バックエンド）
1. Firebase環境構築
2. 認証API（B1.2）
3. 推し設定API（B1.3）
4. タスク登録API（B2.1）
5. タスク取得API（B2.2）
6. OGP取得（B2.3）
7. ステータス更新API（B2.4）

### Phase 1（iOS）
1. Firebaseクライアント統合
2. 認証画面
3. ホーム画面（ダッシュボード）
4. タスク一覧画面
5. タスク登録画面
6. 推し設定画面
7. コミュニティ画面

### Phase 2（Android）
- iOS実装を参考にAndroid版開発

## 今後の拡張予定

### Phase 3以降の機能
- イベント同伴募集掲示板
- チケット/グッズ交換機能
- スポンサード投票
- 課金システム（ポイント購入）
- プレミアム機能
