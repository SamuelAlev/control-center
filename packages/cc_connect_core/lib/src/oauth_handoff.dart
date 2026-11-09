import 'dart:convert';

import 'package:cc_connect_core/src/encoding.dart';
import 'package:crypto/crypto.dart' as crypto;

/// A PKCE (RFC 7636, S256) pair. The server keeps [verifier]; only
/// [challenge] goes to Connect and the provider.
final class PkcePair {
  const PkcePair._(this.verifier, this.challenge);

  /// A fresh pair with a 43-character verifier (32 random bytes).
  factory PkcePair.generate() {
    final verifier = b64url(randomBytes(32));
    return PkcePair._(verifier, pkceChallengeFor(verifier));
  }

  /// The secret half.
  final String verifier;

  /// `BASE64URL(SHA256(verifier))`.
  final String challenge;
}

/// The S256 challenge for [verifier].
String pkceChallengeFor(String verifier) =>
    b64url(crypto.sha256.convert(ascii.encode(verifier)).bytes);

/// Whether [verifier] is a syntactically valid PKCE verifier.
bool isPkceVerifier(String verifier) =>
    RegExp(r'^[A-Za-z0-9._~-]{43,128}$').hasMatch(verifier);

/// Whether [challenge] is a syntactically valid S256 challenge.
bool isPkceChallenge(String challenge) =>
    RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(challenge);

/// Length of the browser confirm code.
const int confirmCodeLength = 8;

/// A fresh confirm code: [confirmCodeLength] Crockford characters (40 bits).
String newConfirmCode() =>
    crockfordBase32(randomBytes(5)).substring(0, confirmCodeLength);

/// Normalises a code a human typed: upper-case, separators dropped, and the
/// Crockford look-alikes folded (`O`→`0`, `I`/`L`→`1`). Null when what is
/// left is not a code.
String? normaliseConfirmCode(String typed) {
  final folded = typed
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]'), '')
      .replaceAll('O', '0')
      .replaceAll(RegExp('[IL]'), '1');
  if (folded.length != confirmCodeLength) {
    return null;
  }
  for (final unit in folded.split('')) {
    if (!crockfordAlphabet.contains(unit)) {
      return null;
    }
  }
  return folded;
}

/// The local deep link Connect's `/done` page offers. Opening it on the
/// approving person's own machine hands the code to the client that started
/// [loginId]; a client that did not start it knows the link is a phish.
Uri oauthDoneDeepLink({required String loginId, required String code}) => Uri(
  scheme: 'control-center',
  host: 'oauth-done',
  queryParameters: {'login_id': loginId, 'code': code},
);

/// Parses [oauthDoneDeepLink]; null for anything else.
({String loginId, String code})? parseOauthDoneDeepLink(Uri uri) {
  if (uri.scheme != 'control-center' || uri.host != 'oauth-done') {
    return null;
  }
  final loginId = uri.queryParameters['login_id'];
  final code = normaliseConfirmCode(uri.queryParameters['code'] ?? '');
  if (loginId == null || !isLoginId(loginId) || code == null) {
    return null;
  }
  return (loginId: loginId, code: code);
}

/// A fresh opaque login id (128 bits).
String newLoginId() => b64url(randomBytes(16));

/// Whether [value] has the shape of a login id.
bool isLoginId(String value) => RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(value);
