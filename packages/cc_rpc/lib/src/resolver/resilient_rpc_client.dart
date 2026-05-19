import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';
import 'package:cc_rpc/src/client/server_build.dart';
import 'package:cc_rpc/src/resolver/connection_supervisor.dart';

/// A [RemoteRpcClient]-compatible facade over a [ServerConnectionSupervisor]:
/// one stable client object for the app's whole life, across any number of
/// path failovers (PRD 15 §8 reconnect-and-resume).
///
/// * [call]s wait briefly for a live connection, then delegate. A request
///   that was already in flight when the path died fails with
///   [RemoteRpcClientClosedException] — it is **never** replayed (the server
///   may have executed it; callers own retry semantics until universal
///   idempotency lands with PRD 19).
/// * [subscribe] streams survive failover: each reconnect re-issues
///   `sub/subscribe` on the fresh session and the first emission is the
///   reconciliation snapshot, exactly the protocol's documented semantics.
///   Consumers keep one stream and simply see a new snapshot. What it does NOT
///   re-issue is a subscription the server *rejected* on a live session (a
///   `sub/subscribe` error or a `sub/error` push): that error is forwarded and
///   the stream ends, because retrying it only re-triggers the same rejection at
///   round-trip speed.
/// * [notifications] merges every successive session's pushes.
///
/// The richer connection state (path, latency, relayed/insecure) is on
/// [supervisor]`.status` — that is what the connection pill renders.
class ResilientRpcClient implements RemoteRpcClient {
  /// Wraps [supervisor]; call [ServerConnectionSupervisor.start] first (the
  /// boot flow owns first-connect errors), then construct this.
  ResilientRpcClient(this.supervisor, {Duration? callWait})
    : _callWait = callWait ?? const Duration(seconds: 15) {
    _inner = supervisor.client;
    _applyWorkspace(_inner);
    _wireInner(_inner);
    _clientsSub = supervisor.clients.listen((client) {
      _inner = client;
      _applyWorkspace(client);
      _wireInner(client);
      final waiters = List<Completer<RemoteRpcClient>>.of(_clientWaiters);
      _clientWaiters.clear();
      for (final w in waiters) {
        if (!w.isCompleted) {
          w.complete(client);
        }
      }
    });
    _statusSub = supervisor.status.listen((status) {
      final open = status.phase == ServerConnectionPhase.connected;
      if (open != _lastOpen && !_connectionState.isClosed) {
        _lastOpen = open;
        _connectionState.add(
          open ? RemoteChannelState.open : RemoteChannelState.closed,
        );
      }
      if ((status.phase == ServerConnectionPhase.closed ||
              status.phase == ServerConnectionPhase.identityMismatch) &&
          !_closed) {
        _failWaiters(
          StateError('server connection ended: ${status.phase.name}'),
        );
      }
    });
  }

  /// The owning supervisor (status stream, descriptor, pinned fingerprint).
  final ServerConnectionSupervisor supervisor;

  final Duration _callWait;
  RemoteRpcClient? _inner;
  String? _activeWorkspaceId;
  bool _closed = false;
  bool _lastOpen = true;

  StreamSubscription<RemoteRpcClient>? _clientsSub;
  StreamSubscription<ServerConnectionStatus>? _statusSub;
  StreamSubscription<JsonRpcNotification>? _notificationsSub;
  final List<Completer<RemoteRpcClient>> _clientWaiters = [];
  final StreamController<JsonRpcNotification> _notifications =
      StreamController<JsonRpcNotification>.broadcast();
  final StreamController<RemoteChannelState> _connectionState =
      StreamController<RemoteChannelState>.broadcast();

  void _wireInner(RemoteRpcClient? client) {
    unawaited(_notificationsSub?.cancel());
    _notificationsSub = client?.notifications.listen((n) {
      if (!_notifications.isClosed) {
        _notifications.add(n);
      }
    });
  }

  void _applyWorkspace(RemoteRpcClient? client) {
    if (client != null) {
      client.activeWorkspaceId = _activeWorkspaceId;
    }
  }

  void _failWaiters(Object error) {
    final waiters = List<Completer<RemoteRpcClient>>.of(_clientWaiters);
    _clientWaiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) {
        w.completeError(error);
      }
    }
  }

  Future<RemoteRpcClient> _live() async {
    final inner = _inner;
    if (inner != null && inner.isOpen) {
      return inner;
    }
    if (_closed) {
      throw const RemoteRpcClientClosedException('RPC client closed');
    }
    final waiter = Completer<RemoteRpcClient>();
    _clientWaiters.add(waiter);
    try {
      return await waiter.future.timeout(_callWait);
    } on TimeoutException {
      _clientWaiters.remove(waiter);
      throw const RemoteRpcClientClosedException(
        'No live server connection (still reconnecting).',
      );
    }
  }

  @override
  @override
  int? get agreedProtocolVersion => _inner?.agreedProtocolVersion;

  @override
  String? get activeWorkspaceId => _activeWorkspaceId;

  @override
  set activeWorkspaceId(String? value) {
    _activeWorkspaceId = value;
    _inner?.activeWorkspaceId = value;
  }

  @override
  Stream<JsonRpcNotification> get notifications => _notifications.stream;

  @override
  Stream<RemoteChannelState> get connectionState => _connectionState.stream;

  @override
  bool get isOpen => _inner?.isOpen ?? false;

  @override
  void start() {
    // Sessions are started by the supervisor as they are created.
  }

  @override
  Future<Map<String, dynamic>> initialize({
    String clientName = 'cc-client',
    String clientVersion = BuildInfo.buildVersion,
  }) async {
    final client = await _live();
    return client.initialize(
      clientName: clientName,
      clientVersion: clientVersion,
    );
  }

  /// The live session's advertised build identity (follows failover: each
  /// new session's `initialize` re-stamps the inner client). Null while no
  /// session has completed its handshake.
  @override
  ServerBuild? get serverBuild => _inner?.serverBuild;

  @override
  Future<List<Map<String, dynamic>>> listWorkspaces() async {
    final client = await _live();
    return client.listWorkspaces();
  }

  @override
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) async {
    final client = await _live();
    return client.call(
      op,
      args,
      opVersion: opVersion,
      idempotencyKey: idempotencyKey,
      dryRun: dryRun,
      timeout: timeout,
      coalesce: coalesce,
    );
  }

  @override
  Future<Map<String, dynamic>> callResult(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
    bool? coalesce,
  }) async {
    final client = await _live();
    return client.callResult(
      op,
      args,
      opVersion: opVersion,
      idempotencyKey: idempotencyKey,
      dryRun: dryRun,
      timeout: timeout,
      coalesce: coalesce,
    );
  }

  @override
  Stream<Map<String, dynamic>> subscribe(
    String query,
    Map<String, dynamic> args,
  ) {
    late final StreamController<Map<String, dynamic>> controller;
    StreamSubscription<Map<String, dynamic>>? innerSub;
    var cancelled = false;

    Future<void> attach() async {
      while (!cancelled && !_closed) {
        final RemoteRpcClient client;
        try {
          client = await _live();
        } catch (e, s) {
          if (!cancelled && !controller.isClosed) {
            // Still reconnecting past the wait budget: keep the stream open
            // and try again — a resilient subscription outlives outages.
            if (e is RemoteRpcClientClosedException && !_closed) {
              continue;
            }
            controller.addError(e, s);
            await controller.close();
          }
          return;
        }
        final done = Completer<void>();
        // Set when the SERVER actively failed this subscription (a
        // `sub/subscribe` error response or a `sub/error` push), as opposed to
        // the session merely ending under it.
        var failed = false;
        innerSub = client
            .subscribe(query, args)
            .listen(
              controller.add,
              onError: (Object error, StackTrace stack) {
                if (error is RemoteRpcClientClosedException) {
                  // Session died mid-flight; resubscribe on the next one.
                  if (!done.isCompleted) {
                    done.complete();
                  }
                  return;
                }
                failed = true;
                if (!controller.isClosed) {
                  controller.addError(error, stack);
                }
              },
              onDone: () {
                if (!done.isCompleted) {
                  done.complete();
                }
              },
            );
        await done.future;
        unawaited(innerSub?.cancel());
        innerSub = null;
        if (cancelled || _closed) {
          return;
        }
        // A server-side rejection on a session that is STILL LIVE is not
        // something reconnecting fixes: re-issuing the same `sub/subscribe`
        // re-triggers it as fast as the round trip allows. That is the
        // resubscribe storm (a client holding a terminal session id its server
        // no longer knows after a restart flooded the host log at round-trip
        // speed). Surface the error once — the consumer's retry policy owns
        // what happens next (`appProviderRetry` never retries an unrecoverable
        // code) — and end the stream. Failures observed while the transport is
        // already down are session deaths, not rejections, so those still
        // re-attach below.
        if (failed && (_inner?.isOpen ?? false)) {
          if (!controller.isClosed) {
            await controller.close();
          }
          return;
        }
        // The inner subscription ended because its session closed. Wait for
        // a fresh client (no timeout — outages can be long) and re-register.
        if (_inner == null || !_inner!.isOpen) {
          final waiter = Completer<RemoteRpcClient>();
          _clientWaiters.add(waiter);
          try {
            await waiter.future;
          } catch (_) {
            if (!controller.isClosed) {
              await controller.close();
            }
            return;
          }
        }
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () => unawaited(attach()),
      onCancel: () async {
        cancelled = true;
        await innerSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _failWaiters(const RemoteRpcClientClosedException('RPC client closed'));
    await _clientsSub?.cancel();
    await _statusSub?.cancel();
    await _notificationsSub?.cancel();
    await _notifications.close();
    await _connectionState.close();
    await supervisor.close();
  }
}
