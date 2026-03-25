#!/bin/bash

# Custom Claimsを設定するシェルスクリプト
# gcloud認証を使用してFirebase Admin APIを呼び出します

UID="nn8L3RmgATPEqgfua6WdOMJwxdc2"
PROJECT_ID="kpopvote-9de2b"

echo "🔧 Custom Claimsを設定中..."
echo "   プロジェクト: $PROJECT_ID"
echo "   UID: $UID"
echo "   Custom Claim: {\"admin\": true}"
echo ""

# gcloudからアクセストークンを取得
echo "🔑 アクセストークンを取得中..."
ACCESS_TOKEN=$(gcloud auth print-access-token)

if [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ エラー: アクセストークンが取得できませんでした"
  echo "   gcloud auth loginを実行してください"
  exit 1
fi

echo "✅ アクセストークン取得成功"
echo ""

# Firebase Admin SDK REST APIを使用してCustom Claimsを設定
echo "🔄 Custom Claimsを設定中..."

RESPONSE=$(curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:update?key=AIzaSyDKf-6LYt5jXZvJ8rR2iQ5xX9z8yKn7M0A" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"localId\": \"$UID\",
    \"customAttributes\": \"{\\\"admin\\\":true}\"
  }")

echo "$RESPONSE" | grep -q "localId"

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Custom Claimsを正常に設定しました！"
  echo ""
  echo "📋 次のステップ:"
  echo "   1. https://kpopvote-admin.web.app/login にアクセス"
  echo "   2. メールアドレスとパスワードでログイン"
  echo "   3. ダッシュボードが表示されることを確認"
  echo ""
  echo "⚠️  注意: ログイン済みの場合は、一度ログアウトして再ログインしてください"
  echo "   （Custom Claimsの反映にはトークンのリフレッシュが必要）"
  echo ""
else
  echo ""
  echo "❌ エラー: Custom Claimsの設定に失敗しました"
  echo ""
  echo "レスポンス:"
  echo "$RESPONSE"
  echo ""
  exit 1
fi
