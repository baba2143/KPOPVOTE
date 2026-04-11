"use client";

import React from "react";
import Image from "next/image";
import {
  Smartphone,
  Calendar,
  Users,
  Bell,
  Star,
  Heart,
} from "lucide-react";
import FadeInSection from "./FadeInSection";

export default function OshiPickLP() {
  return (
    <div className="font-sans antialiased bg-white selection:bg-pink-200 selection:text-pink-900 overflow-x-hidden">
      {/* Navbar */}
      <nav className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-md border-b border-pink-100 h-16 flex items-center">
        <div className="container mx-auto px-6 flex justify-center items-center">
          <div className="font-bold text-xl tracking-tighter italic bg-clip-text text-transparent bg-gradient-to-r from-pink-500 to-violet-500">
            OSHI Pick
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <header className="relative pt-32 pb-20 md:pt-48 md:pb-32 bg-gradient-to-b from-pink-50 via-white to-white overflow-hidden">
        {/* Decorative Background Elements */}
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-pink-200/30 rounded-full blur-3xl -translate-y-1/2 translate-x-1/3"></div>
        <div className="absolute bottom-0 left-0 w-[600px] h-[600px] bg-violet-200/30 rounded-full blur-3xl translate-y-1/3 -translate-x-1/3"></div>
        <div className="absolute top-40 left-10 text-pink-300 animate-bounce">
          <Heart className="w-8 h-8 fill-pink-200/50" />
        </div>
        <div className="absolute top-60 right-20 text-yellow-300 animate-pulse">
          <Star className="w-12 h-12 fill-yellow-100" />
        </div>

        <div className="container mx-auto px-6 relative z-10">
          <div className="flex flex-col md:flex-row items-center gap-12 md:gap-24">
            {/* Text Content */}
            <div className="md:w-1/2 text-center md:text-left">
              <div className="inline-block px-4 py-1.5 rounded-full bg-pink-100 text-pink-600 text-xs font-bold tracking-widest mb-6 border border-pink-200 shadow-sm animate-fade-in-up">
                K-POP FANDOM APP
              </div>
              <h1
                className="text-5xl md:text-7xl font-extrabold tracking-tight text-gray-900 leading-[1.1] mb-8 animate-fade-in-up"
                style={{ animationDelay: "0.1s" }}
              >
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-pink-500 via-purple-500 to-indigo-500">
                  推し
                </span>
                を、
                <br />
                もっと近くに。
              </h1>
              <p
                className="text-gray-500 text-lg leading-relaxed mb-10 max-w-lg mx-auto md:mx-0 animate-fade-in-up"
                style={{ animationDelay: "0.2s" }}
              >
                投票も、スケジュールも、仲間との交流も。
                <br />
                K-POP推し活のすべてが、これひとつで完結。
                <br />
                あなたの「推したい」気持ちを、全力サポートします。
              </p>

              <div
                className="flex flex-col sm:flex-row gap-4 justify-center md:justify-start animate-fade-in-up"
                style={{ animationDelay: "0.3s" }}
              >
                <a
                  href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-block transition-transform hover:scale-105"
                >
                  <Image
                    src="/app-store-badge.svg"
                    alt="Download on the App Store"
                    width={180}
                    height={60}
                    className="h-[60px] w-auto"
                  />
                </a>
                <div className="flex flex-col items-center">
                  <Image
                    src="/google-play-badge.svg"
                    alt="Get it on Google Play"
                    width={180}
                    height={60}
                    className="h-[60px] w-auto opacity-70 grayscale"
                  />
                  <span className="text-xs font-bold text-gray-500 mt-1">
                    準備中
                  </span>
                </div>
              </div>
            </div>

            {/* App Mockup Image */}
            <div
              className="md:w-1/2 relative animate-fade-in-up"
              style={{ animationDelay: "0.4s" }}
            >
              <div className="relative z-10 mx-auto w-[320px] md:w-[700px] rotate-[-6deg] hover:rotate-0 transition-transform duration-500">
                <Image
                  src="/product_app_final.jpg"
                  alt="App Screen"
                  width={700}
                  height={500}
                  className="rounded-[3rem] shadow-[0_20px_60px_-15px_rgba(236,72,153,0.3)] border-[8px] border-white"
                />
              </div>
              {/* Back Circle */}
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[350px] h-[350px] bg-gradient-to-tr from-pink-300 to-purple-300 rounded-full opacity-20 blur-2xl z-0"></div>
            </div>
          </div>
        </div>
      </header>

      {/* Features Section */}
      <section className="py-24 bg-white relative">
        <div className="container mx-auto px-6 md:px-12">
          <div className="text-center mb-20">
            <h2 className="text-3xl md:text-4xl font-bold mb-4">
              Why OSHI Pick?
            </h2>
            <p className="text-gray-500">選ばれる3つの理由</p>
          </div>

          <div className="grid md:grid-cols-3 gap-12">
            {[
              {
                icon: <Calendar className="w-8 h-8 text-pink-500" />,
                title: "投票スケジュール管理",
                desc: "見逃せない音楽番組や授賞式の投票期間をカレンダーで一括管理。開始・終了のタイミングで通知が届くので安心です。",
              },
              {
                icon: <Users className="w-8 h-8 text-purple-500" />,
                title: "ファンダムコミュニティ",
                desc: "同じ推しを持つ仲間と情報交換。戦略的な投票呼びかけや、推しの魅力を語り合う掲示板機能も充実しています。",
              },
              {
                icon: <Bell className="w-8 h-8 text-indigo-500" />,
                title: "スマートリマインダー",
                desc: "「あと10分で投票締め切り！」など、重要なタイミングをプッシュ通知でお知らせ。毎日の「ポチ活」を習慣化できます。",
              },
            ].map((feature, i) => (
              <FadeInSection key={i} delay={i * 100}>
                <div className="p-8 rounded-2xl bg-gray-50 hover:bg-pink-50/50 transition-colors border border-gray-100 hover:border-pink-100 group">
                  <div className="w-16 h-16 bg-white rounded-2xl shadow-sm flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                    {feature.icon}
                  </div>
                  <h3 className="text-xl font-bold mb-4 text-gray-900">
                    {feature.title}
                  </h3>
                  <p className="text-gray-500 leading-7 text-sm">
                    {feature.desc}
                  </p>
                </div>
              </FadeInSection>
            ))}
          </div>
        </div>
      </section>

      {/* App Screenshots Gallery */}
      <section className="py-24 bg-gray-50 overflow-hidden">
        <div className="container mx-auto px-6 mb-12 text-center">
          <FadeInSection>
            <h2 className="text-3xl md:text-4xl font-bold mb-4">App Gallery</h2>
            <p className="text-gray-500">アプリ画面イメージ</p>
          </FadeInSection>
        </div>

        {/* Horizontal Scroll Container */}
        <div className="flex overflow-x-auto pb-12 gap-8 px-6 md:px-12 snap-x snap-mandatory scrollbar-hide">
          {[111, 112, 113, 114, 115, 116, 117, 118, 119].map((num) => (
            <div key={num} className="snap-center shrink-0 first:pl-6 last:pr-6">
              <Image
                src={`/oshipick/screenshots/${num}.png`}
                alt={`Screen ${num}`}
                width={300}
                height={500}
                className="h-[400px] md:h-[500px] w-auto rounded-[2rem] shadow-xl border-4 border-white hover:scale-105 transition-transform duration-300"
              />
            </div>
          ))}
        </div>
      </section>

      {/* Testimonials / Stats */}
      <section className="py-20 bg-[#fff5f9]">
        <div className="container mx-auto px-6 text-center">
          <FadeInSection>
            <div className="inline-flex items-center justify-center p-3 rounded-full bg-white shadow-sm mb-8">
              <div className="flex -space-x-2 mr-4">
                {[1, 2, 3, 4].map((n) => (
                  <div
                    key={n}
                    className="w-8 h-8 rounded-full bg-gray-200 border-2 border-white flex items-center justify-center text-[8px] font-bold text-gray-400"
                  >
                    USER
                  </div>
                ))}
              </div>
              <span className="text-sm font-bold text-gray-600">
                30,000+ Fans are using OSHI Pick
              </span>
            </div>

            <h2 className="text-3xl md:text-5xl font-bold tracking-tight mb-8">
              さあ、推しを
              <br />
              <span className="text-pink-500">頂点</span>へ連れて行こう。
            </h2>
          </FadeInSection>
        </div>
      </section>

      {/* CTA Footer */}
      <section className="py-24 bg-gray-900 text-white relative overflow-hidden">
        <div className="absolute inset-0 opacity-20 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]"></div>
        <div className="container mx-auto px-6 relative z-10 text-center">
          <FadeInSection>
            <div className="w-16 h-16 mx-auto bg-gradient-to-tr from-pink-500 to-purple-500 rounded-2xl flex items-center justify-center mb-8 shadow-[0_0_30px_rgba(236,72,153,0.5)]">
              <Smartphone className="w-8 h-8 text-white" />
            </div>
            <h2 className="text-3xl font-bold mb-8">今すぐダウンロード</h2>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href="https://apps.apple.com/jp/app/oshi-pick/id6755575658"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block transition-transform hover:scale-105"
              >
                <Image
                  src="/app-store-badge.svg"
                  alt="Download on the App Store"
                  width={180}
                  height={60}
                  className="h-[60px] w-auto border border-white/20 rounded-lg"
                />
              </a>
              <div className="flex flex-col items-center">
                <Image
                  src="/google-play-badge.svg"
                  alt="Get it on Google Play"
                  width={180}
                  height={60}
                  className="h-[60px] w-auto opacity-70 grayscale border border-white/10 rounded-lg"
                />
                <span className="text-xs font-bold text-gray-400 mt-1">
                  準備中
                </span>
              </div>
            </div>
            <p className="mt-8 text-gray-500 text-xs">
              © 2025 Switch Media LLC. All rights reserved.
            </p>
          </FadeInSection>
        </div>
      </section>

      <style jsx>{`
        @keyframes fade-in-up {
          from {
            opacity: 0;
            transform: translateY(20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        .animate-fade-in-up {
          animation: fade-in-up 0.8s ease-out forwards;
          opacity: 0;
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
