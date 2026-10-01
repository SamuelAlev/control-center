import assert from 'node:assert/strict';
import { X509Certificate, createHash } from 'node:crypto';
import { inflateRawSync } from 'node:zlib';
import { describe, it } from 'node:test';
import { parseCertificate } from '../src/scripts/sso-check/x509.ts';
import { authnRequestXml, evaluateSamlMetadata, HTTP_REDIRECT, samlTestSignInUrl, type SamlMetadata } from '../src/scripts/sso-check/saml.ts';
import { discoveryUrl, endpointProblem, evaluateDiscovery, normalizeIssuer, oidcTestSignInUrl, parseDiscovery } from '../src/scripts/sso-check/oidc.ts';
import { blockedAsMixedContent, evaluateProviders, normalizeOrigin } from '../src/scripts/sso-check/server.ts';
import type { Check } from '../src/scripts/sso-check/checks.ts';

// Self-signed fixtures (openssl req -x509). RSA: v1, UTCTime → GeneralizedTime
// (expires 2052). EC: v3 with extensions, P-256, expires 2036. RSA3: 3072-bit,
// UTF-8 subject.
const RSA_CERT = 'MIICrjCCAZYCCQDOwSNu7WaJGDANBgkqhkiG9w0BAQsFADAYMRYwFAYDVQQDDA1zc28tY2hlY2stcnNhMCAXDTI2MTAwMTE5MjMzN1oYDzIwNTIxMDA0MTkyMzM3WjAYMRYwFAYDVQQDDA1zc28tY2hlY2stcnNhMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAuHePnUzdKmcKSnx1gp9xHm391+TvU6Krx7BLCYDlVVYoPWxAdzXDtNW0jpvU9YHVCA1elzTRGiyVVemowd7/seIpa/ERgSHo5fZXFDz+o/4JlTtkkHj4jwEFs2rEZDRaf3A+jUGD0vtSPKP4qdo+1/EjtSGjjPZdeRLtMOlIkiFGxJ2cQjNiETq5jPU/gP7AbC6qFtCbdG+fCir+gZapB2mXoe2ke0DrtEM8SSbPjnp9FkxC5PEOlD2lIvwo/m3OxsqWDGu/rR6jhn9cdEZt6wCAFdeLenv9fwu/VMMf0z2Wuki7RXe7vwNcz/NsArTM9HWzZxiEj6Xbh4MHNcXTRwIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQCMtN5ABVaD3GIcpOCAGE3kJliQAGLk8f24zDJ36rYLR+yCABfKn1iH1wNzPlhmAp1v0pVtpUewfiXJp3k/NFHTygDi5y8IU9oVA/IggpAW3/rFqy8OvI3sp+W0+YDQDT8vQRmDikN2FqFN3uM9J21guSHZfdOh6YzV2ZJ/5nY3Nyreb+jWMhF0+yRFoIOweh6aDTB/ah4U0glevMEjXOLfyY5RQfVinF8z6P44vuC2oi+Ep75hqJv50IdwV0wW1OfJR2nDB6PQ6Pk6TwdDdNBP+S3/VqzxdPE2Mo+mvZK4QiF6mR8iz/XCe1fwDvzC95b8dzZJMHNQGSQ/OI8D55O+';
const EC_CERT = 'MIIBMTCB2KADAgECAgkAi+EUr1VV7vwwCgYIKoZIzj0EAwIwFzEVMBMGA1UEAwwMc3NvLWNoZWNrLWVjMB4XDTI2MTAwMTE5MjcyNloXDTM2MDkyODE5MjcyNlowFzEVMBMGA1UEAwwMc3NvLWNoZWNrLWVjMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEE65A9l4GpUaCQS6LzTe/4ZM0CCZNI8Gp5WFRbhTZONQQI9QERE13eZXxFs+tzh246rZ2ta3JOPapokuZrmh8iqMNMAswCQYDVR0TBAIwADAKBggqhkjOPQQDAgNIADBFAiEAtWdRuzPM1jNfEL1HSbTWonNRL6IjoXdtFdo1UcPObIUCIFchpNR8boN2pTBZJAFbtAnANaivvK/2vUfnlSBrXflB';
const RSA3_CERT = 'MIIDrjCCAhYCCQDBEjIN78F/WTANBgkqhkiG9w0BAQsFADAZMRcwFQYDVQQDDA7DnG7Dr2NvZGUgVGVzdDAeFw0yNjEwMDExOTIzMzFaFw0zNjA5MjgxOTIzMzFaMBkxFzAVBgNVBAMMDsOcbsOvY29kZSBUZXN0MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEA2CWYmbVvjLfT2iTLlICW8NNoEgWWo2c3NNfYRi1Z/KTzeR9DNSLjKvISwZ7RIaD+MGUJENNV4ozvzUM427qsRUslOC66bfmwGD4W/SunwHK+3XXHUv68t1FZrtk0Wt6CctDiA85bqZi2Dd6NKn41HfWvAkghL67GM4+BFK4GO8C/X42ze4PppIB9m7KjQDAzig1mIUsyBn1MMZPufHLny2IMBDkVEQzR9UqqrA+rn89WR0+CumIiJhDbiptRMSbjccDYv9PXbT20pPqdusKoApXXMsEn2lP8iKBwYgUD7mXxdhnnqieUeuCS7oToEgZSpTQ/Jk12EThptIGgsozA1CD38iTCVqf5ml5WOuQjPlNKv8ixvgjnnkCqgarsEh8xJg/iASs5lHFMqNXZIoQzHLJMJTSYnBZFPwv3TreE4ddehW5lwaynLPbHVwj7YdIauwlOm4Et6CIeHHpO7v+v/QkDVYdSKBnNqqKpYB4uKckMlik4go7GgXVyGDBMgjTnAgMBAAEwDQYJKoZIhvcNAQELBQADggGBAKC5y7isJwj2NKUdqHds/v0k8rdKH0t+RzXl8+wmnHvgQ2Nn8YV3dqdsFV/kEqOwdg4Li8NQz0mODLh2hh2jxfzfT5yIIygM554Gk807/ioGnh+0yKk2Cs/Yq8AGw+hWz7WBscYYFzcKugdDsiju7fYZSqHZetMrfqPBYWnxl8DWon/9phL2M0t0V9vO0AaNjRQdarg/V/u2reWN/mAF7TD7Day7VWZ6LuSkUiIXrq20m02PW0ciXocmA5ze40SfSGYE/duYNliht95FyG2uxTSicLSvEpjH+FdeYFWUae7KCma4HsHJj7s1MX5DmYoyCCPrjbr/Zg83rinDa6HtAJw6G9mu7mHEYoHAMKNRSWkmFSW9AknQQVFdaAESgdvUGnsi+0B34o9kev6xZdzyO/LEJlCGcqVQuH1qkCgz8Iyq6ZcKcRPL8d9CC5UvhOMOwUqZSFhfTPb0WyxoY84RKASMgpNcPxAjEa60h86v/sZxH160FPbiaSyTlgrHlXhymg==';

const statuses = (checks: Check[]) => checks.map(check => check.status);
const der = (base64: string) => Buffer.from(base64, 'base64');

describe('certificate summary', () => {
  for (const [name, cert] of [['RSA v1', RSA_CERT], ['EC v3', EC_CERT], ['RSA 3072', RSA3_CERT]] as const) {
    it(`matches node:crypto for ${name}`, () => {
      const summary = parseCertificate(cert);
      const reference = new X509Certificate(der(cert));
      assert.equal(summary.notBefore.getTime(), new Date(reference.validFrom).getTime());
      assert.equal(summary.notAfter.getTime(), new Date(reference.validTo).getTime());
      assert.equal(summary.subject, reference.subject.replace(/^CN=/, ''));
    });
  }

  it('describes the public key', () => {
    assert.equal(parseCertificate(RSA_CERT).key, 'RSA 2048-bit');
    assert.equal(parseCertificate(RSA3_CERT).key, 'RSA 3072-bit');
    assert.equal(parseCertificate(EC_CERT).key, 'EC P-256');
  });

  it('tolerates the line breaks metadata wraps certificates in', () => {
    const wrapped = RSA_CERT.replace(/(.{64})/g, '$1\n      ');
    assert.equal(parseCertificate(wrapped).subject, 'sso-check-rsa');
  });

  it('throws on anything that is not a certificate', () => {
    assert.throws(() => parseCertificate('not base64 at all!'));
    assert.throws(() => parseCertificate(btoa('hello world')));
    assert.throws(() => parseCertificate(RSA_CERT.slice(0, 200)));
  });
});

const idp = (overrides: Partial<Extract<SamlMetadata, { kind: 'idp' }>> = {}): SamlMetadata => ({
  kind: 'idp',
  idpCount: 1,
  entityId: 'http://www.okta.com/exk1a2b3c4d5',
  protocols: ['urn:oasis:names:tc:SAML:2.0:protocol'],
  wantAuthnRequestsSigned: false,
  validUntil: null,
  ssoServices: [
    { binding: HTTP_REDIRECT, location: 'https://acme.okta.com/app/cc/exk1a2b3c4d5/sso/saml' },
    { binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST', location: 'https://acme.okta.com/app/cc/exk1a2b3c4d5/sso/saml' },
  ],
  signingCertificates: [RSA_CERT],
  ...overrides,
});
const NOW = new Date('2027-01-01T00:00:00Z');

describe('SAML metadata rules', () => {
  it('passes a complete Okta-style descriptor', () => {
    const checks = evaluateSamlMetadata(idp(), NOW);
    assert.deepEqual(statuses(checks), ['pass', 'pass', 'pass']);
    assert.equal(checks[1].values?.[0].value, 'https://acme.okta.com/app/cc/exk1a2b3c4d5/sso/saml');
  });

  it('fails without an HTTP-Redirect endpoint, naming what is offered', () => {
    const checks = evaluateSamlMetadata(idp({ ssoServices: [{ binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST', location: 'https://idp/sso' }] }), NOW);
    const failure = checks.find(check => check.status === 'fail');
    assert.match(failure?.detail ?? '', /only lists HTTP-POST/);
  });

  it('refuses a non-web sign-on location', () => {
    const checks = evaluateSamlMetadata(idp({ ssoServices: [{ binding: HTTP_REDIRECT, location: 'javascript:alert(1)' }] }), NOW);
    assert.ok(checks.some(check => check.status === 'fail' && /not a web address/.test(check.title)));
  });

  it('fails without a signing certificate', () => {
    assert.ok(statuses(evaluateSamlMetadata(idp({ signingCertificates: [] }), NOW)).includes('fail'));
  });

  it('fails when the only certificate expired, warns when another still works', () => {
    const later = new Date('2040-01-01T00:00:00Z');
    assert.ok(statuses(evaluateSamlMetadata(idp({ signingCertificates: [EC_CERT] }), later)).includes('fail'));
    const rotated = evaluateSamlMetadata(idp({ signingCertificates: [EC_CERT, RSA_CERT] }), later);
    assert.ok(!statuses(rotated).includes('fail'));
    assert.ok(rotated.some(check => check.status === 'warn' && /1 of 2 expired/.test(check.title)));
  });

  it('warns a month before expiry', () => {
    const expiry = parseCertificate(EC_CERT).notAfter;
    const soon = new Date(expiry.getTime() - 10 * 86_400_000);
    const checks = evaluateSamlMetadata(idp({ signingCertificates: [EC_CERT] }), soon);
    assert.ok(checks.some(check => check.status === 'warn' && /expires in 10 days/.test(check.title)));
  });

  it('warns when the IdP wants signed requests or the metadata expired', () => {
    const checks = evaluateSamlMetadata(idp({ wantAuthnRequestsSigned: true, validUntil: '2026-06-01T00:00:00Z' }), NOW);
    assert.equal(checks.filter(check => check.status === 'warn').length, 2);
  });

  it('explains documents that are not IdP metadata', () => {
    for (const meta of [
      { kind: 'unparsable', message: 'error on line 1' },
      { kind: 'not-metadata', root: 'html' },
      { kind: 'sp-only' },
      { kind: 'no-idp' },
    ] as SamlMetadata[]) {
      assert.deepEqual(statuses(evaluateSamlMetadata(meta, NOW)), ['fail']);
    }
  });
});

describe('SAML test sign-in', () => {
  it('builds the request cc_saml sends: no ACS URL, POST response binding, escaped issuer', () => {
    const xml = authnRequestXml({ id: '_abc', issueInstant: new Date('2027-01-01T12:00:00.123Z'), destination: 'https://idp/sso?a=1&b=2', spEntityId: 'https://cc.example.com/saml?x=<y>' });
    assert.match(xml, /IssueInstant="2027-01-01T12:00:00Z"/);
    assert.match(xml, /Destination="https:\/\/idp\/sso\?a=1&amp;b=2"/);
    assert.match(xml, /<saml:Issuer>https:\/\/cc\.example\.com\/saml\?x=&lt;y&gt;<\/saml:Issuer>/);
    assert.match(xml, /ProtocolBinding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"/);
    assert.doesNotMatch(xml, /AssertionConsumerService/);
  });

  it('deflates and base64-encodes it onto the endpoint, keeping its query', async () => {
    const url = new URL(await samlTestSignInUrl({ ssoUrl: 'https://idp.example.com/sso?tenant=acme', spEntityId: 'https://cc.example.com/saml' }));
    assert.equal(url.searchParams.get('tenant'), 'acme');
    const xml = inflateRawSync(Buffer.from(url.searchParams.get('SAMLRequest')!, 'base64')).toString('utf8');
    assert.match(xml, /^<samlp:AuthnRequest /);
    assert.match(xml, /ID="_[0-9a-f]{32}"/);
    assert.match(xml, /<saml:Issuer>https:\/\/cc\.example\.com\/saml<\/saml:Issuer>/);
  });
});

const ISSUER = 'https://id.example.com/realms/acme';
const keycloak = {
  issuer: ISSUER,
  authorization_endpoint: `${ISSUER}/protocol/openid-connect/auth`,
  token_endpoint: `${ISSUER}/protocol/openid-connect/token`,
  response_types_supported: ['code', 'none', 'id_token', 'code id_token'],
  code_challenge_methods_supported: ['plain', 'S256'],
  scopes_supported: ['openid', 'profile', 'email', 'offline_access'],
  token_endpoint_auth_methods_supported: ['private_key_jwt', 'client_secret_basic', 'client_secret_post', 'none'],
  claims_supported: ['sub', 'iss', 'name', 'email', 'email_verified', 'groups'],
};
const options = { issuer: ISSUER, confidential: false, groupsClaim: '' };

describe('OIDC issuer input', () => {
  it('applies the server trust rule', () => {
    assert.ok('issuer' in normalizeIssuer(ISSUER));
    assert.ok('issuer' in normalizeIssuer('http://localhost:9000/application/o/cc/'));
    assert.ok('issuer' in normalizeIssuer('http://127.0.0.1:8080'));
    assert.ok('error' in normalizeIssuer('http://id.example.com'));
    assert.ok('error' in normalizeIssuer(''));
    assert.ok('error' in normalizeIssuer('id.example.com'));
  });

  it('points readers who paste the discovery URL at the issuer', () => {
    const result = normalizeIssuer(`${ISSUER}/.well-known/openid-configuration`);
    assert.ok('error' in result && result.error.includes(ISSUER));
  });

  it('derives the discovery URL like the server', () => {
    assert.equal(discoveryUrl(`${ISSUER}/`), `${ISSUER}/.well-known/openid-configuration`);
  });
});

describe('OIDC discovery rules', () => {
  it('passes a Keycloak document', () => {
    assert.deepEqual([...new Set(statuses(evaluateDiscovery(keycloak, options)))], ['pass']);
  });

  it('tolerates a trailing-slash difference in the issuer', () => {
    assert.equal(evaluateDiscovery(keycloak, { ...options, issuer: `${ISSUER}/` })[0].status, 'pass');
  });

  it('fails when the document names another issuer', () => {
    const checks = evaluateDiscovery({ ...keycloak, issuer: 'https://login.example.com/acme/v2.0' }, options);
    assert.equal(checks[0].status, 'fail');
    assert.equal(checks[0].values?.[1].value, 'https://login.example.com/acme/v2.0');
  });

  it('fails endpoints off the issuer origin, as the server refuses them', () => {
    const google = { ...keycloak, token_endpoint: 'https://oauth2.googleapis.com/token' };
    const failure = evaluateDiscovery(google, options).find(check => check.status === 'fail');
    assert.match(failure?.values?.[0].value ?? '', /oauth2\.googleapis\.com/);
    assert.equal(endpointProblem('https://id.example.com:443/token', ISSUER), null);
    assert.match(endpointProblem('https://id.example.com:8443/token', ISSUER) ?? '', /not id\.example\.com/);
    assert.equal(endpointProblem('https://user:pw@id.example.com/token', ISSUER), 'carries credentials');
    assert.equal(endpointProblem('https://id.example.com/token#x', ISSUER), 'has a fragment');
  });

  it('checks PKCE and the response type', () => {
    const { code_challenge_methods_supported: _, ...silent } = keycloak;
    assert.ok(statuses(evaluateDiscovery(silent, options)).includes('warn'));
    assert.ok(statuses(evaluateDiscovery({ ...keycloak, code_challenge_methods_supported: ['plain'] }, options)).includes('fail'));
    assert.ok(statuses(evaluateDiscovery({ ...keycloak, response_types_supported: ['id_token'] }, options)).includes('fail'));
  });

  it('checks the token auth method against the client type', () => {
    const basicOnly = { ...keycloak, token_endpoint_auth_methods_supported: ['client_secret_basic'] };
    assert.ok(statuses(evaluateDiscovery(basicOnly, { ...options, confidential: true })).includes('fail'));
    assert.ok(statuses(evaluateDiscovery(basicOnly, options)).includes('warn'));
    const { token_endpoint_auth_methods_supported: _, ...unlisted } = keycloak;
    const defaulted = evaluateDiscovery(unlisted, { ...options, confidential: true });
    assert.ok(defaulted.some(check => check.status === 'warn' && /client_secret_basic only/.test(check.detail ?? '')));
  });

  it('notes missing claims without failing', () => {
    const checks = evaluateDiscovery({ ...keycloak, claims_supported: ['sub', 'email'] }, { ...options, groupsClaim: 'roles' });
    assert.deepEqual(checks.filter(check => check.status === 'info').map(check => check.title), [
      'The email_verified claim is not advertised',
      'The roles claim is not advertised',
    ]);
  });

  it('bounds and parses pasted documents', () => {
    assert.equal(parseDiscovery(JSON.stringify(keycloak)).ok, true);
    assert.equal(parseDiscovery('{').ok, false);
    assert.equal(parseDiscovery(JSON.stringify({ pad: 'x'.repeat(70_000) })).ok, false);
    assert.equal(evaluateDiscovery([], options)[0].status, 'fail');
  });
});

describe('OIDC test sign-in', () => {
  it('sends the server\'s authorization request with a valid PKCE pair shape', async () => {
    const url = new URL(await oidcTestSignInUrl({
      authorizationEndpoint: `${ISSUER}/protocol/openid-connect/auth?stale=1`,
      clientId: 'control-center',
      redirectUri: 'https://cc.example.com/oidc/callback',
    }));
    const params = Object.fromEntries(url.searchParams);
    assert.equal(params.stale, undefined);
    assert.equal(params.response_type, 'code');
    assert.equal(params.client_id, 'control-center');
    assert.equal(params.redirect_uri, 'https://cc.example.com/oidc/callback');
    assert.equal(params.scope, 'openid profile email');
    assert.equal(params.code_challenge_method, 'S256');
    assert.match(params.code_challenge, /^[A-Za-z0-9_-]{43}$/);
    assert.match(params.state, /^[A-Za-z0-9_-]{43}$/);
    assert.notEqual(params.state, params.nonce);
    // The challenge is a SHA-256 digest; sanity-check the encoding round-trips.
    assert.equal(Buffer.from(params.code_challenge, 'base64url').length, createHash('sha256').digest().length);
  });
});

describe('server address', () => {
  it('normalizes to an origin', () => {
    assert.deepEqual(normalizeOrigin('cc.example.com'), { origin: 'https://cc.example.com' });
    assert.deepEqual(normalizeOrigin(' https://cc.example.com:8443/connect?x=1 '), { origin: 'https://cc.example.com:8443' });
    assert.deepEqual(normalizeOrigin('http://192.168.1.20:7420'), { origin: 'http://192.168.1.20:7420' });
    assert.ok('error' in normalizeOrigin('ftp://cc.example.com'));
    assert.ok('error' in normalizeOrigin(''));
  });

  it('knows which origins an https page cannot fetch', () => {
    assert.equal(blockedAsMixedContent('https:', 'http://192.168.1.20:7420'), true);
    assert.equal(blockedAsMixedContent('https:', 'http://localhost:7420'), false);
    assert.equal(blockedAsMixedContent('https:', 'https://cc.example.com'), false);
    assert.equal(blockedAsMixedContent('http:', 'http://192.168.1.20:7420'), false);
  });

  it('reads /auth/providers', () => {
    const origin = 'https://cc.example.com';
    assert.equal(evaluateProviders({ providers: [{ id: 'saml', kind: 'saml', label: 'SAML' }], pairingEnabled: true }, 'saml', origin).status, 'pass');
    assert.equal(evaluateProviders({ providers: [], pairingEnabled: true }, 'oidc', origin).status, 'warn');
    assert.match(evaluateProviders('<html>', 'saml', origin).title, /not like a Control Center server/);
  });
});
