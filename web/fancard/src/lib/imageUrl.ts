/**
 * Normalize Firebase Storage URLs by removing :443 port
 * which can cause issues with Next.js Image component
 */
export function normalizeImageUrl(url: string | undefined | null): string | undefined {
  if (!url) return undefined;

  // Remove :443 port from Firebase Storage URLs
  // Example: https://firebasestorage.googleapis.com:443/v0/b/...
  // becomes: https://firebasestorage.googleapis.com/v0/b/...
  return url.replace(/:443(?=\/)/g, '');
}
