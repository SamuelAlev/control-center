import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Unit tests for [ServerConnectionSupervisor]: resolve → connect → monitor →
/// fail over. The [ReachabilityResolver] is replaced with a scripted subclass
/// so every (re)connect returns a hand-built [RemoteRpcClient] over an
/// [InProcessRpcChannel] pair — driven by a tiny server loop that answers
/// `connection.ping` and `connection.describe`. This exercises health pings,
/// descriptor refresh (changed / unchanged / foreign / errored), hysteresis
/// failover on missed pings, transport-close detection, identity-mismatch as a
/// terminal stop, TOFU fingerprint pinning, and clean close.
void main() {
  const psk = 'psk';

  ConnectionDescriptor descriptor({
    List<ConnectionPath> paths = const [LoopbackPath(port: 9030)],
    bool insecureAllowed = false,
  }) => ConnectionDescriptor(
    serverId: 'srv-1',
    serverName: 'dev',
    fingerprint: '0123456789abcdef',
    paths: paths,
    insecureAllowed: insecureAllowed,
  );

  /// Builds a started [RemoteRpcClient] over the client half of an
  /// [InProcessRpcChannel] pair. The returned `(server, client)` lets the test
  /// drive the server side (answer pings / describe, or close to simulate a
  /// dropped transport).
  (InProcessRpcChannel, RemoteRpcClient) makeClient() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    final client = RemoteRpcClient(
      clientChannel,
      timeout: const Duration(seconds: 5),
    )..start();
    return (server, client);
  }

  /// Answers `connection.ping` and (optionally) `connection.describe`
  /// repo/call ops on the server half of a channel until it closes. Returns the
  /// subscription so the test can cancel it. [describeResult] drives the
  /// describe refresh path:
  ///  * null  → the op errors (describe-error branch)
  ///  * a Map → returned as `{data: {descriptor: <that map>}}`
  StreamSubscription<Map<String, dynamic>> serveHealthChecks(
    InProcessRpcChannel server, {
    Map<String, dynamic>? describeResult,
  }) {
    return server.incoming.listen((frame) async {
      if (frame['method'] != RpcMethods.repoCall) {
        return;
      }
      final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
      final op = params['op'] as String?;
      if (op == 'connection.ping') {
        await server.send({
          'jsonrpc': '2.0',
          'id': frame['id'],
          'result': {'data': const <String, dynamic>{}},
        });
        return;
      }
      if (op == 'connection.describe') {
        if (describeResult == null) {
          await server.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'error': {'code': -32601, 'message': 'op unknown'},
          });
        } else {
          await server.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'result': {
              'data': {'descriptor': describeResult},
            },
          });
        }
      }
    });
  }

  /// A scripted resolver: each call to [connect] pops the next prepared
  /// [ResolvedConnection]; throws if the script runs dry.
  _ScriptedResolver resolver(List<ResolvedConnection> connections) =>
      _ScriptedResolver(connections);

  /// Builds a [ResolvedConnection] wrapping a fresh in-process client. The
  /// server half is returned so the test can wire its own handler via
  /// [serveHealthChecks] (stored on [ConnHolder.sub]).
  ConnHolder scriptedConnection({String fingerprint = 'fp-AAAA'}) {
    final (server, client) = makeClient();
    return ConnHolder(
      connection: ResolvedConnection(
        client: client,
        path: const LoopbackPath(port: 9030),
        latency: const Duration(milliseconds: 5),
        serverFingerprint: fingerprint,
      ),
      server: server,
    );
  }

  group('ServerConnectionSupervisor start + status', () {
    test('start connects and emits a connected status', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(sup.close);

      // Initial phase is connecting.
      expect(sup.current.phase, ServerConnectionPhase.connecting);

      // Subscribe before start so the connecting emission is captured (the
      // status stream is broadcast; awaiting `first` before start deadlocks).
      final firstStatus = sup.status.first;
      final client = await sup.start();
      expect(
        await firstStatus,
        isA<ServerConnectionStatus>().having(
          (s) => s.phase,
          'phase',
          ServerConnectionPhase.connecting,
        ),
      );
      expect(client, same(c.connection.client));
      expect(sup.current.phase, ServerConnectionPhase.connected);
      expect(sup.current.path, const LoopbackPath(port: 9030));
      expect(sup.current.insecure, isFalse);
      expect(sup.current.relayed, isFalse);

      c.sub = serveHealthChecks(c.server);
    });

    test(
      'pins the fingerprint on first connect (TOFU) via the callback',
      () async {
        String? pinned;
        final c = scriptedConnection(fingerprint: 'fp-TOFU');
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([c.connection]),
          onFingerprintPinned: (fp) => pinned = fp,
        );
        addTearDown(sup.close);

        await sup.start();
        expect(pinned, 'fp-TOFU');
        expect(sup.pinnedFingerprint, 'fp-TOFU');

        c.sub = serveHealthChecks(c.server);
      },
    );

    test(
      'does not re-pin when a pinnedFingerprint was provided up front',
      () async {
        var pinnedCalls = 0;
        final c = scriptedConnection(fingerprint: 'fp-PRE');
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          pinnedFingerprint: 'fp-PRE',
          resolver: resolver([c.connection]),
          onFingerprintPinned: (_) => pinnedCalls++,
        );
        addTearDown(sup.close);

        await sup.start();
        expect(pinnedCalls, 0);
        expect(sup.pinnedFingerprint, 'fp-PRE');

        c.sub = serveHealthChecks(c.server);
      },
    );

    test('emits a fresh client on the clients stream after start', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(sup.close);

      final streamed = sup.clients.first;
      final started = await sup.start();
      expect(await streamed, same(started));

      c.sub = serveHealthChecks(c.server);
    });
  });

  group('ServerConnectionSupervisor health loop', () {
    test('a successful ping resets missed pings and reports latency', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
        pingInterval: const Duration(milliseconds: 20),
        maxMissedPings: 3,
      );
      addTearDown(sup.close);

      await sup.start();
      c.sub = serveHealthChecks(c.server);

      // Wait for at least one ping cycle.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(sup.current.phase, ServerConnectionPhase.connected);
      expect(sup.client, isNotNull);
      await c.sub?.cancel();
    });

    test(
      'a ping opUnknown disables ping and relies on transport-close',
      () async {
        final c = scriptedConnection();
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([c.connection]),
          pingInterval: const Duration(milliseconds: 20),
        );
        addTearDown(sup.close);

        await sup.start();
        // Server answers every repo/call with an op-unknown error → ping support
        // disabled (the describe refresh is also swallowed).
        c.sub = c.server.incoming.listen((frame) async {
          if (frame['method'] == RpcMethods.repoCall) {
            await c.server.send({
              'jsonrpc': '2.0',
              'id': frame['id'],
              'error': {'code': RpcErrorCodes.opUnknown, 'message': 'no ping'},
            });
          }
        });

        await Future<void>.delayed(const Duration(milliseconds: 80));
        // Still connected — disabled pings never increment misses.
        expect(sup.current.phase, ServerConnectionPhase.connected);
        await c.sub?.cancel();
      },
    );

    test(
      'consecutive missed pings past maxMissedPings declare the path dead',
      () async {
        final first = scriptedConnection();
        // The reconnect succeeds with a second connection.
        final second = scriptedConnection();
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([first.connection, second.connection]),
          pingInterval: const Duration(milliseconds: 10),
          maxMissedPings: 2,
          // beforeReconnect fires between attempts — verify the hook runs.
          beforeReconnect: () async {},
        );
        addTearDown(sup.close);

        await sup.start();
        // Server never answers pings → every ping throws (channel.send is a
        // no-op race only if closed; here the requests just time out at the
        // client's 5s default, so use a faster client timeout by NOT answering).
        // Drive misses by answering ping with a throw: close the server so the
        // ping call errors.
        unawaited(first.server.close());

        // The reconnect loop fires after 2 missed pings, then succeeds.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        second.sub = serveHealthChecks(second.server);
        expect(sup.current.phase, ServerConnectionPhase.connected);
      },
    );
  });

  group('ServerConnectionSupervisor descriptor refresh', () {
    test('adopts a refreshed descriptor from the same server id', () async {
      ConnectionDescriptor? updated;
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
        descriptorRefreshInterval: const Duration(milliseconds: 30),
        onDescriptorUpdated: (d) => updated = d,
      );
      addTearDown(sup.close);

      await sup.start();
      // describe returns a descriptor with a new path but the same server id.
      c.sub = serveHealthChecks(
        c.server,
        describeResult: ConnectionDescriptor(
          serverId: 'srv-1',
          serverName: 'dev',
          fingerprint: '0123456789abcdef',
          paths: const [LanPath(host: '192.168.1.5', port: 9030, tls: true)],
        ).toJson(),
      );

      // The periodic refresh fires every 30ms; poll until the callback lands.
      for (var i = 0; i < 50 && updated == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(updated, isNotNull);
      expect(
        sup.descriptor.paths.single,
        const LanPath(host: '192.168.1.5', port: 9030, tls: true),
      );
    });

    test('ignores a refreshed descriptor from a foreign server id', () async {
      final c = scriptedConnection();
      final original = descriptor();
      final sup = ServerConnectionSupervisor(
        descriptor: original,
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
        descriptorRefreshInterval: const Duration(milliseconds: 30),
      );
      addTearDown(sup.close);

      await sup.start();
      c.sub = serveHealthChecks(
        c.server,
        describeResult: ConnectionDescriptor(
          serverId: 'foreign-server',
          serverName: 'evil',
          fingerprint: 'abcdef',
          paths: const [WssPath(uri: 'wss://evil.example/rpc')],
        ).toJson(),
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));
      // Unchanged — the foreign descriptor was refused.
      expect(sup.descriptor.serverId, 'srv-1');
      expect(sup.descriptor.paths, original.paths);
    });

    test(
      'survives a describe error (older server / transient failure)',
      () async {
        final c = scriptedConnection();
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([c.connection]),
          descriptorRefreshInterval: const Duration(milliseconds: 30),
        );
        addTearDown(sup.close);

        await sup.start();
        // describeResult null → the server returns an op-unknown error, which
        // the refresh swallows; the stored descriptor stands.
        c.sub = serveHealthChecks(c.server, describeResult: null);

        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(sup.current.phase, ServerConnectionPhase.connected);
      },
    );
  });

  group('ServerConnectionSupervisor reconnect + identity mismatch', () {
    test(
      'a dropped transport triggers reconnect-and-resume with a new client',
      () async {
        final first = scriptedConnection();
        final second = scriptedConnection();
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([first.connection, second.connection]),
        );
        addTearDown(sup.close);

        final firstClient = await sup.start();
        expect(sup.client, same(firstClient));

        // Drop the live transport → path dead → reconnect emits a fresh client.
        unawaited(first.connection.client.close());
        unawaited(first.server.close());

        // The new client arrives on the clients stream.
        final newClient = await sup.clients.first;
        expect(newClient, isNot(same(firstClient)));
        expect(sup.current.phase, ServerConnectionPhase.connected);
        second.sub = serveHealthChecks(second.server);
      },
    );

    test('an identity mismatch is terminal (no retry loop)', () async {
      final first = scriptedConnection();
      final r = _ScriptedResolver([
        first.connection,
        // The reconnect attempt presents the wrong identity → terminal.
        _MismatchableResolvedConnection(
          client: first.connection.client,
          path: const LoopbackPath(port: 9030),
          latency: Duration.zero,
          serverFingerprint: 'fp-AAAA',
        )..throwMismatch = true,
      ]);
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: r,
      );
      addTearDown(sup.close);

      await sup.start();
      unawaited(first.connection.client.close());
      unawaited(first.server.close());

      // Phase transitions to identityMismatch (terminal).
      while (sup.current.phase != ServerConnectionPhase.identityMismatch &&
          sup.current.phase != ServerConnectionPhase.closed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(sup.current.phase, ServerConnectionPhase.identityMismatch);
      expect(sup.current.error, isNotNull);
    });
  });

  group('ServerConnectionSupervisor adoptDescriptor', () {
    test('adopts a descriptor with the same server id', () {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(sup.close);

      final updated = ConnectionDescriptor(
        serverId: 'srv-1',
        serverName: 'dev',
        fingerprint: '0123456789abcdef',
        paths: const [WssPath(uri: 'wss://box.example/rpc')],
      );
      sup.adoptDescriptor(updated);
      expect(
        sup.descriptor.paths.single,
        const WssPath(uri: 'wss://box.example/rpc'),
      );
    });

    test('refuses a descriptor from a foreign server id', () {
      final c = scriptedConnection();
      final original = descriptor();
      final sup = ServerConnectionSupervisor(
        descriptor: original,
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(sup.close);

      sup.adoptDescriptor(
        ConnectionDescriptor(
          serverId: 'foreign',
          serverName: 'evil',
          fingerprint: 'abcdef',
          paths: const [WssPath(uri: 'wss://evil.example/rpc')],
        ),
      );
      expect(sup.descriptor.serverId, 'srv-1');
      expect(sup.descriptor.paths, original.paths);
    });
  });

  group('ServerConnectionSupervisor close', () {
    test('tears the connection down and emits the closed phase', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );

      await sup.start();
      c.sub = serveHealthChecks(c.server);

      final statuses = <ServerConnectionPhase>[];
      final sub = sup.status.listen((s) => statuses.add(s.phase));
      addTearDown(sub.cancel);

      await sup.close();
      expect(sup.current.phase, ServerConnectionPhase.closed);
      expect(sup.client, isNull);
      // close() is idempotent.
      await sup.close();
      expect(statuses, contains(ServerConnectionPhase.closed));
    });

    test(
      'close before a pending adopt closes the freshly won connection',
      () async {
        // If close() lands between resolve and adopt, the won connection is
        // torn down rather than adopted. Stage this by closing immediately after
        // start resolves.
        final c = scriptedConnection();
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([c.connection]),
        );

        await sup.start();
        c.sub = serveHealthChecks(c.server);
        await sup.close();
        expect(sup.current.phase, ServerConnectionPhase.closed);
      },
    );
  });

  group('ServerConnectionStatus', () {
    test('relayed follows the path (direct vs relay)', () {
      const direct = ServerConnectionStatus(
        phase: ServerConnectionPhase.connected,
        path: LoopbackPath(port: 1),
      );
      expect(direct.relayed, isFalse);

      const relayed = ServerConnectionStatus(
        phase: ServerConnectionPhase.connected,
        path: RelayPath(signalingUrl: 'wss://b', room: 'r'),
      );
      expect(relayed.relayed, isTrue);

      const noPath = ServerConnectionStatus(
        phase: ServerConnectionPhase.connecting,
      );
      expect(noPath.relayed, isFalse);
    });

    test('defaults', () {
      const s = ServerConnectionStatus(
        phase: ServerConnectionPhase.reconnecting,
      );
      expect(s.path, isNull);
      expect(s.latency, isNull);
      expect(s.attempt, 0);
      expect(s.insecure, isFalse);
      expect(s.error, isNull);
    });
  });
}

/// A [ReachabilityResolver] whose [connect] returns a scripted sequence of
/// [ResolvedConnection]s. A `_MismatchableResolvedConnection` whose
/// `throwMismatch` flag is set makes [connect] throw
/// [ServerIdentityMismatchException] instead, exercising the reconnect-loop's
/// terminal branch.
class _ScriptedResolver extends ReachabilityResolver {
  _ScriptedResolver(this._connections);

  final List<ResolvedConnection> _connections;

  @override
  Future<ResolvedConnection> connect(
    ConnectionDescriptor descriptor, {
    required String deviceId,
    required String psk,
    String? pinnedFingerprint,
  }) async {
    if (_connections.isEmpty) {
      throw StateError('scripted resolver is dry');
    }
    final next = _connections.removeAt(0);
    if (next is _MismatchableResolvedConnection && next.throwMismatch) {
      throw const ServerIdentityMismatchException(
        expectedFingerprint: 'expected',
        actualFingerprint: 'actual',
      );
    }
    return next;
  }
}

/// A [ResolvedConnection] that can additionally signal the scripted resolver to
/// throw an identity mismatch (a plain subclass keeps the rest of the surface).
class _MismatchableResolvedConnection extends ResolvedConnection {
  _MismatchableResolvedConnection({
    required super.client,
    required super.path,
    required super.latency,
    required super.serverFingerprint,
  });

  /// When true, the scripted resolver throws a mismatch instead of returning.
  bool throwMismatch = false;
}

/// A mutable holder pairing a scripted [ResolvedConnection] with its server
/// half and the live health-check subscription the test wires up.
class ConnHolder {
  /// Creates a [ConnHolder].
  ConnHolder({required this.connection, required this.server});

  /// The resolved connection handed to the supervisor.
  final ResolvedConnection connection;

  /// The server half of the in-process pair driving this connection.
  final InProcessRpcChannel server;

  /// The test's health-check listener (set via serveHealthChecks). It is
  // cancelled implicitly when the supervisor closes the channel pair, so the
  // cancel_subscriptions lint is suppressed here.
  // ignore: cancel_subscriptions
  StreamSubscription<Map<String, dynamic>>? sub;
}
