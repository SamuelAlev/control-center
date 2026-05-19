import 'dart:convert';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';

/// Ed25519 server-identity: the cryptographic root of TOFU fingerprint
/// pinning (PRD 15 §9).
///
/// Every cc_server mints one Ed25519 keypair at first boot and keeps it for
/// life. Its **fingerprint** — the SHA-256 hex of the raw public key — is the
/// server's identity: it rides in every `ConnectionDescriptor`, invite link,
/// and pairing QR, and clients pin it on first pair. On every subsequent
/// connect the server proves possession by signing the client's fresh auth
/// nonce; a changed fingerprint is a hard refusal (re-pair via a new invite),
/// never a "continue anyway?" dialog.
///
/// Being an app-layer identity (not TLS cert pinning), it survives
/// TLS-terminating tunnels (cloudflared, ngrok) and works identically over
/// loopback, LAN, WSS, and the broker relay — closing the DNS-rebind residual
/// (FINDINGS §1): rebinding a hostname to another host cannot forge the
/// signature.
final class ServerIdentityCrypto {
  ServerIdentityCrypto._();

  static const String _signContext = 'cc-server-identity-v1';

  static final Ed25519 _ed25519 = Ed25519();

  /// Generates a fresh Ed25519 keypair and returns its 32-byte private seed,
  /// base64url-encoded without padding (the persisted secret).
  static Future<String> generateSeed() async {
    final keyPair = await _ed25519.newKeyPair();
    final seed = await keyPair.extractPrivateKeyBytes();
    return _b64(seed);
  }

  /// Derives the base64url public key from a persisted [seedB64].
  static Future<String> publicKeyFromSeed(String seedB64) async {
    final keyPair = await _keyPairFromSeed(seedB64);
    final publicKey = await keyPair.extractPublicKey();
    return _b64(publicKey.bytes);
  }

  /// The SHA-256 hex fingerprint of a base64url [publicKeyB64] — the pinned
  /// server identity string shown to users and stored client-side.
  static String fingerprintOf(String publicKeyB64) =>
      sha256.convert(_unb64(publicKeyB64)).toString();

  /// Signs the identity challenge for [nonce] (the client's fresh auth nonce)
  /// with the key derived from [seedB64]. Returns a base64url signature.
  static Future<String> signChallenge({
    required String seedB64,
    required String nonce,
  }) async {
    final keyPair = await _keyPairFromSeed(seedB64);
    final signature = await _ed25519.sign(
      utf8.encode('$_signContext|$nonce'),
      keyPair: keyPair,
    );
    return _b64(signature.bytes);
  }

  /// Verifies a server's identity proof: [signatureB64] must be a valid
  /// Ed25519 signature over the [nonce] challenge by [publicKeyB64]. Returns
  /// false on any malformed input (fail closed, never throw on hostile data).
  static Future<bool> verifyChallenge({
    required String nonce,
    required String publicKeyB64,
    required String signatureB64,
  }) async {
    try {
      final publicKey = SimplePublicKey(
        _unb64(publicKeyB64),
        type: KeyPairType.ed25519,
      );
      final signature = Signature(_unb64(signatureB64), publicKey: publicKey);
      return await _ed25519.verify(
        utf8.encode('$_signContext|$nonce'),
        signature: signature,
      );
    } catch (_) {
      return false;
    }
  }

  static Future<SimpleKeyPair> _keyPairFromSeed(String seedB64) =>
      _ed25519.newKeyPairFromSeed(_unb64(seedB64));

  static String _b64(List<int> bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');

  static List<int> _unb64(String value) =>
      base64Url.decode(base64Url.normalize(value));
}

/// Thrown by clients when a server's identity does not verify against the
/// pinned fingerprint — a rebind/MITM signal. Callers MUST treat this as a
/// hard stop: no retry, no downgrade; re-pairing via a fresh invite is the
/// only recovery.
class ServerIdentityMismatchException implements Exception {
  /// Creates a [ServerIdentityMismatchException].
  const ServerIdentityMismatchException({
    required this.expectedFingerprint,
    required this.actualFingerprint,
  });

  /// The fingerprint the client had pinned.
  final String expectedFingerprint;

  /// The fingerprint the connecting server actually presented (empty when the
  /// server presented no identity at all).
  final String actualFingerprint;

  @override
  String toString() =>
      'ServerIdentityMismatchException: pinned '
      '${_short(expectedFingerprint)} but the server presented '
      '${actualFingerprint.isEmpty ? 'no identity' : _short(actualFingerprint)} '
      '— refusing to connect. Re-pair with a fresh invite if the server was '
      'legitimately reinstalled.';

  static String _short(String fp) => fp.length > 12 ? fp.substring(0, 12) : fp;
}
