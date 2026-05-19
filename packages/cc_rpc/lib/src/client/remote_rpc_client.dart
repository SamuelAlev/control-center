import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';

/// Thrown when a `repo/call` returns a JSON-RPC error. [code] is one of
/// [RpcErrorCodes]; clients switch on it (e.g. roll back on a conflict).
class RemoteRpcException implements Exception {
  /// Creates a [RemoteRpcException].
  RemoteRpcException(this.code, this.message, [this.data]);

  /// Stable error code (see [RpcErrorCodes]).
  final int code;

  /// Human-readable message.
  final String message;

  /// Optional structured error data.
  final Object? data;

  @override
  String toString() => 'RemoteRpcException($code): $message';
}

/// The client half of the cc_rpc protocol — transport-agnostic.
///
/// Drives any [RemoteRpcChannelPort] (in-process, WSS, or WebRTC): correlates
/// `id`-bearing requests to responses, routes `sub/*` pushes to subscription
/// streams, and surfaces server notifications. This is what a desktop in REMOTE
/// mode and the full web build use to talk to a server; the same class is the
/// in-memory protocol-conformance harness in tests.
class RemoteRpcClient {
  /// Creates a client over the given channel. Call [start] before requests.
  RemoteRpcClient(this._channel, {Duration? timeout})
    : _timeout = timeout ?? const Duration(seconds: 30);

  final RemoteRpcChannelPort _channel;
  final Duration _timeout;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final Map<String, StreamController<Map<String, dynamic>>> _subs = {};
  final StreamController<JsonRpcNotification> _notifications =
      StreamController<JsonRpcNotification>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _incomingSub;
  int _nextId = 0;
  bool _closing = false;

  /// The workspace this client acts in. It is injected as `workspace_id` into
  /// every `call`/`subscribe` whose args don't already name one. The server is
  /// stateless — it holds no session workspace — so each request must carry its
  /// own. The app keeps this pointed at the active workspace (the route); a
  /// caller that targets a specific workspace passes `workspace_id` in args,
  /// which overrides this default.
  String? activeWorkspaceId;

  /// Server push notifications that are not subscription snapshots
  /// (e.g. `notifications/message_received`, `notifications/ticket_*`).
  Stream<JsonRpcNotification> get notifications => _notifications.stream;

  /// The underlying transport's connection state — `open`, then `closed` when
  /// the socket drops. Web/desktop-remote clients watch this to drive
  /// auto-reconnect (the client itself does not reconnect; it correlates frames
  /// on a single channel, so a new channel needs a new client).
  Stream<RemoteChannelState> get connectionState => _channel.state;

  /// Whether the underlying transport is currently open.
  bool get isOpen => _channel.isOpen;

  /// Begins consuming inbound frames. Idempotent.
  void start() {
    _incomingSub ??= _channel.incoming.listen(_onFrame);
  }

  /// Sends `initialize` and returns the result (incl. `capabilities`).
  Future<Map<String, dynamic>> initialize({
    String clientName = 'cc-client',
    String clientVersion = '0.1.0',
  }) async {
    final res = await _request('initialize', {
      'clientInfo': {'name': clientName, 'version': clientVersion},
      'protocol': {'min': 1, 'max': 2},
    });
    return (res['result'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// Lists the workspaces this session may bind to (for the switcher). Each
  /// entry is `{id, name}`; the server decides what the device is allowed to see.
  Future<List<Map<String, dynamic>>> listWorkspaces() async {
    final res = await _request(RpcMethods.listWorkspaces, const {});
    _throwIfError(res);
    final result = (res['result'] as Map?)?.cast<String, dynamic>() ?? {};
    final list = (result['workspaces'] as List?) ?? const [];
    return list.whereType<Map>().map((w) => w.cast<String, dynamic>()).toList();
  }

  /// Merges [activeWorkspaceId] into [args] as `workspace_id` unless the caller
  /// already named one (an explicit per-call workspace always wins). Returns
  /// [args] unchanged when there is no active workspace.
  Map<String, dynamic> _withWorkspace(Map<String, dynamic> args) {
    final ws = activeWorkspaceId;
    if (ws == null || args.containsKey('workspace_id')) {
      return args;
    }
    return {'workspace_id': ws, ...args};
  }

  /// Invokes a declared repo operation, returning its typed `data`. Throws
  /// [RemoteRpcException] on a JSON-RPC error.
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
  }) async {
    final res = await _request(RpcMethods.repoCall, {
      'op': op,
      'opVersion': ?opVersion,
      'args': _withWorkspace(args),
    });
    _throwIfError(res);
    final result = (res['result'] as Map).cast<String, dynamic>();
    return (result['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// Opens a reactive subscription. Each emission is a full snapshot map. The
  /// `sub/unsubscribe` is sent automatically when the returned stream is
  /// cancelled. On reconnect the caller re-subscribes (the first emission is the
  /// reconciliation).
  Stream<Map<String, dynamic>> subscribe(
    String query,
    Map<String, dynamic> args,
  ) {
    late final StreamController<Map<String, dynamic>> controller;
    String? subId;
    // Set the instant the listener cancels. The `sub/subscribe` round-trip is
    // async, so a cancel can land WHILE it is in flight — before `subId` exists.
    // `onCancel` then can't unsubscribe (it has no id yet), so the [onListen]
    // continuation reads this flag and tears the subscription down once the id
    // arrives. Without it, that continuation would register a dead controller
    // the client never unsubscribes — leaking one server-side subscription per
    // mount→subscribe→dispose churn until the per-session cap trips (-33011).
    var cancelled = false;
    controller = StreamController<Map<String, dynamic>>(
      onListen: () async {
        try {
          final res = await _request(RpcMethods.subscribe, {
            'query': query,
            'args': _withWorkspace(args),
          });
          if (res.containsKey('error')) {
            // The server created NO subscription on an error — nothing to
            // unsubscribe. This branch MUST return before the id block below so a
            // racing cancel (which set `cancelled`) can't trigger a spurious
            // unsubscribe for an id the server never issued.
            final err = (res['error'] as Map).cast<String, dynamic>();
            controller.addError(
              RemoteRpcException(
                err['code'] as int? ?? RpcErrorCodes.internalError,
                err['message'] as String? ?? 'subscribe failed',
              ),
            );
            await controller.close();
            return;
          }
          final id = ((res['result'] as Map)['subscriptionId']) as String?;
          if (id == null) {
            return;
          }
          if (cancelled) {
            // Cancelled mid-round-trip: `onCancel` already ran with `subId == null`
            // and skipped the unsubscribe. Tear the now-known server subscription
            // down and do NOT register the (already-dead) controller. This is the
            // one place that closes the leak.
            unawaited(_unsubscribe(id));
            return;
          }
          subId = id;
          _subs[id] = controller;
        } catch (e, s) {
          // A failed `sub/subscribe` (timeout, closed channel, send error) must
          // surface as a stream error, otherwise the controller stays open with
          // no data and no error — and its StreamProvider hangs in loading
          // forever instead of showing an error/retry state.
          if (!controller.isClosed) {
            controller.addError(e, s);
            await controller.close();
          }
        }
      },
      onCancel: () async {
        cancelled = true;
        final id = subId;
        if (id == null) {
          // The round-trip is still in flight; the [onListen] continuation will
          // observe `cancelled` and unsubscribe once it learns the id. The
          // `subId == null` vs `!= null` split keeps the two paths mutually
          // exclusive, so a subscription is unsubscribed exactly once.
          return;
        }
        _subs.remove(id);
        await _unsubscribe(id);
      },
    );
    return controller.stream;
  }

  /// Best-effort `sub/unsubscribe` for [subscriptionId]. Skips during [close]
  /// and on a dead channel: a request there never gets a response and would
  /// block for the full RPC timeout — once per live subscription, so close()
  /// on a dropped socket would hang ~timeout × N. The server drops a session's
  /// subscriptions when the connection ends anyway.
  Future<void> _unsubscribe(String subscriptionId) async {
    if (_closing || !_channel.isOpen) {
      return;
    }
    try {
      await _request(RpcMethods.unsubscribe, {
        'subscriptionId': subscriptionId,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Map<String, dynamic> params,
  ) async {
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    await _channel.send({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    return completer.future.timeout(
      _timeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('RPC $method timed out', _timeout);
      },
    );
  }

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (id is int && _pending.containsKey(id)) {
      _pending.remove(id)!.complete(frame);
      return;
    }
    final method = frame['method'];
    if (method is! String) {
      return;
    }
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case RpcMethods.subSnapshot:
        final subId = params['subscriptionId'] as String?;
        final data = (params['data'] as Map?)?.cast<String, dynamic>() ?? {};
        if (subId != null) {
          _subs[subId]?.add(data);
        }
      case RpcMethods.subError:
        final subId = params['subscriptionId'] as String?;
        final controller = subId == null ? null : _subs.remove(subId);
        if (controller != null && !controller.isClosed) {
          // Surface the server-side stream failure so the consumer's
          // StreamProvider transitions to AsyncError (retry UI) instead of
          // hanging in loading forever — a silent close here previously masked
          // any host-side subscription error as an infinite spinner.
          final code = params['code'] as int? ?? RpcErrorCodes.internalError;
          final kind = (params['data'] as Map?)?['kind'];
          controller.addError(
            RemoteRpcException(
              code,
              kind is String ? 'subscription error: $kind' : 'subscription error',
            ),
          );
          unawaited(controller.close());
        }
      default:
        _notifications.add(JsonRpcNotification(method: method, params: params));
    }
  }

  void _throwIfError(Map<String, dynamic> res) {
    final error = res['error'];
    if (error is Map) {
      throw RemoteRpcException(
        error['code'] as int? ?? RpcErrorCodes.internalError,
        error['message'] as String? ?? 'error',
        error['data'],
      );
    }
  }

  /// Closes the client (cancels inbound, fails pending, closes subscriptions).
  Future<void> close() async {
    _closing = true;
    await _incomingSub?.cancel();
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('client closed'));
      }
    }
    _pending.clear();
    // Snapshot the controllers and clear the map *before* closing them.
    // Closing a subscription controller drives its onCancel callback (set in
    // [subscribe]), which calls `_subs.remove(...)` — mutating `_subs` while
    // iterating its values would throw a ConcurrentModificationError. Clearing
    // first turns those removes into no-ops and we iterate the snapshot.
    final subs = _subs.values.toList();
    _subs.clear();
    for (final s in subs) {
      await s.close();
    }
    await _notifications.close();
  }
}
