# Cloud Shellを使用したCustom Claims設定手順

## 📋 概要

このドキュメントは、Google Cloud Shellを使用して管理者のCustom Claimsを設定する手順を説明します。

**対象ユーザー:**
- UID: `nn8L3RmgATPEqgfua6WdOMJwxdc2`
- Email: `baba_m@switch-media-jp.com`

**設定するCustom Claim:**
```json
{"admin": true}
```

---

## 🚀 実行手順

### ステップ1: Cloud Shellを開く

1. ブラウザで以下のURLにアクセス:
   ```
   https://console.cloud.google.com/home/dashboard?project=kpopvote-9de2b
   ```

2. 画面右上の **「Cloud Shellをアクティブにする」** アイコンをクリック
   - ターミナルのようなアイコンです
   - ブラウザ下部にターミナルウィンドウが開きます

3. Cloud Shellが起動したら、以下のコマンドを実行してプロジェクトを確認:
   ```bash
   gcloud config get-value project
   ```

   **期待される出力:** `kpopvote-9de2b`

---

### ステップ2: Firebase Admin SDKをインストール

Cloud Shellで以下を**順番に**実行してください:

```bash
# 1. プロジェクトIDを明示的に設定
gcloud config set project kpopvote-9de2b

# 2. 作業ディレクトリを作成
mkdir -p ~/admin-setup
cd ~/admin-setup

# 3. package.jsonを作成
cat > package.json << 'EOF'
{
  "name": "admin-setup",
  "version": "1.0.0",
  "dependencies": {
    "firebase-admin": "^12.0.0"
  }
}
EOF

# 4. Firebase Admin SDKをインストール
npm install
```

**実行時間:** 約30秒～1分

---

### ステップ3: Custom Claims設定スクリプトを作成

```bash
cat > setClaims.js << 'EOF'
const admin = require('firebase-admin');

console.log('🔧 Firebase Admin SDKを初期化中...');

// Cloud Shellは自動的に認証されているため、
// credentialの指定は不要
admin.initializeApp({
  projectId: 'kpopvote-9de2b'
});

const uid = 'nn8L3RmgATPEqgfua6WdOMJwxdc2';

console.log('');
console.log('📋 設定情報:');
console.log('   プロジェクト: kpopvote-9de2b');
console.log('   UID:', uid);
console.log('   Custom Claim: {"admin": true}');
console.log('');

console.log('🔄 Custom Claimsを設定中...');

admin.auth().setCustomUserClaims(uid, { admin: true })
  .then(() => {
    console.log('✅ Custom Claims設定成功！');
    console.log('');
    console.log('📋 確認: ユーザー情報を取得中...');
    return admin.auth().getUser(uid);
  })
  .then((userRecord) => {
    console.log('');
    console.log('✅ 確認完了:');
    console.log('   Email:', userRecord.email);
    console.log('   UID:', userRecord.uid);
    console.log('   Custom Claims:', JSON.stringify(userRecord.customClaims));
    console.log('');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('');
    console.log('🎉 設定完了！次のステップに進んでください:');
    console.log('');
    console.log('1. 管理画面にアクセス:');
    console.log('   https://kpopvote-admin.web.app/login');
    console.log('');
    console.log('2. ログイン:');
    console.log('   - Email: baba_m@switch-media-jp.com');
    console.log('   - Password: 設定したパスワード');
    console.log('');
    console.log('3. ⚠️ 重要: 既にログイン済みの場合:');
    console.log('   一度ログアウトしてから再ログインしてください');
    console.log('   （Custom Claimsの反映にはトークンのリフレッシュが必要）');
    console.log('');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('');
    process.exit(0);
  })
  .catch((error) => {
    console.error('');
    console.error('❌ エラーが発生しました:');
    console.error('   ', error.message);
    console.error('');
    console.error('🔧 トラブルシューティング:');
    console.error('   1. プロジェクトIDが正しいか確認:');
    console.error('      gcloud config get-value project');
    console.error('');
    console.error('   2. UIDが正しいか確認:');
    console.error('      Firebase Console → Authentication → Users');
    console.error('');
    console.error('   3. Cloud ShellにFirebase Admin権限があるか確認');
    console.error('');
    process.exit(1);
  });
EOF
```

---

### ステップ4: スクリプトを実行

```bash
node setClaims.js
```

**期待される出力:**

```
🔧 Firebase Admin SDKを初期化中...

📋 設定情報:
   プロジェクト: kpopvote-9de2b
   UID: nn8L3RmgATPEqgfua6WdOMJwxdc2
   Custom Claim: {"admin": true}

🔄 Custom Claimsを設定中...
✅ Custom Claims設定成功！

📋 確認: ユーザー情報を取得中...

✅ 確認完了:
   Email: baba_m@switch-media-jp.com
   UID: nn8L3RmgATPEqgfua6WdOMJwxdc2
   Custom Claims: {"admin":true}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 設定完了！次のステップに進んでください:
...
```

---

### ステップ5: ログインテスト

1. **管理画面にアクセス:**
   ```
   https://kpopvote-admin.web.app/login
   ```

2. **ログイン:**
   - Email: `baba_m@switch-media-jp.com`
   - Password: 設定したパスワード

3. **⚠️ 重要: 既にログイン済みの場合:**
   - ログアウトボタンをクリック
   - 再度ログイン
   - Custom Claimsはトークンに含まれるため、リフレッシュが必要です

4. **確認:**
   - ✅ ログイン成功
   - ✅ ダッシュボード画面が表示される
   - ✅ 「アクセス拒否」エラーが表示されない

---

## 🔧 トラブルシューティング

### エラー: "ENOTFOUND metadata.google.internal"

**原因:** Cloud Shellが正しく初期化されていない

**解決策:**
```bash
gcloud config set project kpopvote-9de2b
```

---

### エラー: "User with uid not found"

**原因:** UIDが間違っている

**解決策:**
Firebase Consoleで正しいUIDを確認:
```
https://console.firebase.google.com/project/kpopvote-9de2b/authentication/users
```

---

### ログイン後「アクセス拒否」と表示される

**原因:** トークンがリフレッシュされていない

**解決策:**
1. ログアウト
2. ブラウザのキャッシュをクリア（推奨）
3. 再度ログイン

---

### Custom Claimsが設定されているか確認したい

**Cloud Shellで確認:**
```bash
cat > checkClaims.js << 'EOF'
const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'kpopvote-9de2b' });

admin.auth().getUser('nn8L3RmgATPEqgfua6WdOMJwxdc2')
  .then((userRecord) => {
    console.log('Custom Claims:', userRecord.customClaims);
    process.exit(0);
  });
EOF

node checkClaims.js
```

**期待される出力:**
```
Custom Claims: { admin: true }
```

---

## ✅ 完了チェックリスト

- [ ] Cloud Shellを開いた
- [ ] Firebase Admin SDKをインストールした
- [ ] setClaims.jsを実行した
- [ ] 「✅ Custom Claims設定成功！」と表示された
- [ ] 管理画面にログインした
- [ ] ダッシュボードが表示された

すべてチェックがついたら、**Week 1 Day 3完全完了**です！🎉

---

## 📚 参考情報

- **管理画面URL:** https://kpopvote-admin.web.app
- **Firebase Console:** https://console.firebase.google.com/project/kpopvote-9de2b
- **Cloud Console:** https://console.cloud.google.com/home/dashboard?project=kpopvote-9de2b

---

## 📞 サポート

問題が解決しない場合は、以下の情報を添えて相談してください:

1. エラーメッセージの全文
2. 実行したコマンド
3. `gcloud config get-value project` の出力
4. Firebase Consoleのスクリーンショット
