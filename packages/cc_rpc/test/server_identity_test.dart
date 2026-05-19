import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  group('ServerIdentityCrypto', () {
    test(
      'a signed challenge verifies against the derived public key',
      () async {
        final seed = await ServerIdentityCrypto.generateSeed();
        final pub = await ServerIdentityCrypto.publicKeyFromSeed(seed);
        final sig = await ServerIdentityCrypto.signChallenge(
          seedB64: seed,
          nonce: 'nonce-123',
        );
        expect(
          await ServerIdentityCrypto.verifyChallenge(
            nonce: 'nonce-123',
            publicKeyB64: pub,
            signatureB64: sig,
          ),
          isTrue,
        );
      },
    );

    test('a replayed signature over a different nonce fails', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final pub = await ServerIdentityCrypto.publicKeyFromSeed(seed);
      final sig = await ServerIdentityCrypto.signChallenge(
        seedB64: seed,
        nonce: 'nonce-123',
      );
      expect(
        await ServerIdentityCrypto.verifyChallenge(
          nonce: 'nonce-456',
          publicKeyB64: pub,
          signatureB64: sig,
        ),
        isFalse,
      );
    });

    test('a different key cannot forge the proof', () async {
      final seedA = await ServerIdentityCrypto.generateSeed();
      final seedB = await ServerIdentityCrypto.generateSeed();
      final pubA = await ServerIdentityCrypto.publicKeyFromSeed(seedA);
      final sigB = await ServerIdentityCrypto.signChallenge(
        seedB64: seedB,
        nonce: 'nonce-123',
      );
      expect(
        await ServerIdentityCrypto.verifyChallenge(
          nonce: 'nonce-123',
          publicKeyB64: pubA,
          signatureB64: sigB,
        ),
        isFalse,
      );
    });

    test('the fingerprint is a stable sha256 hex of the public key', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final pub = await ServerIdentityCrypto.publicKeyFromSeed(seed);
      final fp1 = ServerIdentityCrypto.fingerprintOf(pub);
      final fp2 = ServerIdentityCrypto.fingerprintOf(pub);
      expect(fp1, fp2);
      expect(fp1, hasLength(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(fp1), isTrue);
    });

    test('malformed inputs fail closed instead of throwing', () async {
      expect(
        await ServerIdentityCrypto.verifyChallenge(
          nonce: 'n',
          publicKeyB64: '!!not-base64!!',
          signatureB64: 'zzz',
        ),
        isFalse,
      );
    });

    test('the seed round-trips to the same public key (persistence)', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final pub1 = await ServerIdentityCrypto.publicKeyFromSeed(seed);
      final pub2 = await ServerIdentityCrypto.publicKeyFromSeed(seed);
      expect(pub1, pub2);
    });
  });
}
