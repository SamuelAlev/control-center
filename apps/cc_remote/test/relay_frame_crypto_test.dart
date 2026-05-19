import 'package:cc_remote/auth/relay_frame_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const psk = 'wADQ1h0u-EXAMPLE-pre-shared-key-0123456789';
  const plaintext = '{"jsonrpc":"2.0","id":1,"method":"repo/call"}';
  final fixedNonce = List<int>.generate(16, (i) => i);

  test('round-trips a frame through seal/open', () {
    final sealed = RelayFrameCrypto.seal(plaintext, psk);
    expect(RelayFrameCrypto.open(sealed, psk), plaintext);
  });

  test('open with the wrong PSK fails closed', () {
    final sealed = RelayFrameCrypto.seal(plaintext, psk);
    expect(
      () => RelayFrameCrypto.open(sealed, 'a-different-key'),
      throwsA(isA<RelayFrameAuthException>()),
    );
  });

  test('known-answer vector matches the cc_rpc canonical (interop lock)', () {
    // Identical to packages/cc_rpc/test/relay_frame_crypto_test.dart. If this
    // value diverges, the phone and cc_server can no longer decrypt each other.
    const kat =
        'AAECAwQFBgcICQoLDA0OD8_0q5xo0q_T9oJQhRLDUWdwq9HAWHkJKOADyu8paGvR'
        'czOLkfBwqI3j8J9n_BjVv_L_IfZX7y-CKGirNduAYc-mYprS3mXuP_-zL2zY';
    expect(RelayFrameCrypto.seal(plaintext, psk, nonceOverride: fixedNonce), kat);
    expect(RelayFrameCrypto.open(kat, psk), plaintext);
  });
}
