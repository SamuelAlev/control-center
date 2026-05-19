import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Cryptographic primitives for remote-control pairing and channel auth.
///
/// Reuses the `Random.secure()` + base64url + `sha256`/`Hmac` patterns from
/// `GoogleOAuthService`. Everything here is pure (no `dart:io`) so it runs
/// identically on the desktop and in tests. Lives in the data layer because it
/// depends on `package:crypto` (an infrastructure package the architecture
/// rules keep out of `domain/`).
///
/// Two layers protect the WebRTC DataChannel:
///  1. **SDP signature** — the offerer HMAC-signs its SDP (which embeds the
///     DTLS fingerprint) with the PSK so a MITM signaling broker can't swap
///     fingerprints. The answerer verifies before accepting the connection.
///  2. **Nonce challenge** — after the channel opens, each side proves it
///     holds the PSK with an HMAC over a fresh nonce bound to both DTLS
///     fingerprints, compared in constant time.
class RemoteControlCrypto {
  RemoteControlCrypto._();

  /// Generates a 32-byte PSK, base64url-encoded without padding.
  static String generatePsk([Random? random]) {
    final rnd = random ?? Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => rnd.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Generates a 16-byte pairing room code, base64url-encoded without padding.
  static String generateRoomCode([Random? random]) {
    final rnd = random ?? Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => rnd.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Generates an 8-byte nonce, base64url-encoded without padding.
  static String generateNonce([Random? random]) {
    final rnd = random ?? Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(8, (_) => rnd.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// HMAC-SHA256 of [sdp] keyed by the [psk], base64url without padding.
  /// Binds the SDP (and its DTLS fingerprint) to the PSK so a broker can't
  /// substitute a different fingerprint unnoticed.
  static String signSdp(String sdp, String psk) {
    final digest = Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(sdp));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Verifies an SDP signature in constant time.
  static bool verifySdpSignature(String sdp, String psk, String signature) {
    final expected = signSdp(sdp, psk);
    return constantTimeEquals(utf8.encode(expected), utf8.encode(signature));
  }

  /// HMAC-SHA256 over `nonce|localFp|remoteFp` keyed by [psk], base64url
  /// without padding. Binding both fingerprints ties the proof to this exact
  /// DTLS session, not a replayed nonce.
  static String respondToChallenge({
    required String nonce,
    required String psk,
    required String localFingerprint,
    required String remoteFingerprint,
  }) {
    final message = '$nonce|$localFingerprint|$remoteFingerprint';
    final digest = Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(message));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Verifies a challenge response in constant time.
  static bool verifyChallengeResponse({
    required String nonce,
    required String psk,
    required String localFingerprint,
    required String remoteFingerprint,
    required String response,
  }) {
    final expected = respondToChallenge(
      nonce: nonce,
      psk: psk,
      localFingerprint: localFingerprint,
      remoteFingerprint: remoteFingerprint,
    );
    return constantTimeEquals(utf8.encode(expected), utf8.encode(response));
  }

  /// HMAC-SHA256 over a proxy [target] (a raw image URL) keyed by [psk],
  /// base64url without padding.
  ///
  /// Authenticates media-proxy `GET`s, which cannot carry the WebSocket session
  /// (a browser `<img>`/CanvasKit fetch can set no headers). The thin client
  /// signs each image URL with the device PSK it already holds; the server
  /// re-derives the signature from the same PSK before fetching. Only a holder
  /// of an `active` device's PSK can mint a URL the server will proxy, so the
  /// endpoint is not an open relay (it cannot be used to SSRF-scan from an
  /// unauthenticated origin). The signature binds the EXACT URL, so a valid
  /// signature for one image can't be replayed against a different target.
  static String signProxyTarget(String target, String psk) {
    final digest = Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(target));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Verifies a [signature] for a proxy [target] in constant time.
  static bool verifyProxyTarget(String target, String psk, String signature) {
    final expected = signProxyTarget(target, psk);
    return constantTimeEquals(utf8.encode(expected), utf8.encode(signature));
  }

  /// Constant-time byte comparison (the same loop the MCP HTTP server uses for
  /// bearer-token checks). Returns true only when [a] and [b] are byte-identical
  /// and same length, without short-circuiting on the first difference.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
