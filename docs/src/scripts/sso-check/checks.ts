/** One row of the SSO checker's report. Pure data so the rules stay testable outside a browser. */
export type CheckStatus = 'pass' | 'warn' | 'fail' | 'info';

export interface CheckValue {
  label: string;
  /** Rendered in the mono lane, left-to-right (URLs, IDs, dates). */
  value: string;
}

export interface Check {
  status: CheckStatus;
  title: string;
  detail?: string;
  values?: CheckValue[];
}

export const hasFailure = (checks: readonly Check[]) => checks.some(check => check.status === 'fail');

/** ISO calendar date: unambiguous across every locale the docs serve. */
export const isoDate = (date: Date) => date.toISOString().slice(0, 10);

/** Mirrors `OidcConfig.isIssuerAllowed` on the server: https, or http on loopback only. */
export function isTrustedHttpUrl(url: URL): boolean {
  if (url.protocol === 'https:') return url.hostname !== '';
  return url.protocol === 'http:' && isLoopbackHost(url.hostname);
}

export function isLoopbackHost(hostname: string): boolean {
  return hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '[::1]' || hostname === '::1';
}

export function tryUrl(value: string): URL | null {
  try {
    return new URL(value);
  } catch {
    return null;
  }
}

/** URL-safe random token, the same shape the server uses for state/nonce/verifier. */
export function randomToken(bytes = 32): string {
  const buffer = crypto.getRandomValues(new Uint8Array(bytes));
  return base64Url(buffer);
}

export function base64(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.length; i += 0x8000) binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  return btoa(binary);
}

export const base64Url = (bytes: Uint8Array) => base64(bytes).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
