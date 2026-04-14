"use client";

import { useEffect, useRef, useState, ReactNode } from "react";

interface FeatureSectionProps {
  badge?: string;
  title: string;
  description: string;
  children: ReactNode;
  reverse?: boolean;
}

export default function FeatureSection({
  badge,
  title,
  description,
  children,
  reverse = false,
}: FeatureSectionProps) {
  const [isVisible, setIsVisible] = useState(false);
  const sectionRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
        }
      },
      { threshold: 0.15 }
    );

    if (sectionRef.current) {
      observer.observe(sectionRef.current);
    }

    return () => observer.disconnect();
  }, []);

  return (
    <section
      ref={sectionRef}
      className="py-32 md:py-40 bg-black relative overflow-hidden"
    >
      {/* Subtle gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-zinc-950/50 to-black" />

      <div className="relative z-10 max-w-7xl mx-auto px-6">
        <div
          className={`flex flex-col ${
            reverse ? "lg:flex-row-reverse" : "lg:flex-row"
          } gap-16 lg:gap-24 items-center`}
        >
          {/* Text content */}
          <div
            className={`flex-1 transition-all duration-700 ${
              isVisible
                ? "opacity-100 translate-y-0"
                : "opacity-0 translate-y-8"
            }`}
          >
            {badge && (
              <span className="inline-block text-xs text-zinc-500 tracking-widest uppercase mb-4">
                {badge}
              </span>
            )}
            <h2 className="text-4xl md:text-5xl lg:text-6xl font-bold text-white leading-[1.1] tracking-tight mb-6">
              {title}
            </h2>
            <p className="text-lg text-zinc-400 leading-relaxed max-w-lg">
              {description}
            </p>
          </div>

          {/* Visual content */}
          <div
            className={`flex-1 transition-all duration-700 delay-200 ${
              isVisible
                ? "opacity-100 translate-y-0"
                : "opacity-0 translate-y-8"
            }`}
          >
            {children}
          </div>
        </div>
      </div>
    </section>
  );
}
