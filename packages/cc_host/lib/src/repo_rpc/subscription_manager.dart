import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_host/src/repo_rpc/watch_query.dart';

/// Owns a session's live reactive subscriptions and proxies server-side
/// repository `.watch()` streams to the client as `sub/snapshot` pushes.
///
/// Semantics (plan § Protocol):
///  * `sub/subscribe {query, args}` → `{subscriptionId, rev:0}`, then an initial
///    full snapshot and one per change (v1 is snapshot-only).
///  * **Authoritative workspace** — the query handler is given the session's
///    bound workspace; an unbound session is rejected for a workspace-scoped
///    query (no default-allow), matching the repo-RPC chokepoint.
///  * **Per-session cap** — rejects past [maxPerSession] live subscriptions.
///  * **Workspace switch** — [invalidateAll] tears every subscription down with
///    a `sub/error{workspace_changed}` so the client re-subscribes under the new
///    workspace; no cross-workspace emission can leak.
///  * Subscriptions are session-scoped: the client replays `sub/subscribe` on
///    reconnect (the first emission is the reconciliation).
class SubscriptionManager {
  /// Creates a [SubscriptionManager].
  ///
  /// [send] pushes a JSON-RPC notification frame to the client. [maxPerSession]
  /// bounds concurrent subscriptions (DoS guard).
  SubscriptionManager({
    required this.registry,
    required this.send,
    required this.deviceId,
    this.maxPerSession = 128,
  });

  /// The closed watch-query allow-list.
  final WatchQueryRegistry registry;

  /// Pushes a notification frame to the client.
  final void Function(Map<String, dynamic> frame) send;

  /// The subscribing device (for query context / auditing).
  final String deviceId;

  /// Max concurrent subscriptions per session.
  final int maxPerSession;

  final Map<String, _Subscription> _subs = {};
  int _counter = 0;

  /// Handles `sub/subscribe`. A workspace-scoped query carries its target
  /// `workspace_id` in `params['args']` (the server is stateless — no session
  /// workspace).
  Map<String, dynamic> subscribe({
    required dynamic id,
    required Map<String, dynamic> params,
  }) {
    final queryName = params['query'];
    if (queryName is! String || queryName.isEmpty) {
      return _error(id, RpcErrorCodes.invalidParams, 'Missing query');
    }
    final query = registry.lookup(queryName);
    if (query == null) {
      return _error(id, RpcErrorCodes.opUnknown, 'Unknown query: $queryName');
    }
    if (_subs.length >= maxPerSession) {
      return _error(
        id,
        RpcErrorCodes.tooManySubscriptions,
        'Subscription limit ($maxPerSession) reached',
      );
    }

    final rawArgs = params['args'];
    final args = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};
    // Per-request workspace: a scoped query carries its target workspace_id in
    // args (client-supplied). The server holds no session workspace, so multiple
    // clients on one server each scope their own subscriptions. A cross-workspace
    // query (workspaceScoped: false) reads workspace_id as a plain selector over
    // global rows.
    String? workspaceId;
    if (query.workspaceScoped) {
      final ws = args['workspace_id'];
      if (ws is! String || ws.isEmpty) {
        return _error(
          id,
          RpcErrorCodes.validation,
          'Missing required argument: workspace_id',
        );
      }
      workspaceId = ws;
    }

    final subId = 's${++_counter}';
    final ctx = WatchQueryContext(
      args: args,
      workspaceId: workspaceId,
      deviceId: deviceId,
    );

    var rev = 0;
    // Stored in _subs and cancelled via _cancel/_cancelAll; the analyzer can't
    // see the ownership transfer.
    // ignore: cancel_subscriptions
    late final StreamSubscription<Map<String, dynamic>> streamSub;
    try {
      streamSub = query
          .handler(ctx)
          .listen(
            (data) {
              rev++;
              send({
                'jsonrpc': '2.0',
                'method': RpcMethods.subSnapshot,
                'params': {
                  'subscriptionId': subId,
                  'rev': rev,
                  'full': true,
                  'data': data,
                },
              });
            },
            onError: (Object e, StackTrace st) {
              CcHostLog.warning('Subscription $subId ($queryName): $e');
              send({
                'jsonrpc': '2.0',
                'method': RpcMethods.subError,
                'params': {
                  'subscriptionId': subId,
                  'code': RpcErrorCodes.internalError,
                  'data': {'kind': 'stream_error'},
                },
              });
              _cancel(subId);
            },
          );
    } catch (e, st) {
      CcHostLog.error('subscribe $queryName failed: $e', e, st);
      return _error(id, RpcErrorCodes.internalError, 'Subscription failed');
    }
    _subs[subId] = _Subscription(streamSub);
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {'subscriptionId': subId, 'rev': 0},
    };
  }

  /// Handles `sub/unsubscribe`.
  Map<String, dynamic> unsubscribe({
    required dynamic id,
    required Map<String, dynamic> params,
  }) {
    final subId = params['subscriptionId'];
    if (subId is String) {
      _cancel(subId);
    }
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {'ok': true},
    };
  }

  /// Tears down every live subscription, pushing a `sub/error{kind}` for each so
  /// the client knows to re-subscribe (used on workspace switch).
  void invalidateAll(String kind) {
    for (final entry in _subs.entries.toList()) {
      send({
        'jsonrpc': '2.0',
        'method': RpcMethods.subError,
        'params': {
          'subscriptionId': entry.key,
          'code': RpcErrorCodes.workspaceMismatch,
          'data': {'kind': kind},
        },
      });
    }
    _cancelAll();
  }

  /// Cancels all subscriptions (session teardown). No client notification.
  Future<void> dispose() async => _cancelAll();

  void _cancel(String subId) {
    final sub = _subs.remove(subId);
    sub?.cancel();
  }

  void _cancelAll() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
  }

  Map<String, dynamic> _error(dynamic id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };
}

class _Subscription {
  _Subscription(this._sub);
  // ignore: cancel_subscriptions
  final StreamSubscription<Map<String, dynamic>> _sub;
  void cancel() => unawaited(_sub.cancel());
}
