import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/server_build.dart';

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

/// Signalled to in-flight requests when the [RemoteRpcClient] is closed
/// (e.g. the server disconnected/restarted). Not an error — a cancellation.
class RemoteRpcClientClosedException implements Exception {
  /// Creates a [RemoteRpcClientClosedException].
  const RemoteRpcClientClosedException([this.message]);

  /// Human-readable message.
  final String? message;

  @override
  String toString() => message ?? 'RPC client closed';
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

  /// Live shared subscriptions, keyed by `(query, effective-args)`. Lets
  /// several callers of [subscribe] with identical coordinates share ONE
  /// server subscription (ref-counted) instead of each opening its own. See
  /// [subscribe].
  final Map<String, _SharedSubscription> _shared = {};
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

  /// The connected server's build identity from the last `initialize`
  /// response — its advertised version, git sha, and repo-RPC catalog
  /// version. Null before initialize completes or when the server predates
  /// these fields (an old server is exactly the mismatch worth surfacing).
  ServerBuild? get serverBuild => _serverBuild;
  ServerBuild? _serverBuild;

  /// Sends `initialize` and returns the result (incl. `capabilities`).
  ///
  /// The default [clientVersion] is the CI-stamped [BuildInfo.buildVersion]
  /// the client was compiled with, so every caller reports the truth without
  /// each of them threading a version string.
  Future<Map<String, dynamic>> initialize({
    String clientName = 'cc-client',
    String clientVersion = BuildInfo.buildVersion,
  }) async {
    final res = await _request('initialize', {
      'clientInfo': {'name': clientName, 'version': clientVersion},
      'protocol': {'min': 1, 'max': 2},
    });
    final result = (res['result'] as Map?)?.cast<String, dynamic>() ?? {};
    _serverBuild = ServerBuild.fromInitializeResult(result);
    return result;
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
  ///
  /// [idempotencyKey] (PRD 19 §3) is a first-class field of the envelope, minted
  /// once per *logical action* and reused across every retry of that intent, so
  /// a double-click / reconnect replay / offline flush collapse to one apply.
  /// [dryRun] (PRD 19 §4) asks the server for the op's [ActionPreview] instead
  /// of applying it (only ops that declare a preview support it).
  /// [timeout] overrides the client-wide request timeout for long-running ops
  /// (e.g. a newsfeed refresh that fetches every feed host-side).
  Future<Map<String, dynamic>> call(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
  }) async {
    final res = await callResult(
      op,
      args,
      opVersion: opVersion,
      idempotencyKey: idempotencyKey,
      dryRun: dryRun,
      timeout: timeout,
    );
    return (res['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  /// As [call], but returns the whole `result` envelope — `{op, data,
  /// deduplicated?, dry_run?}` — for callers that need to observe the
  /// idempotency/dry-run flags (bulk ops, the mutation queue, tests).
  Future<Map<String, dynamic>> callResult(
    String op,
    Map<String, dynamic> args, {
    int? opVersion,
    String? idempotencyKey,
    bool dryRun = false,
    Duration? timeout,
  }) async {
    final res = await _request(RpcMethods.repoCall, {
      'op': op,
      'opVersion': ?opVersion,
      'idempotency_key': ?idempotencyKey,
      if (dryRun) 'dry_run': true,
      'args': _withWorkspace(args),
    }, timeout: timeout);
    _throwIfError(res);
    return (res['result'] as Map).cast<String, dynamic>();
  }

  /// Opens a reactive subscription. Each emission is a full snapshot map. The
  /// `sub/unsubscribe` is sent automatically when the returned stream is
  /// cancelled. On reconnect the caller re-subscribes (the first emission is the
  /// reconciliation).
  ///
  /// Deduplicates identical live subscriptions: several callers with the same
  /// `(query, effective-args)` share ONE server subscription, ref-counted, and
  /// each server subscription runs its own (potentially GitHub-hitting) SWR
  /// revalidation — so undeduped churn multiplies upstream API load. Riverpod
  /// already collapses watchers of one family-keyed provider, but *distinct*
  /// providers (or autoDispose churn during navigation) can still request the
  /// same coordinates concurrently; this catches those. Late joiners are
  /// replayed the last snapshot so their stream still gets an immediate first
  /// emission. Best-effort: if the args can't be canonicalised the same way for
  /// two callers, they simply don't share — never wrong, just less deduped.
  Stream<Map<String, dynamic>> subscribe(
    String query,
    Map<String, dynamic> args,
  ) {
    final effectiveArgs = _withWorkspace(args);
    final key = _subKey(query, effectiveArgs);
    final shared = _shared.putIfAbsent(
      key,
      () => _SharedSubscription(
        _subscribeRaw(query, effectiveArgs),
        onEmpty: () => _shared.remove(key),
      ),
    );
    return shared.attach();
  }

  /// Stable dedupe key for a subscription. Sorts the top-level args so callers
  /// that build the map in a different order still collide (subscription args
  /// are flat coordinate maps). A mismatch only costs a missed dedupe, never
  /// correctness.
  static String _subKey(String query, Map<String, dynamic> args) {
    final keys = args.keys.toList()..sort();
    return '$query${jsonEncode({for (final k in keys) k: args[k]})}';
  }

  /// The undeduped single subscription — one server subscription per call.
  /// [subscribe] layers ref-counted sharing over this.
  Stream<Map<String, dynamic>> _subscribeRaw(
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
    Map<String, dynamic> params, {
    Duration? timeout,
  }) async {
    final id = ++_nextId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    await _channel.send({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    });
    final effectiveTimeout = timeout ?? _timeout;
    return completer.future.timeout(
      effectiveTimeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('RPC $method timed out', effectiveTimeout);
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
              kind is String
                  ? 'subscription error: $kind'
                  : 'subscription error',
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
        c.completeError(
          const RemoteRpcClientClosedException(
            'RPC client closed; pending requests cancelled.',
          ),
        );
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
    // The shared subscriptions wrap those `_subs` streams; closing the sources
    // drives each shared layer's onDone → it closes its listeners and removes
    // itself from [_shared]. Clear defensively in case any had not yet started.
    _shared.clear();
    await _notifications.close();
  }
}

/// Ref-counted fan-out over one underlying [RemoteRpcClient._subscribeRaw]
/// stream, so N callers requesting the same subscription coordinates share a
/// single server subscription.
///
/// The source is a single-subscription stream; this listens to it exactly once
/// and forwards every event to all attached per-listener controllers. The last
/// snapshot is cached and replayed to a late joiner so its stream still gets an
/// immediate first emission (the SWR reconciliation contract). When the last
/// listener cancels — or the source ends/errors — the shared entry tears down
/// and removes itself via [onEmpty], so a subsequent request re-establishes a
/// fresh subscription.
class _SharedSubscription {
  _SharedSubscription(this._source, {required this.onEmpty});

  final Stream<Map<String, dynamic>> _source;

  /// Invoked exactly once when this shared subscription is finished with (last
  /// listener gone, or the source completed). Removes it from the owner's map.
  final void Function() onEmpty;

  final Set<StreamController<Map<String, dynamic>>> _listeners =
      <StreamController<Map<String, dynamic>>>{};
  StreamSubscription<Map<String, dynamic>>? _sub;
  Map<String, dynamic>? _last;
  bool _started = false;
  bool _dead = false;

  /// Returns a per-listener stream attached to this shared subscription.
  Stream<Map<String, dynamic>> attach() {
    late final StreamController<Map<String, dynamic>> controller;
    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        _listeners.add(controller);
        _start();
        // Replay the latest snapshot to a late joiner so it does not wait for
        // the next server push to leave its loading state.
        final last = _last;
        if (last != null && !controller.isClosed) {
          controller.add(last);
        }
      },
      onCancel: () {
        _listeners.remove(controller);
        if (_listeners.isEmpty) {
          _teardown();
        }
      },
    );
    return controller.stream;
  }

  void _start() {
    if (_started || _dead) {
      return;
    }
    _started = true;
    _sub = _source.listen(
      (data) {
        _last = data;
        for (final l in _listeners.toList()) {
          if (!l.isClosed) {
            l.add(data);
          }
        }
      },
      onError: (Object e, StackTrace st) {
        for (final l in _listeners.toList()) {
          if (!l.isClosed) {
            l.addError(e, st);
          }
        }
      },
      onDone: () {
        // The source ended (server `sub/error` close, or the channel dropped).
        // Close every listener and drop this entry so the next request opens a
        // fresh subscription.
        _dead = true;
        final listeners = _listeners.toList();
        _listeners.clear();
        for (final l in listeners) {
          if (!l.isClosed) {
            unawaited(l.close());
          }
        }
        onEmpty();
      },
    );
  }

  void _teardown() {
    if (_dead) {
      return;
    }
    _dead = true;
    unawaited(_sub?.cancel());
    _sub = null;
    onEmpty();
  }
}
