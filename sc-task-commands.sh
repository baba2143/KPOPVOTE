#!/bin/bash

# K-VOTE COLLECTOR タスク一括作成スクリプト
# Phase 0: バックエンド基盤構築（2週間）

echo "🚀 K-VOTE COLLECTOR タスク作成を開始します..."
echo ""

# Phase 0 エピック作成
echo "📦 Phase 0 エピック作成中..."
/sc:task create "Phase 0: バックエンド基盤構築（2週間）" --epic
echo "✅ Phase 0 エピック作成完了"
echo ""

# ================================
# Week 1: 基盤構築と認証の確立
# ================================
echo "📅 Week 1 タスク作成中..."

# B1.1: Firebase環境設定
echo "  ├─ B1.1: Firebase環境設定"
/sc:task create "B1.1: Firebase環境設定" --priority high \
  --description "Firebaseプロジェクト設定、Firestoreスキーマ定義、セキュリティルール設定（認証済みユーザーのみアクセス許可）" \
  --assignee "バックエンド" \
  --epic "Phase 0"

# B1.2: ユーザー認証API実装
echo "  ├─ B1.2: ユーザー認証API実装"
/sc:task create "B1.2: ユーザー認証API実装" --priority high \
  --description "Cloud Functions (/auth/login, /auth/register) 実装、Firebase Authentication連携" \
  --assignee "バックエンド" \
  --epic "Phase 0"

# B1.3: 推し設定API実装
echo "  └─ B1.3: 推し設定API実装"
/sc:task create "B1.3: 推し設定API実装" --priority high \
  --description "ユーザーのmyBiasリストをusersコレクションに登録・更新するAPI (/user/setBias) 実装" \
  --assignee "バックエンド" \
  --epic "Phase 0"

echo "✅ Week 1 タスク作成完了"
echo ""

# ================================
# Week 2: タスク管理APIの確立
# ================================
echo "📅 Week 2 タスク作成中..."

# B2.1: タスク登録API（コア）実装
echo "  ├─ B2.1: タスク登録API（コア）実装"
/sc:task create "B2.1: タスク登録API（コア）実装" --priority high \
  --description "ユーザーのタスクをFirestoreに登録するAPI (/task/register) 実装。OGP処理は未実装" \
  --assignee "バックエンド" \
  --epic "Phase 0"

# B2.2: タスク取得API実装
echo "  ├─ B2.2: タスク取得API実装"
/sc:task create "B2.2: タスク取得API実装" --priority high \
  --description "ログインユーザーのタスクリストをdeadlineでソートして返すAPI (/task/getUserTasks) 実装" \
  --assignee "バックエンド" \
  --epic "Phase 0"

# B2.3: OGP取得プロトタイプ開発
echo "  ├─ B2.3: OGP取得プロトタイプ開発"
/sc:task create "B2.3: OGP取得プロトタイプ開発" --priority high \
  --description "Cloud Functionsで外部URLからog:titleとog:imageタグを抽出する実験的な関数実装、安定性評価" \
  --assignee "バックエンド" \
  --epic "Phase 0"

# B2.4: ステータス更新API実装
echo "  └─ B2.4: ステータス更新API実装"
/sc:task create "B2.4: ステータス更新API実装" --priority high \
  --description "タスクの進捗ステータスを更新するAPI (/task/updateStatus) 実装" \
  --assignee "バックエンド" \
  --epic "Phase 0"

echo "✅ Week 2 タスク作成完了"
echo ""

# ================================
# 完了メッセージ
# ================================
echo "🎉 全タスク作成完了！"
echo ""
echo "📋 作成されたタスク:"
echo "  ├─ Phase 0 エピック × 1"
echo "  ├─ Week 1 タスク × 3"
echo "  └─ Week 2 タスク × 4"
echo "  合計: 8タスク"
echo ""
echo "📊 次のコマンドで確認できます:"
echo "  /sc:task list"
echo ""
echo "✅ タスク管理の準備が整いました！"
