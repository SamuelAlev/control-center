import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';
import 'package:cc_rpc/src/client/rpc_snapshot_cache.dart';
import 'package:cc_rpc/src/client/server_build.dart';
import 'package:cc_rpc/src/resolver/connection_supervisor.dart';

/// Stable [RemoteRpcClient] over [ServerConnectionSupervisor] across path
/// failovers. In-flight [call]s are never replayed on death. [subscribe]
/// re-issues on reconnect (rejected subs end the stream). [notifications]
/// merges sessions. Richer state is on [supervisor].status.
class ResilientRpcClient implements RemoteRpcClient {
  /// Wraps [supervisor]; call [ServerConnectionSupervisor.start] first (the
  /// boot flow owns first-connect errors), then construct this.
  ResilientRpcClient(this.supervisor, {Duration? callWait, this._snapshotCache})
    : _callWait = callWait ?? const Duration(seconds: 15) {
    _inner = supervisor.client;
    _applyWorkspace(_inner);
    _wireInner(_inner);
    _clientsSub = supervisor.clients.listen((client) {
      _terminalError = null;
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
      if (_closed) {
        return;
      }
      if (status.authenticationRejected) {
        final denial = RemoteRpcException(
          RpcErrorCodes.unauthorized,
          'Server rejected authentication',
        );
        _terminalError = denial;
        _inner = null;
        _snapshotCache?.clear();
        if (_snapshotCache case final cache?) {
          unawaited(cache.flush());
        }
        _failWaiters(denial);
      } else if (status.phase == ServerConnectionPhase.closed ||
          status.phase == ServerConnectionPhase.identityMismatch) {
        _terminalError = RemoteRpcClientClosedException(
          'Server connection ended: ${status.phase.name}',
        );
        if (status.phase == ServerConnectionPhase.identityMismatch) {
          _snapshotCache?.clear();
          if (_snapshotCache case final cache?) {
            unawaited(cache.flush());
          }
        }
        _failWaiters(_terminalError!);
      }
    });
  }

  /// The owning supervisor (status stream, descriptor, pinned fingerprint).
  final ServerConnectionSupervisor supervisor;

  final Duration _callWait;
  RpcSnapshotCache? _snapshotCache;

  /// Switches the cache only after an authenticated identity has been verified
  /// and its scoped store has hydrated. Existing listeners retain their cache
  /// scope, so no in-flight response can leak into another account's store.
  void setSnapshotCache(RpcSnapshotCache? cache) {
    _snapshotCache = cache;
  }

  RemoteRpcClient? _inner;
  String? _activeWorkspaceId;
  bool _closed = false;
  bool _lastOpen = true;

  Object? _terminalError;
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
    final terminal = _terminalError;
    if (terminal != null) {
      throw terminal;
    }
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
    final effectiveArgs = _frozenArgs(args);
    final cache = _safeSubscriptions.contains(query) ? _snapshotCache : null;
    final key = _snapshotKey('sub', query, effectiveArgs);
    late final StreamController<Map<String, dynamic>> controller;
    StreamSubscription<Map<String, dynamic>>? innerSub;
    Completer<RemoteRpcClient>? pending;
    Completer<void>? attachedDone;
    var cancelled = false;

    Future<RemoteRpcClient> live() async {
      final terminal = _terminalError;
      if (terminal != null) {
        throw terminal;
      }
      final current = _inner;
      if (current != null && current.isOpen) {
        return current;
      }
      if (_closed || cancelled) {
        throw const RemoteRpcClientClosedException();
      }
      final waiter = Completer<RemoteRpcClient>();
      pending = waiter;
      _clientWaiters.add(waiter);
      try {
        return await waiter.future;
      } finally {
        _clientWaiters.remove(waiter);
        if (identical(pending, waiter)) {
          pending = null;
        }
      }
    }

    Future<void> attach() async {
      final terminal = _terminalError;
      if (terminal != null) {
        controller.addError(terminal);
        await controller.close();
        return;
      }
      final stale = cache?.read(key);
      if (stale != null && !cancelled) {
        controller.add(stale);
      }
      while (!cancelled && !_closed) {
        final RemoteRpcClient client;
        try {
          client = await live();
        } catch (e, s) {
          if (cancelled || controller.isClosed) {
            return;
          }
          controller.addError(e, s);
          await controller.close();
          return;
        }
        if (cancelled) {
          return;
        }
        final done = Completer<void>();
        attachedDone = done;
        var failed = false;
        var denied = false;
        innerSub = client
            .subscribe(query, effectiveArgs)
            .listen(
              (snapshot) {
                if (cancelled ||
                    controller.isClosed ||
                    _terminalError != null) {
                  return;
                }
                cache?.write(key, snapshot);
                controller.add(snapshot);
              },
              onError: (Object error, StackTrace stack) {
                denied = _isAuthoritativeDenial(error);
                if (denied) {
                  _evictDeniedSnapshot(cache, key, effectiveArgs, error);
                } else if (error is RemoteRpcClientClosedException ||
                    error is TimeoutException ||
                    !client.isOpen) {
                  // Transport loss does not replace a cached render with an error.
                  if (!done.isCompleted) {
                    done.complete();
                  }
                  return;
                }
                failed = true;
                if (!cancelled && !controller.isClosed) {
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
        attachedDone = null;
        await innerSub?.cancel();
        innerSub = null;
        if (cancelled || _closed) {
          return;
        }
        // An active server's refusal is final, not a reason to spin retrying.
        if (failed && (denied || client.isOpen)) {
          await controller.close();
          return;
        }
        if (!client.isOpen && !identical(_inner, client)) {
          continue;
        }
        if (!client.isOpen) {
          try {
            final waiter = Completer<RemoteRpcClient>();
            pending = waiter;
            _clientWaiters.add(waiter);
            await waiter.future;
          } catch (error, stack) {
            if (!cancelled && !controller.isClosed) {
              if (!_closed) {
                controller.addError(error, stack);
              }
              await controller.close();
            }
            return;
          } finally {
            final waiter = pending;
            if (waiter != null) {
              _clientWaiters.remove(waiter);
            }
            pending = null;
          }
        }
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () => unawaited(attach()),
      onCancel: () async {
        cancelled = true;
        final done = attachedDone;
        if (done != null && !done.isCompleted) {
          done.complete();
        }
        final waiter = pending;
        if (waiter != null) {
          _clientWaiters.remove(waiter);
          if (!waiter.isCompleted) {
            waiter.completeError(const RemoteRpcClientClosedException());
          }
        }
        await innerSub?.cancel();
      },
    );
    return controller.stream;
  }

  /// Explicit cached read stream, never used for mutations or ordinary calls.
  /// A listener receives the stale value first and a fresh response on every
  /// live session, including sessions established after a prolonged outage.
  @override
  Stream<Map<String, dynamic>> watchCall(String op, Map<String, dynamic> args) {
    if (!offlineSafeReadOps.contains(op)) {
      throw ArgumentError.value(op, 'op', 'Not an offline-safe read operation');
    }
    final effectiveArgs = _frozenArgs(args);
    final cache = _snapshotCache;
    final key = _snapshotKey('call', op, effectiveArgs);
    late final StreamController<Map<String, dynamic>> controller;
    Completer<RemoteRpcClient>? pending;
    StreamSubscription<Map<String, dynamic>>? innerSub;
    Completer<void>? attachedDone;
    var cancelled = false;

    Future<void> attach() async {
      final terminal = _terminalError;
      if (terminal != null) {
        controller.addError(terminal);
        await controller.close();
        return;
      }
      final stale = cache?.read(key);
      if (stale != null && !cancelled) {
        controller.add(stale);
      }
      RemoteRpcClient? last;
      while (!cancelled && !_closed) {
        if (_terminalError != null) {
          controller.addError(_terminalError!);
          await controller.close();
          return;
        }
        try {
          final current = _inner;
          if (current == null || !current.isOpen || identical(current, last)) {
            final waiter = Completer<RemoteRpcClient>();
            pending = waiter;
            _clientWaiters.add(waiter);
            try {
              last = await waiter.future;
            } finally {
              _clientWaiters.remove(waiter);
              if (identical(pending, waiter)) {
                pending = null;
              }
            }
          } else {
            last = current;
          }
          if (cancelled || _closed) {
            return;
          }
          if (_terminalError != null) {
            controller.addError(_terminalError!);
            await controller.close();
            return;
          }
          final done = Completer<void>();
          attachedDone = done;
          Object? readError;
          StackTrace? readStack;
          innerSub = last
              .watchCall(op, effectiveArgs)
              .listen(
                (fresh) {
                  if (cancelled || _closed || _terminalError != null) {
                    return;
                  }
                  cache?.write(key, fresh);
                  controller.add(fresh);
                },
                onError: (Object error, StackTrace stack) {
                  readError = error;
                  readStack = stack;
                  if (!done.isCompleted) {
                    done.complete();
                  }
                },
                onDone: () {
                  if (!done.isCompleted) {
                    done.complete();
                  }
                },
              );
          await done.future;
          attachedDone = null;
          await innerSub?.cancel();
          innerSub = null;
          if (cancelled || _closed) {
            return;
          }
          if (readError != null) {
            Error.throwWithStackTrace(readError!, readStack!);
          }
          if (_terminalError != null) {
            controller.addError(_terminalError!);
            await controller.close();
            return;
          }
        } catch (error, stack) {
          if (cancelled || controller.isClosed) {
            return;
          }
          if (_terminalError != null) {
            controller.addError(_terminalError!);
            await controller.close();
            return;
          }
          final denied = _isAuthoritativeDenial(error);
          if (denied) {
            _evictDeniedSnapshot(cache, key, effectiveArgs, error);
          }
          if (!denied &&
              (error is RemoteRpcClientClosedException ||
                  error is TimeoutException ||
                  (last != null && !last.isOpen))) {
            continue;
          }
          controller.addError(error, stack);
          await controller.close();
          return;
        }
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () => unawaited(attach()),
      onCancel: () async {
        cancelled = true;
        final done = attachedDone;
        if (done != null && !done.isCompleted) {
          done.complete();
        }
        final waiter = pending;
        if (waiter != null) {
          _clientWaiters.remove(waiter);
          if (!waiter.isCompleted) {
            waiter.completeError(const RemoteRpcClientClosedException());
          }
        }
        await innerSub?.cancel();
      },
    );
    return controller.stream;
  }

  Map<String, dynamic> _frozenArgs(Map<String, dynamic> args) =>
      args.containsKey('workspace_id')
      ? Map<String, dynamic>.of(args)
      : {'workspace_id': _activeWorkspaceId, ...args};

  static String _snapshotKey(
    String kind,
    String name,
    Map<String, dynamic> args,
  ) => jsonEncode([kind, name, _canonical(args)]);

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) {
      return value.map(_canonical).toList();
    }
    return value;
  }

  static bool _isAuthoritativeDenial(Object error) =>
      error is RemoteRpcException &&
      (error.code == RpcErrorCodes.unauthorized ||
          error.code == RpcErrorCodes.workspaceMismatch ||
          error.code == RpcErrorCodes.notFound ||
          error.code == RpcErrorCodes.noWorkspaceBound);

  static void _evictDeniedSnapshot(
    RpcSnapshotCache? cache,
    String key,
    Map<String, dynamic> args,
    Object error,
  ) {
    if (cache == null) {
      return;
    }
    final code = (error as RemoteRpcException).code;
    if (code == RpcErrorCodes.unauthorized ||
        code == RpcErrorCodes.workspaceMismatch ||
        code == RpcErrorCodes.noWorkspaceBound) {
      final workspace = args['workspace_id'];
      if (workspace is String) {
        cache.evictWorkspace(workspace);
      } else {
        cache.clear();
      }
    } else {
      cache.remove(key); // A missing entity does not revoke its workspace.
    }
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
    await _snapshotCache?.flush();
    await supervisor.close();
  }
}

// Explicit render-only snapshots. Live control, credentials, presence,
// permissions and mutation-shaped operations must never enter persistence.
const _safeSubscriptions = <String>{
  'workspace.watchAll',
  'workspace.watchReposForWorkspace',
  'agents.watchForWorkspace',
  'agents.watchAll',
  'pr.watchOpenForWorkspace',
  'pr.watchNeedsMyReviewCount',
  'pr.watchRepoAccessForWorkspace',
  'pr_review.watchPullRequest',
  'pr_review.watchDiff',
  'pr_review.watchFiles',
  'pr_review.watchFileContent',
  'pr_review.watchCommits',
  'pr_review.watchCommitFiles',
  'pr_review.watchReviews',
  'pr_review.watchReviewComments',
  'pr_review.watchIssueComments',
  'pr_review.watchTimelineEvents',
  'pr_review.watchCheckRuns',
  'pr_review.watchCommitStatuses',
  'pr_review.watchReviewers',
  'calendar.watchAccounts',
  'calendar.watchSources',
  'calendar.watchEventsInRange',
  'calendar.watchEventById',
  'meeting.watchByWorkspace',
  'meeting.watchSegments',
  'meeting.watchSpeakers',
  'meeting.watchActionItems',
  'meeting.watchDecisions',
  'meeting.watchActionItemStats',
  'meeting.watchDecisionCounts',
  'pipeline_run.watchRun',
  'pipeline_run.watchAll',
  'pipeline_run.watchForWorkspace',
  'pipeline_run.watchStepRunsForPipeline',
  'pipeline_template.watchForWorkspace',
  'pipeline_trigger.watchForWorkspace',
  'messaging.watchSpaces',
  'messaging.watchMessages',
  'messaging.watchSpaceMessages',
  'messaging.watchMessagesWindow',
  'messaging.watchParticipants',
  'messaging.watchSpaceActivity',
  'messaging.watchConversationTokens',
  'messaging.watchUserPromptHistory',
  'conversation.watchForSpace',
  'conversation.watchThreadSummaries',
  'agent_run_log.watchByAgent',
  'agent_run_log.watchByConversation',
  'agent_run_log.watchBySpace',
  'agent_run_log.watchRecent',
};
