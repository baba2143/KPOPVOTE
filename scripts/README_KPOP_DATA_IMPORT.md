# K-POPデータ自動取得ガイド

## 📋 概要
Wikipedia + Spotify APIからK-POPグループ・メンバーデータを自動取得し、CSV形式で出力します。

- **グループデータ**: 600件以上のK-POPグループ
- **メンバーデータ**: 数千件のアイドルメンバー情報

## 🔧 事前準備

### 1. Spotify Developer登録

1. [Spotify Developer Dashboard](https://developer.spotify.com/dashboard) にアクセス
2. Spotifyアカウントでログイン
3. 「Create app」をクリック
4. アプリ情報を入力：
   - **App name**: KPOPVOTE Data Fetcher
   - **App description**: Educational data collection for K-POP voting app
   - **Redirect URIs**: http://localhost（使用しないが必須）
   - **APIs used**: Web API
5. 「Save」をクリック
6. 「Settings」から **Client ID** と **Client Secret** をコピー

### 2. 環境変数設定

プロジェクトルートの `.env` ファイルを編集：

```bash
# .env ファイル
SPOTIFY_CLIENT_ID=あなたのClient ID
SPOTIFY_CLIENT_SECRET=あなたのClient Secret
```

## 🚀 実行方法

### グループデータ取得

#### 1. スクリプト実行

```bash
npm run fetch-kpop-groups
```

#### 2. 実行内容

スクリプトは以下の処理を自動で行います：

1. **Spotify認証**: アクセストークンを取得
2. **Wikipediaデータ取得**: K-POPグループ一覧を取得（600件以上）
3. **Spotify検索**: 各グループの画像URLを取得（100ms間隔、レート制限対策）
4. **CSV生成**: `scripts/kpop-groups-{日付}.csv` を生成

**実行時間**: 約10-30分（Spotifyレート制限のため）

#### 3. 生成されるCSV

**ファイル名**: `kpop-groups-20251118.csv` （日付部分は実行日）

**フォーマット**:
```csv
name,imageUrl
aespa,https://i.scdn.co/image/...
NewJeans,https://i.scdn.co/image/...
BLACKPINK,https://i.scdn.co/image/...
```

**文字コード**: UTF-8 with BOM（Excelで開ける）

---

### メンバーデータ取得

#### 1. 前提条件

**グループCSVが必要**: 先に `npm run fetch-kpop-groups` を実行し、グループデータを取得しておく必要があります。

#### 2. スクリプト実行

```bash
npm run fetch-kpop-members
```

#### 3. 実行内容

スクリプトは以下の処理を自動で行います：

1. **グループCSV読み込み**: 既存の `kpop-groups-*.csv` からグループ一覧を取得
2. **Wikipedia HTMLパース**: 各グループページからメンバー情報を抽出
3. **Spotify検索**: 各メンバーのプロフィール画像を取得
4. **CSV生成**: `scripts/kpop-members-{日付}.csv` を生成

**実行時間**: 約30-60分（グループ数とレート制限に依存）

**想定取得件数**: 3,000-10,000メンバー（グループページの構造に依存）

#### 4. 生成されるCSV

**ファイル名**: `kpop-members-20251118.csv` （日付部分は実行日）

**フォーマット**:
```csv
name,groupName,imageUrl
Jisoo,Blackpink,https://i.scdn.co/image/...
V,BTS,https://i.scdn.co/image/...
Karina,Aespa,https://i.scdn.co/image/...
```

**文字コード**: UTF-8 with BOM（Excelで開ける）

#### 5. 精度について

**メンバー取得率**: 60-80%（Wikipediaページの構造に依存）
- 主要グループ（BTS、BLACKPINK等）は高精度で取得可能
- マイナーグループは構造が統一されていないため取得率が低い可能性あり

**画像取得率**: 50-70%（Spotify検索精度に依存）
- ソロ活動しているメンバーは高精度
- グループ活動のみのメンバーは検索が困難な場合あり

**対応**: 不足分は管理画面から手動で追加可能

## 📊 CSVインポート

### グループCSVのインポート

1. https://kpopvote-admin.web.app にアクセス
2. 「アイドルマスター管理」→「グループ」タブ
3. 「CSVインポート」ボタンをクリック
4. `scripts/kpop-groups-{日付}.csv` を選択
5. インポート結果を確認

### メンバーCSVのインポート

1. https://kpopvote-admin.web.app にアクセス
2. 「アイドルマスター管理」→「アイドル」タブ
3. 「CSVインポート」ボタンをクリック
4. `scripts/kpop-members-{日付}.csv` を選択
5. インポート結果を確認

### インポート仕様

- **更新モード**: Upsert（名前が一致すれば更新、なければ新規作成）
- **バリデーション**: 全行を事前検証、エラーがあれば全体失敗
- **エラー表示**: 行番号とエラー内容を詳細表示

## 🔍 トラブルシューティング

### エラー: Spotify認証失敗

```
❌ Spotify認証情報が設定されていません
```

**解決方法**:
- `.env` ファイルが存在するか確認
- `SPOTIFY_CLIENT_ID` と `SPOTIFY_CLIENT_SECRET` が正しく設定されているか確認

### エラー: Spotify API レート制限

```
❌ Spotify検索エラー: Rate limit exceeded
```

**解決方法**:
- 自動的に100ms間隔で実行されているため、通常は発生しません
- 発生した場合は、スクリプトを再実行すると途中から継続します

### CSVが空 or 少ない

**原因**: Wikipedia APIの応答が変わった可能性

**解決方法**:
1. Wikipediaのカテゴリページを確認: https://en.wikipedia.org/wiki/Category:South_Korean_idol_groups
2. スクリプトのカテゴリ名が正しいか確認

## 📝 補足情報

### データ品質

- **画像URL取得率**: 約70-80%（Spotifyに登録されているグループ）
- **韓国語名取得率**: 約50-60%（Wikipediaに韓国語版ページがあるグループ）

### 画像URLがないグループ

以下の理由で画像URLが取得できない場合があります：
- Spotifyに登録されていない
- グループ名の表記が異なる（英語名 vs 韓国語表記）
- マイナーグループでSpotifyでヒットしない

→ **対応**: 管理画面から手動で画像URLを追加できます

### 定期更新

新しいグループを追加したい場合：
1. スクリプトを再実行
2. CSVインポート（重複は更新、新規は追加）

## 🎯 実行順序

### 推奨手順

1. **グループデータ取得**: `npm run fetch-kpop-groups`
2. **グループCSVインポート**: 管理画面からグループデータをインポート
3. **メンバーデータ取得**: `npm run fetch-kpop-members`
4. **メンバーCSVインポート**: 管理画面からメンバーデータをインポート
5. **データ確認**: 主要グループとメンバーが正しく登録されているか確認
6. **不足分の手動追加**: 必要に応じて管理画面から追加

### 注意事項

- メンバーデータ取得には**グループCSVが必要**です
- 各スクリプトは完了まで**30-60分**かかります
- レート制限対策のため、並列実行ではなく**順次実行**してください

---

**作成日**: 2025-11-18
**更新日**: 2025-11-18（メンバーデータ取得機能追加）
