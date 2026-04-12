"use client";

import React, { useEffect, useState, useRef } from "react";
import Image from "next/image";
import { ChevronRight } from "lucide-react";

function useScrollReveal() {
  const [isVisible, setIsVisible] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold: 0.1 }
    );

    if (ref.current) {
      observer.observe(ref.current);
    }

    return () => observer.disconnect();
  }, []);

  return { ref, isVisible };
}

function RevealSection({
  children,
  className = "",
  delay = 0,
}: {
  children: React.ReactNode;
  className?: string;
  delay?: number;
}) {
  const { ref, isVisible } = useScrollReveal();

  return (
    <div
      ref={ref}
      className={`transition-all duration-700 ${className}`}
      style={{
        opacity: isVisible ? 1 : 0,
        transform: isVisible ? "translateY(0)" : "translateY(30px)",
        transitionDelay: `${delay}ms`,
      }}
    >
      {children}
    </div>
  );
}

export default function OshiPickLP() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 50);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <div className="min-h-screen bg-[#0d0d12] text-white font-sans antialiased overflow-x-hidden">
      {/* Header */}
      <header
        className={`fixed top-0 w-full z-50 transition-all duration-300 ${
          scrolled ? "bg-[#0d0d12]/95 backdrop-blur-lg" : "bg-transparent"
        }`}
      >
        <div className="container mx-auto px-6 py-4 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-[#ff3c78] rounded-full flex items-center justify-center text-white font-bold text-sm">
              O
            </div>
            <span className="text-xl font-bold">
              <span className="text-[#ff3c78]">shi</span> Pick
            </span>
          </div>
          <a
            href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 px-5 py-2.5 bg-[#ff3c78] rounded-full text-sm font-bold hover:bg-[#ff5c8f] transition-colors"
          >
            <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
            </svg>
            App Store
          </a>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center pt-20">
        {/* Background gradient */}
        <div className="absolute inset-0 overflow-hidden">
          <div className="absolute top-0 right-0 w-[800px] h-[800px] bg-[#ff3c78]/20 rounded-full blur-[150px] translate-x-1/3 -translate-y-1/4" />
          <div className="absolute bottom-0 left-0 w-[600px] h-[600px] bg-[#a855f7]/15 rounded-full blur-[120px] -translate-x-1/4 translate-y-1/4" />
        </div>

        <div className="container mx-auto px-6 relative z-10">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            {/* Left Content */}
            <div>
              <div className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full border border-[#ff3c78]/30 bg-[#ff3c78]/10 mb-8">
                <span className="w-2 h-2 bg-[#ff3c78] rounded-full" />
                <span className="text-sm text-[#ff3c78] font-medium">
                  アプリリリースイベントまもなく開催！
                </span>
              </div>

              <h1 className="text-5xl md:text-6xl lg:text-7xl font-extrabold leading-tight mb-8">
                推し活が
                <br />
                <span className="bg-gradient-to-r from-[#ff3c78] to-[#ff6b9d] bg-clip-text text-transparent">
                  そのまま投票に。
                </span>
              </h1>

              <p className="text-lg text-gray-400 mb-10 leading-relaxed">
                MV共有、画像投稿、ファン同士の交流——。
                <br />
                あなたの推し活動が、投票ポイントになる。
                <br />
                K-POPファンのための新しい投票アプリ。
              </p>

              <div className="flex flex-wrap gap-4">
                <a
                  href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-block transition-transform hover:scale-105"
                >
                  <Image
                    src="/app-store-badge.svg"
                    alt="Download on the App Store"
                    width={160}
                    height={53}
                    className="h-[53px] w-auto"
                  />
                </a>
                <div className="flex flex-col items-center">
                  <Image
                    src="/google-play-badge.svg"
                    alt="Get it on Google Play"
                    width={160}
                    height={53}
                    className="h-[53px] w-auto opacity-40 grayscale"
                  />
                  <span className="text-xs text-gray-500 mt-1">準備中</span>
                </div>
              </div>
            </div>

            {/* Right - Phone Mockup */}
            <div className="relative flex justify-center">
              <div className="relative">
                <Image
                  src="/oshipick/screenshots/111.png"
                  alt="OSHI Pick App"
                  width={300}
                  height={600}
                  className="w-[280px] md:w-[300px] rounded-[2.5rem] shadow-2xl"
                />
                {/* Floating Cards */}
                <div className="absolute -right-4 md:-right-20 top-[10%] bg-[#1a1a24] rounded-xl px-4 py-3 shadow-xl border border-white/10">
                  <span className="text-[#22d3ee] font-bold">+5pt</span>
                  <span className="text-white ml-2">MV投稿</span>
                </div>
                <div className="absolute -right-4 md:-right-24 top-[45%] bg-[#1a1a24] rounded-xl px-4 py-3 shadow-xl border border-white/10">
                  <span className="text-[#a855f7] font-bold">+3pt</span>
                  <span className="text-white ml-2">画像投稿</span>
                </div>
                <div className="absolute -right-4 md:-right-20 bottom-[20%] bg-[#1a1a24] rounded-xl px-4 py-3 shadow-xl border border-white/10">
                  <span className="text-[#ff3c78] font-bold">+1pt</span>
                  <span className="text-white ml-2">いいね</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-24 relative">
        <div className="container mx-auto px-6">
          <RevealSection>
            <div className="text-center mb-16">
              <span className="inline-block px-4 py-2 rounded-full border border-white/20 text-sm text-gray-400 mb-6">
                FEATURES
              </span>
              <h2 className="text-4xl md:text-5xl font-bold mb-4">
                推し活のすべてを、ひとつに。
              </h2>
              <p className="text-gray-400 text-lg max-w-2xl mx-auto">
                投票、コミュニティ、スケジュール管理——
                <br />
                K-POPファンに必要な機能をひとつのアプリに。
              </p>
            </div>
          </RevealSection>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: "/oshipick/images/01.png",
                title: "アイドルランキング",
                desc: "週間・月間・総合ランキングで推しを応援。1票=1ポイントで、いつでも投票できます。",
              },
              {
                icon: "/oshipick/images/02.png",
                title: "投票タスク管理",
                desc: "複数の投票アプリの情報を一元管理。締切アラートで投票漏れを防ぎます。",
              },
              {
                icon: "/oshipick/images/03.png",
                title: "ファンコミュニティ",
                desc: "同じ推しのファン同士でつながる。MV投稿、画像共有、グッズ交換も。",
              },
              {
                icon: "/oshipick/images/04.png",
                title: "イベントカレンダー",
                desc: "カムバック、ライブ、TV出演——推しの予定をファン同士で共有。",
              },
              {
                icon: "/oshipick/images/05.png",
                title: "グッズ交換",
                desc: "コミュニティ内でグッズ交換の相手を探せます。安全なマッチング機能。",
              },
              {
                icon: "/oshipick/images/06.png",
                title: "推しパーソナライズ",
                desc: "推しを設定すると、関連する投票やコンテンツを自動でフィルタリング。",
              },
            ].map((feature, i) => (
              <RevealSection key={i} delay={i * 100}>
                <div className="p-6 rounded-2xl bg-[#16161d] border border-white/5 hover:border-white/10 transition-colors">
                  <div className="w-14 h-14 rounded-xl overflow-hidden mb-5">
                    <Image
                      src={feature.icon}
                      alt={feature.title}
                      width={56}
                      height={56}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <h3 className="text-xl font-bold mb-3">{feature.title}</h3>
                  <p className="text-gray-400 text-sm leading-relaxed">
                    {feature.desc}
                  </p>
                </div>
              </RevealSection>
            ))}
          </div>
        </div>
      </section>

      {/* Points Section */}
      <section className="py-24 relative">
        <div className="container mx-auto px-6">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            {/* Points Table */}
            <RevealSection>
              <div className="bg-[#16161d] rounded-2xl p-6 border border-white/5">
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-8 h-8 bg-gradient-to-r from-[#fbbf24] to-[#f59e0b] rounded-lg flex items-center justify-center">
                    <span className="text-sm">🏆</span>
                  </div>
                  <span className="font-bold text-lg">ポイントの貯め方</span>
                </div>

                {/* 投票系 */}
                <div className="mb-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="flex items-center gap-2">
                      <span>🎯</span>
                      <span className="font-bold">投票系</span>
                    </span>
                    <span className="text-xs px-2 py-1 bg-[#ff3c78]/20 text-[#ff3c78] rounded">高報酬</span>
                  </div>
                  <div className="pl-6 space-y-2 text-sm">
                    <div className="flex justify-between text-gray-400">
                      <span>✨ タスク登録</span>
                      <span className="text-[#22d3ee]">+10P</span>
                    </div>
                    <div className="flex justify-between text-gray-400">
                      <span>🔗 タスク共有 <span className="text-xs text-gray-600">1日3回まで</span></span>
                      <span className="text-[#22d3ee]">+5P</span>
                    </div>
                  </div>
                </div>

                {/* コンテンツ系 */}
                <div className="mb-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="flex items-center gap-2">
                      <span>📱</span>
                      <span className="font-bold">コンテンツ系</span>
                    </span>
                    <span className="text-xs px-2 py-1 bg-[#a855f7]/20 text-[#a855f7] rounded">中報酬</span>
                  </div>
                  <div className="pl-6 space-y-2 text-sm">
                    <div className="flex justify-between text-gray-400">
                      <span>🎬 MV投稿</span>
                      <span className="text-[#22d3ee]">+5P</span>
                    </div>
                    <div className="flex justify-between text-gray-400">
                      <span>👀 MV視聴報告 <span className="text-xs text-gray-600">1日3回まで</span></span>
                      <span className="text-[#22d3ee]">+2P</span>
                    </div>
                    <div className="flex justify-between text-gray-400">
                      <span>📂 コレクション作成</span>
                      <span className="text-[#22d3ee]">+10P</span>
                    </div>
                    <div className="flex justify-between text-gray-400">
                      <span>🖼️ 画像投稿</span>
                      <span className="text-[#22d3ee]">+3P</span>
                    </div>
                    <div className="flex justify-between text-gray-400">
                      <span>🎁 グッズ交換投稿</span>
                      <span className="text-[#22d3ee]">+5P</span>
                    </div>
                  </div>
                </div>

                {/* コミュニティ系 */}
                <div className="mb-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="flex items-center gap-2">
                      <span>💬</span>
                      <span className="font-bold">コミュニティ系</span>
                    </span>
                    <span className="text-xs px-2 py-1 bg-[#22d3ee]/20 text-[#22d3ee] rounded">低報酬</span>
                  </div>
                  <div className="pl-6 space-y-2 text-sm">
                    <div className="flex justify-between text-gray-400">
                      <span>✏️ テキスト投稿</span>
                      <span className="text-[#22d3ee]">+2P</span>
                    </div>
                    <div className="flex justify-between text-gray-400">
                      <span>❤️ いいね <span className="text-xs text-gray-600">1日10回まで</span></span>
                      <span className="text-[#22d3ee]">+1P</span>
                    </div>
                    <div className="flex justify-between text-gray-400">
                      <span>💭 コメント <span className="text-xs text-gray-600">1日10回まで</span></span>
                      <span className="text-[#22d3ee]">+2P</span>
                    </div>
                    <div className="flex justify-between text-gray-400">
                      <span>👤 フォロー <span className="text-xs text-gray-600">1日5回まで</span></span>
                      <span className="text-[#22d3ee]">+3P</span>
                    </div>
                  </div>
                </div>

                {/* 特別報酬 */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="flex items-center gap-2">
                      <span>⭐</span>
                      <span className="font-bold">特別報酬</span>
                    </span>
                    <span className="text-xs px-2 py-1 bg-[#fbbf24]/20 text-[#fbbf24] rounded">ボーナス</span>
                  </div>
                  <div className="pl-6 space-y-2 text-sm">
                    <div className="flex justify-between text-gray-400">
                      <span>👥 友達招待</span>
                      <span className="text-[#fbbf24]">+50P</span>
                    </div>
                  </div>
                </div>
              </div>
            </RevealSection>

            {/* Right Content */}
            <RevealSection delay={200}>
              <div>
                <h2 className="text-4xl md:text-5xl font-bold mb-6 leading-tight">
                  広告視聴ゼロ。
                  <br />
                  推し活がポイントになる。
                </h2>
                <p className="text-gray-400 text-lg mb-8 leading-relaxed">
                  従来の投票アプリでは、広告を見てポイントを貯める必要がありました。
                </p>
                <p className="text-gray-400 text-lg mb-8 leading-relaxed">
                  OSHI Pickでは、MV共有、画像投稿、ファン同士の交流など——
                  <br />
                  あなたの推し活動がそのままポイントになります。
                </p>
                <a
                  href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-6 py-3 rounded-full border border-[#ff3c78] text-[#ff3c78] hover:bg-[#ff3c78] hover:text-white transition-all"
                >
                  <span>⭐</span>
                  推し活動で投票ポイントが貯まる
                </a>
              </div>
            </RevealSection>
          </div>
        </div>
      </section>

      {/* Event Section */}
      <section className="py-24 relative">
        <div className="container mx-auto px-6">
          <RevealSection>
            <div className="text-center mb-8">
              <span className="inline-block px-5 py-2 rounded-full bg-[#ff3c78] text-white text-sm font-bold">
                リリース記念イベント
              </span>
            </div>
            <div className="text-center mb-12">
              <h2 className="text-3xl md:text-5xl font-bold mb-6">
                1位のアーティストは
                <br />
                新宿ユニカビジョンに広告掲出
              </h2>
              <p className="text-gray-400 text-lg">
                無料で獲得できるポイントで投票に参加。
                <br />
                あなたの1票が、推しを街頭ビジョンへ届けます。
              </p>
            </div>

            <div className="grid lg:grid-cols-2 gap-12 items-center">
              <div className="text-center lg:text-left">
                <div className="grid grid-cols-2 gap-8 mb-8">
                  <div>
                    <p className="text-gray-500 text-sm mb-1">開催期間（予定）</p>
                    <p className="text-2xl font-bold">4/1（水）〜4/26（日）</p>
                  </div>
                  <div>
                    <p className="text-gray-500 text-sm mb-1">掲出場所</p>
                    <p className="text-2xl font-bold">新宿ユニカビジョン</p>
                  </div>
                </div>
                <div className="mb-8">
                  <p className="text-gray-500 text-sm mb-1">参加費</p>
                  <p className="text-2xl font-bold">無料</p>
                </div>
                <p className="text-gray-500 text-sm mb-8">
                  ※合計投票数が10,000票以上を達成しなかった場合は、広告掲載の権利は次回のイベントに持ち越します。
                </p>
                <a
                  href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-[#ff3c78] to-[#a855f7] rounded-full font-bold hover:shadow-[0_0_30px_rgba(255,60,120,0.4)] transition-all"
                >
                  今すぐ参加する
                  <ChevronRight className="w-5 h-5" />
                </a>
              </div>
              <div className="flex justify-center">
                <Image
                  src="/oshipick/images/grand-election-banner.png"
                  alt="K-POP総選挙"
                  width={500}
                  height={300}
                  className="rounded-2xl shadow-2xl"
                />
              </div>
            </div>
          </RevealSection>
        </div>
      </section>

      {/* App Preview Section */}
      <section className="py-24">
        <div className="container mx-auto px-6 mb-12">
          <RevealSection>
            <div className="text-center">
              <span className="inline-block px-4 py-2 rounded-full border border-white/20 text-sm text-gray-400 mb-6">
                APP PREVIEW
              </span>
              <h2 className="text-4xl md:text-5xl font-bold">アプリの画面</h2>
            </div>
          </RevealSection>
        </div>

        <div className="flex overflow-x-auto pb-8 gap-6 px-6 snap-x snap-mandatory scrollbar-hide">
          {[
            { img: "/oshipick/screenshots/111.png", label: "推し活をひとつに" },
            { img: "/oshipick/screenshots/112.png", label: "投票タスク管理" },
            { img: "/oshipick/screenshots/113.png", label: "アイドルランキング" },
            { img: "/oshipick/screenshots/114.png", label: "ファンコミュニティ" },
            { img: "/oshipick/screenshots/115.png", label: "イベントカレンダー" },
            { img: "/oshipick/screenshots/116.png", label: "グッズ交換" },
            { img: "/oshipick/screenshots/117.png", label: "投票イベント" },
          ].map((item, i) => (
            <div key={i} className="snap-center shrink-0 flex flex-col items-center">
              <div className="bg-[#16161d] rounded-[2rem] p-3 mb-4">
                <Image
                  src={item.img}
                  alt={item.label}
                  width={200}
                  height={400}
                  className="w-[180px] md:w-[200px] rounded-[1.5rem]"
                />
              </div>
              <span className="text-sm text-gray-400">{item.label}</span>
            </div>
          ))}
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-32 relative">
        <div className="absolute inset-0 bg-gradient-to-t from-[#ff3c78]/10 to-transparent" />
        <div className="container mx-auto px-6 text-center relative z-10">
          <RevealSection>
            <h2 className="text-4xl md:text-6xl font-bold mb-6">
              推しと、もっと近くに。
            </h2>
            <p className="text-gray-400 text-lg mb-10">
              OSHI Pickで、推し活をもっと楽しく。
              <br />
              今すぐ無料でダウンロード。
            </p>
            <a
              href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-3 px-8 py-4 bg-white text-black rounded-xl font-bold hover:bg-gray-100 transition-colors"
            >
              <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
              </svg>
              <div className="text-left">
                <div className="text-xs opacity-70">App Store</div>
                <div className="font-bold">からダウンロード</div>
              </div>
            </a>
          </RevealSection>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-8 border-t border-white/10">
        <div className="container mx-auto px-6">
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 bg-[#ff3c78] rounded-full flex items-center justify-center text-white font-bold text-xs">
                O
              </div>
              <span className="font-bold">
                <span className="text-[#ff3c78]">shi</span> Pick
              </span>
            </div>
            <div className="flex gap-8 text-sm text-gray-400">
              <a href="#" className="hover:text-white transition-colors">利用規約</a>
              <a href="#" className="hover:text-white transition-colors">プライバシーポリシー</a>
              <a href="#" className="hover:text-white transition-colors">お問い合わせ</a>
              <a href="#" className="hover:text-white transition-colors">運営会社</a>
            </div>
            <div className="flex gap-4">
              <a href="#" className="w-10 h-10 rounded-full border border-white/20 flex items-center justify-center hover:bg-white/10 transition-colors">
                <span className="text-sm font-bold">X</span>
              </a>
              <a href="#" className="w-10 h-10 rounded-full border border-white/20 flex items-center justify-center hover:bg-white/10 transition-colors">
                <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
                </svg>
              </a>
            </div>
          </div>
        </div>
      </footer>

      {/* Global Styles */}
      <style jsx global>{`
        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }
        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>
    </div>
  );
}
