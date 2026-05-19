import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  const psk = 'wADQ1h0u-EXAMPLE-pre-shared-key-0123456789';
  const plaintext = '{"jsonrpc":"2.0","id":1,"method":"repo/call"}';
  // A fixed 16-byte nonce so the sealed output is deterministic for the KAT.
  final fixedNonce = List<int>.generate(16, (i) => i);

  test('round-trips a frame through seal/open', () {
    final sealed = RelayFrameCrypto.seal(plaintext, psk);
    expect(sealed, isNot(contains('=')), reason: 'base64url, no padding');
    expect(RelayFrameCrypto.open(sealed, psk), plaintext);
  });

  test('a fresh nonce makes two seals of the same frame differ', () {
    final a = RelayFrameCrypto.seal(plaintext, psk);
    final b = RelayFrameCrypto.seal(plaintext, psk);
    expect(a, isNot(b), reason: 'per-frame random nonce');
    expect(RelayFrameCrypto.open(a, psk), plaintext);
    expect(RelayFrameCrypto.open(b, psk), plaintext);
  });

  test('open with the wrong PSK fails closed (authentication)', () {
    final sealed = RelayFrameCrypto.seal(plaintext, psk);
    expect(
      () => RelayFrameCrypto.open(sealed, 'a-different-key'),
      throwsA(isA<RelayFrameAuthException>()),
    );
  });

  test('a tampered ciphertext fails the MAC', () {
    final sealed = RelayFrameCrypto.seal(plaintext, psk, nonceOverride: fixedNonce);
    // Flip the last base64 char to mutate the ciphertext tail.
    final tampered = sealed.substring(0, sealed.length - 1) +
        (sealed.endsWith('A') ? 'B' : 'A');
    expect(
      () => RelayFrameCrypto.open(tampered, psk),
      throwsA(isA<RelayFrameAuthException>()),
    );
  });

  test('too-short / garbage tokens throw instead of returning bytes', () {
    expect(() => RelayFrameCrypto.open('', psk),
        throwsA(isA<RelayFrameAuthException>()));
    expect(() => RelayFrameCrypto.open('!!!not-base64!!!', psk),
        throwsA(isA<RelayFrameAuthException>()));
  });

  test('known-answer vector — locks the wire format across both impls', () {
    // The phone (cc_remote) mirrors RelayFrameCrypto byte-for-byte; this exact
    // vector is asserted on BOTH sides, so any divergence in KDF labels, CTR
    // counter encoding, field order, or base64 mode breaks one of them.
    final sealed = RelayFrameCrypto.seal(plaintext, psk, nonceOverride: fixedNonce);
    expect(sealed, _kat);
    expect(RelayFrameCrypto.open(_kat, psk), plaintext);
  });
}

/// Known-answer output of `seal(plaintext, psk, nonceOverride: 0..15)`.
const _kat =
    'AAECAwQFBgcICQoLDA0OD8_0q5xo0q_T9oJQhRLDUWdwq9HAWHkJKOADyu8paGvR'
    'czOLkfBwqI3j8J9n_BjVv_L_IfZX7y-CKGirNduAYc-mYprS3mXuP_-zL2zY';
