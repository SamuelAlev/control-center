import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Unit tests for [ResilientRpcClient] — the one stable client facade over a
/// [ServerConnectionSupervisor] that transparently survives path failover.
///
/// The supervisor is real (start → connect → adopt), but the
/// [ReachabilityResolver] is a scripted subclass returning hand-built
/// [RemoteRpcClient]s over [InProcessRpcChannel] pairs. A tiny server loop
/// answers `initialize` / `repo/call` / `session/list_workspaces` so the facade's
/// delegating methods, the call-wait budget, failover re-registration and
/// close semantics are all exercised without a socket.
void main() {
  const psk = 'psk';

  ConnectionDescriptor descriptor() => ConnectionDescriptor(
    serverId: 'srv-1',
    serverName: 'dev',
    fingerprint: '0123456789abcdef',
    paths: const [LoopbackPath(port: 9030)],
  );

  /// A started [RemoteRpcClient] over the client half of an in-process pair.
  (InProcessRpcChannel, RemoteRpcClient) makeClient() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    final client = RemoteRpcClient(
      clientChannel,
      timeout: const Duration(seconds: 5),
    )..start();
    return (server, client);
  }

  /// A scripted resolver returning the given connections in order.
  _ScriptedResolver resolver(List<ResolvedConnection> connections) =>
      _ScriptedResolver(connections);

  /// Builds a [ResolvedConnection] over a fresh in-process client and a server
  /// driver that answers the repo-RPC surface. Returns the holder so a test can
  /// stage failover by closing the server later. The holder records the request
  /// id for each method so a test can answer `sub/subscribe` precisely.
  _Conn scriptedConnection({
    String fingerprint = 'fp-AAAA',
    Map<String, dynamic> Function(String op)? answer,
  }) {
    final (server, client) = makeClient();
    final sentIds = <String, List<Object>>{};
    // Stored on the returned _Conn and cancelled on failover/close.
    // ignore: cancel_subscriptions
    final sub = server.incoming.listen((frame) async {
      final id = frame['id'];
      final method = frame['method'] as String?;
      if (method != null && id != null) {
        (sentIds[method] ??= []).add(id);
      }
      if (method == 'initialize') {
        await server.send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'capabilities': const {'subscriptions': true},
          },
        });
        return;
      }
      if (method == RpcMethods.listWorkspaces) {
        await server.send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {
            'workspaces': [
              {'id': 'ws-1', 'name': 'Workspace One'},
            ],
          },
        });
        return;
      }
      if (method == RpcMethods.repoCall) {
        final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
        final op = params['op'] as String? ?? '';
        if (answer != null) {
          final data = answer(op);
          await server.send({
            'jsonrpc': '2.0',
            'id': id,
            'result': {'op': op, 'data': data},
          });
          return;
        }
        await server.send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'op': op, 'data': const <String, dynamic>{}},
        });
      }
    });
    return _Conn(
      connection: ResolvedConnection(
        client: client,
        path: const LoopbackPath(port: 9030),
        latency: const Duration(milliseconds: 5),
        serverFingerprint: fingerprint,
      ),
      server: server,
      sub: sub,
      sentIds: sentIds,
    );
  }

  group('ResilientRpcClient delegation', () {
    test('call delegates to the live inner client', () async {
      final c = scriptedConnection(answer: (op) => {'echo': op});
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(
        () => sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
      );

      await sup.start();
      final resilient = ResilientRpcClient(sup);
      addTearDown(resilient.close);

      final data = await resilient.call('tickets.list', const {});
      expect(data, {'echo': 'tickets.list'});
    });

    test('callResult returns the whole result envelope', () async {
      final c = scriptedConnection(answer: (op) => {'k': 'v'});
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(
        () => sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
      );

      await sup.start();
      final resilient = ResilientRpcClient(sup);
      addTearDown(resilient.close);

      final result = await resilient.callResult('tickets.list', const {});
      expect(result['op'], 'tickets.list');
      expect(result['data'], {'k': 'v'});
    });

    test('initialize delegates and returns capabilities', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(
        () => sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
      );

      await sup.start();
      final resilient = ResilientRpcClient(sup);
      addTearDown(resilient.close);

      final result = await resilient.initialize();
      expect(result['capabilities'], {'subscriptions': true});
    });

    test('listWorkspaces delegates', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(
        () => sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
      );

      await sup.start();
      final resilient = ResilientRpcClient(sup);
      addTearDown(resilient.close);

      final workspaces = await resilient.listWorkspaces();
      expect(workspaces.single['id'], 'ws-1');
    });

    test('isOpen mirrors the inner client', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(
        () => sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
      );

      await sup.start();
      final resilient = ResilientRpcClient(sup);
      addTearDown(resilient.close);

      expect(resilient.isOpen, isTrue);
    });

    test('activeWorkspaceId propagates to the inner client', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(
        () => sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
      );

      await sup.start();
      final resilient = ResilientRpcClient(sup);
      addTearDown(resilient.close);

      resilient.activeWorkspaceId = 'ws-42';
      expect(resilient.activeWorkspaceId, 'ws-42');
      expect(c.connection.client.activeWorkspaceId, 'ws-42');
    });
  });

  group('ResilientRpcClient notifications + connection state', () {
    test('forwards server notifications through the merged stream', () async {
      final c = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([c.connection]),
      );
      addTearDown(
        () => sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
      );

      await sup.start();
      final resilient = ResilientRpcClient(sup);
      addTearDown(resilient.close);

      final received = <String>[];
      final sub = resilient.notifications.listen((n) => received.add(n.method));

      // Push a notification from the server (fire-and-forget send).
      unawaited(
        c.server.send({
          'jsonrpc': '2.0',
          'method': 'notifications/message_received',
          'params': {'id': 'm-1'},
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(received, ['notifications/message_received']);
      await sub.cancel();
    });

    test(
      'connectionState emits open then closed across the lifecycle',
      () async {
        final c = scriptedConnection();
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([c.connection]),
        );
        addTearDown(
          () =>
              sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
        );

        await sup.start();
        final resilient = ResilientRpcClient(sup);
        addTearDown(resilient.close);

        final states = <RemoteChannelState>[];
        final sub = resilient.connectionState.listen(states.add);
        addTearDown(sub.cancel);

        // Closing the supervisor flips phase to closed → connectionState emits
        // closed. (open was the initial _lastOpen, so only closed is new.)
        await sup.close();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(states, contains(RemoteChannelState.closed));
      },
    );
  });

  group('ResilientRpcClient failover (reconnect-and-resume)', () {
    test(
      'a call made while the path is down waits, then resumes on the new client',
      () async {
        // Two connections; the supervisor fails over from the first to the
        // second when the first transport drops.
        final first = scriptedConnection(answer: (op) => {'gen': 1});
        final second = scriptedConnection(answer: (op) => {'gen': 2});
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([first.connection, second.connection]),
        );
        addTearDown(
          () =>
              sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
        );

        await sup.start();
        final resilient = ResilientRpcClient(
          sup,
          callWait: const Duration(seconds: 3),
        );
        addTearDown(resilient.close);

        // Drop the live transport → path dead → reconnect emits a fresh client.
        // Closing the server half propagates closed state cleanly.
        await first.server.close();
        await first.sub.cancel();

        // The next call waits for the new client, then runs on it.
        final data = await resilient.call('tickets.list', const {});
        expect(data, {'gen': 2});
      },
    );

    test(
      'a call after the facade is closed throws immediately',
      timeout: const Timeout(Duration(seconds: 5)),
      () async {
        final c = scriptedConnection();
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([c.connection]),
        );
        addTearDown(
          () =>
              sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
        );

        await sup.start();
        final resilient = ResilientRpcClient(sup);

        // Closing the transport (so the inner client reports !isOpen) and then the
        // facade makes _live() take the _closed fast-path and throw.
        await c.server.close();
        await c.sub.cancel();
        await resilient.close().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );

        await expectLater(
          resilient.call('tickets.list', const {}),
          throwsA(isA<RemoteRpcClientClosedException>()),
        );
      },
    );

    test(
      'close fails in-flight waiters with a cancellation error',
      timeout: const Timeout(Duration(seconds: 5)),
      () async {
        final first = scriptedConnection();
        // The resolver has only one connection: after the first path drops, every
        // reconnect attempt is dry (throws) so no new client ever arrives and the
        // call's waiter stays pending until close() fails it.
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([first.connection]),
        );
        addTearDown(
          () =>
              sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
        );

        await sup.start();
        final resilient = ResilientRpcClient(
          sup,
          callWait: const Duration(seconds: 2),
        );

        // Drop the live path; the supervisor enters reconnecting (no client).
        await first.server.close();
        await first.sub.cancel();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Issue a call (it blocks waiting for a client that never comes). Register
        // the error expectation FIRST so the Future has a listener attached before
        // close() completes the waiter with an error (otherwise the error leaks to
        // the zone as unhandled in the gap before expectLater subscribes).
        final call = resilient.call('tickets.list', const {});
        final expectation = expectLater(
          call,
          throwsA(isA<RemoteRpcClientClosedException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await resilient.close().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );

        await expectation;
      },
    );
  });

  group('ResilientRpcClient subscribe (reconnect-and-resume)', () {
    test('delivers snapshots and re-registers across a failover', () async {
      final first = scriptedConnection();
      final second = scriptedConnection();
      final sup = ServerConnectionSupervisor(
        descriptor: descriptor(),
        deviceId: 'dev-1',
        psk: psk,
        resolver: resolver([first.connection, second.connection]),
      );
      addTearDown(
        () => sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
      );

      await sup.start();
      final resilient = ResilientRpcClient(sup);
      addTearDown(resilient.close);

      final snapshots = <Map<String, dynamic>>[];
      final sub = resilient
          .subscribe('tickets.watchForWorkspace', const {})
          .listen(snapshots.add);

      // Let the first session's sub/subscribe round-trip land and answer it.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      unawaited(
        first.server.send({
          'jsonrpc': '2.0',
          'id': first.subIdFor(RpcMethods.subscribe),
          'result': {'subscriptionId': 's-1'},
        }),
      );
      unawaited(
        first.server.send({
          'jsonrpc': '2.0',
          'method': RpcMethods.subSnapshot,
          'params': {
            'subscriptionId': 's-1',
            'rev': 1,
            'full': true,
            'data': {'tickets': 3},
          },
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(snapshots, hasLength(1));

      // Fail over to the second session; the resilient subscription
      // re-registers there.
      await first.server.close();
      await first.sub.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      unawaited(
        second.server.send({
          'jsonrpc': '2.0',
          'id': second.subIdFor(RpcMethods.subscribe),
          'result': {'subscriptionId': 's-2'},
        }),
      );
      unawaited(
        second.server.send({
          'jsonrpc': '2.0',
          'method': RpcMethods.subSnapshot,
          'params': {
            'subscriptionId': 's-2',
            'rev': 1,
            'full': true,
            'data': {'tickets': 7},
          },
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      // A new snapshot from the second session arrives on the same stream.
      expect(snapshots.last['tickets'], 7);

      await sub.cancel();
    });

    test(
      'a rejected subscribe on a live session is not re-issued (no storm)',
      () async {
        final c = scriptedConnection();
        final sup = ServerConnectionSupervisor(
          descriptor: descriptor(),
          deviceId: 'dev-1',
          psk: psk,
          resolver: resolver([c.connection]),
        );
        addTearDown(
          () =>
              sup.close().timeout(const Duration(seconds: 1), onTimeout: () {}),
        );

        await sup.start();
        final resilient = ResilientRpcClient(sup);
        addTearDown(resilient.close);

        final errors = <Object>[];
        var done = false;
        final sub = resilient
            .subscribe('terminal.output', const {'session_id': 'tty1-gone'})
            .listen((_) {}, onError: errors.add, onDone: () => done = true);
        addTearDown(sub.cancel);

        // The server rejects it — the session id predates its restart, so no
        // retry can succeed.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        unawaited(
          c.server.send({
            'jsonrpc': '2.0',
            'id': c.subIdFor(RpcMethods.subscribe),
            'error': {
              'code': RpcErrorCodes.notFound,
              'message': 'Terminal session not found: tty1-gone',
            },
          }),
        );

        // Re-issuing on the same live session would spin at round-trip speed —
        // the resubscribe storm that flooded the host log. Exactly one attempt.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(c.sentIds[RpcMethods.subscribe], hasLength(1));
        expect(errors, hasLength(1));
        expect(
          (errors.single as RemoteRpcException).code,
          RpcErrorCodes.notFound,
        );
        expect(done, isTrue);
      },
    );
  });
}

/// A scripted [ReachabilityResolver]: [connect] pops the next prepared
/// [ResolvedConnection] in order.
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
    return _connections.removeAt(0);
  }
}

/// A mutable holder pairing a scripted [ResolvedConnection] with its server
/// half, the live server driver subscription and the recorded request ids.
class _Conn {
  /// Creates a [_Conn].
  _Conn({
    required this.connection,
    required this.server,
    required this.sub,
    required this.sentIds,
  });

  /// The resolved connection handed to the supervisor.
  final ResolvedConnection connection;

  /// The server half of the in-process pair driving this connection.
  final InProcessRpcChannel server;

  /// The server driver's inbound subscription.
  final StreamSubscription<Map<String, dynamic>> sub;

  /// Request ids the client used, keyed by method (recorded by the driver).
  final Map<String, List<Object>> sentIds;

  /// The last request id the client used for [method], or null if not yet sent.
  Object? subIdFor(String method) {
    final ids = sentIds[method];
    return ids == null || ids.isEmpty ? null : ids.last;
  }
}
