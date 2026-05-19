import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A PKCE (RFC 7636) verifier/challenge pair plus a CSRF state nonce, generated
/// for one OAuth authorization round-trip.
class PkcePair {
  /// Creates a [PkcePair].
  const PkcePair({
    required this.codeVerifier,
    required this.codeChallenge,
    required this.state,
  });

  /// Generates a fresh pair using a cryptographically secure RNG.
  ///
  /// The verifier is 32 random bytes, base64url-encoded (43 chars, within the
  /// RFC's 43–128 range). The challenge is `BASE64URL(SHA256(verifier))` and the
  /// method is always `S256`. The [state] nonce is an independent 16 random
  /// bytes, base64url-encoded.
  factory PkcePair.generate() {
    final rng = Random.secure();
    final verifierBytes = Uint8List.fromList(
      List<int>.generate(32, (_) => rng.nextInt(256)),
    );
    final verifier = _base64Url(verifierBytes);
    final challenge = _base64Url(
      Uint8List.fromList(sha256.convert(ascii.encode(verifier)).bytes),
    );
    final stateBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => rng.nextInt(256)),
    );
    return PkcePair(
      codeVerifier: verifier,
      codeChallenge: challenge,
      state: _base64Url(stateBytes),
    );
  }

  /// The PKCE code verifier (kept secret, sent at token exchange).
  final String codeVerifier;

  /// The PKCE code challenge (`S256` of the verifier), sent on the auth request.
  final String codeChallenge;

  /// The CSRF state nonce echoed back on the callback.
  final String state;

  /// The PKCE challenge method (always `S256`).
  String get codeChallengeMethod => 'S256';

  static String _base64Url(Uint8List bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}
