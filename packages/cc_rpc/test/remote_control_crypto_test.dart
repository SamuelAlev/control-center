import 'dart:convert';
import 'dart:math';

import 'package:cc_rpc/src/crypto/remote_control_crypto.dart';
import 'package:test/test.dart';

/// Pairing PSKs and relay admission tokens remain in use; the obsolete
/// SDP/nonce channel-authentication primitives are covered instead by Noise.
void main() {
  group('RemoteControlCrypto generation', () {
    test('generatePsk produces a 32-byte base64url pairing credential', () {
      final psk = RemoteControlCrypto.generatePsk(Random(42));
      expect(psk, isNot(contains('=')));
      expect(base64Url.decode(base64Url.normalize(psk)), hasLength(32));
    });

    test('generateRoomCode produces 16 bytes base64url (no padding)', () {
      final code = RemoteControlCrypto.generateRoomCode(Random(42));
      expect(code, isNot(contains('=')));
      // 16 bytes → ~22 base64url chars without padding.
      expect(code.length, 22);
    });

    test('generation is deterministic with a seeded Random', () {
      final a = RemoteControlCrypto.generatePsk(Random(1));
      final b = RemoteControlCrypto.generatePsk(Random(1));
      expect(a, b);
    });

    test('two different seeds produce different values', () {
      final a = RemoteControlCrypto.generatePsk(Random(1));
      final b = RemoteControlCrypto.generatePsk(Random(2));
      expect(a, isNot(b));
    });
  });

  group('RemoteControlCrypto relay admission', () {
    test('relayAdmissionToken is deterministic', () {
      expect(
        RemoteControlCrypto.relayAdmissionToken(psk: 'psk', room: 'room-1'),
        RemoteControlCrypto.relayAdmissionToken(psk: 'psk', room: 'room-1'),
      );
    });

    test('relayAdmissionToken differs per room', () {
      expect(
        RemoteControlCrypto.relayAdmissionToken(psk: 'psk', room: 'room-1'),
        isNot(
          RemoteControlCrypto.relayAdmissionToken(psk: 'psk', room: 'room-2'),
        ),
      );
    });

    test('relayAdmissionHash is a sha256 hex of the token', () {
      final token = RemoteControlCrypto.relayAdmissionToken(
        psk: 'psk',
        room: 'room-1',
      );
      final hash = RemoteControlCrypto.relayAdmissionHash(token);
      expect(hash.length, 64); // sha256 hex = 64 chars.
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });
  });

  group('RemoteControlCrypto proxy target signing', () {
    const psk = 'psk';
    const target = 'https://example.com/image.png';

    test('verifyProxyTarget accepts a valid signature', () {
      final sig = RemoteControlCrypto.signProxyTarget(target, psk);
      expect(RemoteControlCrypto.verifyProxyTarget(target, psk, sig), isTrue);
    });

    test('verifyProxyTarget rejects a different target (no replay)', () {
      final sig = RemoteControlCrypto.signProxyTarget(target, psk);
      expect(
        RemoteControlCrypto.verifyProxyTarget(
          'https://evil.com/x.png',
          psk,
          sig,
        ),
        isFalse,
      );
    });
  });

  group('RemoteControlCrypto constantTimeEquals', () {
    test('equal lists return true', () {
      expect(
        RemoteControlCrypto.constantTimeEquals([1, 2, 3], [1, 2, 3]),
        isTrue,
      );
    });

    test('unequal lists return false', () {
      expect(
        RemoteControlCrypto.constantTimeEquals([1, 2, 3], [1, 2, 4]),
        isFalse,
      );
    });

    test('different lengths return false', () {
      expect(
        RemoteControlCrypto.constantTimeEquals([1, 2], [1, 2, 3]),
        isFalse,
      );
    });

    test('empty lists are equal', () {
      expect(RemoteControlCrypto.constantTimeEquals([], []), isTrue);
    });
  });
}
