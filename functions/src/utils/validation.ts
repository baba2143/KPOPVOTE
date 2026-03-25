/**
 * Validation utilities for K-VOTE COLLECTOR
 */

import { ValidationResult } from "../types";

/**
 * Validate email format
 * @param {string} email - Email address to validate
 * @return {ValidationResult} Validation result with error message if invalid
 */
export const validateEmail = (email: string): ValidationResult => {
  if (!email || typeof email !== "string") {
    return { valid: false, error: "Email is required" };
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return { valid: false, error: "Invalid email format" };
  }

  return { valid: true };
};

/**
 * Validate password strength
 * Requirements: At least 8 characters
 * @param {string} password - Password to validate
 * @return {ValidationResult} Validation result with error message if invalid
 */
export const validatePassword = (password: string): ValidationResult => {
  if (!password || typeof password !== "string") {
    return { valid: false, error: "Password is required" };
  }

  if (password.length < 8) {
    return {
      valid: false,
      error: "Password must be at least 8 characters long",
    };
  }

  return { valid: true };
};

/**
 * Validate display name
 * @param {string} displayName - Display name to validate (optional)
 * @return {ValidationResult} Validation result with error message if invalid
 */
export const validateDisplayName = (displayName?: string): ValidationResult => {
  if (!displayName) {
    return { valid: true }; // Optional field
  }

  if (typeof displayName !== "string") {
    return { valid: false, error: "Display name must be a string" };
  }

  if (displayName.length < 1 || displayName.length > 50) {
    return {
      valid: false,
      error: "Display name must be between 1 and 50 characters",
    };
  }

  return { valid: true };
};

/**
 * Validate URL format
 * @param {string} url - URL to validate
 * @return {ValidationResult} Validation result with error message if invalid
 */
export const validateURL = (url: string): ValidationResult => {
  if (!url || typeof url !== "string") {
    return { valid: false, error: "URL is required" };
  }

  try {
    new URL(url);
    return { valid: true };
  } catch (error) {
    return { valid: false, error: "Invalid URL format" };
  }
};

/**
 * Validate ISO 8601 date format
 * @param {string} dateString - Date string to validate (ISO 8601 format)
 * @return {ValidationResult} Validation result with error message if invalid
 */
export const validateISODate = (dateString: string): ValidationResult => {
  if (!dateString || typeof dateString !== "string") {
    return { valid: false, error: "Date is required" };
  }

  const date = new Date(dateString);
  if (isNaN(date.getTime())) {
    return { valid: false, error: "Invalid date format (ISO 8601 required)" };
  }

  return { valid: true };
};
