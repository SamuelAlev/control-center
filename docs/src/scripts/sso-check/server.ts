/**
 * The checker's one request to the reader's own Control Center server:
 * `GET /auth/providers`, the unauthenticated, CORS-open probe the connect
 * screens use. It carries connection ids/kinds/labels only, so asking it
 * reveals nothing the login screen would not.
 */
import { isLoopbackHost, tryUrl, type Check } from './checks.ts';

export type SsoKind = 'saml' | 'oidc';

const LABEL: Record<SsoKind, string> = { saml: 'SAML', oidc: 'OpenID Connect' };
const TOGGLE: Record<SsoKind, string> = { saml: 'Use SAML for sign-in', oidc: 'Use OpenID Connect for sign-in' };

/** Accepts `cc.example.com`, `https://cc.example.com/any/path` and the like; returns the bare origin. */
export function normalizeOrigin(input: string): { origin: string } | { error: string } {
  const trimmed = input.trim();
  if (!trimmed) return { error: 'Enter the address your users open.' };
  const url = tryUrl(/^[a-z][a-z0-9+.-]*:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`);
  if (!url || (url.protocol !== 'https:' && url.protocol !== 'http:') || !url.hostname) {
    return { error: 'Enter an http(s) address, like https://cc.example.com.' };
  }
  return { origin: url.origin };
}

/** An https page cannot fetch a plain-http origin unless it is loopback (mixed content). */
export function blockedAsMixedContent(pageProtocol: string, origin: string): boolean {
  const url = new URL(origin);
  return pageProtocol === 'https:' && url.protocol === 'http:' && !isLoopbackHost(url.hostname);
}

export function evaluateProviders(body: unknown, kind: SsoKind, origin: string): Check {
  const providers = (body as { providers?: unknown } | null)?.providers;
  if (!Array.isArray(providers)) {
    return {
      status: 'warn',
      title: 'That address answered, but not like a Control Center server',
      detail: `${origin}/auth/providers did not return a provider list. Check that the address points at the server itself, not a proxy page or the web client host.`,
    };
  }
  const offered = providers.some(provider => (provider as { kind?: unknown })?.kind === kind);
  return offered
    ? {
        status: 'pass',
        title: `Server reachable, ${LABEL[kind]} sign-in is on`,
        detail: 'Your browser reached the server and it offers this sign-in method on the connect screen.',
        values: [{ label: 'Server', value: origin }],
      }
    : {
        status: 'warn',
        title: `Server reachable, but ${LABEL[kind]} sign-in is off`,
        detail: `Turn on "${TOGGLE[kind]}" in Settings → Server → Single sign-on and save. Until then the server refuses ${LABEL[kind]} logins.`,
        values: [{ label: 'Server', value: origin }],
      };
}

export async function probeServer(origin: string, kind: SsoKind, pageProtocol: string): Promise<Check> {
  if (blockedAsMixedContent(pageProtocol, origin)) {
    return {
      status: 'info',
      title: 'Server not checked from this page',
      detail: 'This page is served over https, so your browser blocks requests to a plain-http address. Your users are unaffected; use Test connection in the app instead.',
      values: [{ label: 'Server', value: origin }],
    };
  }
  let response: Response;
  try {
    response = await fetch(`${origin}/auth/providers`, {
      credentials: 'omit',
      cache: 'no-store',
      signal: AbortSignal.timeout(10_000),
    });
  } catch {
    return {
      status: 'warn',
      title: 'Could not reach the server from this browser',
      detail: 'Sign-in needs your users\' browsers to reach this address. Check it is the address they open and that the server is running. If your browser asked for permission to access devices on your local network, allow it and check again.',
      values: [{ label: 'Server', value: origin }],
    };
  }
  if (!response.ok) {
    return {
      status: 'warn',
      title: `The server answered HTTP ${response.status}`,
      detail: `${origin}/auth/providers should answer 200. Check that the address points at the Control Center server and not a proxy in front of it.`,
    };
  }
  let body: unknown = null;
  try {
    body = await response.json();
  } catch {
    // Reported by evaluateProviders as "not like a Control Center server".
  }
  return evaluateProviders(body, kind, origin);
}
