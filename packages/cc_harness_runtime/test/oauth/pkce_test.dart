import 'dart:convert';

import 'package:cc_harness_runtime/src/oauth/pkce.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  test('generates a URL-safe verifier and a matching S256 challenge', () {
    final pkce = Pkce.generate();
    // Verifier is base64url without padding.
    expect(pkce.verifier, isNotEmpty);
    expect(pkce.verifier.contains('='), isFalse);
    expect(pkce.verifier.contains('+'), isFalse);
    expect(pkce.verifier.contains('/'), isFalse);

    // Challenge is S256(verifier), base64url without padding.
    final expected = base64Url
        .encode(sha256.convert(ascii.encode(pkce.verifier)).bytes)
        .replaceAll('=', '');
    expect(pkce.challenge, expected);
  });

  test('each generation is unique', () {
    expect(Pkce.generate().verifier, isNot(Pkce.generate().verifier));
    expect(randomOAuthState(), isNot(randomOAuthState()));
  });
}
