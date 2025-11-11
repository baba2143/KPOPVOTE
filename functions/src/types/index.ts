/**
 * Type definitions for K-VOTE COLLECTOR
 */

// User related types
export interface UserProfile {
  uid: string;
  email: string;
  displayName?: string;
  photoURL?: string;
  myBias: BiasSettings[];
  createdAt: Date;
  updatedAt: Date;
}

export interface BiasSettings {
  artistId: string;
  artistName: string;
  memberIds: string[];
  memberNames: string[];
}

// Auth related types
export interface RegisterRequest {
  email: string;
  password: string;
  displayName?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  uid: string;
  email: string;
  displayName?: string;
  token: string;
}

// Task related types
export interface Task {
  taskId: string;
  userId: string;
  title: string;
  url: string;
  deadline: Date;
  targetMembers: string[];
  isCompleted: boolean;
  completedAt?: Date;
  ogpTitle?: string;
  ogpImage?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface TaskRegisterRequest {
  title: string;
  url: string;
  deadline: string; // ISO 8601 format
  targetMembers?: string[];
}

export interface TaskUpdateStatusRequest {
  taskId: string;
  isCompleted: boolean;
}

// API response types
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// Task response types
export interface TaskRegisterResponse {
  taskId: string;
  title: string;
  url: string;
  deadline: string;
  targetMembers: string[];
  isCompleted: boolean;
  completedAt: null;
  ogpTitle: null;
  ogpImage: null;
}

export interface TaskData {
  taskId: string;
  title: string;
  url: string;
  deadline: string;
  targetMembers: string[];
  isCompleted: boolean;
  completedAt: string | null;
  ogpTitle: string | null;
  ogpImage: string | null;
  createdAt: string | null;
  updatedAt: string | null;
}

export interface TasksResponse {
  tasks: TaskData[];
  count: number;
}

export interface TaskOGPResponse {
  taskId: string;
  ogpTitle: string | null;
  ogpImage: string | null;
}

export interface TaskStatusResponse {
  taskId: string;
  isCompleted: boolean;
  completedAt: string | null;
  updatedAt: string | null;
}

// Validation result
export interface ValidationResult {
  valid: boolean;
  error?: string;
}
