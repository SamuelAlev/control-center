import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:test/test.dart';

void main() {
  ConnectionDescriptor descriptor() => ConnectionDescriptor(
    serverId: 'srv-1',
    serverName: 'Sam’s Mac',
    fingerprint: 'ab' * 32,
    paths: const [
      LanPath(host: '192.168.1.10', port: 9030, tls: true),
      WssPath(uri: 'wss://cc.example.com/rpc'),
      RelayPath(signalingUrl: 'wss://broker.example.com', room: 'room-1'),
    ],
    bulkHttpBase: 'https://cc.example.com',
  );

  PairingPayload sample() => PairingPayload(
    descriptor: descriptor(),
    deviceId: 'dev-1',
    psk: 'psk-base64url',
    expiresAt: DateTime.utc(2026, 1, 1, 12, 30),
  );

  group('PairingPayload v2', () {
    test('encode/decode round-trips the descriptor + credential', () {
      final decoded = PairingPayload.decode(sample().encode());
      expect(decoded.version, 2);
      expect(decoded.deviceId, 'dev-1');
      expect(decoded.psk, 'psk-base64url');
      expect(decoded.descriptor, descriptor());
      expect(
        decoded.expiresAt.isAtSameMomentAs(DateTime.utc(2026, 1, 1, 12, 30)),
        isTrue,
      );
    });

    test('serializes with compact keys (v/d/i/k/x only)', () {
      final json = sample().toJson();
      expect(json.keys.toSet(), {'v', 'd', 'i', 'k', 'x'});
      expect(json['v'], 2);
      expect(json['d'], descriptor().toJson());
    });

    test('a payload without a descriptor map is rejected', () {
      expect(
        () => PairingPayload.fromJson(const {'v': 2, 'i': 'dev', 'k': 'psk'}),
        throwsFormatException,
      );
      // The deleted v1 shape (s/r/k/i/t/m) has no `d` — it must not parse.
      expect(
        () => PairingPayload.fromJson(const {
          'v': 1,
          's': 'wss://broker',
          'r': 'room',
          'k': 'psk',
          'i': 'mac-1',
        }),
        throwsFormatException,
      );
    });

    test('deep link puts payload in the fragment', () {
      final link = sample().toDeepLink('remote.example.com');
      expect(link.startsWith('https://remote.example.com/#'), isTrue);
      // Nothing before the '#' leaks the PSK to the host.
      final beforeHash = link.substring(0, link.indexOf('#'));
      expect(beforeHash.contains('psk'), isFalse);
    });

    test('deep link uses http for loopback hosts (local dev has no TLS)', () {
      expect(
        sample()
            .toDeepLink('localhost:8081')
            .startsWith('http://localhost:8081/#'),
        isTrue,
      );
      expect(
        sample()
            .toDeepLink('127.0.0.1:8081')
            .startsWith('http://127.0.0.1:8081/#'),
        isTrue,
      );
    });

    test('deep link honours a host that already carries a scheme', () {
      expect(
        sample()
            .toDeepLink('http://localhost:8081')
            .startsWith('http://localhost:8081/#'),
        isTrue,
      );
      // A trailing slash on the origin is not doubled before the fragment.
      expect(
        sample().toDeepLink('https://remote.example.com/').contains('com//#'),
        isFalse,
      );
    });

    test('isExpired flips after expiry', () {
      final past = PairingPayload(
        descriptor: descriptor(),
        deviceId: '',
        psk: '',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final future = PairingPayload(
        descriptor: descriptor(),
        deviceId: '',
        psk: '',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      expect(past.isExpired, isTrue);
      expect(future.isExpired, isFalse);
    });
  });
}
