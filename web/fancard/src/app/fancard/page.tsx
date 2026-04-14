import { Metadata } from "next";
import FanCardLP from "@/components/LP/FanCardLP";

export const metadata: Metadata = {
  title: "FanCard - あなたの推し活プロフィールを作成して、共有しよう",
  description:
    "K-POPファンのための推し活プロフィールが作成できる「FanCard」。推しメンバー、SNS、MV、画像をブロックで組み合わせて、あなただけのカードを作成。URLでかんたんシェア。",
  keywords: [
    "FanCard",
    "ファンカード",
    "推し活名刺",
    "K-POP",
    "推し活プロフィールカード",
    "推し活",
    "プロフィールカード",
    "推しカード",
    "ファンプロフィール",
    "K-POPファン",
    "推しメン紹介",
    "推し活共有",
    "オタ活",
    "推しプロフィール",
  ],
  openGraph: {
    type: "website",
    locale: "ja_JP",
    url: "https://oshipick.com/fancard",
    siteName: "OSHI Pick",
    title: "FanCard - あなたの推し活プロフィールを作成して、共有しよう",
    description:
      "K-POPファンのための推し活プロフィールが作成できる「FanCard」。推しメンバー、SNS、MV、画像をブロックで組み合わせて、あなただけのカードを作成。",
    images: [
      {
        url: "/fancard/og-image.png",
        width: 1200,
        height: 630,
        alt: "FanCard - 推し活プロフィール",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "FanCard - あなたの推し活プロフィールを作成して、共有しよう",
    description:
      "K-POPファンのための推し活プロフィールが作成できる「FanCard」。ブロックを組み合わせて、あなただけのカードを作成。",
    site: "@OSHI_Pick",
    creator: "@OSHI_Pick",
    images: ["/fancard/og-image.png"],
  },
  alternates: {
    canonical: "https://oshipick.com/fancard",
  },
};

export default function FanCardLPPage() {
  return <FanCardLP />;
}
