# K-VOTE COLLECTOR FanCard

K-POPファン向けの「推し活名刺」公開ページ。

## 技術スタック

- **Framework**: Next.js 14 (App Router)
- **Styling**: Tailwind CSS
- **Hosting**: Vercel
- **Backend**: Firebase Functions

## 開発

```bash
# 依存関係インストール
npm install

# 開発サーバー起動
npm run dev

# ビルド
npm run build

# 本番サーバー起動
npm run start
```

## 環境変数

`.env.local` を作成して以下を設定:

```
NEXT_PUBLIC_API_BASE_URL=https://us-central1-kpopvote-9de2b.cloudfunctions.net
NEXT_PUBLIC_BASE_URL=http://localhost:3000
```

## デプロイ

Vercelに接続してmainブランチへのプッシュで自動デプロイ。

## URL構成

- `/` - トップページ（アプリダウンロード案内）
- `/{username}` - FanCard公開ページ
- `/{username}/opengraph-image` - OGP画像（自動生成）
