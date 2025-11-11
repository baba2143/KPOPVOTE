# タスク完了時のチェックリスト

## Phase 0: バックエンドAPI開発完了基準

### 各タスク完了時の共通チェック項目

#### ✅ コード品質
- [ ] TypeScript型定義が適切
- [ ] エラーハンドリング実装済み
- [ ] 入力バリデーション実装済み
- [ ] ログ出力適切（デバッグ可能な情報）
- [ ] コードコメント適切（複雑なロジックに説明）

#### ✅ セキュリティ
- [ ] 認証チェック実装（必要な場合）
- [ ] ユーザー権限検証（自分のデータのみアクセス）
- [ ] SQLインジェクション対策（該当しないがXSS対策）
- [ ] レート制限考慮

#### ✅ テスト
- [ ] ユニットテスト実装
- [ ] 正常系テスト通過
- [ ] 異常系テスト通過（エラーケース）
- [ ] エッジケーステスト通過

#### ✅ ドキュメント
- [ ] API仕様書更新（エンドポイント、パラメータ、レスポンス）
- [ ] README更新（必要に応じて）
- [ ] Postmanコレクション更新

#### ✅ デプロイ
- [ ] ローカルエミュレーターで動作確認
- [ ] Firebase Functions デプロイ成功
- [ ] 本番環境で動作確認

---

## B1.1: Firebase環境設定 完了基準

### 設定完了項目
- [ ] Firebaseプロジェクト作成完了
- [ ] Firestoreデータベース有効化
- [ ] Firebase Authentication有効化（Email/Password）
- [ ] Firebase Storage設定（画像用）
- [ ] Firebase Cloud Messaging設定（通知用）

### Firestoreスキーマ
- [ ] `users` コレクション作成
- [ ] `communityPosts` コレクション作成
- [ ] `inAppVotes` コレクション作成
- [ ] 必要なインデックス作成（`deadline`, `targetMembers`）

### セキュリティルール
- [ ] `firestore.rules` ファイル作成
- [ ] 認証済みユーザーのみアクセス可能ルール
- [ ] ユーザーは自分のタスクのみ読み書き可能ルール
- [ ] コミュニティ投稿ルール（全員閲覧可、作成者のみ編集可）
- [ ] ルールデプロイ成功

### 動作確認
- [ ] Firebase Console でデータベース確認可能
- [ ] セキュリティルールテスト実施・合格

---

## B1.2: ユーザー認証API実装 完了基準

### 実装機能
- [ ] `POST /auth/register` エンドポイント実装
  - Email/Passwordでユーザー登録
  - `users` コレクションにユーザー情報保存
  - 初期ポイント付与（例: 1000ポイント）
  
- [ ] `POST /auth/login` エンドポイント実装
  - Email/Passwordでログイン
  - JWTトークン発行
  - セッション管理

### テストケース
- [ ] 新規登録成功（正常系）
- [ ] 重複メール登録エラー（異常系）
- [ ] 不正なメール形式エラー（バリデーション）
- [ ] パスワード要件不足エラー（最低8文字等）
- [ ] ログイン成功（正常系）
- [ ] 不正な認証情報エラー（異常系）

### 動作確認
- [ ] Postmanで登録・ログイン成功
- [ ] Firebase Console でユーザー作成確認
- [ ] トークン発行・検証成功

---

## B1.3: 推し設定API実装 完了基準

### 実装機能
- [ ] `POST /user/setBias` エンドポイント実装
  - `myBias` 配列更新（メンバー名リスト）
  - 空配列バリデーション（最低1名必要）
  
- [ ] `GET /user/getBias` エンドポイント実装
  - 現在の推し設定取得

### テストケース
- [ ] 推し設定成功（正常系）
- [ ] 推し更新成功（既存データ上書き）
- [ ] 推し追加成功（配列に追加）
- [ ] 空配列エラー（異常系）
- [ ] 認証なしエラー（セキュリティ）

### 動作確認
- [ ] Postmanで設定・取得成功
- [ ] Firebase Console でデータ更新確認

---

## B2.1: タスク登録API（コア）実装 完了基準

### 実装機能
- [ ] `POST /task/register` エンドポイント実装
  - 投票タスク情報保存
  - サブコレクション `users/{uid}/tasks/{taskId}` に保存
  - 必須フィールドバリデーション

### 保存データ
- [ ] `originalUrl` - 投票URL
- [ ] `voteName` - 投票名
- [ ] `externalAppName` - アプリ名
- [ ] `targetMembers` - 対象メンバー配列
- [ ] `deadline` - 締め切り日時
- [ ] `isCompleted` - false（初期値）
- [ ] `createdAt` - 登録日時

### テストケース
- [ ] タスク登録成功（正常系）
- [ ] 必須フィールド欠落エラー
- [ ] 不正なURL形式エラー
- [ ] 過去の締め切り日エラー
- [ ] targetMembers空配列エラー

### 動作確認
- [ ] Postmanでタスク登録成功
- [ ] Firebase Console でタスクデータ確認

---

## B2.2: タスク取得API実装 完了基準

### 実装機能
- [ ] `GET /task/getUserTasks` エンドポイント実装
  - ユーザーのタスク一覧取得
  - `deadline` でソート（昇順デフォルト）
  - `targetMembers` でフィルター（推し別）
  - `isCompleted` でフィルター（完了/未完了）

### クエリパラメータ
- [ ] `sortBy` - ソート基準（deadline, createdAt）
- [ ] `order` - ソート順序（asc, desc）
- [ ] `filterBias` - 推しフィルター（メンバー名）
- [ ] `includeCompleted` - 完了済み含む（true/false）

### テストケース
- [ ] 全タスク取得成功（正常系）
- [ ] 推しフィルター動作確認（特定メンバーのみ）
- [ ] 締め切りソート確認（昇順・降順）
- [ ] 完了済み除外確認
- [ ] 空リスト正常応答（タスクなし）

### 動作確認
- [ ] Postmanで各クエリパラメータ動作確認
- [ ] 複数フィルター組み合わせ動作確認

---

## B2.3: OGP取得プロトタイプ開発 完了基準

### 実装機能
- [ ] `POST /task/fetchOGP` エンドポイント実装
  - 外部URLからOGP情報取得
  - `og:title` 抽出
  - `og:image` URL抽出
  
- [ ] `utils/ogpParser.ts` ユーティリティ実装
  - HTMLパース処理
  - metaタグ抽出
  - エラーハンドリング

### ライブラリ選定
- [ ] `cheerio` または `open-graph-scraper` 導入
- [ ] タイムアウト設定（10秒）
- [ ] リトライロジック（3回）

### テストケース
- [ ] OGP取得成功（一般的なサイト）
- [ ] OGP取得成功（投票サイト）
  - [ ] IDOL CHAMP
  - [ ] Mnet Plus
  - [ ] MUBEAT
  - [ ] Show Champion
- [ ] OGPなしサイトでもエラーにならない（空文字列返却）
- [ ] タイムアウト処理確認
- [ ] 不正なURL処理確認

### 安定性評価
- [ ] 各投票アプリからの取得成功率測定（> 90%）
- [ ] レスポンス時間計測（平均 < 3秒）
- [ ] エラー率確認（< 5%）
- [ ] 評価レポート作成

### 動作確認
- [ ] Postmanで各投票サイトURL テスト
- [ ] ログで取得データ確認

---

## B2.4: ステータス更新API実装 完了基準

### 実装機能
- [ ] `PATCH /task/updateStatus` エンドポイント実装
  - `isCompleted` フラグ更新
  - `statusNote` 更新（`notVoted`, `pointShortage`, `completed`）
  - `userMemo` 更新

### リクエストデータ
- [ ] `taskId` - 更新対象タスクID
- [ ] `isCompleted` - 完了フラグ
- [ ] `statusNote` - ステータスノート
- [ ] `userMemo` - ユーザーメモ（任意）

### テストケース
- [ ] ステータス更新成功（正常系）
- [ ] 存在しないタスクIDエラー
- [ ] 不正なステータス値エラー
- [ ] 他人のタスク更新不可確認（セキュリティ）
- [ ] 部分更新成功（一部フィールドのみ）

### 動作確認
- [ ] Postmanで更新成功
- [ ] Firebase Console でデータ更新確認

---

## Phase 0 完了の最終チェック

### 全APIエンドポイント統合確認
- [ ] 認証フロー動作（登録→ログイン→認証必要API呼び出し）
- [ ] タスクライフサイクル動作（登録→取得→更新）
- [ ] 推しフィルタリング動作（推し設定→タスク取得で絞り込み）

### ドキュメント完成
- [ ] API仕様書作成（全エンドポイント）
- [ ] Postmanコレクション作成
- [ ] README更新（セットアップ手順）

### iOS開発チームへのハンドオフ
- [ ] API仕様書共有
- [ ] エンドポイントURL共有
- [ ] テストアカウント提供
- [ ] Firebase設定ファイル提供（`GoogleService-Info.plist`）

### 次フェーズ準備
- [ ] Phase 1（iOS開発）タスク作成
- [ ] コミュニティAPI設計開始
- [ ] 独自投票API設計開始

---

## コマンド実行チェックリスト

### 開発中の定期実行
```bash
# コード品質チェック
npm run lint          # Lintエラーなし
npm run format        # コードフォーマット

# テスト実行
npm test              # 全テスト合格

# ビルド確認
npm run build         # ビルド成功
```

### デプロイ前の必須チェック
```bash
# ローカルエミュレーター確認
firebase emulators:start --only functions,firestore

# セキュリティルールテスト
firebase emulators:exec --only firestore "npm run test:rules"

# デプロイ
firebase deploy --only functions
firebase deploy --only firestore:rules,firestore:indexes
```

### デプロイ後の動作確認
```bash
# Functions ログ確認
firebase functions:log --limit 50

# エラー監視
firebase functions:log --only errors
```

---

## トラブルシューティング時のチェック

### よくある問題と対処
- **Functions タイムアウト**: 処理時間確認、非同期処理最適化
- **Firestore 権限エラー**: セキュリティルール確認、認証状態確認
- **OGP取得失敗**: タイムアウト延長、リトライ回数増加
- **テスト失敗**: モックデータ確認、環境変数確認

### デバッグコマンド
```bash
# Functions ローカルデバッグ
npm run serve

# Firestore エミュレーター UI
open http://localhost:4000

# ログストリーミング
firebase functions:log --follow
```
