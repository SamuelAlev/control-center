/**
 * OpenID Connect half of the manual's SSO checker. Mirrors `OidcService` on
 * the server: the issuer trust rule, the discovery URL, the same-origin
 * endpoint rule and the exact authorization request (code + PKCE S256,
 * `openid profile email`). The client secret is never asked for; whether
 * one exists is enough to check the token-endpoint auth method.
 */
import { base64Url, isTrustedHttpUrl, randomToken, tryUrl, type Check } from './checks.ts';

const WELL_KNOWN = '/.well-known/openid-configuration';
export const OIDC_SCOPES = ['openid', 'profile', 'email'] as const;
/** Same bound as `OidcService._maxDiscoveryBytes`. */
export const MAX_DISCOVERY_BYTES = 64 * 1024;

const trimTrailingSlash = (value: string) => (value.endsWith('/') ? value.slice(0, -1) : value);

export function normalizeIssuer(input: string): { issuer: string } | { error: string } {
  const issuer = input.trim();
  if (!issuer) return { error: 'Enter your issuer URL.' };
  if (trimTrailingSlash(issuer).endsWith(WELL_KNOWN)) {
    return { error: `Enter the issuer itself: ${trimTrailingSlash(issuer).slice(0, -WELL_KNOWN.length) || issuer}, without ${WELL_KNOWN}.` };
  }
  const url = tryUrl(issuer);
  if (!url || !url.hostname) return { error: 'Enter a full URL, like https://id.example.com.' };
  if (!isTrustedHttpUrl(url)) {
    return { error: 'The issuer must use https. Plain http is accepted only for localhost, 127.0.0.1 and ::1.' };
  }
  return { issuer };
}

/** `<issuer>/.well-known/openid-configuration`, trailing slash trimmed like the server. */
export const discoveryUrl = (issuer: string) => `${trimTrailingSlash(issuer)}${WELL_KNOWN}`;

export interface OidcOptions {
  issuer: string;
  confidential: boolean;
  groupsClaim: string;
}

const stringList = (value: unknown): string[] | null =>
  Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : null;

const effectivePort = (url: URL) => url.port || (url.protocol === 'https:' ? '443' : url.protocol === 'http:' ? '80' : '');

/** Same rule as `OidcService._trustedEndpoints`: the endpoint stays on the issuer's scheme, host and port. */
export function endpointProblem(value: unknown, issuer: string): string | null {
  if (typeof value !== 'string' || !value) return 'missing';
  const endpoint = tryUrl(value);
  const origin = new URL(issuer);
  if (!endpoint || !isTrustedHttpUrl(endpoint)) return 'not an https URL';
  if (endpoint.username || endpoint.password) return 'carries credentials';
  if (endpoint.hash) return 'has a fragment';
  if (endpoint.protocol !== origin.protocol || endpoint.hostname !== origin.hostname || effectivePort(endpoint) !== effectivePort(origin)) {
    return `on ${endpoint.host}, not ${origin.host}`;
  }
  return null;
}

export function evaluateDiscovery(doc: unknown, options: OidcOptions): Check[] {
  if (typeof doc !== 'object' || doc === null || Array.isArray(doc)) {
    return [{ status: 'fail', title: 'The discovery document is not a JSON object' }];
  }
  const d = doc as Record<string, unknown>;
  const checks: Check[] = [];

  if (typeof d.issuer !== 'string') {
    checks.push({ status: 'fail', title: 'The document has no issuer', detail: 'Every discovery document must state its issuer. Check that the URL points at an OpenID Connect provider.' });
  } else if (trimTrailingSlash(d.issuer) !== trimTrailingSlash(options.issuer)) {
    checks.push({
      status: 'fail',
      title: 'The issuer does not match',
      detail: `Tokens from this provider carry iss=${d.issuer}, and the server refuses tokens whose issuer differs from the one you configure. Use the issuer exactly as the document states it.`,
      values: [
        { label: 'You entered', value: options.issuer },
        { label: 'Document says', value: d.issuer },
      ],
    });
  } else {
    checks.push({ status: 'pass', title: 'Issuer matches', values: [{ label: 'Issuer', value: d.issuer }] });
  }

  const endpointProblems = [
    ['Authorization endpoint', d.authorization_endpoint],
    ['Token endpoint', d.token_endpoint],
  ].flatMap(([label, value]) => {
    const problem = endpointProblem(value, options.issuer);
    return problem ? [{ label: label as string, value: typeof value === 'string' ? `${value} (${problem})` : problem }] : [];
  });
  if (endpointProblems.length) {
    checks.push({
      status: 'fail',
      title: 'Endpoints the server will not use',
      detail: 'The server reads identities straight from the token endpoint and trusts them because the TLS connection to your issuer vouches for them. So both endpoints must be https and on the issuer\'s own host and port.',
      values: endpointProblems,
    });
  } else {
    checks.push({
      status: 'pass',
      title: 'Endpoints are on the issuer\'s origin',
      values: [
        { label: 'Authorization', value: d.authorization_endpoint as string },
        { label: 'Token', value: d.token_endpoint as string },
      ],
    });
  }

  const responseTypes = stringList(d.response_types_supported);
  if (responseTypes && !responseTypes.some(type => type.split(' ').includes('code'))) {
    checks.push({
      status: 'fail',
      title: 'Authorization code flow is not supported',
      detail: `Control Center signs in with response_type=code. This provider lists only: ${responseTypes.join(', ') || 'nothing'}.`,
    });
  }

  const pkce = stringList(d.code_challenge_methods_supported);
  if (!pkce) {
    checks.push({
      status: 'warn',
      title: 'PKCE support is not advertised',
      detail: 'Control Center always sends a PKCE S256 challenge. Many providers support it without saying so; if logins fail at the token step, enable PKCE for the client.',
    });
  } else if (!pkce.includes('S256')) {
    checks.push({ status: 'fail', title: 'PKCE S256 is not supported', detail: `Control Center sends S256 challenges. This provider lists only: ${pkce.join(', ') || 'nothing'}.` });
  } else {
    checks.push({ status: 'pass', title: 'PKCE S256 is supported' });
  }

  const scopes = stringList(d.scopes_supported);
  const missingScopes = scopes ? OIDC_SCOPES.filter(scope => !scopes.includes(scope)) : [];
  if (missingScopes.length) {
    checks.push({
      status: 'warn',
      title: `Scope ${missingScopes.join(', ')} is not advertised`,
      detail: 'Control Center requests openid profile email. Allow these scopes on the client, or the provider may refuse the login.',
    });
  }

  const listedMethods = stringList(d.token_endpoint_auth_methods_supported);
  // OpenID Connect Discovery §3: an absent list means client_secret_basic only.
  const methods = listedMethods ?? ['client_secret_basic'];
  if (options.confidential) {
    if (methods.includes('client_secret_post')) {
      checks.push({ status: 'pass', title: 'The client secret can be sent as client_secret_post' });
    } else {
      checks.push({
        status: listedMethods ? 'fail' : 'warn',
        title: 'client_secret_post is not advertised',
        detail: `Control Center sends the client secret in the token request body (client_secret_post). ${listedMethods ? `This provider lists only: ${listedMethods.join(', ')}.` : 'This provider does not list its methods, which by default means client_secret_basic only.'} Allow client_secret_post on the client, or switch it to a public PKCE client.`,
      });
    }
  } else if (methods.includes('none')) {
    checks.push({ status: 'pass', title: 'Public clients are supported' });
  } else {
    checks.push({
      status: 'warn',
      title: 'Public clients are not advertised',
      detail: 'This provider does not list the "none" token auth method. If the login fails with invalid_client, the client needs a secret: paste it into Client secret in the app and choose Confidential here.',
    });
  }

  const claims = stringList(d.claims_supported);
  if (claims) {
    if (!claims.includes('email')) {
      checks.push({
        status: 'warn',
        title: 'The email claim is not advertised',
        detail: 'Control Center names new accounts after the email claim. Without it, check that the client\'s ID token includes email.',
      });
    }
    if (!claims.includes('email_verified')) {
      checks.push({
        status: 'info',
        title: 'The email_verified claim is not advertised',
        detail: 'A first login matches an existing account by email only when email_verified is true. Without it, the login creates a new account instead.',
      });
    }
    const groupsClaim = options.groupsClaim.trim() || 'groups';
    if (!claims.includes(groupsClaim)) {
      checks.push({
        status: 'info',
        title: `The ${groupsClaim} claim is not advertised`,
        detail: 'Group-to-role mapping reads it from the ID token. Providers often leave custom claims out of this list, so confirm it on a real token before relying on group mapping.',
      });
    }
  }
  return checks;
}

export type DiscoveryResult =
  | { ok: true; doc: unknown }
  /** `unreadable`: the browser could not read the response at all (CORS, DNS, offline), so pasting it is the way forward. */
  | { ok: false; check: Check; unreadable: boolean };

/** Parses pasted or fetched discovery text with the server's size bound. */
export function parseDiscovery(text: string): DiscoveryResult {
  if (new TextEncoder().encode(text).length > MAX_DISCOVERY_BYTES) {
    return { ok: false, unreadable: false, check: { status: 'fail', title: 'The discovery document is over 64 KB', detail: 'The server refuses discovery documents this large.' } };
  }
  try {
    return { ok: true, doc: JSON.parse(text) };
  } catch {
    return { ok: false, unreadable: false, check: { status: 'fail', title: 'The discovery document is not valid JSON' } };
  }
}

/** Fetches discovery from the reader's browser, refusing redirects like the server does. */
export async function fetchDiscovery(issuer: string): Promise<DiscoveryResult> {
  const url = discoveryUrl(issuer);
  let response: Response;
  try {
    response = await fetch(url, { credentials: 'omit', cache: 'no-store', redirect: 'manual', signal: AbortSignal.timeout(15_000) });
  } catch {
    return {
      ok: false,
      unreadable: true,
      check: {
        status: 'warn',
        title: 'Your browser could not read the discovery document',
        detail: 'Either the issuer URL is wrong, or the provider does not let other sites read it (CORS), which Okta and some others restrict. Your server fetches it directly, so this alone does not break sign-in. Open the URL, then paste what it shows below to finish the check.',
        values: [{ label: 'Discovery URL', value: url }],
      },
    };
  }
  if (response.type === 'opaqueredirect' || (response.status >= 300 && response.status < 400)) {
    return {
      ok: false,
      unreadable: false,
      check: {
        status: 'fail',
        title: 'The discovery URL redirects',
        detail: 'The server does not follow redirects for discovery. Use the issuer the provider redirects to, exactly as its discovery document states it.',
        values: [{ label: 'Discovery URL', value: url }],
      },
    };
  }
  if (response.status !== 200) {
    return {
      ok: false,
      unreadable: false,
      check: {
        status: 'fail',
        title: `The discovery URL answered HTTP ${response.status}`,
        detail: 'Check the issuer URL. For Keycloak it includes the realm, like https://id.example.com/realms/acme.',
        values: [{ label: 'Discovery URL', value: url }],
      },
    };
  }
  return parseDiscovery(await response.text());
}

/** The authorization request the server builds in `OidcService.beginLogin`, with a throwaway state, nonce and PKCE pair. */
export async function oidcTestSignInUrl(options: { authorizationEndpoint: string; clientId: string; redirectUri: string }): Promise<string> {
  const verifier = randomToken() + randomToken();
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier));
  const url = new URL(options.authorizationEndpoint);
  // Replaces any existing query, as Dart's `Uri.replace(queryParameters:)` does on the server.
  url.search = new URLSearchParams({
    response_type: 'code',
    client_id: options.clientId,
    redirect_uri: options.redirectUri,
    scope: OIDC_SCOPES.join(' '),
    state: randomToken(),
    nonce: randomToken(),
    code_challenge: base64Url(new Uint8Array(digest)),
    code_challenge_method: 'S256',
  }).toString();
  return url.toString();
}
