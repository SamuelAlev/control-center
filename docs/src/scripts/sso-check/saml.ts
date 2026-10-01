/**
 * SAML half of the manual's SSO checker. Mirrors what the server's cc_saml
 * native accepts (`IdpDescriptor::from_metadata_xml` + the HTTP-Redirect
 * AuthnRequest in `cc_saml_build_authn_request`), so a clean report here
 * predicts a clean "Test connection" in the app. Everything runs in the
 * reader's tab; nothing is uploaded.
 */
import { parseCertificate } from './x509.ts';
import { base64, isoDate, isLoopbackHost, tryUrl, type Check } from './checks.ts';

export const MD_NS = 'urn:oasis:names:tc:SAML:2.0:metadata';
const DS_NS = 'http://www.w3.org/2000/09/xmldsig#';
const SAML2_PROTOCOL = 'urn:oasis:names:tc:SAML:2.0:protocol';
export const HTTP_REDIRECT = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect';
const HTTP_POST = 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST';

/** Expiry this close counts as "rotate soon". */
const EXPIRY_WARNING_DAYS = 30;
const DAY_MS = 86_400_000;

/** The plain-data view of a metadata document the rules run on. */
export type SamlMetadata =
  | { kind: 'unparsable'; message: string }
  | { kind: 'not-metadata'; root: string }
  | { kind: 'sp-only' }
  | { kind: 'no-idp' }
  | {
      kind: 'idp';
      /** IdP entities in the document; the server uses the first. */
      idpCount: number;
      entityId: string | null;
      protocols: string[];
      wantAuthnRequestsSigned: boolean;
      validUntil: string | null;
      ssoServices: { binding: string; location: string }[];
      signingCertificates: string[];
    };

const childElements = (parent: Element, name: string, ns = MD_NS) =>
  Array.from(parent.children).filter(child => child.namespaceURI === ns && child.localName === name);

/** Reads the fields the rules need out of a DOMParser document. Browser-only (needs a DOM). */
export function extractMetadata(doc: Document): SamlMetadata {
  const error = doc.getElementsByTagName('parsererror')[0];
  if (error) {
    // Chromium/WebKit put the message in a <div>; Firefox leads with it as the first text line.
    const text = error.querySelector('div')?.textContent ?? error.textContent ?? '';
    const message = text.split('\n').map(line => line.trim()).find(Boolean) ?? 'The XML is not well-formed.';
    return { kind: 'unparsable', message };
  }
  const root = doc.documentElement;
  const isMd = (el: Element, name: string) => el.namespaceURI === MD_NS && el.localName === name;
  if (!isMd(root, 'EntityDescriptor') && !isMd(root, 'EntitiesDescriptor')) {
    return { kind: 'not-metadata', root: root.namespaceURI ? `${root.localName} (${root.namespaceURI})` : root.localName };
  }
  const entities = isMd(root, 'EntityDescriptor') ? [root] : Array.from(root.getElementsByTagNameNS(MD_NS, 'EntityDescriptor'));
  const idps = entities.filter(entity => childElements(entity, 'IDPSSODescriptor').length > 0);
  if (idps.length === 0) {
    return entities.some(entity => childElements(entity, 'SPSSODescriptor').length > 0) ? { kind: 'sp-only' } : { kind: 'no-idp' };
  }
  const entity = idps[0];
  const idp = childElements(entity, 'IDPSSODescriptor')[0];
  const signingCertificates = childElements(idp, 'KeyDescriptor')
    .filter(key => {
      const use = key.getAttribute('use');
      return use === null || use === '' || use === 'signing';
    })
    .flatMap(key => Array.from(key.getElementsByTagNameNS(DS_NS, 'X509Certificate')))
    .map(cert => (cert.textContent ?? '').replace(/\s+/g, ''))
    .filter(Boolean);
  return {
    kind: 'idp',
    idpCount: idps.length,
    entityId: entity.getAttribute('entityID'),
    protocols: (idp.getAttribute('protocolSupportEnumeration') ?? '').split(/\s+/).filter(Boolean),
    wantAuthnRequestsSigned: ['true', '1'].includes((idp.getAttribute('WantAuthnRequestsSigned') ?? '').trim()),
    validUntil: idp.getAttribute('validUntil') ?? entity.getAttribute('validUntil'),
    ssoServices: childElements(idp, 'SingleSignOnService').map(service => ({
      binding: service.getAttribute('Binding') ?? '',
      location: service.getAttribute('Location') ?? '',
    })),
    signingCertificates: [...new Set(signingCertificates)],
  };
}

const bindingName = (binding: string) =>
  binding === HTTP_REDIRECT ? 'HTTP-Redirect' : binding === HTTP_POST ? 'HTTP-POST' : binding.split(':').pop() || binding;

function certificateChecks(certificates: string[], now: Date): Check[] {
  if (certificates.length === 0) {
    return [{
      status: 'fail',
      title: 'No signing certificate',
      detail: 'Control Center only accepts signed assertions and checks them against the certificates in this metadata. Make sure the IdP publishes its signing certificate (a KeyDescriptor with use="signing").',
    }];
  }
  const summaries = certificates.map(cert => {
    try {
      return parseCertificate(cert);
    } catch {
      return null;
    }
  });
  const usable = summaries.filter(summary => summary && summary.notBefore <= now && summary.notAfter > now).length;
  const label = (index: number) => (certificates.length > 1 ? `Signing certificate ${index + 1} of ${certificates.length}` : 'Signing certificate');
  return summaries.map((summary, index): Check => {
    if (!summary) {
      return {
        status: usable > 0 ? 'warn' : 'fail',
        title: `${label(index)} could not be read`,
        detail: 'The X509Certificate element does not hold a base64 DER certificate. Copy the metadata again without editing it.',
      };
    }
    const values = [
      ...(summary.subject ? [{ label: 'Subject', value: summary.subject }] : []),
      { label: 'Valid until', value: isoDate(summary.notAfter) },
      { label: 'Key', value: summary.key },
    ];
    if (summary.notAfter <= now) {
      return {
        status: usable > 0 ? 'warn' : 'fail',
        title: `${label(index)} expired`,
        detail: usable > 0
          ? 'Another listed certificate is still valid, so logins signed with that one keep working. Remove the expired one at your IdP when you can.'
          : 'Assertions signed with an expired certificate are refused. Rotate the certificate at your IdP, then paste its fresh metadata.',
        values,
      };
    }
    if (summary.notBefore > now) {
      return {
        status: usable > 0 ? 'warn' : 'fail',
        title: `${label(index)} is not valid yet`,
        detail: `It only becomes valid on ${isoDate(summary.notBefore)}.`,
        values,
      };
    }
    const daysLeft = Math.floor((summary.notAfter.getTime() - now.getTime()) / DAY_MS);
    if (daysLeft < EXPIRY_WARNING_DAYS) {
      return {
        status: 'warn',
        title: `${label(index)} expires in ${daysLeft === 1 ? '1 day' : `${daysLeft} days`}`,
        detail: 'Logins stop working when it expires. Rotate it at your IdP and paste the new metadata into Control Center before then.',
        values,
      };
    }
    return { status: 'pass', title: `${label(index)} is valid`, values };
  });
}

export function evaluateSamlMetadata(meta: SamlMetadata, now: Date): Check[] {
  switch (meta.kind) {
    case 'unparsable':
      return [{ status: 'fail', title: 'The XML does not parse', detail: meta.message }];
    case 'not-metadata':
      return [{
        status: 'fail',
        title: 'This is not SAML metadata',
        detail: `Expected an md:EntityDescriptor root in the ${MD_NS} namespace, found ${meta.root}. If your IdP gave you a metadata URL, open it and copy everything it serves.`,
      }];
    case 'sp-only':
      return [{
        status: 'fail',
        title: 'This is service-provider metadata',
        detail: 'It describes an app that receives SAML logins, possibly Control Center itself. Paste the metadata of your identity provider instead.',
      }];
    case 'no-idp':
      return [{ status: 'fail', title: 'No identity provider in this document', detail: 'None of its entities has an IDPSSODescriptor.' }];
  }

  const checks: Check[] = [];
  if (meta.idpCount > 1) {
    checks.push({
      status: 'warn',
      title: `${meta.idpCount} identity providers in one document`,
      detail: 'Control Center uses the first one only. Paste the EntityDescriptor of your app alone to be sure it picks the right one.',
    });
  }
  if (!meta.entityId) {
    checks.push({ status: 'fail', title: 'The IdP has no entity ID', detail: 'The EntityDescriptor is missing its entityID attribute.' });
  } else {
    checks.push({
      status: 'pass',
      title: 'Identity provider found',
      detail: 'Responses must name this issuer, or the server refuses them.',
      values: [{ label: 'Entity ID', value: meta.entityId }],
    });
  }
  if (!meta.protocols.includes(SAML2_PROTOCOL)) {
    checks.push({
      status: 'warn',
      title: 'SAML 2.0 is not declared',
      detail: `The IDPSSODescriptor's protocolSupportEnumeration does not list ${SAML2_PROTOCOL}. Control Center speaks SAML 2.0 only.`,
    });
  }

  const redirect = meta.ssoServices.find(service => service.binding === HTTP_REDIRECT);
  const redirectUrl = redirect ? tryUrl(redirect.location) : null;
  if (!redirect) {
    const offered = meta.ssoServices.map(service => bindingName(service.binding));
    checks.push({
      status: 'fail',
      title: 'No HTTP-Redirect sign-on endpoint',
      detail: `Control Center sends its sign-in request with the HTTP-Redirect binding. ${offered.length ? `This IdP only lists ${offered.join(', ')}.` : 'This IdP lists no SingleSignOnService at all.'} Enable the Redirect binding for the app at your IdP.`,
    });
  } else if (!redirectUrl || (redirectUrl.protocol !== 'https:' && redirectUrl.protocol !== 'http:')) {
    checks.push({ status: 'fail', title: 'The sign-on endpoint is not a web address', values: [{ label: 'Location', value: redirect.location }] });
  } else if (redirectUrl.protocol === 'http:' && !isLoopbackHost(redirectUrl.hostname)) {
    checks.push({
      status: 'warn',
      title: 'The sign-on endpoint uses plain http',
      detail: 'Users would type their IdP password into an unencrypted page. Serve the IdP over https.',
      values: [{ label: 'HTTP-Redirect', value: redirect.location }],
    });
  } else {
    checks.push({ status: 'pass', title: 'Sign-on endpoint found', values: [{ label: 'HTTP-Redirect', value: redirect.location }] });
  }

  checks.push(...certificateChecks(meta.signingCertificates, now));

  if (meta.wantAuthnRequestsSigned) {
    checks.push({
      status: 'warn',
      title: 'The IdP asks for signed sign-in requests',
      detail: 'Control Center sends unsigned requests, so the IdP will likely refuse them. Turn off request signing for this app at the IdP (in Keycloak: "Client signature required").',
    });
  }
  if (meta.validUntil) {
    const validUntil = new Date(meta.validUntil);
    if (!Number.isNaN(validUntil.getTime()) && validUntil <= now) {
      checks.push({
        status: 'warn',
        title: 'This metadata has expired',
        detail: 'Its validUntil date has passed. Download fresh metadata from your IdP; stale copies often carry a rotated-out certificate.',
        values: [{ label: 'Valid until', value: isoDate(validUntil) }],
      });
    }
  }
  return checks;
}

/** The default SP entity ID the server derives: `<origin>/saml`. */
export const defaultSpEntityId = (origin: string) => `${origin}/saml`;

const escapeXml = (value: string) =>
  value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

/** The same AuthnRequest shape cc_saml sends: no ACS URL (the IdP uses the registered one), POST response binding, unsigned. */
export function authnRequestXml(options: { id: string; issueInstant: Date; destination: string; spEntityId: string }): string {
  const instant = options.issueInstant.toISOString().replace(/\.\d{3}Z$/, 'Z');
  return `<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="${escapeXml(options.id)}" Version="2.0" IssueInstant="${instant}" Destination="${escapeXml(options.destination)}" ProtocolBinding="${HTTP_POST}"><saml:Issuer>${escapeXml(options.spEntityId)}</saml:Issuer></samlp:AuthnRequest>`;
}

async function deflateRaw(text: string): Promise<Uint8Array> {
  const stream = new Blob([text]).stream().pipeThrough(new CompressionStream('deflate-raw'));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

/** HTTP-Redirect binding: DEFLATE, base64, then the SAMLRequest query parameter on the IdP's endpoint. */
export async function samlTestSignInUrl(options: { ssoUrl: string; spEntityId: string; now?: Date }): Promise<string> {
  const id = `_${Array.from(crypto.getRandomValues(new Uint8Array(16)), byte => byte.toString(16).padStart(2, '0')).join('')}`;
  const xml = authnRequestXml({ id, issueInstant: options.now ?? new Date(), destination: options.ssoUrl, spEntityId: options.spEntityId });
  const url = new URL(options.ssoUrl);
  url.searchParams.set('SAMLRequest', base64(await deflateRaw(xml)));
  return url.toString();
}
