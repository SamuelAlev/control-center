import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_connect_core/src/encoding.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// The fixed DER prefix of an Ed25519 SubjectPublicKeyInfo (RFC 8410): the
/// AlgorithmIdentifier for id-Ed25519 followed by a 33-byte BIT STRING header.
const List<int> _ed25519SpkiPrefix = [
  0x30, 0x2a, 0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x03, 0x21, 0x00, //
];

/// Number of Crockford characters in an install id (130 bits of SHA-256).
const int installIdLength = 26;

/// HKDF salt for per-origin install keys. Changing it re-keys every server.
const String _installKeySalt = 'cc-connect-id/v1';

/// Reduces a Connect URL to the origin its keys are derived for.
///
/// Lower-cased scheme and host, the port only when it is not the scheme's
/// default, and nothing else: `https://Connect.Example:443/x/` and
/// `https://connect.example` are the same Connect, so they must derive the
/// same key, while `http://` and `https://` never do. Throws [FormatException]
/// for anything that is not an absolute http(s) URL.
String canonicalConnectOrigin(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null ||
      !(uri.scheme == 'https' || uri.scheme == 'http') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw FormatException('Not an http(s) origin: $url');
  }
  final scheme = uri.scheme.toLowerCase();
  // `connect.example.` and `connect.example` are one host: a single trailing
  // root dot must not derive a second install identity.
  var host = uri.host.toLowerCase();
  if (host.endsWith('.') && !host.endsWith('..')) {
    host = host.substring(0, host.length - 1);
  }
  if (host.isEmpty) {
    throw FormatException('Not an http(s) origin: $url');
  }
  final defaultPort = scheme == 'https' ? 443 : 80;
  final port = uri.hasPort && uri.port != defaultPort ? ':${uri.port}' : '';
  final printableHost = host.contains(':') ? '[$host]' : host;
  return '$scheme://$printableHost$port';
}

/// Reduces a Connect URL to the base URL its keys, seals and callbacks are
/// bound to: the canonical origin plus the path prefix it is mounted under
/// (an embedded Connect lives at `<server>/connect`), without a trailing
/// slash, query or fragment. Throws [FormatException] like
/// [canonicalConnectOrigin].
String canonicalConnectBaseUrl(String url) {
  final origin = canonicalConnectOrigin(url);
  // Uri.parse already resolves dot segments, percent-encoded ones included;
  // refuse them in the raw text so `/a/../b` or `/a/%2e%2e` is never
  // silently read as another mount, and an encoded slash never splits one.
  final raw = url
      .trim()
      .split(RegExp('[?#]'))
      .first
      .replaceFirst(RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*://[^/]*'), '');
  for (final segment in raw.split('/')) {
    final String decoded;
    try {
      decoded = Uri.decodeComponent(segment);
    } on ArgumentError {
      throw FormatException('Not a Connect base URL: $url');
    }
    if (decoded == '.' || decoded == '..' || decoded.contains('/')) {
      throw FormatException('Not a Connect base URL: $url');
    }
  }
  final uri = Uri.parse(url.trim());
  final segments = [
    for (final segment in uri.pathSegments)
      if (segment.isNotEmpty) segment,
  ];
  if (segments.isEmpty) {
    return origin;
  }
  return '$origin/${segments.map(Uri.encodeComponent).join('/')}';
}

/// Whether [origin] (canonical) is a loopback origin, the only place a Connect
/// may run without TLS.
bool isLoopbackOrigin(String origin) {
  final host = Uri.parse(origin).host;
  return host == 'localhost' || host == '::1' || _ipv4Loopback.hasMatch(host);
}

final RegExp _ipv4Loopback = RegExp(
  r'^127\.(25[0-5]|2[0-4]\d|1?\d?\d)\.(25[0-5]|2[0-4]\d|1?\d?\d)\.(25[0-5]|2[0-4]\d|1?\d?\d)$',
);

/// The DER SubjectPublicKeyInfo of a raw 32-byte Ed25519 public key.
Uint8List ed25519Spki(List<int> publicKey) {
  if (publicKey.length != 32) {
    throw ArgumentError('Ed25519 public keys are 32 bytes');
  }
  return Uint8List.fromList([..._ed25519SpkiPrefix, ...publicKey]);
}

/// The raw public key inside a `keyid` (base64url SPKI), or null when it is
/// not exactly an Ed25519 SPKI.
Uint8List? publicKeyFromKeyId(String keyId) {
  final Uint8List der;
  try {
    der = unb64url(keyId);
  } on FormatException {
    return null;
  }
  if (der.length != _ed25519SpkiPrefix.length + 32) {
    return null;
  }
  for (var i = 0; i < _ed25519SpkiPrefix.length; i++) {
    if (der[i] != _ed25519SpkiPrefix[i]) {
      return null;
    }
  }
  return Uint8List.sublistView(der, _ed25519SpkiPrefix.length);
}

/// The install id a `keyid` names: the first [installIdLength] lower-case
/// Crockford characters of SHA-256(SPKI). Connect recomputes this from the
/// verified key and never trusts a caller-supplied id. Null for a malformed
/// key id.
String? installIdForKeyId(String keyId) {
  final publicKey = publicKeyFromKeyId(keyId);
  if (publicKey == null) {
    return null;
  }
  return installIdForPublicKey(publicKey);
}

/// The install id of a raw Ed25519 [publicKey].
String installIdForPublicKey(List<int> publicKey) {
  final digest = crypto.sha256.convert(ed25519Spki(publicKey)).bytes;
  return crockfordBase32(digest).substring(0, installIdLength).toLowerCase();
}

/// Whether [value] has the shape of an install id.
bool isInstallId(String value) =>
    value.length == installIdLength &&
    RegExp(r'^[0-9a-hjkmnp-tv-z]+$').hasMatch(value);

/// One cc_server's identity towards one Connect origin.
///
/// Every server holds a single 32-byte master seed (`connect_install_key`)
/// and derives an independent Ed25519 key per Connect origin with
/// HKDF-SHA256, so the hosted Connect and a company's self-hosted one see
/// unlinkable install ids for the same server. The seed is separate from the
/// device-pairing identity: rotating one never disturbs the other.
final class ConnectInstallIdentity {
  ConnectInstallIdentity._({
    required this.origin,
    required this.publicKey,
    required this._keyPair,
  }) : keyId = b64url(ed25519Spki(publicKey)),
       installId = installIdForPublicKey(publicKey);

  static final Ed25519 _ed25519 = Ed25519();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// A fresh 32-byte master seed.
  static Uint8List newMasterSeed() => randomBytes(32);

  /// Derives the identity for [connectUrl] from [masterSeed]. The HKDF
  /// `info` is the canonical base URL ([canonicalConnectBaseUrl]).
  static Future<ConnectInstallIdentity> derive({
    required List<int> masterSeed,
    required String connectUrl,
  }) async {
    if (masterSeed.length != 32) {
      throw ArgumentError('connect_install_key must be 32 bytes');
    }
    final origin = canonicalConnectBaseUrl(connectUrl);
    final derived = await _hkdf.deriveKey(
      secretKey: SecretKey(masterSeed),
      nonce: utf8.encode(_installKeySalt),
      info: utf8.encode(origin),
    );
    final seed = await derived.extractBytes();
    final keyPair = await _ed25519.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    return ConnectInstallIdentity._(
      origin: origin,
      publicKey: Uint8List.fromList(publicKey.bytes),
      keyPair: keyPair,
    );
  }

  final SimpleKeyPair _keyPair;

  /// The canonical Connect base URL this identity belongs to.
  final String origin;

  /// The raw 32-byte Ed25519 public key.
  final Uint8List publicKey;

  /// The RFC 9421 `keyid`: base64url of the DER SPKI.
  final String keyId;

  /// What Connect and its operators call this server.
  final String installId;

  /// Signs [message] with this identity's private key.
  Future<Uint8List> sign(List<int> message) async {
    final signature = await _ed25519.sign(message, keyPair: _keyPair);
    return Uint8List.fromList(signature.bytes);
  }
}

/// Verifies a raw Ed25519 [signature] over [message] by [publicKey]. False
/// on any malformed input: hostile bytes never throw.
Future<bool> verifyEd25519({
  required List<int> message,
  required List<int> signature,
  required List<int> publicKey,
}) async {
  if (signature.length != 64 || publicKey.length != 32) {
    return false;
  }
  try {
    return await Ed25519().verify(
      message,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
      ),
    );
  } on Object {
    return false;
  }
}
