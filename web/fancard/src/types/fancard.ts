/**
 * FanCard Types for Web Frontend
 * Mirrors the backend types for type safety
 */

export type FanCardTemplate = "default" | "cute" | "cool" | "elegant" | "dark";
export type FanCardFontFamily = "default" | "rounded" | "serif";

export interface FanCardTheme {
  template: FanCardTemplate;
  backgroundColor: string;
  primaryColor: string;
  fontFamily: FanCardFontFamily;
}

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

interface BaseBlock {
  id: string;
  order: number;
  isVisible: boolean;
}

export interface BiasBlockData {
  showFromMyBias: boolean;
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

export interface LinkBlockData {
  title: string;
  url: string;
  iconUrl?: string;
  backgroundColor?: string;
}

export interface LinkBlock extends BaseBlock {
  type: "link";
  data: LinkBlockData;
}

export interface MVLinkBlockData {
  title: string;
  youtubeUrl: string;
  thumbnailUrl?: string;
  artistName?: string;
}

export interface MVLinkBlock extends BaseBlock {
  type: "mvLink";
  data: MVLinkBlockData;
}

export interface SNSBlockData {
  platform: SNSPlatform;
  username: string;
  url: string;
}

export interface SNSBlock extends BaseBlock {
  type: "sns";
  data: SNSBlockData;
}

export interface TextBlockData {
  content: string;
  alignment: "left" | "center" | "right";
}

export interface TextBlock extends BaseBlock {
  type: "text";
  data: TextBlockData;
}

export interface ImageBlockData {
  imageUrl: string;
  caption?: string;
  linkUrl?: string;
}

export interface ImageBlock extends BaseBlock {
  type: "image";
  data: ImageBlockData;
}

export type FanCardBlock =
  | BiasBlock
  | LinkBlock
  | MVLinkBlock
  | SNSBlock
  | TextBlock
  | ImageBlock;

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

export interface BiasSettings {
  artistId: string;
  artistName: string;
  memberIds: string[];
  memberNames: string[];
}

export interface FanCardPublicData {
  fanCard: FanCardResponse;
  userDisplayName?: string;
  userPhotoURL?: string;
  myBias?: BiasSettings[];
}
