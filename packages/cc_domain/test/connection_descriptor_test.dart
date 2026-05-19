import 'package:cc_domain/cc_domain.dart';
import 'package:test/test.dart';

void main() {
  ConnectionDescriptor full() => ConnectionDescriptor(
    serverId: 'srv-1',
    serverName: 'Home box',
    fingerprint: 'a' * 64,
    paths: const [
      RelayPath(signalingUrl: 'wss://sig.example', room: 'room-1'),
      WssPath(uri: 'wss://cc.example.com'),
      LoopbackPath(port: 9030),
      LanPath(host: '192.168.1.20', port: 9030, tls: false),
      TailnetPath(host: 'box.tail1234.ts.net', port: 9030, tls: true),
    ],
    bulkHttpBase: 'https://cc.example.com',
    stunUrls: const ['stun:stun.example:3478'],
  );

  group('ConnectionDescriptor', () {
    test('encodes and decodes losslessly (QR/invite embedding)', () {
      final descriptor = full();
      final decoded = ConnectionDescriptor.decode(descriptor.encode());
      expect(decoded, descriptor);
      expect(decoded.paths, hasLength(5));
      expect(decoded.bulkHttpBase, 'https://cc.example.com');
    });

    test('ranks paths loopback > LAN > tailnet > wss > relay', () {
      final ranked = full().paths.toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));
      expect(ranked.map((p) => p.runtimeType).toList(), [
        LoopbackPath,
        LanPath,
        TailnetPath,
        WssPath,
        RelayPath,
      ]);
    });

    test(
      'only the relay path is not direct (drives the relayed indicator)',
      () {
        for (final path in full().paths) {
          expect(path.isDirect, path is! RelayPath, reason: '$path');
        }
      },
    );

    test(
      'unknown path tags are skipped, not fatal (forward compatibility)',
      () {
        final decoded = ConnectionDescriptor.fromJson({
          'v': 1,
          'sid': 'srv-1',
          'n': 'x',
          'fp': 'f' * 64,
          'p': [
            {'t': 'quantum-teleport', 'q': 1},
            {'t': 'wss', 'u': 'wss://cc.example.com'},
          ],
        });
        expect(decoded.paths.single, isA<WssPath>());
      },
    );

    test(
      'validation: requires serverId, fingerprint, and at least one path',
      () {
        expect(
          () => ConnectionDescriptor(
            serverId: '',
            serverName: 'x',
            fingerprint: 'f',
            paths: const [LoopbackPath(port: 1)],
          ),
          throwsArgumentError,
        );
        expect(
          () => ConnectionDescriptor(
            serverId: 's',
            serverName: 'x',
            fingerprint: '',
            paths: const [LoopbackPath(port: 1)],
          ),
          throwsArgumentError,
        );
        expect(
          () => ConnectionDescriptor(
            serverId: 's',
            serverName: 'x',
            fingerprint: 'f',
            paths: const [],
          ),
          throwsArgumentError,
        );
      },
    );

    test('rpc and probe URIs derive correctly per path kind', () {
      expect(
        const LoopbackPath(port: 9031).rpcUri.toString(),
        'ws://127.0.0.1:9031/rpc',
      );
      expect(
        const LanPath(
          host: 'box.local',
          port: 9030,
          tls: true,
        ).rpcUri.toString(),
        'wss://box.local:9030/rpc',
      );
      expect(
        const WssPath(uri: 'wss://cc.example.com').rpcUri.toString(),
        'wss://cc.example.com/rpc',
      );
      expect(
        const WssPath(uri: 'wss://cc.example.com/custom').rpcUri.toString(),
        'wss://cc.example.com/custom',
      );
      expect(
        const WssPath(uri: 'wss://cc.example.com').probeUri.toString(),
        'https://cc.example.com',
      );
      expect(
        const RelayPath(signalingUrl: 'wss://sig', room: 'r').rpcUri,
        isNull,
      );
    });

    test('withPaths replaces paths while keeping identity (descriptor '
        'refresh)', () {
      final updated = full().withPaths(const [
        WssPath(uri: 'wss://rotated.example'),
      ], newBulkHttpBase: 'https://rotated.example');
      expect(updated.serverId, 'srv-1');
      expect(updated.fingerprint, 'a' * 64);
      expect(updated.paths.single, isA<WssPath>());
      expect(updated.bulkHttpBase, 'https://rotated.example');
    });
  });
}
