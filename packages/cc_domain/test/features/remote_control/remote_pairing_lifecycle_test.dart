import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 11, 12);

  test('a credential with no recorded expiry is expired', () {
    expect(RemotePairingLifecycle.isExpired(null, now), isTrue);
  });

  test('a credential is live until its expiry passes', () {
    final expiry = RemotePairingLifecycle.credentialExpiry(now);
    expect(RemotePairingLifecycle.isExpired(expiry, now), isFalse);
    expect(
      RemotePairingLifecycle.isExpired(
        expiry,
        expiry.add(const Duration(seconds: 1)),
      ),
      isTrue,
    );
  });
}
