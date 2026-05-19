import 'dart:math';

import 'package:cc_rpc/src/crypto/remote_control_crypto.dart';
import 'package:test/test.dart';

/// Unit tests for [RemoteControlCrypto] — the pure cryptographic primitives for
/// remote-control pairing and channel auth. Covers generation, sign/verify
/// round-trips, tamper detection and constant-time comparison edge cases.
void main() {
  group('RemoteControlCrypto generation', () {
    test('generatePsk produces 32 bytes base64url (no padding)', () {
      final psk = RemoteControlCrypto.generatePsk(Random(42));
      expect(psk, isNot(contains('=')));
      // 32 bytes → ~43 base64url chars without padding.
      expect(psk.length, 43);
    });

    test('generateRoomCode produces 16 bytes base64url (no padding)', () {
      final code = RemoteControlCrypto.generateRoomCode(Random(42));
      expect(code, isNot(contains('=')));
      // 16 bytes → ~22 base64url chars without padding.
      expect(code.length, 22);
    });

    test('generateNonce produces 8 bytes base64url (no padding)', () {
      final nonce = RemoteControlCrypto.generateNonce(Random(42));
      expect(nonce, isNot(contains('=')));
      // 8 bytes → ~11 base64url chars without padding.
      expect(nonce.length, 11);
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

  group('RemoteControlCrypto SDP signature', () {
    const sdp = 'v=0\r\no=- 123 1 IN IP4 0.0.0.0\r\n';
    const psk = 'a-very-secret-pre-shared-key';

    test('signSdp is deterministic for the same inputs', () {
      expect(
        RemoteControlCrypto.signSdp(sdp, psk),
        RemoteControlCrypto.signSdp(sdp, psk),
      );
    });

    test('verifySdpSignature accepts a valid signature', () {
      final sig = RemoteControlCrypto.signSdp(sdp, psk);
      expect(RemoteControlCrypto.verifySdpSignature(sdp, psk, sig), isTrue);
    });

    test('verifySdpSignature rejects a tampered SDP', () {
      final sig = RemoteControlCrypto.signSdp(sdp, psk);
      expect(
        RemoteControlCrypto.verifySdpSignature('v=0\r\ntampered', psk, sig),
        isFalse,
      );
    });

    test('verifySdpSignature rejects a wrong PSK', () {
      final sig = RemoteControlCrypto.signSdp(sdp, psk);
      expect(
        RemoteControlCrypto.verifySdpSignature(sdp, 'wrong-psk', sig),
        isFalse,
      );
    });
  });

  group('RemoteControlCrypto nonce challenge', () {
    test('respondToChallenge is symmetric in verification', () {
      const psk = 'psk';
      final response = RemoteControlCrypto.respondToChallenge(
        nonce: 'n-1',
        psk: psk,
        localFingerprint: 'AA:BB',
        remoteFingerprint: 'CC:DD',
      );
      expect(
        RemoteControlCrypto.verifyChallengeResponse(
          nonce: 'n-1',
          psk: psk,
          localFingerprint: 'AA:BB',
          remoteFingerprint: 'CC:DD',
          response: response,
        ),
        isTrue,
      );
    });

    test('verifyChallengeResponse rejects a different nonce', () {
      const psk = 'psk';
      final response = RemoteControlCrypto.respondToChallenge(
        nonce: 'n-1',
        psk: psk,
        localFingerprint: 'AA:BB',
        remoteFingerprint: 'CC:DD',
      );
      expect(
        RemoteControlCrypto.verifyChallengeResponse(
          nonce: 'n-2',
          psk: psk,
          localFingerprint: 'AA:BB',
          remoteFingerprint: 'CC:DD',
          response: response,
        ),
        isFalse,
      );
    });

    test('verifyChallengeResponse rejects swapped fingerprints', () {
      const psk = 'psk';
      final response = RemoteControlCrypto.respondToChallenge(
        nonce: 'n-1',
        psk: psk,
        localFingerprint: 'AA:BB',
        remoteFingerprint: 'CC:DD',
      );
      // localFingerprint and remoteFingerprint swapped → different message.
      expect(
        RemoteControlCrypto.verifyChallengeResponse(
          nonce: 'n-1',
          psk: psk,
          localFingerprint: 'CC:DD',
          remoteFingerprint: 'AA:BB',
          response: response,
        ),
        isFalse,
      );
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
