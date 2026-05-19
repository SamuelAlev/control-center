import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/core/server/lan_discovery.dart';
import 'package:control_center/core/server/loopback_discovery.dart';
import 'package:control_center/core/server/server_discovery.dart';
import 'package:control_center/core/server/server_entry_factory.dart';
import 'package:control_center/core/server/tailscale_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tailscalePeersFrom', () {
    test('parses online peers with IPv4 addresses, stripping the DNS dot', () {
      final peers = tailscalePeersFrom('''
{
  "Self": {"DNSName": "laptop.tail1234.ts.net.", "Online": true},
  "Peer": {
    "nodekey:1": {
      "HostName": "devbox",
      "DNSName": "devbox.tail1234.ts.net.",
      "Online": true,
      "TailscaleIPs": ["100.64.0.1", "fd7a:115c:a1e0::1"]
    }
  }
}
''');
      expect(peers, hasLength(1));
      expect(peers.single.name, 'devbox');
      expect(peers.single.dnsName, 'devbox.tail1234.ts.net');
      expect(peers.single.addresses, const ['100.64.0.1']);
      expect(peers.single.host, 'devbox.tail1234.ts.net');
    });

    test('skips offline peers, peers without IPv4, and Self', () {
      final peers = tailscalePeersFrom('''
{
  "Self": {
    "HostName": "laptop",
    "DNSName": "laptop.tail1234.ts.net.",
    "Online": true,
    "TailscaleIPs": ["100.64.0.9"]
  },
  "Peer": {
    "nodekey:1": {
      "HostName": "offline-box",
      "Online": false,
      "TailscaleIPs": ["100.64.0.2"]
    },
    "nodekey:2": {
      "HostName": "v6-only",
      "Online": true,
      "TailscaleIPs": ["fd7a:115c:a1e0::2"]
    },
    "nodekey:3": {
      "HostName": "no-ips",
      "Online": true
    }
  }
}
''');
      expect(peers, isEmpty);
    });

    test('falls back to the IP as host when MagicDNS is disabled', () {
      final peers = tailscalePeersFrom('''
{
  "Peer": {
    "nodekey:1": {
      "HostName": "devbox",
      "DNSName": "",
      "Online": true,
      "TailscaleIPs": ["100.64.0.1"]
    }
  }
}
''');
      expect(peers.single.host, '100.64.0.1');
    });

    test('malformed JSON and wrong shapes yield nothing', () {
      expect(tailscalePeersFrom('not json'), isEmpty);
      expect(tailscalePeersFrom('[]'), isEmpty);
      expect(tailscalePeersFrom('{"Peer": []}'), isEmpty);
      expect(tailscalePeersFrom('{}'), isEmpty);
    });
  });

  group('ServerDiscovery.watch', () {
    DiscoveredServer server(
      String id,
      DiscoverySource source, {
      String host = 'h',
    }) => DiscoveredServer(
      name: id,
      host: host,
      port: 9030,
      serverId: id,
      fingerprintPrefix: '',
      tls: true,
      source: source,
    );

    test(
      'LAN wins over tailnet even when the tailnet chunk lands first',
      () async {
        final discovery = ServerDiscovery(
          local: _FakeLocalDiscovery(),
          lan: _FakeLanDiscovery(
            // The LAN answer arrives AFTER the tailnet chunk below.
            delay: const Duration(milliseconds: 50),
            results: [server('s1', DiscoverySource.lan, host: 'lan-host')],
          ),
          tailnet: _FakeTailnetDiscovery(
            chunks: [
              [server('s1', DiscoverySource.tailscale, host: 'ts-host')],
            ],
          ),
        );
        final snapshots = await discovery.watch().toList();
        // First snapshot: the tailnet version (LAN not back yet).
        expect(snapshots.first.single.host, 'ts-host');
        // Final snapshot: the LAN version replaced it.
        final last = snapshots.last;
        expect(last, hasLength(1));
        expect(last.single.host, 'lan-host');
        expect(last.single.source, DiscoverySource.lan);
      },
    );

    test('de-dupes by serverId and unions distinct servers', () async {
      final discovery = ServerDiscovery(
        local: _FakeLocalDiscovery(),
        lan: _FakeLanDiscovery(results: [server('a', DiscoverySource.lan)]),
        tailnet: _FakeTailnetDiscovery(
          chunks: [
            [
              server('a', DiscoverySource.tailscale),
              server('b', DiscoverySource.tailscale),
            ],
          ],
        ),
      );
      final last = await discovery.discover();
      expect(last.map((s) => s.serverId), containsAll(<String>['a', 'b']));
      expect(last, hasLength(2));
    });

    test('a loopback server is found and badged local', () async {
      final discovery = ServerDiscovery(
        local: _FakeLocalDiscovery(
          results: [
            server('s-local', DiscoverySource.local, host: '127.0.0.1'),
          ],
        ),
        lan: _FakeLanDiscovery(),
        tailnet: _FakeTailnetDiscovery(),
      );
      final last = await discovery.discover();
      expect(last.single.serverId, 's-local');
      expect(last.single.source, DiscoverySource.local);
      expect(last.single.rpcUrl, 'wss://127.0.0.1:9030/rpc');
    });

    test('LAN wins over a local result for the same server', () async {
      final discovery = ServerDiscovery(
        local: _FakeLocalDiscovery(
          results: [server('s1', DiscoverySource.local, host: '127.0.0.1')],
        ),
        lan: _FakeLanDiscovery(
          results: [server('s1', DiscoverySource.lan, host: 'lan-host')],
        ),
        tailnet: _FakeTailnetDiscovery(),
      );
      final last = await discovery.discover();
      expect(last.single.host, 'lan-host');
    });

    test('a failing source still yields the other and completes', () async {
      final discovery = ServerDiscovery(
        local: _FakeLocalDiscovery(),
        lan: _FakeLanDiscovery(error: StateError('no multicast')),
        tailnet: _FakeTailnetDiscovery(
          chunks: [
            [server('b', DiscoverySource.tailscale)],
          ],
        ),
      );
      final last = await discovery.discover();
      expect(last.single.serverId, 'b');
    });
    test(
      'cancelling the watch subscription cancels the tailnet stream',
      () async {
        final tailnet = _FakeTailnetDiscovery(neverCompletes: true);
        final discovery = ServerDiscovery(
          local: _FakeLocalDiscovery(),
          lan: _FakeLanDiscovery(
            delay: const Duration(milliseconds: 50),
            results: const [],
          ),
          tailnet: tailnet,
        );
        final sub = discovery.watch().listen((_) {});
        await sub.cancel();
        // Let the tailnet stream's onCancel fire.
        await Future<void>.delayed(Duration.zero);
        expect(tailnet.cancelled, isTrue);
      },
    );
  });

  group('connectionPathFor', () {
    test('classifies a tailnet IP URL as TailnetPath, not WssPath', () {
      final path = connectionPathFor(Uri.parse('wss://100.64.0.1:9030/rpc'));
      expect(path, isA<TailnetPath>());
      expect((path as TailnetPath).host, '100.64.0.1');
      expect(path.port, 9030);
      expect(path.tls, isTrue);
    });

    test('classifies a MagicDNS URL as TailnetPath, preserving tls=false', () {
      final path = connectionPathFor(
        Uri.parse('ws://devbox.tail1234.ts.net:9030/rpc'),
      );
      expect(path, isA<TailnetPath>());
      expect((path as TailnetPath).tls, isFalse);
    });

    test('public TLS stays WssPath, LAN plaintext stays LanPath', () {
      expect(
        connectionPathFor(Uri.parse('wss://example.com:9030/rpc')),
        isA<WssPath>(),
      );
      expect(
        connectionPathFor(Uri.parse('ws://192.168.1.20:9030/rpc')),
        isA<LanPath>(),
      );
      expect(
        connectionPathFor(Uri.parse('ws://127.0.0.1:9030/rpc')),
        isA<LoopbackPath>(),
      );
    });
  });
}

class _FakeLocalDiscovery extends LoopbackServerDiscovery {
  _FakeLocalDiscovery({this.results = const []});

  final List<DiscoveredServer> results;

  @override
  Future<List<DiscoveredServer>> discover({
    int port = defaultCcServerPort,
  }) async => results;
}

class _FakeLanDiscovery extends LanServerDiscovery {
  _FakeLanDiscovery({this.results = const [], this.delay, this.error});

  final List<DiscoveredServer> results;
  final Duration? delay;
  final Object? error;

  @override
  Future<List<DiscoveredServer>> discover({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (error != null) {
      throw error!;
    }
    return results;
  }
}

class _FakeTailnetDiscovery extends TailscaleServerDiscovery {
  _FakeTailnetDiscovery({this.chunks = const [], this.neverCompletes = false});

  final List<List<DiscoveredServer>> chunks;

  /// When true the stream never emits nor completes — stands in for a slow
  /// tailnet probe, so a cancelled watch() subscription is the ONLY way it
  /// gets torn down (the cancellation test).
  final bool neverCompletes;
  bool cancelled = false;

  @override
  Stream<List<DiscoveredServer>> discoverStream({
    int port = defaultCcServerPort,
  }) {
    final controller = StreamController<List<DiscoveredServer>>()
      ..onCancel = () {
        cancelled = true;
      };
    if (neverCompletes) {
      return controller.stream;
    }
    for (final chunk in chunks) {
      controller.add(chunk);
    }
    unawaited(controller.close());
    return controller.stream;
  }
}
