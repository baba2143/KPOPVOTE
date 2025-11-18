/**
 * K-POPグループデータ取得スクリプト
 *
 * データソース:
 * - Wikipedia: グループ名（英語・韓国語）
 * - Spotify API: 画像URL、Spotify ID
 *
 * 使用方法:
 *   1. .envファイルにSpotify認証情報を設定
 *   2. npm run fetch-kpop-groups
 *   3. scripts/kpop-groups-{date}.csvが生成される
 *   4. 管理画面からCSVインポート
 */

import axios from 'axios';
import { Parser } from 'json2csv';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

// 環境変数の読み込み
dotenv.config();

const SPOTIFY_CLIENT_ID = process.env.SPOTIFY_CLIENT_ID;
const SPOTIFY_CLIENT_SECRET = process.env.SPOTIFY_CLIENT_SECRET;

interface KPopGroup {
  name: string; // 英語名
  nameKo?: string; // 韓国語名
  imageUrl?: string | null;
  spotifyId?: string | null;
}

interface WikipediaPageInfo {
  pageid: number;
  title: string;
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
 * WikipediaからK-POPグループ一覧を取得
 */
async function fetchFromWikipedia(): Promise<WikipediaPageInfo[]> {
  console.log('📚 Wikipediaからグループ一覧を取得中...');

  const categories = [
    'Category:South_Korean_idol_groups',
    'Category:South_Korean_boy_bands',
    'Category:South_Korean_girl_groups',
    'Category:K-pop_music_groups',
  ];

  const allGroups: WikipediaPageInfo[] = [];
  const seenTitles = new Set<string>();

  for (const category of categories) {
    console.log(`  📂 ${category} を検索中...`);
    let cmcontinue: string | undefined = undefined;

    // ページネーションで全件取得
    while (true) {
      const params: any = {
        action: 'query',
        list: 'categorymembers',
        cmtitle: category,
        cmtype: 'page', // ページのみ取得（サブカテゴリを除外）
        cmlimit: 500,
        format: 'json',
      };

      if (cmcontinue) {
        params.cmcontinue = cmcontinue;
      }

      const response = await axios.get('https://en.wikipedia.org/w/api.php', {
        params,
        headers: {
          'User-Agent': 'KPOPVote-DataFetcher/1.0 (Educational Purpose)',
        },
      });

      const members = response.data.query.categorymembers;

      // "List of" で始まるリストページを除外、重複も除外
      const filteredMembers = members.filter(
        (page: WikipediaPageInfo) =>
          !page.title.startsWith('List of') && !seenTitles.has(page.title)
      );

      filteredMembers.forEach((page: WikipediaPageInfo) => {
        seenTitles.add(page.title);
        allGroups.push(page);
      });

      // 続きがあるかチェック
      if (response.data.continue) {
        cmcontinue = response.data.continue.cmcontinue;
        await sleep(100); // Wikipedia API レート制限対策
      } else {
        break;
      }
    }

    console.log(`    → ${seenTitles.size}件（累計）`);
    await sleep(100); // Wikipedia API レート制限対策
  }

  console.log(`\n  ✅ 合計 ${allGroups.length}件のグループを発見\n`);

  return allGroups;
}

/**
 * Wikipediaページから韓国語名を取得
 */
async function fetchKoreanName(pageTitle: string): Promise<string | undefined> {
  try {
    const response = await axios.get('https://en.wikipedia.org/w/api.php', {
      params: {
        action: 'query',
        titles: pageTitle,
        prop: 'langlinks',
        lllang: 'ko',
        format: 'json',
      },
      headers: {
        'User-Agent': 'KPOPVote-DataFetcher/1.0 (Educational Purpose)',
      },
    });

    const pages = response.data.query.pages;
    const pageId = Object.keys(pages)[0];

    if (pages[pageId].langlinks && pages[pageId].langlinks.length > 0) {
      return pages[pageId].langlinks[0]['*'];
    }
  } catch (error) {
    // 韓国語名が取得できない場合はundefinedを返す
  }

  return undefined;
}

/**
 * Spotify APIでグループ情報を検索
 */
async function searchSpotify(
  groupName: string,
  accessToken: string
): Promise<{ imageUrl: string | null; spotifyId: string | null }> {
  try {
    const response = await axios.get('https://api.spotify.com/v1/search', {
      params: {
        q: groupName, // シンプルな検索に変更
        type: 'artist',
        limit: 1,
      },
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (
      response.data.artists.items &&
      response.data.artists.items.length > 0
    ) {
      const artist = response.data.artists.items[0];
      return {
        imageUrl: artist.images[0]?.url || null,
        spotifyId: artist.id || null,
      };
    }
  } catch (error: any) {
    console.error(`  ❌ Spotify検索エラー (${groupName}):`, error.message);
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
  console.log('🎵 K-POPグループデータ取得を開始します\n');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  try {
    // Step 1: Spotify認証
    console.log('🔐 Spotify認証中...');
    const accessToken = await getSpotifyAccessToken();
    console.log('  ✅ 認証成功\n');

    // Step 2: Wikipediaからグループ一覧取得
    const wikiPages = await fetchFromWikipedia();

    // Step 3: 各グループの詳細情報を取得
    console.log('🔍 各グループの詳細情報を取得中...');
    console.log('  （Spotifyレート制限対策のため、100msごとに処理します）\n');

    const groups: KPopGroup[] = [];
    let processed = 0;

    for (const page of wikiPages) {
      processed++;
      const groupName = page.title;

      // 進捗表示
      if (processed % 10 === 0) {
        console.log(`  進捗: ${processed}/${wikiPages.length} (${Math.round((processed / wikiPages.length) * 100)}%)`);
      }

      // 韓国語名を取得
      const nameKo = await fetchKoreanName(groupName);

      // Spotifyで検索（100ms間隔）
      await sleep(100);
      const spotifyData = await searchSpotify(groupName, accessToken);

      groups.push({
        name: groupName,
        nameKo,
        imageUrl: spotifyData.imageUrl,
        spotifyId: spotifyData.spotifyId,
      });
    }

    console.log(`\n  ✅ ${groups.length}件のグループデータを取得完了\n`);

    // Step 4: CSV出力
    console.log('📄 CSVファイルを生成中...');

    const timestamp = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const filename = `kpop-groups-${timestamp}.csv`;
    const filepath = path.join(__dirname, filename);

    const fields = ['name', 'imageUrl'];
    const opts = { fields, withBOM: true }; // BOM付きでExcel対応

    const parser = new Parser(opts);
    const csv = parser.parse(groups);

    fs.writeFileSync(filepath, csv, 'utf-8');

    console.log(`  ✅ CSVファイルを生成しました: ${filepath}\n`);

    // 統計情報
    const withImage = groups.filter((g) => g.imageUrl).length;
    const withKoreanName = groups.filter((g) => g.nameKo).length;

    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📊 取得結果サマリー');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log(`総グループ数: ${groups.length}`);
    console.log(`画像URLあり: ${withImage}件 (${Math.round((withImage / groups.length) * 100)}%)`);
    console.log(`韓国語名あり: ${withKoreanName}件 (${Math.round((withKoreanName / groups.length) * 100)}%)`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    console.log('✨ 完了！次のステップ:');
    console.log(`  1. ${filepath} を確認`);
    console.log('  2. https://kpopvote-admin.web.app にアクセス');
    console.log('  3. グループタブ → CSVインポート');
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
