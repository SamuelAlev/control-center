import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/src/errors/rpc_error_mapping.dart';
import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';
import 'package:cc_host/src/repo_rpc/repo_op_dispatcher.dart' show WorkspaceRoleResolver;
import 'package:cc_host/src/repo_rpc/watch_query.dart';

/// Owns a session's live reactive subscriptions and proxies server-side
/// repository `.watch()` streams to the client as `sub/snapshot` pushes.
///
/// Semantics (plan § Protocol):
///  * `sub/subscribe {query, args}` → `{subscriptionId, rev:0}`, then an initial
///    full snapshot and one per change (v1 is snapshot-only).
///  * **Authoritative workspace** — a workspace-scoped query names its target
///    in args; when [workspaceExists] is wired, an id the registry does not
///    know is refused (sub/error, not-found) BEFORE the handler runs, because
///    the handler opens that workspace's database and opening CREATES the
///    file — an ungated stale id sprays empty ghost `workspace.db` files.
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
    required this.userId,
    this.mapException,
    this.workspaceExists,
    this.resolveRole,
    this.maxPerSession = 128,
  });

  /// The closed watch-query allow-list.
  final WatchQueryRegistry registry;

  /// Pushes a notification frame to the client.
  final void Function(Map<String, dynamic> frame) send;

  /// The subscribing device (for query context / auditing).
  final String deviceId;

  /// The authenticated user behind the session (user-scoped streams key off
  /// this, never off client args).
  final String userId;

  /// Classifies a watch-stream failure into a stable [RpcErrorCodes] response,
  /// exactly like `RepoOpDispatcher.mapException` does for `repo/call`. Without
  /// it a domain rejection (a `WorkspaceMismatchException` from the workspace
  /// chokepoint, a `NotFoundException`) reaches the client as a generic
  /// internal error — which its retry policy treats as transient, producing a
  /// resubscribe storm against an error no retry can fix. Applied to BOTH
  /// failure paths: a handler that throws synchronously (before returning a
  /// stream) and one whose stream errors later.
  final RpcExceptionMapper? mapException;

  /// Max concurrent subscriptions per session.
  final int maxPerSession;

  /// Registry existence gate for workspace-scoped queries, mirroring the one
  /// on `RepoOpDispatcher`. Runs before the query handler
  /// attaches: the handler opens the named workspace's database and opening
  /// CREATES the file, so an unregistered id must be refused first. Null (bare
  /// test managers) skips the gate.
  final WorkspaceExistsChecker? workspaceExists;

  /// Membership gate for workspace-scoped queries — the `sub/subscribe`
  /// counterpart of `RepoOpDispatcher.resolveRole`. The caller must be a
  /// member of the named workspace; a non-member is refused with an
  /// `unauthorized` stream error BEFORE the handler attaches, so a user
  /// cannot stream another workspace's channels, tickets, or any other
  /// workspace-scoped data by naming its id. Null (bare test managers) skips
  /// the gate; production wiring always supplies it.
  final WorkspaceRoleResolver? resolveRole;

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
      userId: userId,
    );

    // Attaching the query handler opens the named workspace's database and
    // opening CREATES the file — so when the existence gate is wired, check
    // the registry (async) BEFORE the handler runs: an unregistered id (a
    // stale client-held active workspace) must be refused without
    // materialising a ghost `workspace.db` on disk. The membership gate rides
    // the same async path: a non-member naming an existing workspace is
    // refused `unauthorized` before a single row streams.
    final gate = workspaceExists;
    final roleResolver = resolveRole;
    final targetWorkspace = workspaceId;
    if (targetWorkspace != null && (gate != null || roleResolver != null)) {
      _subs[subId] = _Subscription.pending(targetWorkspace);
      unawaited(() async {
        if (gate != null && !await gate(targetWorkspace)) {
          CcHostLog.warning(
            'Denying subscription $subId ($queryName) for '
            '$userId@$deviceId — unknown workspace $targetWorkspace',
          );
          _sendStreamError(subId, RpcErrorCodes.notFound);
          _cancel(subId);
          return;
        }
        if (roleResolver != null &&
            await roleResolver(targetWorkspace, userId) == null) {
          CcHostLog.warning(
            'Denying subscription $subId ($queryName) for '
            '$userId@$deviceId — not a member of workspace $targetWorkspace',
          );
          _sendStreamError(subId, RpcErrorCodes.unauthorized);
          _cancel(subId);
          return;
        }
        if (!_subs.containsKey(subId)) {
          return; // Unsubscribed while the gates resolved.
        }
        final error = _attach(
          subId: subId,
          queryName: queryName,
          query: query,
          ctx: ctx,
          args: args,
          workspaceId: targetWorkspace,
        );
        if (error != null) {
          // The subscribe ack already went out, so a synchronous rejection is
          // delivered as a stream error carrying the same code the ungated
          // path would have returned in the response.
          _sendStreamError(subId, error.code);
          _cancel(subId);
        }
      }());
      return _ack(id, subId);
    }

    final error = _attach(
      subId: subId,
      queryName: queryName,
      query: query,
      ctx: ctx,
      args: args,
      workspaceId: workspaceId,
    );
    return error != null
        ? _error(id, error.code, error.message)
        : _ack(id, subId);
  }

  /// Attaches [query]'s stream to [subId], proxying its emissions as
  /// `sub/snapshot` pushes. Returns the error code+message when the handler
  /// rejects synchronously (before returning a stream); null on success.
  ({int code, String message})? _attach({
    required String subId,
    required String queryName,
    required WatchQuery query,
    required WatchQueryContext ctx,
    required Map<String, dynamic> args,
    required String? workspaceId,
  }) {
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
              // Include the coordinates: without them a doomed watch (a repo
              // not linked to the workspace, a deleted PR) is unattributable
              // from the log line alone.
              CcHostLog.warning('Subscription $subId ($queryName $args): $e');
              // Forward a PRECISE code so the client can tell an
              // unrecoverable failure (a GitHub rate limit, an auth error,
              // a workspace mismatch, a deleted PR) apart from a transient
              // one. The client's retry policy must NOT resubscribe on the
              // former — a fresh subscription just re-issues the same
              // doomed upstream call, which is exactly the resubscribe
              // storm that trips the rate limit.
              _sendStreamError(
                subId,
                mapException?.call(e)?.code ?? _streamErrorCode(e),
              );
              _cancel(subId);
            },
          );
    } catch (e, st) {
      // A handler can reject SYNCHRONOUSLY, before it ever returns a stream (a
      // missing entity, a cross-workspace session id). Classify it exactly like
      // the `onError` path above: without this, a domain rejection reached the
      // client as `internalError` — which its retry policy reads as transient —
      // and every retry re-threw the same rejection, so a single stale
      // subscription argument produced an unbounded resubscribe storm and one
      // error+stack log line per round trip.
      final mapped = mapException?.call(e);
      if (mapped != null) {
        CcHostLog.warning(
          'Subscription rejected ($queryName $args): ${mapped.message}',
        );
        return (code: mapped.code, message: mapped.message);
      }
      CcHostLog.error('subscribe $queryName failed: $e', e, st);
      return (
        code: RpcErrorCodes.internalError,
        message: 'Subscription failed',
      );
    }
    _subs[subId] = _Subscription(streamSub, workspaceId);
    return null;
  }

  Map<String, dynamic> _ack(dynamic id, String subId) => {
    'jsonrpc': '2.0',
    'id': id,
    'result': {'subscriptionId': subId, 'rev': 0},
  };

  /// Pushes a `sub/error` notification for [subId] (see the classification
  /// contract on [mapException]).
  void _sendStreamError(String subId, int code) {
    send({
      'jsonrpc': '2.0',
      'method': RpcMethods.subError,
      'params': {
        'subscriptionId': subId,
        'code': code,
        'data': {'kind': 'stream_error'},
      },
    });
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

  /// Tears down every live subscription targeting [workspaceId], pushing a
  /// `sub/error{kind}` for each. Used when the session user's membership in
  /// that workspace is revoked: the per-call role gate makes `repo/call`
  /// revocation live on its own, but an ATTACHED stream would otherwise keep
  /// pushing that workspace's data until the client unsubscribed.
  void dropWorkspace(String workspaceId, {String kind = 'member_removed'}) {
    for (final entry in _subs.entries.toList()) {
      if (entry.value.workspaceId != workspaceId) {
        continue;
      }
      send({
        'jsonrpc': '2.0',
        'method': RpcMethods.subError,
        'params': {
          'subscriptionId': entry.key,
          'code': RpcErrorCodes.unauthorized,
          'data': {'kind': kind},
        },
      });
      _cancel(entry.key);
    }
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

  /// Maps a watch-stream failure to the RPC error code the client sees, the
  /// fallback behind [mapException]. A [NetworkException] carries the upstream
  /// classification (`error_mapper`), so a GitHub rate limit surfaces as
  /// [RpcErrorCodes.rateLimited], an auth failure as
  /// [RpcErrorCodes.unauthorized] and a 404 (a PR/entity that does not exist
  /// upstream — retrying cannot conjure it) as [RpcErrorCodes.notFound];
  /// anything else is a generic internal error (transient — the client may
  /// retry with backoff).
  static int _streamErrorCode(Object e) {
    if (e is NetworkException) {
      switch (e.code) {
        case 'rate_limited':
          return RpcErrorCodes.rateLimited;
        case 'auth_error':
          return RpcErrorCodes.unauthorized;
        case 'not_found':
          return RpcErrorCodes.notFound;
      }
    }
    return RpcErrorCodes.internalError;
  }
}

class _Subscription {
  _Subscription(this._sub, this.workspaceId);

  /// A subscription whose handler has not attached yet (the workspace
  /// existence/membership gates are still resolving); cancellation is a no-op
  /// until the real stream replaces this entry.
  _Subscription.pending(this.workspaceId) : _sub = null;

  // ignore: cancel_subscriptions
  final StreamSubscription<Map<String, dynamic>>? _sub;

  /// The workspace this subscription streams from (null for global queries) —
  /// recorded so [SubscriptionManager.dropWorkspace] can tear down exactly the
  /// subscriptions a revoked membership must kill.
  final String? workspaceId;

  void cancel() => unawaited(_sub?.cancel());
}
