/**
 * Idol Master type definitions
 */

export interface IdolMaster {
  idolId: string;
  name: string;
  groupName: string;
  imageUrl: string | null;
  createdAt: string | null;
  updatedAt: string | null;
}

export interface IdolCreateRequest {
  name: string;
  groupName: string;
  imageUrl?: string;
}

export interface IdolUpdateRequest {
  idolId: string;
  name?: string;
  groupName?: string;
  imageUrl?: string;
}
