import 'package:cc_domain/core/domain/value_objects/connection_descriptor.dart';
import 'package:test/test.dart';

/// Exercises [ConnectionDescriptor] and the [ConnectionPath] sealed union:
/// JSON round-trip, encode/decode, copyWith, equality and the fromJson
/// dispatcher's forward-compat (unknown tag → null).
void main() {
  group('ConnectionPath.fromJson dispatcher', () {
    test('decodes a loopback path', () {
      final p = ConnectionPath.fromJson({'t': 'lo', 'port': 8080});
      expect(p, isA<LoopbackPath>());
      expect((p as LoopbackPath).port, 8080);
    });

    test('decodes a LAN path', () {
      final p = ConnectionPath.fromJson({
        't': 'lan',
        'h': 'host',
        'port': 443,
        'tls': true,
      });
      expect(p, isA<LanPath>());
      final lan = p as LanPath;
      expect(lan.host, 'host');
      expect(lan.port, 443);
      expect(lan.tls, isTrue);
    });

    test('decodes a tailnet path', () {
      final p = ConnectionPath.fromJson({'t': 'ts', 'h': 'tail', 'port': 8443});
      expect(p, isA<TailnetPath>());
      expect((p as TailnetPath).host, 'tail');
    });

    test('decodes a wss path', () {
      final p = ConnectionPath.fromJson({'t': 'wss', 'u': 'wss://host/rpc'});
      expect(p, isA<WssPath>());
      expect((p as WssPath).uri, 'wss://host/rpc');
    });

    test('decodes a relay path', () {
      final p = ConnectionPath.fromJson({
        't': 'rly',
        's': 'wss://sig',
        'r': 'room1',
      });
      expect(p, isA<RelayPath>());
      expect((p as RelayPath).room, 'room1');
    });

    test('returns null for an unknown tag (forward compat)', () {
      expect(ConnectionPath.fromJson({'t': 'future'}), isNull);
    });

    test('tolerates missing fields with defaults', () {
      final p = ConnectionPath.fromJson({'t': 'lo'});
      expect((p as LoopbackPath).port, 0);
    });
  });

  group('ConnectionPath toJson round-trip', () {
    test('loopback round-trips', () {
      const p = LoopbackPath(port: 9999);
      expect(ConnectionPath.fromJson(p.toJson()), p);
    });

    test('LAN round-trips', () {
      const p = LanPath(host: 'h', port: 443, tls: true);
      expect(ConnectionPath.fromJson(p.toJson()), p);
    });

    test('wss round-trips', () {
      const p = WssPath(uri: 'wss://x');
      expect(ConnectionPath.fromJson(p.toJson()), p);
    });

    test('relay round-trips', () {
      const p = RelayPath(signalingUrl: 'wss://s', room: 'r');
      expect(ConnectionPath.fromJson(p.toJson()), p);
    });
  });

  group('ConnectionPath properties', () {
    test('isDirect is true for loopback/LAN/tailnet/wss, false for relay', () {
      expect(const LoopbackPath(port: 1).isDirect, isTrue);
      expect(const LanPath(host: 'h', port: 1, tls: false).isDirect, isTrue);
      expect(const WssPath(uri: 'wss://x').isDirect, isTrue);
      expect(const RelayPath(signalingUrl: 's', room: 'r').isDirect, isFalse);
    });

    test('rank orders loopback best, relay worst', () {
      expect(
        const LoopbackPath(port: 1).rank,
        lessThan(const LanPath(host: 'h', port: 1, tls: false).rank),
      );
      expect(
        const RelayPath(signalingUrl: 's', room: 'r').rank,
        greaterThan(const WssPath(uri: 'wss://x').rank),
      );
    });
  });

  group('ConnectionDescriptor', () {
    ConnectionDescriptor descriptor() => ConnectionDescriptor(
      serverId: 'srv-1',
      serverName: 'My Server',
      fingerprint: 'abcdef0123456789',
      paths: const [LoopbackPath(port: 8080)],
      stunUrls: const ['stun:stun.l.google.com:19302'],
    );

    test('fromJson + toJson round-trip', () {
      final d = descriptor();
      expect(ConnectionDescriptor.fromJson(d.toJson()), d);
    });

    test('encode + decode round-trip', () {
      final d = descriptor();
      final encoded = d.encode();
      expect(encoded, isNotEmpty);
      expect(ConnectionDescriptor.decode(encoded), d);
    });

    test('withPaths preserves the other fields', () {
      final d = descriptor();
      final next = d.withPaths(const [WssPath(uri: 'wss://x')]);
      expect(next.paths.first, isA<WssPath>());
      expect(next.serverId, d.serverId);
      expect(next.serverName, d.serverName);
      expect(next.fingerprint, d.fingerprint);
    });

    test('withPaths forwards newBulkHttpBase', () {
      final d = descriptor();
      final next = d.withPaths(d.paths, newBulkHttpBase: 'https://bulk');
      expect(next.bulkHttpBase, 'https://bulk');
    });

    test('equality and hashCode', () {
      expect(descriptor(), descriptor());
      expect(descriptor().hashCode, descriptor().hashCode);
    });

    test('unequal when serverId differs', () {
      final a = descriptor();
      final b = ConnectionDescriptor(
        serverId: 'other',
        serverName: 'My Server',
        fingerprint: 'abcdef0123456789',
        paths: const [LoopbackPath(port: 8080)],
      );
      expect(a, isNot(b));
    });

    test('toString truncates the fingerprint', () {
      final d = descriptor();
      final s = d.toString();
      expect(s, contains('srv-1'));
      expect(s, contains('…'));
    });
  });
}
