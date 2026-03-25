# ⚡ クイックスタート: 管理者権限設定

## 🎯 目標

管理画面にログインできるように、ユーザーに管理者権限（Custom Claims）を設定します。

**現在の状況:**
- ✅ 管理画面デプロイ済み: https://kpopvote-admin.web.app
- ✅ ユーザー作成済み: `baba_m@switch-media-jp.com`
- ⚠️ **Custom Claims未設定** ← 今ここ！

---

## 📋 実行手順（5分で完了）

### 1. Google Cloud Consoleを開く

ブラウザで以下をクリック:
```
https://console.cloud.google.com/home/dashboard?project=kpopvote-9de2b
```

### 2. Cloud Shellを起動

画面右上の **「Cloud Shellをアクティブにする」** アイコン（ターミナルアイコン）をクリック

→ ブラウザ下部にターミナルが開きます

### 3. 以下のコマンドをコピー＆ペースト

**全体を一度にコピーして、Cloud Shellにペーストしてください:**

```bash
# プロジェクト設定
gcloud config set project kpopvote-9de2b

# 作業ディレクトリ作成
mkdir -p ~/admin-setup && cd ~/admin-setup

# package.json作成
cat > package.json << 'EOF'
{
  "name": "admin-setup",
  "version": "1.0.0",
  "dependencies": {
    "firebase-admin": "^12.0.0"
  }
}
EOF

# Firebase Admin SDKインストール
npm install

# Custom Claims設定スクリプト作成
cat > setClaims.js << 'EOF'
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'kpopvote-9de2b' });

const uid = 'nn8L3RmgATPEqgfua6WdOMJwxdc2';

console.log('🔄 Custom Claimsを設定中...');

admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log('✅ Custom Claims設定成功！');
    return admin.auth().getUser(uid);
  })
  .then((userRecord) => {
    console.log('');
    console.log('確認:');
    console.log('  Email:', userRecord.email);
    console.log('  Custom Claims:', JSON.stringify(userRecord.customClaims));
    console.log('');
    console.log('🎉 完了！管理画面にログインしてください:');
    console.log('   https://kpopvote-admin.web.app/login');
    console.log('');
    console.log('⚠️ 既にログイン済みの場合は、ログアウト→再ログインしてください');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ エラー:', error.message);
    process.exit(1);
  });
EOF

# スクリプト実行
node setClaims.js
```

### 4. 成功メッセージを確認

以下のように表示されればOK:
```
✅ Custom Claims設定成功！

確認:
  Email: baba_m@switch-media-jp.com
  Custom Claims: {"admin":true}

🎉 完了！管理画面にログインしてください:
   https://kpopvote-admin.web.app/login
```

### 5. 管理画面にログイン

1. https://kpopvote-admin.web.app/login を開く
2. ログイン:
   - Email: `baba_m@switch-media-jp.com`
   - Password: 設定したパスワード

**⚠️ 重要:** 既にログイン済みの場合は、**ログアウト→再ログイン**してください！

### 6. 完了確認

- ✅ ログイン成功
- ✅ ダッシュボードが表示される
- ✅ ナビゲーションメニューが使える

---

## 🔧 トラブルシューティング

### 「ログインに失敗しました」と表示される

**原因1:** パスワードが間違っている

**解決策:**
Cloud Shellでパスワードをリセット:
```bash
node -e "const admin = require('firebase-admin'); admin.initializeApp({projectId:'kpopvote-9de2b'}); admin.auth().updateUser('nn8L3RmgATPEqgfua6WdOMJwxdc2', {password: 'NewPassword123!'}).then(() => {console.log('✅ パスワード更新成功'); process.exit(0);});"
```

**原因2:** ブラウザキャッシュに古いパスワードが残っている

**解決策:**
1. シークレットモード/プライベートモードでブラウザを開く
2. https://kpopvote-admin.web.app/login にアクセス
3. 手動でログイン情報を入力

---

### 「アクセス拒否」と表示される

**原因:** トークンがリフレッシュされていない（修正済み）

**解決策:**
1. ログアウト
2. ブラウザのキャッシュをクリア（Cmd+Shift+R または Ctrl+Shift+R）
3. 再度ログイン

---

### Cloud Shellでheredocが完了しない

**症状:** `> ||` や `> EOF` のような表示で止まる

**解決策:** Node.jsワンライナーを使用（最も確実）
```bash
node -e "const admin = require('firebase-admin'); admin.initializeApp({projectId:'kpopvote-9de2b'}); admin.auth().setCustomUserClaims('nn8L3RmgATPEqgfua6WdOMJwxdc2', {admin:true}).then(() => admin.auth().getUser('nn8L3RmgATPEqgfua6WdOMJwxdc2')).then(u => {console.log('✅成功 Email:', u.email, 'Claims:', u.customClaims); process.exit(0);}).catch(e => {console.error('❌', e.message); process.exit(1);});"
```

---

### Cloud Shellでその他のエラーが出る

**解決策:** 詳細手順を参照
→ [`CLOUD_SHELL_SETUP.md`](./CLOUD_SHELL_SETUP.md)

---

## ✅ 完了したら

**Week 1 Day 3 完全完了です！🎉**

次のフェーズ:
- Week 1 Day 4-5: ダッシュボード統計表示・グラフ実装

---

## 📚 参考ドキュメント

- **詳細手順:** [`CLOUD_SHELL_SETUP.md`](./CLOUD_SHELL_SETUP.md)
- **セットアップガイド:** [`README_ADMIN_SETUP.md`](./README_ADMIN_SETUP.md)
