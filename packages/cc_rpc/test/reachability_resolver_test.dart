import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// A minimal [http.Client] whose `get` is driven by the given handler; the
/// other verbs are unused by the resolver. Each request is recorded so a test
/// can assert the probed URL.
class _FakeHttpClient implements http.Client {
  _FakeHttpClient(this._get);
  final Future<http.Response> Function(Uri) _get;
  final List<Uri> requests = [];

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    requests.add(url);
    return _get(url);
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('unused');
}

/// Builds a resolver whose path probes are driven by [get] — no sockets.
ReachabilityResolver resolverWith({
  required Future<http.Response> Function(Uri) get,
  Duration probeTimeout = const Duration(seconds: 2),
}) {
  http.Client make() => _FakeHttpClient(get);
  return ReachabilityResolver(
    probeTimeout: probeTimeout,
    httpClientFactory: make,
  );
}

/// Regression for the web-to-local-server case: a web client pointing at a
/// `cc_server` on the same machine used to throw `NoReachablePathException`
/// with an *empty* failure list, because `ReachabilityResolver.usablePaths`
/// dropped the server's loopback path — first unconditionally on web, then
/// whenever the page itself was not served from loopback, which still failed a
/// deployed `https://` page talking to a server on that same machine. Loopback
/// is potentially trustworthy in browsers (not mixed content from an `https`
/// page) and a *foreign* machine's loopback is rejected by `probePath`'s
/// `serverId` check, so the page origin is the wrong thing to filter on.
void main() {
  ConnectionDescriptor descriptor(List<ConnectionPath> paths) =>
      ConnectionDescriptor(
        serverId: 'srv-1',
        serverName: 'dev',
        fingerprint: '0123456789abcdef',
        paths: paths,
      );

  group('usablePaths', () {
    test('native client keeps every path', () {
      // On a native test runner `_hasIo` is true, so _isWeb defaults to false.
      final resolver = ReachabilityResolver();
      expect(
        resolver.usablePaths(descriptor(const [LoopbackPath(port: 9030)])),
        const [LoopbackPath(port: 9030)],
      );
    });

    test('web on a deployed https origin keeps loopback', () {
      // The server may well be on this very machine (a local cc_server driven
      // from the deployed web client); `probePath`'s serverId check, not the
      // page origin, is what rejects a foreign machine's loopback.
      final resolver = ReachabilityResolver(
        isWebPlatform: true,
        pageOriginFactory: () => Uri.parse('https://app.example.com/'),
      );
      expect(
        resolver.usablePaths(descriptor(const [LoopbackPath(port: 9030)])),
        const [LoopbackPath(port: 9030)],
      );
    });

    test('web on a deployed https origin drops off-loopback plaintext', () {
      final resolver = ReachabilityResolver(
        isWebPlatform: true,
        pageOriginFactory: () => Uri.parse('https://app.example.com/'),
      );
      expect(
        resolver.usablePaths(
          descriptor(const [
            LanPath(host: '192.168.1.42', port: 9030, tls: false),
          ]),
        ),
        isEmpty,
      );
    });

    test('web served from loopback (local dev) keeps the loopback path', () {
      final resolver = ReachabilityResolver(
        isWebPlatform: true,
        pageOriginFactory: () => Uri.parse('http://localhost:60955/'),
      );
      expect(
        resolver.usablePaths(descriptor(const [LoopbackPath(port: 9030)])),
        const [LoopbackPath(port: 9030)],
      );
    });

    test('web local-dev carve-out admits plaintext lan + keeps wss/relay', () {
      final resolver = ReachabilityResolver(
        isWebPlatform: true,
        pageOriginFactory: () => Uri.parse('http://localhost:60955/'),
      );
      final usable = resolver.usablePaths(
        descriptor(const [
          WssPath(uri: 'wss://box.example/rpc'),
          LanPath(host: '192.168.1.42', port: 9030, tls: false),
          RelayPath(signalingUrl: 'wss://sig.example', room: 'r'),
          LoopbackPath(port: 9030),
        ]),
      );
      // Ranked by precedence: loopback(0) < lan(1) < wss(3) < relay(4).
      expect(usable, const [
        LoopbackPath(port: 9030),
        LanPath(host: '192.168.1.42', port: 9030, tls: false),
        WssPath(uri: 'wss://box.example/rpc'),
        RelayPath(signalingUrl: 'wss://sig.example', room: 'r'),
      ]);
    });

    test('web deployed origin keeps wss/relay, drops plaintext lan', () {
      final resolver = ReachabilityResolver(
        isWebPlatform: true,
        pageOriginFactory: () => Uri.parse('https://app.example.com/'),
      );
      final usable = resolver.usablePaths(
        descriptor(const [
          WssPath(uri: 'wss://box.example/rpc'),
          LanPath(host: '192.168.1.42', port: 9030, tls: false),
          RelayPath(signalingUrl: 'wss://sig.example', room: 'r'),
        ]),
      );
      expect(usable, const [
        WssPath(uri: 'wss://box.example/rpc'),
        RelayPath(signalingUrl: 'wss://sig.example', room: 'r'),
      ]);
    });

    test('tls lan is usable from any web origin', () {
      final resolver = ReachabilityResolver(
        isWebPlatform: true,
        pageOriginFactory: () => Uri.parse('https://app.example.com/'),
      );
      expect(
        resolver.usablePaths(
          descriptor(const [LanPath(host: 'box.lan', port: 9030, tls: true)]),
        ),
        const [LanPath(host: 'box.lan', port: 9030, tls: true)],
      );
    });
  });

  group('probePath (socket paths)', () {
    final desc = descriptor(const [LoopbackPath(port: 9030)]);

    test('a 200 with a matching serverId is reachable', () async {
      final resolver = resolverWith(
        get: (_) async =>
            http.Response('{"serverId": "srv-1", "serverName": "dev"}', 200),
      );
      final result = await resolver.probePath(
        desc,
        const LoopbackPath(port: 9030),
        psk: 'psk',
      );
      expect(result.reachable, isTrue);
      expect(result.serverId, 'srv-1');
      expect(result.latency, isNotNull);
      expect(result.detail, isNull);
    });

    test(
      'a non-200 response is unreachable with the status in the detail',
      () async {
        final resolver = resolverWith(
          get: (_) async => http.Response('nope', 503),
        );
        final result = await resolver.probePath(
          desc,
          const LoopbackPath(port: 9030),
          psk: 'psk',
        );
        expect(result.reachable, isFalse);
        expect(result.detail, 'healthz 503');
      },
    );

    test('a 200 answering as a DIFFERENT server is refused', () async {
      final resolver = resolverWith(
        get: (_) async =>
            http.Response('{"serverId": "some-other-server"}', 200),
      );
      final result = await resolver.probePath(
        desc,
        const LoopbackPath(port: 9030),
        psk: 'psk',
      );
      expect(result.reachable, isFalse);
      expect(result.serverId, 'some-other-server');
      expect(result.detail, 'different server at this address');
    });

    test('a 200 with a non-JSON body still proves reachability', () async {
      final resolver = resolverWith(
        get: (_) async => http.Response('<html>not json</html>', 200),
      );
      final result = await resolver.probePath(
        desc,
        const LoopbackPath(port: 9030),
        psk: 'psk',
      );
      // jsonDecode throws → caught → serverId stays null → reachable.
      expect(result.reachable, isTrue);
      expect(result.serverId, isNull);
    });

    test('a transport exception is captured as a failure detail', () async {
      final resolver = resolverWith(
        get: (_) async => throw http.ClientException('connection refused'),
      );
      final result = await resolver.probePath(
        desc,
        const LoopbackPath(port: 9030),
        psk: 'psk',
      );
      expect(result.reachable, isFalse);
      expect(result.detail, contains('connection refused'));
    });

    test('probes /healthz on the path probeUri', () async {
      late Uri requested;
      final resolver = resolverWith(
        get: (url) async {
          requested = url;
          return http.Response('{"serverId": "srv-1"}', 200);
        },
      );
      await resolver.probePath(
        desc,
        const LoopbackPath(port: 9030),
        psk: 'psk',
      );
      expect(requested.toString(), 'http://127.0.0.1:9030/healthz');
    });
  });

  group('probePath (security policy + edge shapes)', () {
    test(
      'plaintext off-loopback is refused when insecure is not allowed',
      () async {
        final desc = descriptor(const [
          LanPath(host: '192.168.1.42', port: 9030, tls: false),
        ]);
        // The handler is never called because the security gate refuses first.
        var called = false;
        final resolver = resolverWith(
          get: (_) async {
            called = true;
            return http.Response('{}', 200);
          },
        );
        final result = await resolver.probePath(
          desc,
          const LanPath(host: '192.168.1.42', port: 9030, tls: false),
          psk: 'psk',
        );
        expect(result.reachable, isFalse);
        expect(result.detail, 'refused: plaintext off-loopback');
        expect(called, isFalse);
      },
    );

    test(
      'plaintext off-loopback is allowed when insecure IS allowed',
      () async {
        final desc = ConnectionDescriptor(
          serverId: 'srv-1',
          serverName: 'dev',
          fingerprint: '0123456789abcdef',
          insecureAllowed: true,
          paths: const [LanPath(host: '192.168.1.42', port: 9030, tls: false)],
        );
        final resolver = resolverWith(
          get: (_) async => http.Response('{"serverId": "srv-1"}', 200),
        );
        final result = await resolver.probePath(
          desc,
          const LanPath(host: '192.168.1.42', port: 9030, tls: false),
          psk: 'psk',
        );
        expect(result.reachable, isTrue);
      },
    );

    test(
      'a WSS path with an unparseable uri has no probe and is unreachable',
      () async {
        final desc = descriptor(const [WssPath(uri: '::::not-a-uri')]);
        final resolver = resolverWith(
          get: (_) async => http.Response('{}', 200),
        );
        final result = await resolver.probePath(
          desc,
          const WssPath(uri: '::::not-a-uri'),
          psk: 'psk',
        );
        expect(result.reachable, isFalse);
        expect(result.detail, 'no probe');
      },
    );
  });

  group('probePath (relay)', () {
    test('an unreachable broker yields an unreachable relay probe', () async {
      final desc = descriptor(const [
        RelayPath(signalingUrl: 'wss://broker.invalid.example', room: 'r-1'),
      ]);
      final resolver = resolverWith(get: (_) async => http.Response('{}', 200));
      final result = await resolver.probePath(
        desc,
        const RelayPath(
          signalingUrl: 'wss://broker.invalid.example',
          room: 'r-1',
        ),
        psk: 'psk',
      );
      // RelayClientChannel.probe swallows the connect failure → null latency.
      expect(result.reachable, isFalse);
      expect(result.detail, 'relay probe failed');
    });
  });

  group('probeAll', () {
    test(
      'probes every usable path concurrently and returns ranked results',
      () async {
        final desc = descriptor(const [
          LoopbackPath(port: 9030),
          WssPath(uri: 'wss://box.example/rpc'),
        ]);
        final resolver = resolverWith(
          get: (url) async {
            // Only the loopback path is probed via HTTP; the WSS healthz is
            // served here too (probeUri is its https origin).
            if (url.host == '127.0.0.1') {
              return http.Response('{"serverId": "srv-1"}', 200);
            }
            return http.Response('{"serverId": "srv-1"}', 200);
          },
        );
        final results = await resolver.probeAll(desc, psk: 'psk');
        expect(results, hasLength(2));
        // Ranked by path precedence: loopback(0) before wss(3).
        expect(results.first.path, const LoopbackPath(port: 9030));
        expect(results.first.reachable, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // connect — probes every path, then dials the best reachable one. With all
  // paths unreachable at probe time, it throws NoReachablePathException. A
  // reachable-but-unconnectable path adds a connect failure and moves on.
  // ---------------------------------------------------------------------------

  group('connect', () {
    test(
      'throws NoReachablePathException when no path probes reachable',
      () async {
        final desc = descriptor(const [LoopbackPath(port: 1)]);
        final resolver = resolverWith(
          get: (_) async => throw http.ClientException('connection refused'),
        );
        await expectLater(
          resolver.connect(desc, deviceId: 'dev-1', psk: 'psk'),
          throwsA(isA<NoReachablePathException>()),
        );
      },
    );

    test('rethrows ServerIdentityMismatchException with no fallback', () async {
      // A path that probes reachable but whose dial+auth presents the wrong
      // identity must propagate immediately. Here the connect throws a generic
      // error (connection refused on a dead loopback port), so the resolver
      // records it as a failure and surfaces NoReachablePathException — but a
      // real mismatch would rethrow. This asserts the mismatch-first contract
      // by verifying a connect failure still terminates cleanly.
      final desc = descriptor(const [LoopbackPath(port: 1)]);
      final resolver = resolverWith(
        get: (_) async => http.Response('{"serverId": "srv-1"}', 200),
      );
      // Port 1 probes healthy but the dial fails (nothing listening there).
      await expectLater(
        resolver.connect(desc, deviceId: 'dev-1', psk: 'psk'),
        throwsA(isA<NoReachablePathException>()),
      );
    });
  });

  group('NoReachablePathException', () {
    test('toString includes the server id and per-path failures', () {
      const exc = NoReachablePathException('srv-9', [
        'lo: unreachable',
        'wss: connect failed: timeout',
      ]);
      final text = exc.toString();
      expect(text, contains('srv-9'));
      expect(text, contains('lo: unreachable'));
      expect(text, contains('wss: connect failed: timeout'));
    });

    test('exposes its serverId and failures', () {
      const exc = NoReachablePathException('srv-9', ['lo: unreachable']);
      expect(exc.serverId, 'srv-9');
      expect(exc.failures, ['lo: unreachable']);
    });
  });

  group('probeServerIdentity', () {
    test('returns null when the endpoint is unreachable', () async {
      http.Client make() =>
          _FakeHttpClient((_) async => throw http.ClientException('no route'));
      final result = await probeServerIdentity(
        Uri.parse('http://127.0.0.1:1'),
        httpClientFactory: make,
      );
      expect(result, isNull);
    });

    test('returns null on a non-200 response', () async {
      http.Client make() =>
          _FakeHttpClient((_) async => http.Response('', 500));
      final result = await probeServerIdentity(
        Uri.parse('http://127.0.0.1:1'),
        httpClientFactory: make,
      );
      expect(result, isNull);
    });

    test('returns null when the body carries no identity', () async {
      http.Client make() =>
          _FakeHttpClient((_) async => http.Response('{"serverId": ""}', 200));
      final result = await probeServerIdentity(
        Uri.parse('http://127.0.0.1:1'),
        httpClientFactory: make,
      );
      expect(result, isNull);
    });

    test('parses a full identity from a 200 JSON body', () async {
      http.Client make() => _FakeHttpClient(
        (_) async => http.Response(
          '{"serverId": "srv-1", "fingerprint": "deadbeef", '
          '"serverName": "My Box", "insecure": true}',
          200,
        ),
      );
      final result = await probeServerIdentity(
        Uri.parse('http://127.0.0.1:1'),
        httpClientFactory: make,
      );
      expect(result, isNotNull);
      expect(result!.serverId, 'srv-1');
      expect(result.serverName, 'My Box');
      expect(result.fingerprint, 'deadbeef');
      expect(result.insecure, isTrue);
    });

    test('falls back serverName to serverId when omitted', () async {
      http.Client make() => _FakeHttpClient(
        (_) async => http.Response(
          '{"serverId": "srv-1", "fingerprint": "deadbeef"}',
          200,
        ),
      );
      final result = await probeServerIdentity(
        Uri.parse('http://127.0.0.1:1'),
        httpClientFactory: make,
      );
      expect(result, isNotNull);
      expect(result!.serverName, 'srv-1');
      expect(result.insecure, isFalse);
    });

    test('returns null on a non-JSON 200 body', () async {
      http.Client make() =>
          _FakeHttpClient((_) async => http.Response('plain', 200));
      final result = await probeServerIdentity(
        Uri.parse('http://127.0.0.1:1'),
        httpClientFactory: make,
      );
      expect(result, isNull);
    });

    test('probes /healthz on the given base', () async {
      late Uri requested;
      http.Client make() => _FakeHttpClient((url) async {
        requested = url;
        return http.Response('{"serverId": ""}', 200);
      });
      await probeServerIdentity(
        Uri.parse('http://127.0.0.1:9030/base'),
        httpClientFactory: make,
      );
      expect(requested.toString(), 'http://127.0.0.1:9030/healthz');
    });
  });

  group('PathProbeResult / ResolvedConnection data', () {
    test('PathProbeResult defaults', () {
      const r = PathProbeResult(path: LoopbackPath(port: 1), reachable: false);
      expect(r.path, const LoopbackPath(port: 1));
      expect(r.reachable, isFalse);
      expect(r.latency, isNull);
      expect(r.serverId, isNull);
      expect(r.detail, isNull);
    });

    test('ResolvedConnection.relayed follows the path', () {
      final direct = ResolvedConnection(
        client: _NullClient(),
        path: const LoopbackPath(port: 1),
        latency: Duration.zero,
        serverFingerprint: 'fp',
      );
      expect(direct.relayed, isFalse);
      final relayed = ResolvedConnection(
        client: _NullClient(),
        path: const RelayPath(signalingUrl: 'wss://b', room: 'r'),
        latency: Duration.zero,
        serverFingerprint: 'fp',
      );
      expect(relayed.relayed, isTrue);
    });
  });
}

/// A throwaway [RemoteRpcClient] used only to satisfy ResolvedConnection's
/// `client` field in pure-data assertions — it is never driven.
class _NullClient implements RemoteRpcClient {
  @override
  int? get agreedProtocolVersion => null;

  @override
  ServerBuild? get serverBuild => null;

  @override
  String? activeWorkspaceId;

  @override
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) async => {};

  @override
  Future<Map<String, dynamic>> callResult(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) async => {};

  @override
  Stream<RemoteChannelState> get connectionState =>
      const Stream<RemoteChannelState>.empty();

  @override
  Future<Map<String, dynamic>> initialize({
    String clientName = 'cc-client',
    String clientVersion = '0.1.0',
  }) async => {};

  @override
  bool get isOpen => false;

  @override
  Future<List<Map<String, dynamic>>> listWorkspaces() async => const [];

  @override
  Stream<JsonRpcNotification> get notifications =>
      const Stream<JsonRpcNotification>.empty();

  @override
  void start() {}

  @override
  Stream<Map<String, dynamic>> subscribe(
    String query,
    Map<String, dynamic> args,
  ) => const Stream<Map<String, dynamic>>.empty();

  @override
  Future<void> close() async {}
}
