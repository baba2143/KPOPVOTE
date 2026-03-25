/**
 * K-POPアイドルメンバーデータ取得スクリプト
 *
 * データソース:
 * - Wikipedia: メンバー名
 * - Spotify API: プロフィール画像
 *
 * 使用方法:
 *   1. グループCSVが存在することを確認（scripts/kpop-groups-*.csv）
 *   2. .envファイルにSpotify認証情報を設定
 *   3. npm run fetch-kpop-members
 *   4. scripts/kpop-members-{date}.csvが生成される
 *   5. 管理画面からCSVインポート
 */

import axios from 'axios';
import { Parser } from 'json2csv';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';
import { load } from 'cheerio';

// 環境変数の読み込み
dotenv.config();

const SPOTIFY_CLIENT_ID = process.env.SPOTIFY_CLIENT_ID;
const SPOTIFY_CLIENT_SECRET = process.env.SPOTIFY_CLIENT_SECRET;

interface KPopMember {
  name: string; // メンバー名
  groupName: string; // グループ名
  imageUrl?: string | null;
  spotifyId?: string | null;
}

interface GroupInfo {
  name: string;
  wikipediaTitle: string;
}

/**
 * Spotify アクセストークンを取得
 */
async function getSpotifyAccessToken(): Promise<string> {
  if (!SPOTIFY_CLIENT_ID || !SPOTIFY_CLIENT_SECRET) {
    throw new Error(
      'Spotify認証情報が設定されていません。.envファイルにSPOTIFY_CLIENT_IDとSPOTIFY_CLIENT_SECRETを設定してください。'
    );
  }

  const credentials = Buffer.from(
    `${SPOTIFY_CLIENT_ID}:${SPOTIFY_CLIENT_SECRET}`
  ).toString('base64');

  const response = await axios.post(
    'https://accounts.spotify.com/api/token',
    'grant_type=client_credentials',
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Authorization: `Basic ${credentials}`,
      },
    }
  );

  return response.data.access_token;
}

/**
 * グループCSVファイルを読み込む
 */
function loadGroupsFromCSV(): GroupInfo[] {
  const files = fs.readdirSync(__dirname).filter((f) => f.startsWith('kpop-groups-') && f.endsWith('.csv'));

  if (files.length === 0) {
    throw new Error('グループCSVファイルが見つかりません。先にfetch-kpop-groupsを実行してください。');
  }

  // 最新のファイルを使用
  const latestFile = files.sort().reverse()[0];
  const filepath = path.join(__dirname, latestFile);

  console.log(`📂 グループCSV読み込み: ${latestFile}`);

  const content = fs.readFileSync(filepath, 'utf-8');
  const lines = content.split('\n').slice(1); // ヘッダー行をスキップ

  const groups: GroupInfo[] = [];

  for (const line of lines) {
    if (!line.trim()) continue;

    // CSVパース（簡易版：ダブルクォートで囲まれたフィールドを考慮）
    const match = line.match(/"([^"]+)"/);
    if (match) {
      const groupName = match[1];
      groups.push({
        name: groupName,
        wikipediaTitle: groupName,
      });
    }
  }

  console.log(`  → ${groups.length}件のグループを読み込み\n`);

  return groups;
}

/**
 * WikipediaページからメンバーリストをHTMLパースで抽出
 */
async function fetchMembersFromWikipedia(groupTitle: string): Promise<string[]> {
  try {
    const response = await axios.get('https://en.wikipedia.org/w/api.php', {
      params: {
        action: 'parse',
        page: groupTitle,
        format: 'json',
        prop: 'text',
      },
      headers: {
        'User-Agent': 'KPOPVote-DataFetcher/1.0 (Educational Purpose)',
      },
    });

    if (response.data.error) {
      return [];
    }

    const html = response.data.parse.text['*'];
    const $ = load(html);

    const members: Set<string> = new Set();

    // パターン1: "Members" セクションのリスト
    $('h2, h3').each((_, heading) => {
      const headingText = $(heading).text().toLowerCase();
      if (headingText.includes('member') || headingText.includes('line-up') || headingText.includes('personnel')) {
        let nextElement = $(heading).next();

        // 次の見出しまでの要素を走査
        while (nextElement.length && !nextElement.is('h2, h3')) {
          // リスト項目からメンバー名を抽出
          nextElement.find('li').each((_, li) => {
            const text = $(li).text();
            // リンクテキストを優先的に抽出
            const links = $(li).find('a');
            if (links.length > 0) {
              links.each((_, link) => {
                const memberName = $(link).text().trim();
                // フィルタリング：日付や数字のみは除外
                if (memberName && !/^\d+$/.test(memberName) && memberName.length > 1) {
                  members.add(memberName);
                }
              });
            }
          });

          nextElement = nextElement.next();
        }
      }
    });

    // パターン2: "Infobox" テーブルのメンバー情報
    $('.infobox').each((_, infobox) => {
      $(infobox).find('th').each((_, th) => {
        const headerText = $(th).text().toLowerCase();
        if (headerText.includes('member')) {
          const value = $(th).next('td');
          value.find('a').each((_, link) => {
            const memberName = $(link).text().trim();
            if (memberName && memberName.length > 1 && !/^\d+$/.test(memberName)) {
              members.add(memberName);
            }
          });
        }
      });
    });

    return Array.from(members);
  } catch (error: any) {
    // ページが存在しないなどのエラーは無視
    return [];
  }
}

/**
 * Spotify APIでメンバー情報を検索
 */
async function searchSpotifyMember(
  memberName: string,
  groupName: string,
  accessToken: string
): Promise<{ imageUrl: string | null; spotifyId: string | null }> {
  try {
    // グループ名を含めて検索精度を向上
    const response = await axios.get('https://api.spotify.com/v1/search', {
      params: {
        q: `${memberName} ${groupName}`,
        type: 'artist',
        limit: 5, // 複数候補から選択
      },
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (response.data.artists.items && response.data.artists.items.length > 0) {
      // 名前が完全一致または部分一致する最初の結果を使用
      const bestMatch = response.data.artists.items.find((artist: any) =>
        artist.name.toLowerCase().includes(memberName.toLowerCase()) ||
        memberName.toLowerCase().includes(artist.name.toLowerCase())
      );

      if (bestMatch) {
        return {
          imageUrl: bestMatch.images[0]?.url || null,
          spotifyId: bestMatch.id || null,
        };
      }

      // マッチしない場合は最初の結果を使用
      const artist = response.data.artists.items[0];
      return {
        imageUrl: artist.images[0]?.url || null,
        spotifyId: artist.id || null,
      };
    }
  } catch (error: any) {
    // エラーは無視（Spotifyで見つからない場合）
  }

  return { imageUrl: null, spotifyId: null };
}

/**
 * レート制限のための待機
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * メイン処理
 */
async function main() {
  console.log('🎵 K-POPメンバーデータ取得を開始します\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    // Step 1: Spotify認証
    console.log('🔐 Spotify認証中...');
    const accessToken = await getSpotifyAccessToken();
    console.log('  ✅ 認証成功\n');

    // Step 2: グループCSV読み込み
    const groups = loadGroupsFromCSV();

    // Step 3: 各グループのメンバー情報を取得
    console.log('🔍 各グループのメンバー情報を取得中...');
    console.log('  （Wikipedia + Spotifyレート制限対策のため、処理に時間がかかります）\n');

    const allMembers: KPopMember[] = [];
    let processedGroups = 0;

    for (const group of groups) {
      processedGroups++;

      // 進捗表示
      if (processedGroups % 10 === 0) {
        console.log(`  進捗: ${processedGroups}/${groups.length} グループ (${Math.round((processedGroups / groups.length) * 100)}%) - ${allMembers.length}メンバー`);
      }

      // WikipediaからメンバーリストをHTMLパースで取得
      await sleep(100); // Wikipedia API レート制限対策
      const memberNames = await fetchMembersFromWikipedia(group.wikipediaTitle);

      if (memberNames.length === 0) {
        continue; // メンバー情報が取得できなかった場合はスキップ
      }

      // 各メンバーのSpotify情報を取得
      for (const memberName of memberNames) {
        await sleep(100); // Spotify API レート制限対策
        const spotifyData = await searchSpotifyMember(memberName, group.name, accessToken);

        allMembers.push({
          name: memberName,
          groupName: group.name,
          imageUrl: spotifyData.imageUrl,
          spotifyId: spotifyData.spotifyId,
        });
      }
    }

    console.log(`\n  ✅ ${allMembers.length}件のメンバーデータを取得完了\n`);

    // Step 4: CSV出力
    console.log('📄 CSVファイルを生成中...');

    const timestamp = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const filename = `kpop-members-${timestamp}.csv`;
    const filepath = path.join(__dirname, filename);

    const fields = ['name', 'groupName', 'imageUrl'];
    const opts = { fields, withBOM: true }; // BOM付きでExcel対応

    const parser = new Parser(opts);
    const csv = parser.parse(allMembers);

    fs.writeFileSync(filepath, csv, 'utf-8');

    console.log(`  ✅ CSVファイルを生成しました: ${filepath}\n`);

    // 統計情報
    const withImage = allMembers.filter((m) => m.imageUrl).length;
    const uniqueGroups = new Set(allMembers.map((m) => m.groupName)).size;

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 取得結果サマリー');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`総メンバー数: ${allMembers.length}`);
    console.log(`対象グループ数: ${uniqueGroups}/${groups.length}`);
    console.log(`画像URLあり: ${withImage}件 (${Math.round((withImage / allMembers.length) * 100)}%)`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('✨ 完了！次のステップ:');
    console.log(`  1. ${filepath} を確認`);
    console.log('  2. https://kpopvote-admin.web.app にアクセス');
    console.log('  3. アイドルタブ → CSVインポート');
    console.log('');
  } catch (error: any) {
    console.error('❌ エラーが発生しました:', error.message);
    if (error.response) {
      console.error('  レスポンスデータ:', error.response.data);
    }
    process.exit(1);
  }
}

// スクリプト実行
main();
