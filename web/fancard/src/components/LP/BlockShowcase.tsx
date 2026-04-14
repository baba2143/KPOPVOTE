"use client";

import { useEffect, useRef, useState } from "react";
import { Heart, Link, Play, Type, Image, Share2 } from "lucide-react";

const blocks = [
  {
    icon: Heart,
    title: "推しメンバー",
    description: "好きなアーティストやメンバーを紹介",
  },
  {
    icon: Share2,
    title: "SNSリンク",
    description: "X、Instagram、TikTokをまとめて表示",
  },
  {
    icon: Link,
    title: "リンク",
    description: "お気に入りのサイトへのリンク",
  },
  {
    icon: Play,
    title: "MVリンク",
    description: "推しのMVを埋め込み表示",
  },
  {
    icon: Type,
    title: "テキスト",
    description: "自己紹介やメッセージを自由に",
  },
  {
    icon: Image,
    title: "画像",
    description: "推し活の写真やイラストを追加",
  },
];

export default function BlockShowcase() {
  const [isVisible, setIsVisible] = useState(false);
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold: 0.1 }
    );

    if (sectionRef.current) {
      observer.observe(sectionRef.current);
    }

    return () => observer.disconnect();
  }, []);

  return (
    <section
      ref={sectionRef}
      className="py-32 md:py-40 bg-black relative"
    >
      <div className="max-w-7xl mx-auto px-6">
        {/* Header */}
        <div
          className={`text-center mb-20 transition-all duration-700 ${
            isVisible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-8"
          }`}
        >
          <span className="inline-block text-xs text-zinc-500 tracking-widest uppercase mb-4">
            Features
          </span>
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold text-white leading-[1.1] tracking-tight">
            推し活に必要なすべてを、
            <br />
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-fuchsia-400 to-violet-400">
              一枚に。
            </span>
          </h2>
        </div>

        {/* Block Grid */}
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 md:gap-6">
          {blocks.map((block, index) => {
            const Icon = block.icon;
            return (
              <div
                key={block.title}
                className={`group p-6 md:p-8 rounded-3xl bg-zinc-950 border border-zinc-900 hover:border-zinc-800 transition-all duration-500 hover:-translate-y-1 ${
                  isVisible
                    ? "opacity-100 translate-y-0"
                    : "opacity-0 translate-y-8"
                }`}
                style={{
                  transitionDelay: isVisible ? `${index * 80}ms` : "0ms",
                }}
              >
                <div className="w-12 h-12 rounded-2xl bg-zinc-900 flex items-center justify-center mb-5 group-hover:bg-gradient-to-br group-hover:from-fuchsia-500/20 group-hover:to-violet-500/20 transition-colors">
                  <Icon className="w-5 h-5 text-zinc-400 group-hover:text-fuchsia-400 transition-colors" />
                </div>
                <h3 className="text-lg font-semibold text-white mb-2">
                  {block.title}
                </h3>
                <p className="text-sm text-zinc-500">{block.description}</p>
              </div>
            );
          })}
        </div>

        {/* Note */}
        <p
          className={`text-center text-sm text-zinc-600 mt-12 transition-all duration-700 delay-500 ${
            isVisible ? "opacity-100" : "opacity-0"
          }`}
        >
          ※ ブロックは最大10個まで追加可能
        </p>
      </div>
    </section>
  );
}
