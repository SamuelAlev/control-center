import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:crypto/crypto.dart';

/// PSK-over-DTLS channel authentication for the remote-control DataChannel.
///
/// Mirrors the desktop's `RemoteControlCrypto` byte-for-byte so the two sides
/// interoperate, but is reimplemented here (we can't import the desktop class —
/// it lives in the `control_center` package, which breaks `flutter build web`).
/// Pure Dart on top of `package:crypto`, so it runs identically on the web.
///
/// The phone is the **verifier / initiator**: after the DataChannel opens it
/// sends a fresh nonce, the desktop responds with an HMAC-SHA256 over
/// `nonce|localFp|remoteFp` keyed by the PSK, and the phone verifies it in
/// constant time. Binding both DTLS fingerprints ties the proof to *this* DTLS
/// session, not a replayed nonce.
///
/// Wire frames (JSON over the DataChannel):
///  - phone → desktop: `{'type':'auth_challenge','nonce':N,'proof':P}`
///  - desktop → phone: `{'type':'auth_response','nonce':N,'response':R}`
///
/// `R` is computed by the **responder** (the desktop) as
/// `HMAC-SHA256(psk, "N|<desktop local fp>|<phone local fp>")`, base64url without
/// padding — i.e. exactly [challengeResponse] called with the responder's own
/// local fingerprint first. The phone reproduces it by passing the desktop's
/// fingerprint as `localFingerprint` and its own as `remoteFingerprint`. The
/// optional `proof` lets a desktop that wants mutual auth verify the phone with
/// the same construction from its own side.
class PskHandshake {
  PskHandshake._();

  /// How long to wait for the desktop's challenge response before giving up.
  static const Duration responseTimeout = Duration(seconds: 10);

  /// Runs the PSK challenge over [channel].
  ///
  /// [localFp] is the phone's own DTLS fingerprint; [remoteFp] is the
  /// desktop's. Throws [PskAuthException] on mismatch or timeout. The channel's
  /// [RpcChannel.incoming] stream is consumed only for the duration of the
  /// handshake — afterwards it is released for [JsonRpcClient] to own.
  static Future<void> run({
    required RemoteRpcChannelPort channel,
    required String psk,
    required String localFp,
    required String remoteFp,
  }) async {
    if (!channel.isOpen) {
      throw const PskAuthException('Channel closed before handshake');
    }

    final nonce = generateNonce();
    // Optional: prove our own possession of the PSK so the desktop can do
    // mutual auth. Computed from the phone's perspective.
    final proof = challengeResponse(
      nonce: nonce,
      psk: psk,
      localFingerprint: localFp,
      remoteFingerprint: remoteFp,
    );

    final response = await _exchange(
      channel: channel,
      request: <String, dynamic>{
        'type': 'auth_challenge',
        'nonce': nonce,
        'proof': proof,
      },
      nonce: nonce,
    );

    // The responder (desktop) computed R as
    // `challengeResponse(localFingerprint: <its local fp>, remoteFingerprint:
    // <its remote fp>)`. The desktop's local fp is *our* remote fp, and its
    // remote fp is *our* local fp — so we reproduce R with those swapped.
    final expected = challengeResponse(
      nonce: nonce,
      psk: psk,
      localFingerprint: remoteFp,
      remoteFingerprint: localFp,
    );

    if (!_constantTimeEquals(utf8.encode(expected), utf8.encode(response))) {
      throw const PskAuthException('Challenge response did not match');
    }
  }

  /// Sends [request], then waits for the matching `auth_response` on the
  /// channel. Throws on timeout or channel close.
  static Future<String> _exchange({
    required RemoteRpcChannelPort channel,
    required Map<String, dynamic> request,
    required String nonce,
  }) async {
    await channel.send(request);

    final completer = Completer<String>();
    late StreamSubscription<Map<String, dynamic>> sub;
    sub = channel.incoming.listen(
      (frame) {
        if (frame['type'] != 'auth_response') {
          return;
        }
        if (frame['nonce'] != nonce) {
          return;
        }
        final response = frame['response'];
        if (response is String && response.isNotEmpty) {
          completer.complete(response);
        } else {
          completer.completeError(
            const PskAuthException('Malformed challenge response'),
          );
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            const PskAuthException('Channel closed during handshake'),
          );
        }
      },
    );

    try {
      return await completer.future.timeout(
        responseTimeout,
        onTimeout: () {
          throw const PskAuthException(
            'Timed out waiting for challenge response',
          );
        },
      );
    } finally {
      await sub.cancel();
    }
  }

  // --- Crypto helpers (mirror desktop RemoteControlCrypto) ----------------

  /// Generates an 8-byte nonce, base64url-encoded without padding.
  static String generateNonce([Random? random]) {
    final rnd = random ?? Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(8, (_) => rnd.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// HMAC-SHA256 of [sdp] keyed by [psk], base64url without padding. Mirrors the
  /// desktop's `RemoteControlCrypto.signSdp`. The phone signs its offer SDP so
  /// the desktop can verify PSK possession *before* it answers / brings up DTLS
  /// (the mandatory pre-DTLS gate, finding #9).
  static String signSdp(String sdp, String psk) {
    final digest = Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(sdp));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// HMAC-SHA256 over `nonce|localFp|remoteFp` keyed by [psk], base64url
  /// without padding. The order is the signer's local-then-remote.
  static String challengeResponse({
    required String nonce,
    required String psk,
    required String localFingerprint,
    required String remoteFingerprint,
  }) {
    final message = '$nonce|$localFingerprint|$remoteFingerprint';
    final digest = Hmac(sha256, utf8.encode(psk)).convert(utf8.encode(message));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Constant-time byte comparison: returns true only when [a] and [b] are
  /// byte-identical and same length, without short-circuiting on the first
  /// differing byte.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
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

/// Thrown when the PSK channel handshake fails (mismatch, timeout, or the
/// channel dropped mid-handshake).
class PskAuthException implements Exception {
  const PskAuthException(this.message);

  final String message;

  @override
  String toString() => 'PskAuthException: $message';
}
