/**
 * Group Master type definitions
 */

export interface GroupMaster {
  groupId: string;
  name: string;
  imageUrl: string | null;
  createdAt: string | null;
  updatedAt: string | null;
}

export interface GroupCreateRequest {
  name: string;
  imageUrl?: string;
}

export interface GroupUpdateRequest {
  groupId: string;
  name?: string;
  imageUrl?: string;
}
