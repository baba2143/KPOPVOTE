import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });

export const metadata: Metadata = {
  metadataBase: new URL("https://oshipick.com"),
  title: {
    default: "OSHI Pick - 推し活がそのまま投票に | K-POP投票アプリ",
    template: "%s | OSHI Pick",
  },
  description:
    "K-POPファン向け投票支援アプリ。MV共有や画像投稿など、推し活がそのままポイントになる新しい投票アプリです。広告視聴ゼロで推しを応援しよう。",
  keywords: [
    "OSHI Pick",
    "推しピック",
    "K-POP",
    "投票",
    "投票アプリ",
    "推し活",
    "アイドル",
    "ランキング",
    "ファン投票",
    "K-POP投票",
    "韓国アイドル",
    "推しメン",
    "ファンコミュニティ",
  ],
  authors: [{ name: "合同会社スイッチメディア" }],
  creator: "合同会社スイッチメディア",
  publisher: "合同会社スイッチメディア",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    type: "website",
    locale: "ja_JP",
    url: "https://oshipick.com",
    siteName: "OSHI Pick",
    title: "OSHI Pick - 推し活がそのまま投票に",
    description:
      "K-POPファン向け投票支援アプリ。MV共有や画像投稿など、推し活がそのままポイントになる新しい投票アプリです。",
    images: [
      {
        url: "/og-image.png",
        width: 1200,
        height: 630,
        alt: "OSHI Pick - K-POP投票アプリ",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "OSHI Pick - 推し活がそのまま投票に",
    description:
      "K-POPファン向け投票支援アプリ。MV共有や画像投稿など、推し活がそのままポイントになる。",
    site: "@OSHI_Pick",
    creator: "@OSHI_Pick",
    images: ["/og-image.png"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "any" },
      { url: "/icon.png", type: "image/png", sizes: "32x32" },
    ],
    apple: [{ url: "/apple-touch-icon.png", sizes: "180x180" }],
  },
  manifest: "/manifest.json",
  alternates: {
    canonical: "https://oshipick.com",
  },
  category: "entertainment",
  classification: "K-POP Fan App",
  other: {
    "apple-itunes-app": "app-id=6755575658",
    "google-play-app": "app-id=com.switchmedia.oshipick",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#ff3c78" },
    { media: "(prefers-color-scheme: dark)", color: "#0a0a0f" },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <head>
        {/* JSON-LD 構造化データ */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "MobileApplication",
              name: "OSHI Pick",
              operatingSystem: "iOS",
              applicationCategory: "EntertainmentApplication",
              description:
                "K-POPファン向け投票支援アプリ。MV共有や画像投稿など、推し活がそのままポイントになる新しい投票アプリです。",
              offers: {
                "@type": "Offer",
                price: "0",
                priceCurrency: "JPY",
              },
              aggregateRating: {
                "@type": "AggregateRating",
                ratingValue: "4.8",
                ratingCount: "100",
              },
              author: {
                "@type": "Organization",
                name: "合同会社スイッチメディア",
                url: "https://switch-media-jp.com",
              },
              downloadUrl:
                "https://apps.apple.com/jp/app/oshi-pick/id6755575658",
              screenshot: "https://oshipick.com/oshipick/images/hero-app.jpg",
              featureList: [
                "アイドルランキング投票",
                "投票タスク管理",
                "ファンコミュニティ",
                "イベントカレンダー",
                "グッズ交換",
                "推しパーソナライズ",
              ],
            }),
          }}
        />
        {/* Organization 構造化データ */}
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              "@context": "https://schema.org",
              "@type": "Organization",
              name: "OSHI Pick",
              url: "https://oshipick.com",
              logo: "https://oshipick.com/oshipick/images/logo.png",
              sameAs: [
                "https://x.com/OSHI_Pick",
                "https://www.instagram.com/oshi_pick/",
              ],
              contactPoint: {
                "@type": "ContactPoint",
                contactType: "customer service",
                availableLanguage: "Japanese",
              },
            }),
          }}
        />
      </head>
      <body className={`${inter.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  );
}
