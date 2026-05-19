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

    test('SDP signature round-trips', () {
      final psk = RemoteControlCrypto.generatePsk();
      const sdp = 'v=0\r\no=- 1 1 IN IP4 0.0.0.0\r\n';
      final sig = RemoteControlCrypto.signSdp(sdp, psk);
      expect(RemoteControlCrypto.verifySdpSignature(sdp, psk, sig), isTrue);
    });

    test('SDP signature rejects a different SDP (tampered fingerprint)', () {
      final psk = RemoteControlCrypto.generatePsk();
      const sdp = 'a=fingerprint:AA:BB\n';
      final sig = RemoteControlCrypto.signSdp(sdp, psk);
      expect(
        RemoteControlCrypto.verifySdpSignature(
          'a=fingerprint:CC:DD\n',
          psk,
          sig,
        ),
        isFalse,
      );
    });

    test('challenge response binds both fingerprints', () {
      final psk = RemoteControlCrypto.generatePsk();
      final nonce = RemoteControlCrypto.generateNonce();
      final resp = RemoteControlCrypto.respondToChallenge(
        nonce: nonce,
        psk: psk,
        localFingerprint: 'AA',
        remoteFingerprint: 'BB',
      );
      expect(
        RemoteControlCrypto.verifyChallengeResponse(
          nonce: nonce,
          psk: psk,
          localFingerprint: 'AA',
          remoteFingerprint: 'BB',
          response: resp,
        ),
        isTrue,
      );
      // Swapped fingerprints must fail.
      expect(
        RemoteControlCrypto.verifyChallengeResponse(
          nonce: nonce,
          psk: psk,
          localFingerprint: 'BB',
          remoteFingerprint: 'AA',
          response: resp,
        ),
        isFalse,
      );
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

  // PairingPayload (v2, descriptor-carrying) is covered in
  // packages/cc_domain/test/features/remote_control/pairing_payload_test.dart.

  // Locks the phone↔desktop PSK handshake direction so it can't silently
  // regress to the old mismatched roles. The phone is the initiator (sends
  // `auth_challenge` + proof); the desktop is the responder. `respondToChallenge`
  // here mirrors the phone's `challengeResponse` (identical HMAC) and the
  // fingerprint-order mappings mirror `psk_handshake.dart` (phone) and
  // `RemoteControlServer._authenticate` (desktop).
  group('PSK handshake (phone initiator ↔ desktop responder)', () {
    const psk = 'shared-psk-base64url';
    const nonce = 'nonce-from-phone';
    // Each peer's own DTLS fingerprint, as read from the negotiated SDP.
    const phoneFp = 'AA:BB:CC:DD';
    const desktopFp = 'EE:FF:00:11';

    test("desktop's response matches what the phone expects", () {
      // Phone perspective: localFp = phoneFp, remoteFp = desktopFp.
      final phoneExpectedResponse = RemoteControlCrypto.respondToChallenge(
        nonce: nonce,
        psk: psk,
        localFingerprint: desktopFp, // phone's remoteFp
        remoteFingerprint: phoneFp, // phone's localFp
      );
      // Desktop perspective: localFp = desktopFp, remoteFp = phoneFp.
      final desktopResponse = RemoteControlCrypto.respondToChallenge(
        nonce: nonce,
        psk: psk,
        localFingerprint: desktopFp,
        remoteFingerprint: phoneFp,
      );
      expect(desktopResponse, phoneExpectedResponse);
    });

    test("desktop accepts the phone's proof of PSK possession", () {
      // Phone's proof: HMAC(psk, nonce|phoneFp|desktopFp).
      final phoneProof = RemoteControlCrypto.respondToChallenge(
        nonce: nonce,
        psk: psk,
        localFingerprint: phoneFp,
        remoteFingerprint: desktopFp,
      );
      // Desktop verifies with the phone's perspective (remoteFp, localFp).
      expect(
        RemoteControlCrypto.verifyChallengeResponse(
          nonce: nonce,
          psk: psk,
          localFingerprint: phoneFp, // desktop's remoteFp
          remoteFingerprint: desktopFp, // desktop's localFp
          response: phoneProof,
        ),
        isTrue,
      );
    });

    test('a swapped fingerprint (broker MITM) fails the proof', () {
      final phoneProof = RemoteControlCrypto.respondToChallenge(
        nonce: nonce,
        psk: psk,
        localFingerprint: phoneFp,
        remoteFingerprint: desktopFp,
      );
      // The desktop sees a different local fingerprint (a broker swapped the
      // SDP) → the bound proof no longer verifies.
      expect(
        RemoteControlCrypto.verifyChallengeResponse(
          nonce: nonce,
          psk: psk,
          localFingerprint: phoneFp,
          remoteFingerprint: 'BA:D0:00:00',
          response: phoneProof,
        ),
        isFalse,
      );
    });
  });
}
