/**
 * Just enough DER to summarize an IdP signing certificate in the browser:
 * subject CN, validity window and public-key shape. The SSO checker uses it
 * to flag expired or soon-expiring certificates before the server ever sees
 * them. This is NOT a verifier (no chain, no signature check); the server's
 * cc_saml native owns everything security-relevant.
 */

export interface CertificateSummary {
  subject: string | null;
  notBefore: Date;
  notAfter: Date;
  /** e.g. `RSA 2048-bit`, `EC P-256`, `Ed25519`. */
  key: string;
}

interface Tlv {
  tag: number;
  contentStart: number;
  end: number;
}

function readTlv(bytes: Uint8Array, offset: number): Tlv {
  if (offset + 2 > bytes.length) throw new Error('truncated DER');
  const tag = bytes[offset];
  let length = bytes[offset + 1];
  let contentStart = offset + 2;
  if (length & 0x80) {
    const count = length & 0x7f;
    if (count === 0 || count > 4 || contentStart + count > bytes.length) throw new Error('bad DER length');
    length = 0;
    for (let i = 0; i < count; i++) length = length * 256 + bytes[contentStart + i];
    contentStart += count;
  }
  const end = contentStart + length;
  if (end > bytes.length) throw new Error('truncated DER');
  return { tag, contentStart, end };
}

function children(bytes: Uint8Array, parent: Tlv): Tlv[] {
  const out: Tlv[] = [];
  for (let offset = parent.contentStart; offset < parent.end; ) {
    const child = readTlv(bytes, offset);
    out.push(child);
    offset = child.end;
  }
  return out;
}

function expect(tlv: Tlv | undefined, tag: number): Tlv {
  if (!tlv || tlv.tag !== tag) throw new Error('unexpected certificate structure');
  return tlv;
}

function oid(bytes: Uint8Array, tlv: Tlv): string {
  const parts: number[] = [];
  let value = 0;
  for (let i = tlv.contentStart; i < tlv.end; i++) {
    value = value * 128 + (bytes[i] & 0x7f);
    if (!(bytes[i] & 0x80)) {
      if (parts.length === 0) parts.push(value < 80 ? Math.floor(value / 40) : 2, value < 80 ? value % 40 : value - 80);
      else parts.push(value);
      value = 0;
    }
  }
  return parts.join('.');
}

function time(bytes: Uint8Array, tlv: Tlv): Date {
  const text = new TextDecoder().decode(bytes.subarray(tlv.contentStart, tlv.end));
  let match: RegExpMatchArray | null;
  let year: number;
  if (tlv.tag === 0x17) {
    // UTCTime: YYMMDDHHMM[SS]Z, two-digit years pivot at 50 (RFC 5280 §4.1.2.5.1).
    match = text.match(/^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?Z$/);
    if (!match) throw new Error('bad UTCTime');
    const yy = Number(match[1]);
    year = yy >= 50 ? 1900 + yy : 2000 + yy;
  } else if (tlv.tag === 0x18) {
    match = text.match(/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})?(?:\.\d+)?Z$/);
    if (!match) throw new Error('bad GeneralizedTime');
    year = Number(match[1]);
  } else {
    throw new Error('unexpected time type');
  }
  return new Date(Date.UTC(year, Number(match[2]) - 1, Number(match[3]), Number(match[4]), Number(match[5]), Number(match[6] ?? 0)));
}

function string(bytes: Uint8Array, tlv: Tlv): string {
  const raw = bytes.subarray(tlv.contentStart, tlv.end);
  if (tlv.tag === 0x1e) {
    // BMPString is UTF-16BE.
    let out = '';
    for (let i = 0; i + 1 < raw.length; i += 2) out += String.fromCharCode((raw[i] << 8) | raw[i + 1]);
    return out;
  }
  return new TextDecoder().decode(raw);
}

const COMMON_NAME = '2.5.4.3';

function commonName(bytes: Uint8Array, name: Tlv): string | null {
  for (const rdn of children(bytes, name)) {
    for (const attribute of children(bytes, rdn)) {
      const [type, value] = children(bytes, attribute);
      if (type?.tag === 0x06 && value && oid(bytes, type) === COMMON_NAME) return string(bytes, value);
    }
  }
  return null;
}

const CURVES: Record<string, string> = {
  '1.2.840.10045.3.1.7': 'P-256',
  '1.3.132.0.34': 'P-384',
  '1.3.132.0.35': 'P-521',
};

function keyDescription(bytes: Uint8Array, spki: Tlv): string {
  const [algorithm, publicKey] = children(bytes, spki);
  const [algorithmOid, parameters] = children(bytes, expect(algorithm, 0x30));
  const id = oid(bytes, expect(algorithmOid, 0x06));
  if (id === '1.2.840.113549.1.1.1') {
    // BIT STRING → (unused-bits byte) → RSAPublicKey SEQUENCE { modulus, exponent }.
    const bitString = expect(publicKey, 0x03);
    const rsaKey = readTlv(bytes, bitString.contentStart + 1);
    const modulus = expect(children(bytes, expect(rsaKey, 0x30))[0], 0x02);
    let start = modulus.contentStart;
    while (start < modulus.end && bytes[start] === 0) start++;
    if (start === modulus.end) return 'RSA';
    const bits = (modulus.end - start - 1) * 8 + (32 - Math.clz32(bytes[start]));
    return `RSA ${bits}-bit`;
  }
  if (id === '1.2.840.10045.2.1') {
    const curve = parameters?.tag === 0x06 ? CURVES[oid(bytes, parameters)] : undefined;
    return curve ? `EC ${curve}` : 'EC';
  }
  if (id === '1.3.101.112') return 'Ed25519';
  if (id === '1.3.101.113') return 'Ed448';
  return `OID ${id}`;
}

export function decodeBase64(text: string): Uint8Array {
  const clean = text.replace(/\s+/g, '');
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(clean) || clean.length % 4 === 1) throw new Error('not base64');
  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Summarizes a base64 (DER) X.509 certificate, as found in `ds:X509Certificate`. Throws on anything unreadable. */
export function parseCertificate(base64: string): CertificateSummary {
  const bytes = decodeBase64(base64);
  const certificate = expect(readTlv(bytes, 0), 0x30);
  const tbs = expect(children(bytes, certificate)[0], 0x30);
  const fields = children(bytes, tbs);
  // Optional explicit version [0] precedes the serial number.
  const offset = fields[0]?.tag === 0xa0 ? 1 : 0;
  const validity = expect(fields[offset + 3], 0x30);
  const subject = expect(fields[offset + 4], 0x30);
  const spki = expect(fields[offset + 5], 0x30);
  const [notBefore, notAfter] = children(bytes, validity);
  if (!notBefore || !notAfter) throw new Error('missing validity');
  return {
    subject: commonName(bytes, subject),
    notBefore: time(bytes, notBefore),
    notAfter: time(bytes, notAfter),
    key: keyDescription(bytes, spki),
  };
}
