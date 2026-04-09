/**
 * FanCard - 推し活名刺 Type Definitions
 */

import { Timestamp } from "firebase-admin/firestore";

// ============================================
// Theme Types
// ============================================

export type FanCardTemplate = "default" | "cute" | "cool" | "elegant" | "dark";
export type FanCardFontFamily = "default" | "rounded" | "serif";

export interface FanCardTheme {
  template: FanCardTemplate;
  backgroundColor: string; // HEX color code (e.g., "#FFFFFF")
  primaryColor: string; // Accent color (e.g., "#9333EA")
  fontFamily: FanCardFontFamily;
}

// ============================================
// Block Types
// ============================================

export type FanCardBlockType =
  | "bias"
  | "link"
  | "mvLink"
  | "sns"
  | "text"
  | "image";

export type SNSPlatform =
  | "x"
  | "instagram"
  | "tiktok"
  | "youtube"
  | "threads"
  | "other";

// Base block interface
interface BaseBlock {
  id: string; // UUID
  order: number; // Display order
  isVisible: boolean; // Show/hide toggle
}

// Bias block - Display favorite members
export interface BiasBlockData {
  showFromMyBias: boolean; // Auto-fetch from user's myBias
  customBias?: {
    artistId: string;
    artistName: string;
    memberId?: string;
    memberName?: string;
    imageUrl?: string;
  }[];
}

export interface BiasBlock extends BaseBlock {
  type: "bias";
  data: BiasBlockData;
}

// Link block - Custom link button
export interface LinkBlockData {
  title: string; // Max 50 chars
  url: string;
  iconUrl?: string; // Custom icon
  backgroundColor?: string; // Button background color
}

export interface LinkBlock extends BaseBlock {
  type: "link";
  data: LinkBlockData;
}

// MV Link block - YouTube embed
export interface MVLinkBlockData {
  title: string; // MV name
  youtubeUrl: string; // Full YouTube URL
  thumbnailUrl?: string; // Auto-fetched thumbnail
  artistName?: string;
}

export interface MVLinkBlock extends BaseBlock {
  type: "mvLink";
  data: MVLinkBlockData;
}

// SNS block - Social media links
export interface SNSBlockData {
  platform: SNSPlatform;
  username: string; // Without @
  url: string; // Full profile URL
}

export interface SNSBlock extends BaseBlock {
  type: "sns";
  data: SNSBlockData;
}

// Text block - Custom text content
export interface TextBlockData {
  content: string; // Max 500 chars
  alignment: "left" | "center" | "right";
}

export interface TextBlock extends BaseBlock {
  type: "text";
  data: TextBlockData;
}

// Image block - Custom image
export interface ImageBlockData {
  imageUrl: string;
  caption?: string;
  linkUrl?: string; // Optional click-through link
}

export interface ImageBlock extends BaseBlock {
  type: "image";
  data: ImageBlockData;
}

// Union type for all blocks
export type FanCardBlock =
  | BiasBlock
  | LinkBlock
  | MVLinkBlock
  | SNSBlock
  | TextBlock
  | ImageBlock;

// ============================================
// FanCard Document
// ============================================

export interface FanCard {
  // Identifiers
  odDisplayName: string; // URL slug (unique, lowercase alphanumeric + hyphen)
  userId: string; // Owner's UID

  // Profile
  displayName: string; // Display name (max 30 chars)
  bio: string; // Bio text (max 200 chars)
  profileImageUrl: string; // Avatar image URL
  headerImageUrl: string; // Header/cover image URL

  // Design
  theme: FanCardTheme;

  // Content
  blocks: FanCardBlock[]; // Max 20 blocks

  // Visibility
  isPublic: boolean;

  // Analytics
  viewCount: number;

  // Timestamps
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ============================================
// API Request Types
// ============================================

export interface FanCardCreateRequest {
  odDisplayName: string; // Required, unique URL slug
  displayName: string; // Required
  bio?: string;
  profileImageUrl?: string;
  headerImageUrl?: string;
  theme?: Partial<FanCardTheme>;
}

export interface FanCardUpdateRequest {
  displayName?: string;
  bio?: string;
  profileImageUrl?: string;
  headerImageUrl?: string;
  theme?: Partial<FanCardTheme>;
  blocks?: FanCardBlock[];
  isPublic?: boolean;
}

export interface FanCardCheckOdDisplayNameRequest {
  odDisplayName: string;
}

export interface FanCardGetByOdDisplayNameRequest {
  odDisplayName: string;
}

// ============================================
// API Response Types
// ============================================

export interface FanCardResponse {
  odDisplayName: string;
  userId: string;
  displayName: string;
  bio: string;
  profileImageUrl: string;
  headerImageUrl: string;
  theme: FanCardTheme;
  blocks: FanCardBlock[];
  isPublic: boolean;
  viewCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface FanCardCreateResponse {
  fanCard: FanCardResponse;
}

export interface FanCardGetResponse {
  fanCard: FanCardResponse | null;
  hasFanCard: boolean;
}

export interface FanCardCheckOdDisplayNameResponse {
  available: boolean;
  suggestion?: string; // Alternative suggestion if not available
}

export interface FanCardPublicResponse {
  fanCard: FanCardResponse;
  // Additional data for public view
  userDisplayName?: string;
  userPhotoURL?: string;
  myBias?: {
    artistId: string;
    artistName: string;
    memberIds: string[];
    memberNames: string[];
  }[];
}

// ============================================
// Validation Constants
// ============================================

export const FANCARD_LIMITS = {
  OD_DISPLAY_NAME_MIN: 3,
  OD_DISPLAY_NAME_MAX: 30,
  DISPLAY_NAME_MAX: 30,
  BIO_MAX: 200,
  BLOCKS_MAX: 20,
  LINK_TITLE_MAX: 50,
  TEXT_CONTENT_MAX: 500,
  IMAGE_MAX_SIZE_MB: 5,
} as const;

// Regex for odDisplayName validation (lowercase alphanumeric + hyphen)
export const OD_DISPLAY_NAME_REGEX = /^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$/;

// Reserved names that cannot be used
export const RESERVED_OD_DISPLAY_NAMES = [
  "admin",
  "api",
  "app",
  "auth",
  "callback",
  "create",
  "delete",
  "edit",
  "fancard",
  "help",
  "home",
  "login",
  "logout",
  "new",
  "null",
  "profile",
  "register",
  "settings",
  "signup",
  "support",
  "undefined",
  "update",
  "user",
  "www",
];

// Default theme
export const DEFAULT_FANCARD_THEME: FanCardTheme = {
  template: "default",
  backgroundColor: "#FFFFFF",
  primaryColor: "#9333EA", // Purple
  fontFamily: "default",
};
