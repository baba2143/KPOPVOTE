"use client";

import React, { useEffect, useState, useRef } from "react";
import Image from "next/image";

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
      className={`transition-all duration-700 ease-out ${className}`}
      style={{
        opacity: isVisible ? 1 : 0,
        transform: isVisible ? "translateY(0)" : "translateY(40px)",
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
    <div className="min-h-screen bg-[#0a0a0f] text-white font-sans antialiased overflow-x-hidden">
      {/* Background Effects */}
      <div className="fixed inset-0 z-[-1]">
        <div
          className="absolute inset-0"
          style={{
            background: `
              radial-gradient(ellipse 80% 50% at 20% 40%, rgba(255, 60, 120, 0.15) 0%, transparent 50%),
              radial-gradient(ellipse 60% 40% at 80% 20%, rgba(168, 85, 247, 0.12) 0%, transparent 50%),
              radial-gradient(ellipse 50% 60% at 60% 80%, rgba(34, 211, 238, 0.08) 0%, transparent 50%)
            `,
          }}
        />
      </div>

      {/* Header */}
      <header
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 border-b border-white/[0.08] ${
          scrolled ? "py-3 bg-[#0a0a0f]/80" : "py-4 bg-[#0a0a0f]/80"
        } backdrop-blur-xl`}
      >
        <div className="max-w-[1200px] mx-auto px-6 flex justify-between items-center">
          <a href="#" className="flex items-center">
            <Image
              src="/oshipick/images/logo.png"
              alt="OSHI Pick"
              width={120}
              height={48}
              className="h-12 w-auto"
            />
          </a>
          <a
            href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-[#ff3c78] text-white text-sm font-semibold rounded-full hover:translate-y-[-2px] hover:shadow-[0_8px_30px_rgba(255,60,120,0.4)] transition-all"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
              <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
            </svg>
            App Store
          </a>
        </div>
      </header>

      {/* Hero Section */}
      <section className="min-h-screen flex items-center pt-[100px] relative">
        <div className="max-w-[1200px] mx-auto px-6">
          <div className="grid lg:grid-cols-2 gap-[60px] items-center">
            {/* Hero Text */}
            <div className="text-center lg:text-left">
              <div
                className="inline-flex items-center gap-2 px-4 py-2 bg-white/[0.03] border border-white/[0.08] rounded-full text-sm text-[#22d3ee] mb-6 animate-fadeInUp"
              >
                <span className="w-2 h-2 bg-[#22d3ee] rounded-full animate-pulse" />
                アプリリリースイベントまもなく開催！
              </div>

              <h1
                className="text-[clamp(2.5rem,6vw,4rem)] font-black leading-[1.1] tracking-tight mb-6 animate-fadeInUp"
                style={{ animationDelay: "0.1s" }}
              >
                推し活が
                <br />
                <span className="bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] bg-clip-text text-transparent">
                  そのまま投票に。
                </span>
              </h1>

              <p
                className="text-lg text-white/70 mb-10 max-w-[480px] mx-auto lg:mx-0 animate-fadeInUp"
                style={{ animationDelay: "0.2s" }}
              >
                MV共有、画像投稿、ファン同士の交流——。
                <br />
                あなたの推し活動が、投票ポイントになる。
                <br />
                K-POPファンのための新しい投票アプリ。
              </p>

              <div
                className="flex flex-wrap items-start gap-3 justify-center lg:justify-start animate-fadeInUp"
                style={{ animationDelay: "0.3s" }}
              >
                <a
                  href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="transition-transform hover:translate-y-[-3px] hover:scale-[1.02]"
                >
                  <Image
                    src="/oshipick/images/app-store-badge.svg"
                    alt="App Storeからダウンロード"
                    width={160}
                    height={48}
                    className="h-12 w-auto"
                  />
                </a>
                <div className="flex flex-col items-center gap-1">
                  <div className="grayscale opacity-50">
                    <Image
                      src="/oshipick/images/google-play-badge.png"
                      alt="Google Playで手に入れよう"
                      width={160}
                      height={72}
                      className="h-[72px] w-auto mt-[-12px] mb-[-12px]"
                    />
                  </div>
                  <span className="text-xs text-white/40 tracking-wider">
                    準備中
                  </span>
                </div>
              </div>
            </div>

            {/* Phone Mockup */}
            <div
              className="relative flex justify-center animate-fadeInUp order-first lg:order-last"
              style={{ animationDelay: "0.4s" }}
            >
              <div
                className="relative w-[280px] h-[580px] rounded-[40px] p-3"
                style={{
                  background: "linear-gradient(145deg, #1a1a2e 0%, #0f0f1a 100%)",
                  boxShadow:
                    "0 50px 100px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(255, 255, 255, 0.1), inset 0 1px 0 rgba(255, 255, 255, 0.1)",
                }}
              >
                <div className="w-full h-full rounded-[32px] overflow-hidden relative">
                  <Image
                    src="/oshipick/images/hero-app.jpg"
                    alt="OSHI Pick アプリ画面"
                    fill
                    className="object-cover object-top"
                  />
                </div>
              </div>

              {/* Floating Cards */}
              <div className="absolute top-[10%] right-[-60px] hidden lg:block">
                <div
                  className="bg-[rgba(20,20,30,0.8)] backdrop-blur-xl border border-white/[0.08] rounded-2xl px-4 py-3 text-sm whitespace-nowrap animate-float"
                  style={{ animationDelay: "0s" }}
                >
                  <span className="text-[#ff3c78]">+5pt</span> MV投稿
                </div>
              </div>
              <div className="absolute bottom-[30%] left-[-80px] hidden lg:block">
                <div
                  className="bg-[rgba(20,20,30,0.8)] backdrop-blur-xl border border-white/[0.08] rounded-2xl px-4 py-3 text-sm whitespace-nowrap animate-float"
                  style={{ animationDelay: "2s" }}
                >
                  <span className="text-[#22d3ee]">+3pt</span> 画像投稿
                </div>
              </div>
              <div className="absolute bottom-[10%] right-[-40px] hidden lg:block">
                <div
                  className="bg-[rgba(20,20,30,0.8)] backdrop-blur-xl border border-white/[0.08] rounded-2xl px-4 py-3 text-sm whitespace-nowrap animate-float"
                  style={{ animationDelay: "4s" }}
                >
                  <span className="text-[#a855f7]">+1pt</span> いいね
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-[clamp(60px,12vw,120px)]">
        <div className="max-w-[1200px] mx-auto px-6">
          <RevealSection>
            <div className="text-center max-w-[700px] mx-auto mb-[60px]">
              <span className="inline-block px-3.5 py-1.5 bg-white/[0.03] border border-white/[0.08] rounded-full text-xs font-semibold tracking-[0.1em] uppercase text-[#a855f7] mb-5">
                Features
              </span>
              <h2 className="text-[clamp(2rem,4vw,3rem)] font-extrabold tracking-tight mb-4">
                推し活のすべてを、ひとつに。
              </h2>
              <p className="text-lg text-white/70">
                投票、コミュニティ、スケジュール管理——
                <br />
                K-POPファンに必要な機能をひとつのアプリに。
              </p>
            </div>
          </RevealSection>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: "🏆",
                title: "アイドルランキング",
                desc: "週間・月間・総合ランキングで推しを応援。1票=1ポイントで、いつでも投票できます。",
              },
              {
                icon: "📋",
                title: "投票タスク管理",
                desc: "複数の投票アプリの情報を一元管理。締切アラートで投票漏れを防ぎます。",
              },
              {
                icon: "💬",
                title: "ファンコミュニティ",
                desc: "同じ推しのファン同士でつながる。MV投稿、画像共有、グッズ交換も。",
              },
              {
                icon: "📅",
                title: "イベントカレンダー",
                desc: "カムバック、ライブ、TV出演——推しの予定をファン同士で共有。",
              },
              {
                icon: "🎁",
                title: "グッズ交換",
                desc: "コミュニティ内でグッズ交換の相手を探せます。安全なマッチング機能。",
              },
              {
                icon: "✨",
                title: "推しパーソナライズ",
                desc: "推しを設定すると、関連する投票やコンテンツを自動でフィルタリング。",
              },
            ].map((feature, i) => (
              <RevealSection key={i} delay={(i % 3) * 100 + 100}>
                <div className="bg-[rgba(20,20,30,0.8)] backdrop-blur-xl border border-white/[0.08] rounded-3xl p-8 transition-all duration-300 hover:translate-y-[-8px] hover:border-white/15 hover:shadow-[0_30px_60px_rgba(0,0,0,0.3)] relative overflow-hidden group">
                  <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                  <div className="w-14 h-14 bg-gradient-to-br from-[#ff3c78] via-[#a855f7] to-[#22d3ee] rounded-2xl flex items-center justify-center text-2xl mb-5">
                    {feature.icon}
                  </div>
                  <h3 className="text-xl font-bold mb-3">{feature.title}</h3>
                  <p className="text-white/70 text-[0.9375rem] leading-relaxed">
                    {feature.desc}
                  </p>
                </div>
              </RevealSection>
            ))}
          </div>
        </div>
      </section>

      {/* Points Section */}
      <section
        className="py-[clamp(60px,12vw,120px)]"
        style={{
          background: "linear-gradient(180deg, rgba(168, 85, 247, 0.05) 0%, transparent 100%)",
        }}
      >
        <div className="max-w-[1200px] mx-auto px-6">
          <div className="grid lg:grid-cols-2 gap-[60px] items-center">
            {/* Points Card */}
            <RevealSection className="order-first lg:order-first">
              <div className="bg-[rgba(20,20,30,0.8)] backdrop-blur-xl border border-white/[0.08] rounded-2xl p-5 max-w-[320px] mx-auto lg:mx-0">
                <h4 className="flex items-center gap-1.5 text-[0.85rem] text-white/70 mb-3">
                  <span>🎁</span> ポイントの貯め方
                </h4>

                {/* 投票系 */}
                <div className="mb-3">
                  <div className="flex items-center justify-between py-1 mb-0.5">
                    <span className="flex items-center gap-1.5 font-semibold text-xs">
                      <span className="text-pink-400">🗳️</span> 投票系
                    </span>
                    <span className="text-[0.55rem] px-1.5 py-0.5 rounded bg-white/10 text-white/70">
                      高報酬
                    </span>
                  </div>
                  <div className="space-y-0">
                    <div className="flex items-center justify-between py-1.5 border-b border-white/[0.08]">
                      <span className="flex items-center gap-1.5 text-[0.7rem]">
                        <span className="w-4 text-center">➕</span>
                        <span className="font-medium">タスク登録</span>
                      </span>
                      <span className="text-[0.7rem] font-bold bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] bg-clip-text text-transparent">
                        +10P
                      </span>
                    </div>
                    <div className="flex items-center justify-between py-1.5 border-b border-white/[0.08]">
                      <span className="flex items-center gap-1.5 text-[0.7rem]">
                        <span className="w-4 text-center">📤</span>
                        <span className="font-medium">タスク共有</span>
                        <span className="text-[0.5rem] text-white/70 bg-white/[0.08] px-1 py-0.5 rounded">
                          1日3回まで
                        </span>
                      </span>
                      <span className="text-[0.7rem] font-bold bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] bg-clip-text text-transparent">
                        +5P
                      </span>
                    </div>
                  </div>
                </div>

                {/* コンテンツ系 */}
                <div className="mb-3">
                  <div className="flex items-center justify-between py-1 mb-0.5">
                    <span className="flex items-center gap-1.5 font-semibold text-xs">
                      <span className="text-cyan-400">📱</span> コンテンツ系
                    </span>
                    <span className="text-[0.55rem] px-1.5 py-0.5 rounded bg-white/10 text-white/70">
                      中報酬
                    </span>
                  </div>
                  <div className="space-y-0">
                    {[
                      { emoji: "🎬", label: "MV投稿", value: "+5P" },
                      {
                        emoji: "👁️",
                        label: "MV視聴報告",
                        limit: "1日3回まで",
                        value: "+2P",
                      },
                      { emoji: "📁", label: "コレクション作成", value: "+10P" },
                      { emoji: "📸", label: "画像投稿", value: "+3P" },
                      { emoji: "🎁", label: "グッズ交換投稿", value: "+5P" },
                    ].map((item, i) => (
                      <div
                        key={i}
                        className="flex items-center justify-between py-1.5 border-b border-white/[0.08] last:border-0"
                      >
                        <span className="flex items-center gap-1.5 text-[0.7rem]">
                          <span className="w-4 text-center">{item.emoji}</span>
                          <span className="font-medium">{item.label}</span>
                          {item.limit && (
                            <span className="text-[0.5rem] text-white/70 bg-white/[0.08] px-1 py-0.5 rounded">
                              {item.limit}
                            </span>
                          )}
                        </span>
                        <span className="text-[0.7rem] font-bold bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] bg-clip-text text-transparent">
                          {item.value}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* コミュニティ系 */}
                <div className="mb-3">
                  <div className="flex items-center justify-between py-1 mb-0.5">
                    <span className="flex items-center gap-1.5 font-semibold text-xs">
                      <span className="text-purple-400">💬</span> コミュニティ系
                    </span>
                    <span className="text-[0.55rem] px-1.5 py-0.5 rounded bg-white/10 text-white/70">
                      低報酬
                    </span>
                  </div>
                  <div className="space-y-0">
                    {[
                      { emoji: "✏️", label: "テキスト投稿", value: "+2P" },
                      {
                        emoji: "❤️",
                        label: "いいね",
                        limit: "1日10回まで",
                        value: "+1P",
                      },
                      {
                        emoji: "💭",
                        label: "コメント",
                        limit: "1日10回まで",
                        value: "+2P",
                      },
                      {
                        emoji: "👤",
                        label: "フォロー",
                        limit: "1日5回まで",
                        value: "+3P",
                      },
                    ].map((item, i) => (
                      <div
                        key={i}
                        className="flex items-center justify-between py-1.5 border-b border-white/[0.08] last:border-0"
                      >
                        <span className="flex items-center gap-1.5 text-[0.7rem]">
                          <span className="w-4 text-center">{item.emoji}</span>
                          <span className="font-medium">{item.label}</span>
                          {item.limit && (
                            <span className="text-[0.5rem] text-white/70 bg-white/[0.08] px-1 py-0.5 rounded">
                              {item.limit}
                            </span>
                          )}
                        </span>
                        <span className="text-[0.7rem] font-bold bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] bg-clip-text text-transparent">
                          {item.value}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* 特別報酬 */}
                <div>
                  <div className="flex items-center justify-between py-1 mb-0.5">
                    <span className="flex items-center gap-1.5 font-semibold text-xs">
                      <span className="text-yellow-400">⭐</span> 特別報酬
                    </span>
                    <span className="text-[0.55rem] px-1.5 py-0.5 rounded bg-white/10 text-white/70">
                      ボーナス
                    </span>
                  </div>
                  <div className="flex items-center justify-between py-1.5">
                    <span className="flex items-center gap-1.5 text-[0.7rem]">
                      <span className="w-4 text-center">👥</span>
                      <span className="font-medium">友達招待</span>
                    </span>
                    <span className="text-[0.7rem] font-bold bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] bg-clip-text text-transparent">
                      +50P
                    </span>
                  </div>
                </div>
              </div>
            </RevealSection>

            {/* Points Text */}
            <RevealSection delay={200}>
              <div>
                <h3 className="text-[clamp(1.75rem,3vw,2.5rem)] font-extrabold mb-5 leading-tight">
                  広告視聴ゼロ。
                  <br />
                  推し活がポイントになる。
                </h3>
                <p className="text-white/70 text-[1.0625rem] mb-4">
                  従来の投票アプリでは、広告を見てポイントを貯める必要がありました。
                </p>
                <p className="text-white/70 text-[1.0625rem] mb-4">
                  OSHI Pickでは、MV共有、画像投稿、ファン同士の交流など——
                  <br />
                  <strong className="text-white">
                    あなたの推し活動がそのままポイントになります。
                  </strong>
                </p>
                <div className="inline-flex items-center gap-2 px-5 py-3 bg-[#ff3c78]/10 border border-[#ff3c78]/20 rounded-xl text-[#ff3c78] font-semibold">
                  <svg
                    width="20"
                    height="20"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                  >
                    <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" />
                  </svg>
                  推し活動で投票ポイントが貯まる
                </div>
              </div>
            </RevealSection>
          </div>
        </div>
      </section>

      {/* Event Section */}
      <section className="py-[clamp(60px,12vw,120px)] relative overflow-hidden">
        <div className="max-w-[1200px] mx-auto px-6">
          <RevealSection>
            <div
              className="rounded-[32px] p-[60px] md:p-[60px] relative overflow-hidden"
              style={{
                background:
                  "linear-gradient(135deg, rgba(255, 60, 120, 0.1) 0%, rgba(168, 85, 247, 0.1) 100%)",
                border: "1px solid rgba(255, 60, 120, 0.2)",
              }}
            >
              <div
                className="absolute top-[-50%] left-[-50%] w-[200%] h-[200%] animate-spin-slow"
                style={{
                  background:
                    "radial-gradient(circle, rgba(255, 60, 120, 0.1) 0%, transparent 50%)",
                }}
              />

              <div className="grid lg:grid-cols-2 gap-10 items-center relative z-10">
                <div className="text-center lg:text-left">
                  <span className="inline-block px-5 py-2 bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] rounded-full font-bold text-sm mb-6">
                    リリース記念イベント
                  </span>
                  <h2 className="text-[clamp(1.75rem,4vw,2.75rem)] font-black mb-5">
                    1位のアーティストは
                    <br />
                    新宿ユニカビジョンに広告掲出
                  </h2>
                  <p className="text-lg text-white/70 mb-8">
                    無料で獲得できるポイントで投票に参加。
                    <br />
                    あなたの1票が、推しを街頭ビジョンへ届けます。
                  </p>

                  <div className="flex flex-wrap justify-center lg:justify-start gap-6 lg:gap-10 mb-8">
                    <div className="text-center">
                      <div className="text-xs text-white/40 uppercase tracking-wider mb-1">
                        開催期間（予定）
                      </div>
                      <div className="text-xl font-bold">4/1（水）〜4/26（日）</div>
                    </div>
                    <div className="text-center">
                      <div className="text-xs text-white/40 uppercase tracking-wider mb-1">
                        掲出場所
                      </div>
                      <div className="text-xl font-bold">新宿ユニカビジョン</div>
                    </div>
                    <div className="text-center">
                      <div className="text-xs text-white/40 uppercase tracking-wider mb-1">
                        参加費
                      </div>
                      <div className="text-xl font-bold">無料</div>
                    </div>
                  </div>

                  <p className="text-[0.8125rem] text-white/40 mb-8">
                    ※合計投票数が10,000票以上を達成しなかった場合は、広告掲載の権利は次回のイベントに持ち越します。
                  </p>

                  <a
                    href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-3 px-8 py-4 bg-gradient-to-r from-[#ff3c78] via-[#a855f7] to-[#22d3ee] rounded-2xl font-bold transition-all hover:translate-y-[-3px] hover:scale-[1.02] hover:shadow-[0_20px_40px_rgba(255,60,120,0.3)]"
                  >
                    今すぐ参加する
                    <svg
                      width="16"
                      height="16"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                    >
                      <path d="M5 12h14M12 5l7 7-7 7" />
                    </svg>
                  </a>
                </div>

                <div className="flex justify-center">
                  <div className="rounded-[20px] overflow-hidden shadow-[0_20px_60px_rgba(0,0,0,0.4)]">
                    <Image
                      src="/oshipick/images/grand-election-banner.png"
                      alt="K-POP総選挙 OSHI Pick GRAND ELECTION"
                      width={500}
                      height={300}
                      className="w-full h-auto"
                    />
                  </div>
                </div>
              </div>
            </div>
          </RevealSection>
        </div>
      </section>

      {/* Screenshots Section */}
      <section
        className="py-[clamp(60px,12vw,120px)]"
        style={{
          background:
            "linear-gradient(180deg, transparent 0%, rgba(34, 211, 238, 0.03) 100%)",
        }}
      >
        <div className="max-w-[1200px] mx-auto px-6 mb-12">
          <RevealSection>
            <div className="text-center">
              <span className="inline-block px-3.5 py-1.5 bg-white/[0.03] border border-white/[0.08] rounded-full text-xs font-semibold tracking-[0.1em] uppercase text-[#a855f7] mb-5">
                App Preview
              </span>
              <h2 className="text-[clamp(2rem,4vw,3rem)] font-extrabold">
                アプリの画面
              </h2>
            </div>
          </RevealSection>
        </div>

        <div className="flex justify-center gap-6 overflow-x-auto pb-10 px-6 snap-x snap-mandatory scrollbar-hide">
          {[
            { img: "/oshipick/images/01.png", label: "推し活をひとつに" },
            { img: "/oshipick/images/02.png", label: "投票タスク管理" },
            { img: "/oshipick/images/03.png", label: "アイドルランキング" },
            { img: "/oshipick/images/04.png", label: "ファンコミュニティ" },
            { img: "/oshipick/images/05.png", label: "イベントカレンダー" },
            { img: "/oshipick/images/06.png", label: "グッズ交換" },
            { img: "/oshipick/images/07.png", label: "投票イベント" },
          ].map((item, i) => (
            <div key={i} className="flex-shrink-0 w-[200px] snap-center">
              <div
                className="rounded-3xl p-2"
                style={{
                  background: "linear-gradient(145deg, #1a1a2e 0%, #0f0f1a 100%)",
                  boxShadow: "0 20px 40px rgba(0, 0, 0, 0.3)",
                }}
              >
                <Image
                  src={item.img}
                  alt={item.label}
                  width={200}
                  height={433}
                  className="w-full rounded-[18px]"
                  style={{ aspectRatio: "9/19.5", objectFit: "cover" }}
                />
              </div>
              <div className="text-center mt-3 text-sm text-white/70">
                {item.label}
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-[100px] pb-[120px]">
        <div className="max-w-[1200px] mx-auto px-6">
          <RevealSection>
            <div className="text-center max-w-[600px] mx-auto">
              <h2 className="text-[clamp(2rem,4vw,3rem)] font-black mb-5">
                推しと、もっと近くに。
              </h2>
              <p className="text-lg text-white/70 mb-10">
                OSHI Pickで、推し活をもっと楽しく。
                <br />
                今すぐ無料でダウンロード。
              </p>
              <a
                href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block transition-transform hover:scale-105"
              >
                <Image
                  src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/ja-jp?size=250x83"
                  alt="Download on the App Store"
                  width={250}
                  height={83}
                  className="h-[54px] w-auto"
                  unoptimized
                />
              </a>
            </div>
          </RevealSection>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/[0.08] py-[60px]">
        <div className="max-w-[1200px] mx-auto px-6">
          <div className="flex flex-col md:flex-row justify-between items-center flex-wrap gap-6">
            <a href="#" className="flex items-center">
              <Image
                src="/oshipick/images/logo.png"
                alt="OSHI Pick"
                width={100}
                height={40}
                className="h-10 w-auto"
              />
            </a>
            <div className="flex flex-wrap justify-center gap-8">
              <a
                href="#"
                className="text-white/70 text-sm hover:text-white transition-colors"
              >
                利用規約
              </a>
              <a
                href="#"
                className="text-white/70 text-sm hover:text-white transition-colors"
              >
                プライバシーポリシー
              </a>
              <a
                href="#"
                className="text-white/70 text-sm hover:text-white transition-colors"
              >
                お問い合わせ
              </a>
              <a
                href="#"
                className="text-white/70 text-sm hover:text-white transition-colors"
              >
                運営会社
              </a>
            </div>
            <div className="flex gap-4">
              <a
                href="https://x.com/OSHI_Pick"
                target="_blank"
                rel="noopener noreferrer"
                className="w-10 h-10 flex items-center justify-center bg-white/[0.03] border border-white/[0.08] rounded-xl text-white/70 hover:bg-[#ff3c78] hover:border-[#ff3c78] hover:text-white transition-all"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
                </svg>
              </a>
              <a
                href="https://www.instagram.com/oshi_pick/"
                target="_blank"
                rel="noopener noreferrer"
                className="w-10 h-10 flex items-center justify-center bg-white/[0.03] border border-white/[0.08] rounded-xl text-white/70 hover:bg-[#ff3c78] hover:border-[#ff3c78] hover:text-white transition-all"
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z" />
                </svg>
              </a>
            </div>
          </div>
          <div className="mt-10 pt-6 border-t border-white/[0.08] text-center text-white/40 text-[0.8125rem]">
            <p>&copy; 2026 合同会社スイッチメディア. All rights reserved.</p>
          </div>
        </div>
      </footer>

      {/* Global Styles */}
      <style jsx global>{`
        @keyframes fadeInUp {
          from {
            opacity: 0;
            transform: translateY(30px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        @keyframes float {
          0%,
          100% {
            transform: translateY(0);
          }
          50% {
            transform: translateY(-15px);
          }
        }

        @keyframes spin-slow {
          from {
            transform: rotate(0deg);
          }
          to {
            transform: rotate(360deg);
          }
        }

        .animate-fadeInUp {
          animation: fadeInUp 0.6s ease both;
        }

        .animate-float {
          animation: float 6s ease-in-out infinite;
        }

        .animate-spin-slow {
          animation: spin-slow 20s linear infinite;
        }

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
