"use client";

import HeroSection from "./HeroSection";
import FeatureSection from "./FeatureSection";
import BlockShowcase from "./BlockShowcase";
import CTASection from "./CTASection";
import Footer from "./Footer";

export default function FanCardLP() {
  return (
    <main className="bg-black min-h-screen">
      {/* Hero */}
      <HeroSection />

      {/* Feature 1: Easy Creation */}
      <FeatureSection
        badge="Create"
        title="スマホをかざすだけ。簡単にシェア"
        description="ブロックを組み合わせるだけで、あなただけのFanCardが完成。特別なスキルは必要ありません。直感的な操作で、今すぐ作り始められます。"
        reverse
      >
        <div className="relative">
          {/* Phone mockup with editor */}
          <div className="relative mx-auto w-[260px]">
            <div className="absolute inset-0 bg-gradient-to-br from-fuchsia-500/20 to-violet-500/20 blur-3xl scale-125" />
            <div className="relative bg-zinc-900 rounded-[2.5rem] p-2.5 shadow-2xl border border-zinc-800">
              <div className="bg-zinc-950 rounded-[2rem] overflow-hidden">
                {/* App header */}
                <div className="flex items-center justify-between px-4 py-3 border-b border-zinc-800">
                  <span className="text-xs text-zinc-400">← 戻る</span>
                  <span className="text-sm text-white font-medium">FanCard編集</span>
                  <span className="text-xs text-fuchsia-400">保存</span>
                </div>
                {/* Editor preview */}
                <div className="p-4 space-y-3">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-fuchsia-400 to-violet-500" />
                    <div className="flex-1">
                      <div className="h-3 w-20 bg-zinc-800 rounded" />
                      <div className="h-2 w-32 bg-zinc-800/50 rounded mt-1.5" />
                    </div>
                  </div>
                  <div className="h-16 bg-zinc-800/50 rounded-xl" />
                  <div className="grid grid-cols-2 gap-2">
                    <div className="h-14 bg-zinc-800/50 rounded-xl" />
                    <div className="h-14 bg-zinc-800/50 rounded-xl" />
                  </div>
                  <button className="w-full py-3 border-2 border-dashed border-zinc-700 rounded-xl text-zinc-500 text-sm hover:border-fuchsia-500/50 hover:text-fuchsia-400 transition-colors">
                    + ブロック追加
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </FeatureSection>

      {/* Feature 2: Share */}
      <FeatureSection
        badge="Share"
        title="URLひとつで、世界中にシェア"
        description="作成したFanCardは固有のURLで公開。SNSのプロフィールに貼り付けるだけで、世界中のファンと繋がれます。"
      >
        <div className="relative">
          {/* URL Preview card */}
          <div className="relative max-w-sm mx-auto">
            <div className="absolute inset-0 bg-gradient-to-br from-violet-500/20 to-fuchsia-500/20 blur-3xl scale-110" />
            <div className="relative bg-zinc-900 rounded-3xl p-6 border border-zinc-800">
              {/* URL bar */}
              <div className="flex items-center gap-3 bg-black rounded-xl p-4 mb-6">
                <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-fuchsia-500 to-violet-600 flex items-center justify-center">
                  <span className="text-white text-xs font-bold">F</span>
                </div>
                <span className="text-white font-mono text-sm">
                  oshipick.com/<span className="text-fuchsia-400">yuuna</span>
                </span>
              </div>
              {/* Share destinations */}
              <p className="text-xs text-zinc-500 mb-4">シェア先</p>
              <div className="flex items-center gap-3">
                <div className="flex-1 py-3 bg-black rounded-xl flex items-center justify-center gap-2 border border-zinc-800 hover:border-zinc-700 transition-colors cursor-pointer">
                  <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
                  </svg>
                  <span className="text-sm text-zinc-400">X</span>
                </div>
                <div className="flex-1 py-3 bg-gradient-to-br from-fuchsia-600 to-violet-600 rounded-xl flex items-center justify-center gap-2 cursor-pointer hover:opacity-90 transition-opacity">
                  <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069z" />
                    <circle cx="12" cy="12" r="3.5" />
                  </svg>
                  <span className="text-sm text-white">Insta</span>
                </div>
                <div className="flex-1 py-3 bg-black rounded-xl flex items-center justify-center gap-2 border border-zinc-800 hover:border-zinc-700 transition-colors cursor-pointer">
                  <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64 2.93 2.93 0 0 1 .88.13V9.4a6.84 6.84 0 0 0-1-.05A6.33 6.33 0 0 0 5 20.1a6.34 6.34 0 0 0 10.86-4.43v-7a8.16 8.16 0 0 0 4.77 1.52v-3.4a4.85 4.85 0 0 1-1-.1z" />
                  </svg>
                  <span className="text-sm text-zinc-400">TikTok</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </FeatureSection>

      {/* Feature 3: Customize */}
      <FeatureSection
        badge="Customize"
        title="あなたらしさを、自由にデザイン"
        description="5種類のテーマと豊富なカスタマイズオプション。推しのカラーに合わせて、世界にひとつだけのカードを作れます。"
      >
        <div className="relative">
          {/* Theme cards stack */}
          <div className="relative h-[400px] flex items-center justify-center">
            {/* Back cards */}
            <div className="absolute w-56 h-72 bg-gradient-to-br from-blue-100 to-cyan-100 rounded-3xl -rotate-12 -translate-x-16 opacity-60 shadow-xl" />
            <div className="absolute w-56 h-72 bg-gradient-to-br from-zinc-800 to-zinc-900 rounded-3xl rotate-6 translate-x-12 opacity-70 shadow-xl" />

            {/* Front card */}
            <div className="relative w-64 h-80 bg-gradient-to-br from-fuchsia-50 to-violet-100 rounded-3xl shadow-2xl p-5 z-10">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-fuchsia-400 to-violet-500 flex items-center justify-center text-lg">
                  💜
                </div>
                <div>
                  <h4 className="font-bold text-zinc-900">みさき</h4>
                  <p className="text-xs text-fuchsia-600">TWICE一筋💕</p>
                </div>
              </div>
              <div className="space-y-2">
                <div className="bg-white/80 rounded-xl p-3">
                  <p className="text-[10px] text-zinc-500">推しメン</p>
                  <p className="text-sm font-medium text-zinc-800">サナ / モモ</p>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div className="bg-white/80 rounded-xl p-3 text-center">
                    <p className="text-[10px] text-zinc-500">X</p>
                    <p className="text-xs font-medium text-zinc-800">@misaki</p>
                  </div>
                  <div className="bg-white/80 rounded-xl p-3 text-center">
                    <p className="text-[10px] text-zinc-500">Insta</p>
                    <p className="text-xs font-medium text-zinc-800">misaki.fan</p>
                  </div>
                </div>
              </div>
              {/* Theme indicator */}
              <div className="absolute -bottom-3 left-1/2 -translate-x-1/2 px-4 py-1.5 bg-black rounded-full">
                <span className="text-xs text-white font-medium">Cute Theme</span>
              </div>
            </div>
          </div>

          {/* Theme dots */}
          <div className="flex items-center justify-center gap-2 mt-4">
            <div className="w-3 h-3 rounded-full bg-gradient-to-br from-pink-300 to-fuchsia-300" />
            <div className="w-3 h-3 rounded-full bg-gradient-to-br from-blue-300 to-cyan-300" />
            <div className="w-3 h-3 rounded-full bg-gradient-to-br from-violet-300 to-purple-300 ring-2 ring-white ring-offset-2 ring-offset-black" />
            <div className="w-3 h-3 rounded-full bg-gradient-to-br from-zinc-700 to-zinc-900" />
            <div className="w-3 h-3 rounded-full bg-gradient-to-br from-gray-200 to-white" />
          </div>
        </div>
      </FeatureSection>

      {/* Block Showcase */}
      <BlockShowcase />

      {/* CTA */}
      <CTASection />

      {/* Footer */}
      <Footer />
    </main>
  );
}
