/**
 * Theme utilities for FanCard
 */

import { FanCardTemplate, FanCardTheme } from "@/types/fancard";

export interface ThemeColors {
  background: string;
  text: string;
  muted: string;
  card: string;
  border: string;
}

export const THEME_PRESETS: Record<FanCardTemplate, ThemeColors> = {
  default: {
    background: "#ffffff",
    text: "#1f2937",
    muted: "#6b7280",
    card: "#f9fafb",
    border: "#e5e7eb",
  },
  cute: {
    background: "#fdf2f8",
    text: "#831843",
    muted: "#be185d",
    card: "#fce7f3",
    border: "#fbcfe8",
  },
  cool: {
    background: "#f0f9ff",
    text: "#0c4a6e",
    muted: "#0369a1",
    card: "#e0f2fe",
    border: "#bae6fd",
  },
  elegant: {
    background: "#faf5ff",
    text: "#581c87",
    muted: "#7e22ce",
    card: "#f3e8ff",
    border: "#e9d5ff",
  },
  dark: {
    background: "#0f0f0f",
    text: "#f3f4f6",
    muted: "#9ca3af",
    card: "#1f1f1f",
    border: "#374151",
  },
};

/**
 * Get theme colors based on theme settings
 */
export function getThemeColors(theme: FanCardTheme): ThemeColors {
  const preset = THEME_PRESETS[theme.template] || THEME_PRESETS.default;

  // Override background if custom color is set
  if (theme.backgroundColor && theme.backgroundColor !== preset.background) {
    return {
      ...preset,
      background: theme.backgroundColor,
    };
  }

  return preset;
}

/**
 * Get CSS class for theme
 */
export function getThemeClass(template: FanCardTemplate): string {
  return `theme-${template}`;
}

/**
 * Get font family class
 */
export function getFontClass(fontFamily: string): string {
  switch (fontFamily) {
    case "rounded":
      return "font-rounded";
    case "serif":
      return "font-serif";
    default:
      return "font-sans";
  }
}
