import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// A PKCE verifier/challenge pair (S256) for an OAuth authorization-code flow.
class Pkce {
  /// Creates a [Pkce].
  const Pkce({required this.verifier, required this.challenge});

  /// Generates a fresh verifier + its S256 challenge.
  factory Pkce.generate() {
    final verifier = _randomUrlToken(32);
    final digest = sha256.convert(ascii.encode(verifier));
    final challenge = _base64Url(digest.bytes);
    return Pkce(verifier: verifier, challenge: challenge);
  }

  /// The high-entropy verifier held by the client and sent at token exchange.
  final String verifier;

  /// The S256 challenge sent in the authorization request.
  final String challenge;
}

/// A random URL-safe state token for CSRF protection.
String randomOAuthState() => _randomUrlToken(24);

String _randomUrlToken(int bytes) {
  final rnd = Random.secure();
  return _base64Url(List<int>.generate(bytes, (_) => rnd.nextInt(256)));
}

/// Base64url-encodes [bytes] without padding (PKCE / OAuth convention).
String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');
