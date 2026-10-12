import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Pairing credential generation, broker room admission and signed proxy
/// targets. The data-channel authentication protocol is Noise; its handshake
/// and record encryption live in the secure channel.
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

  /// Derives the relay-room **admission token** for a device: HMAC-SHA256 of
  /// `cc-admit-v1|<room>` keyed by the device [psk], base64url no padding.
  ///
  /// The server (which holds every device PSK) registers `sha256(token)` with
  /// the signaling broker's room; a client derives the same token from its own
  /// PSK and presents it on join. The broker can verify admission without ever
  /// learning the PSK — the token is a one-way derivation, useless for
  /// anything but joining this one room (PRD 15 §4 invite-gated rooms).
  static String relayAdmissionToken({
    required String psk,
    required String room,
  }) {
    final digest = Hmac(
      sha256,
      utf8.encode(psk),
    ).convert(utf8.encode('cc-admit-v1|$room'));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// The `sha256` hex of a relay admission token — the value the room owner
  /// registers with the broker (`admit` lists carry hashes, never tokens).
  static String relayAdmissionHash(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  /// HMAC-SHA256 over a proxy [target] (a raw image URL) keyed by [psk], base64url without
  /// padding.
  ///
  /// Binds a resource URL to its target and device credential. Browser URL
  /// consumers reach it through the local facade and authenticated encrypted
  /// resource tunnel; this signature is authorization, not confidentiality.
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
