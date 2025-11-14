/**
 * External App Master types
 */

export interface ExternalAppMaster {
  appId: string;
  appName: string;
  appUrl?: string;
  iconUrl?: string;
  createdAt?: string;
}

export interface ExternalAppCreateRequest {
  appName: string;
  appUrl?: string;
  iconUrl?: string;
}

export interface ExternalAppUpdateRequest {
  appName?: string;
  appUrl?: string;
  iconUrl?: string;
}
