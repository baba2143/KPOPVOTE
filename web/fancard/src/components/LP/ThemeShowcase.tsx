"use client";

import { useEffect, useState } from "react";

const themes = [
  {
    id: "cute",
    name: "Cute",
    bg: "from-pink-100 to-purple-100",
    card: "bg-pink-50",
    text: "text-pink-900",
    muted: "text-pink-600",
    displayName: "みさき",
    bio: "TWICE一筋💕",
    oshi: "サナ / モモ",
  },
  {
    id: "dark",
    name: "Dark",
    bg: "from-gray-900 to-gray-800",
    card: "bg-gray-800",
    text: "text-gray-100",
    muted: "text-gray-400",
    displayName: "K-POP Fan",
    bio: "BTSとSEVENTEEN",
    oshi: "ジョングク / ウォヌ",
  },
  {
    id: "elegant",
    name: "Elegant",
    bg: "from-purple-100 to-violet-100",
    card: "bg-purple-50",
    text: "text-purple-900",
    muted: "text-purple-600",
    displayName: "あやか",
    bio: "BLACKPINK Forever",
    oshi: "ジェニ / リサ",
  },
  {
    id: "cool",
    name: "Cool",
    bg: "from-blue-100 to-cyan-100",
    card: "bg-blue-50",
    text: "text-blue-900",
    muted: "text-blue-600",
    displayName: "そうた",
    bio: "Stray Kids推し",
    oshi: "バンチャン / ヒョンジン",
  },
  {
    id: "default",
    name: "Default",
    bg: "from-gray-100 to-gray-50",
    card: "bg-white",
    text: "text-gray-900",
    muted: "text-gray-500",
    displayName: "ゆき",
    bio: "NewJeans大好き",
    oshi: "ミンジ / ハニ",
  },
];

export default function ThemeShowcase() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isPaused, setIsPaused] = useState(false);

  useEffect(() => {
    if (isPaused) return;

    const interval = setInterval(() => {
      setCurrentIndex((prev) => (prev + 1) % themes.length);
    }, 3000);

    return () => clearInterval(interval);
  }, [isPaused]);

  return (
    <div
      className="relative"
      onMouseEnter={() => setIsPaused(true)}
      onMouseLeave={() => setIsPaused(false)}
    >
      {/* Cards carousel */}
      <div className="relative h-[400px] flex items-center justify-center">
        {themes.map((theme, index) => {
          const offset = (index - currentIndex + themes.length) % themes.length;
          const isActive = offset === 0;
          const isNext = offset === 1 || offset === -themes.length + 1;
          const isPrev = offset === themes.length - 1 || offset === -1;

          let transform = "translateX(100%) scale(0.8)";
          let zIndex = 0;
          let opacity = 0;

          if (isActive) {
            transform = "translateX(0) scale(1)";
            zIndex = 20;
            opacity = 1;
          } else if (isNext) {
            transform = "translateX(70%) scale(0.85)";
            zIndex = 10;
            opacity = 0.5;
          } else if (isPrev) {
            transform = "translateX(-70%) scale(0.85)";
            zIndex = 10;
            opacity = 0.5;
          }

          return (
            <div
              key={theme.id}
              className="absolute transition-all duration-500 ease-out"
              style={{
                transform,
                zIndex,
                opacity,
              }}
            >
              {/* Glow effect for active card */}
              {isActive && (
                <div className="absolute inset-0 bg-gradient-to-r from-purple-500 to-pink-500 blur-2xl opacity-30 scale-110" />
              )}

              {/* Card */}
              <div
                className={`relative w-64 md:w-72 rounded-3xl p-6 shadow-2xl bg-gradient-to-br ${theme.bg}`}
              >
                {/* Profile */}
                <div className="flex items-center gap-4 mb-4">
                  <div className="w-14 h-14 rounded-full bg-gradient-to-br from-purple-300 to-pink-300 flex items-center justify-center text-xl">
                    💜
                  </div>
                  <div>
                    <h3 className={`font-bold text-lg ${theme.text}`}>
                      {theme.displayName}
                    </h3>
                    <p className={`text-sm ${theme.muted}`}>{theme.bio}</p>
                  </div>
                </div>

                {/* Content blocks */}
                <div className="space-y-3">
                  <div className={`${theme.card} rounded-xl p-3`}>
                    <p className={`text-xs ${theme.muted} mb-1`}>推しメン</p>
                    <p className={`font-medium ${theme.text}`}>{theme.oshi}</p>
                  </div>
                  <div className="flex gap-2">
                    <div className={`flex-1 ${theme.card} rounded-xl p-3 text-center`}>
                      <p className={`text-xs ${theme.muted}`}>X</p>
                      <p className={`font-medium text-sm ${theme.text}`}>@fan</p>
                    </div>
                    <div className={`flex-1 ${theme.card} rounded-xl p-3 text-center`}>
                      <p className={`text-xs ${theme.muted}`}>Insta</p>
                      <p className={`font-medium text-sm ${theme.text}`}>@fan</p>
                    </div>
                  </div>
                </div>

                {/* Theme label */}
                <div className="absolute -bottom-3 left-1/2 -translate-x-1/2">
                  <span className="px-3 py-1 bg-black/80 text-white text-xs font-medium rounded-full">
                    {theme.name} Theme
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Indicators */}
      <div className="flex items-center justify-center gap-2 mt-8">
        {themes.map((theme, index) => (
          <button
            key={theme.id}
            onClick={() => setCurrentIndex(index)}
            className={`w-2 h-2 rounded-full transition-all ${
              index === currentIndex
                ? "w-8 bg-purple-500"
                : "bg-white/30 hover:bg-white/50"
            }`}
            aria-label={`${theme.name} theme`}
          />
        ))}
      </div>
    </div>
  );
}
