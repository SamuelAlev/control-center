import 'dart:convert';
import 'dart:math';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteControlCrypto', () {
    test('PSK is 32 bytes base64url, no padding', () {
      final psk = RemoteControlCrypto.generatePsk();
      final bytes = base64Url.decode(base64Url.normalize(psk));
      expect(bytes.length, 32);
      expect(psk.contains('='), isFalse);
    });

    test('room code is 16 bytes', () {
      final code = RemoteControlCrypto.generateRoomCode();
      final bytes = base64Url.decode(base64Url.normalize(code));
      expect(bytes.length, 16);
    });

    test('constantTimeEquals is length-safe and correct', () {
      expect(
        RemoteControlCrypto.constantTimeEquals([1, 2, 3], [1, 2, 3]),
        isTrue,
      );
      expect(
        RemoteControlCrypto.constantTimeEquals([1, 2, 3], [1, 2, 4]),
        isFalse,
      );
      expect(
        RemoteControlCrypto.constantTimeEquals([1, 2], [1, 2, 3]),
        isFalse,
      );
    });

    test('deterministic with a fixed Random', () {
      final rng1 = Random(42);
      final rng2 = Random(42);
      expect(
        RemoteControlCrypto.generatePsk(rng1),
        RemoteControlCrypto.generatePsk(rng2),
      );
    });
  });
}
