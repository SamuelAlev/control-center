import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/src/errors/rpc_error_mapping.dart';
import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';
import 'package:cc_host/src/repo_rpc/repo_op_dispatcher.dart'
    show ServerOwnerResolver, WorkspaceRoleResolver;
import 'package:cc_host/src/repo_rpc/watch_query.dart';

/// Session live subscriptions → `sub/snapshot` pushes (snapshot-only v1).
///
/// Workspace-scoped queries: refuse unknown ids via [workspaceExists] before
/// the handler runs (opening creates the file). Cap [maxPerSession].
/// [invalidateAll] on workspace switch. Client replays `sub/subscribe` on
/// reconnect.
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
    this.resolveServerOwner,
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
  /// cannot stream another workspace's spaces, tickets, or any other
  /// workspace-scoped data by naming its id. Null (bare test managers) skips
  /// the gate; production wiring always supplies it.
  final WorkspaceRoleResolver? resolveRole;

  /// The `WatchQuery.serverAuthority` gate, mirroring
  /// `RepoOpDispatcher.resolveServerOwner`: a query that declared authority
  /// is refused when nobody can vouch for the caller (fail closed), never
  /// silently opened because the resolver was left unwired.
  final ServerOwnerResolver? resolveServerOwner;

  final Map<String, _Subscription> _subs = {};
  int _counter = 0;

  /// Latest not-yet-sent full snapshot per subscription.
  ///
  /// A watch that emits several times in one event-loop turn (a transaction
  /// that touches several rows, a burst of drift notifications) used to push
  /// a full snapshot for each. The client replaces its mirror on every
  /// snapshot, so the intermediate ones are pure encode + decode + rebuild.
  /// They collapse to the newest.
  ///
  /// The flush is an event-queue task, not a microtask. An async stream
  /// delivers one event per microtask and schedules the next from inside the
  /// listener, so a microtask queued by that listener runs *between* the
  /// events of the burst and would send the intermediate snapshot. An
  /// event-queue task runs only after that microtask chain has drained, which
  /// is still the same turn the emissions already occupied.
  final Map<String, ({int rev, Map<String, dynamic> data})> _pendingSnapshots =
      {};
  bool _snapshotFlushScheduled = false;

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
    final needsAuthority = query.serverAuthority != ServerAuthority.none;
    if (needsAuthority ||
        (targetWorkspace != null && (gate != null || roleResolver != null))) {
      _subs[subId] = _Subscription.pending(targetWorkspace ?? '');
      unawaited(() async {
        // Server-authority gate for unscoped install-wide streams — fail
        // closed when no resolver is wired, exactly like the repo-op gate.
        if (needsAuthority) {
          final ownerResolver = resolveServerOwner;
          final isOwner = ownerResolver == null
              ? false
              : await ownerResolver(userId);
          if (!isOwner) {
            CcHostLog.warning(
              'Denying subscription $subId ($queryName) for '
              '$userId@$deviceId — requires server '
              '${query.serverAuthority.name}',
            );
            _sendStreamError(subId, RpcErrorCodes.unauthorized);
            _cancel(subId);
            return;
          }
        }
        if (targetWorkspace == null) {
          if (!_subs.containsKey(subId)) {
            return; // Unsubscribed while the gate resolved.
          }
          final error = _attach(
            subId: subId,
            queryName: queryName,
            query: query,
            ctx: ctx,
            args: args,
            workspaceId: null,
          );
          if (error != null) {
            _sendStreamError(subId, error.code);
            _cancel(subId);
          }
          return;
        }
        if (gate != null && !await gate(targetWorkspace)) {
          CcHostLog.warning(
            'Denying subscription $subId ($queryName) for '
            '$userId@$deviceId — unknown workspace $targetWorkspace',
          );
          _sendStreamError(subId, RpcErrorCodes.notFound);
          _cancel(subId);
          return;
        }
        if (roleResolver != null) {
          final role = await roleResolver(targetWorkspace, userId);
          if (role == null) {
            CcHostLog.warning(
              'Denying subscription $subId ($queryName) for '
              '$userId@$deviceId — not a member of workspace $targetWorkspace',
            );
            _sendStreamError(subId, RpcErrorCodes.unauthorized);
            _cancel(subId);
            return;
          }
          // Role floor — the reactive lane's counterpart of the repo-op role
          // gate. Membership alone used to be the whole check, which streamed
          // admin-facing snapshots (the invite roster, the audit trail) to
          // guests.
          final floor = query.effectiveMinRole;
          if (!role.atLeast(floor)) {
            CcHostLog.warning(
              'Denying subscription $subId ($queryName) for '
              '$userId@$deviceId — requires ${floor.wireName}, member is '
              '${role.wireName}',
            );
            _sendStreamError(subId, RpcErrorCodes.unauthorized);
            _cancel(subId);
            return;
          }
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
              _enqueueSnapshot(subId, rev, data);
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

  void _enqueueSnapshot(String subId, int rev, Map<String, dynamic> data) {
    if (!_subs.containsKey(subId)) {
      return;
    }
    _pendingSnapshots[subId] = (rev: rev, data: data);
    if (_snapshotFlushScheduled) {
      return;
    }
    _snapshotFlushScheduled = true;
    // Event queue, not scheduleMicrotask. See [_pendingSnapshots].
    Future<void>(_flushSnapshots);
  }

  void _flushSnapshots() {
    _snapshotFlushScheduled = false;
    if (_pendingSnapshots.isEmpty) {
      return;
    }
    final batch = Map<String, ({int rev, Map<String, dynamic> data})>.of(
      _pendingSnapshots,
    );
    _pendingSnapshots.clear();
    for (final entry in batch.entries) {
      if (!_subs.containsKey(entry.key)) {
        continue;
      }
      final snap = entry.value;
      send({
        'jsonrpc': '2.0',
        'method': RpcMethods.subSnapshot,
        'params': {
          'subscriptionId': entry.key,
          'rev': snap.rev,
          'full': true,
          'data': snap.data,
        },
      });
    }
  }

  void _cancel(String subId) {
    _pendingSnapshots.remove(subId);
    final sub = _subs.remove(subId);
    sub?.cancel();
  }

  void _cancelAll() {
    _pendingSnapshots.clear();
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
