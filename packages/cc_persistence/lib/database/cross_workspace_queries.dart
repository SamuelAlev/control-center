import 'dart:async';

import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// The ONE place workspace-scoped data is read across workspaces.
///
/// Before the database was split, a cross-workspace query was an ordinary
/// `SELECT` with no `WHERE workspace_id`, marked with a `CROSS-WORKSPACE BY
/// DESIGN` doc comment and enforced by a ratchet test's allow-list. That worked,
/// but the surface was diffuse: 87 marked sites spread across 40 DAOs, and
/// nothing stopped an 88th appearing.
///
/// Now crossing workspaces requires opening several database files, and doing
/// that requires this class. The surface is therefore *enumerable*: the callers
/// of [fanOut] and [mergeStreams] are the complete list of everything in the
/// product that legitimately spans workspaces. A routing ratchet test asserts
/// nothing else imports it.
///
/// The legitimate callers fall into four groups:
///
///  * **Operator-facing all-workspace views** — the dashboard's all-agents and
///    all-channels lists, the workspace-health pulse.
///  * **Startup reconcilers** — the orphan-run reaper, the stranded-ticket
///    reconciler, pipeline resume, stranded channel provisioning.
///  * **Maintenance** — retention sweeps, the runtime-state GC, skill
///    re-verification, backup.
///  * **Event routing** — the trigger dispatcher, which fans out and then
///    re-filters per event.
///
/// Everything else has a workspace id in hand and must use it.
class CrossWorkspaceQueries {
  /// Creates a fan-out helper over `manager`.
  const CrossWorkspaceQueries(this._manager);

  final WorkspaceDatabaseManager _manager;

  /// Runs [read] against every workspace and returns the results, skipping
  /// workspaces whose read failed.
  ///
  /// Failures are isolated deliberately: a corrupt or locked workspace file must
  /// not take down the dashboard for the other nine. [onError] sees each
  /// failure so it is logged rather than swallowed.
  ///
  /// Reads run concurrently. Each one opens its workspace's file if it wasn't
  /// open already, so the first all-workspace read after boot is the expensive
  /// one; subsequent ones hit warm connections.
  Future<List<T>> fanOut<T>(
    Future<T> Function(WorkspaceDatabase db) read, {
    void Function(String workspaceId, Object error)? onError,
  }) async {
    final ids = await _manager.allWorkspaceIds();
    final results = await Future.wait([
      for (final id in ids)
        Future(() async {
          try {
            return _Ok<T>(await read(_manager.of(id)));
          } on Object catch (e) {
            onError?.call(id, e);
            return _Failed<T>();
          }
        }),
    ]);
    return [
      for (final r in results)
        if (r is _Ok<T>) r.value,
    ];
  }

  /// Like [fanOut] but keeps each result paired with its workspace id, for
  /// callers that need to attribute rows they merge.
  Future<Map<String, T>> fanOutKeyed<T>(
    Future<T> Function(WorkspaceDatabase db) read, {
    void Function(String workspaceId, Object error)? onError,
  }) async {
    final ids = await _manager.allWorkspaceIds();
    final out = <String, T>{};
    await Future.wait([
      for (final id in ids)
        Future(() async {
          try {
            out[id] = await read(_manager.of(id));
          } on Object catch (e) {
            onError?.call(id, e);
          }
        }),
    ]);
    return out;
  }

  /// Runs [write] against every workspace, sequentially.
  ///
  /// Sequential on purpose: the callers are maintenance sweeps (retention, GC,
  /// vacuum), and running ten write transactions at once would spike I/O while
  /// the server is trying to serve. Returns the number of workspaces that
  /// succeeded.
  Future<int> forEachWorkspace(
    Future<void> Function(WorkspaceDatabase db) write, {
    void Function(String workspaceId, Object error)? onError,
  }) async {
    final ids = await _manager.allWorkspaceIds();
    var ok = 0;
    for (final id in ids) {
      try {
        await write(_manager.of(id));
        ok++;
      } on Object catch (e) {
        onError?.call(id, e);
      }
    }
    return ok;
  }

  /// Merges one stream per workspace into a single stream of the concatenated
  /// lists, re-emitting whenever ANY workspace emits.
  ///
  /// This is how the all-workspace live views work. Two properties matter:
  ///
  ///  * It emits only once every workspace has produced a first value, so
  ///    subscribers never see a half-populated list that then grows — which
  ///    would read as rows appearing out of nowhere.
  ///  * The workspace set is captured at subscribe time. A workspace created
  ///    later is not picked up until the subscriber re-subscribes; the
  ///    workspace-registry stream is what changes, and callers that care watch
  ///    that too.
  ///
  /// [sort] is applied to the merged list — pass one whenever the per-workspace
  /// streams were ordered, because concatenation does not preserve a global
  /// order.
  Stream<List<T>> mergeStreams<T>(
    Stream<List<T>> Function(WorkspaceDatabase db) watch, {
    int Function(T a, T b)? sort,
    int? limit,
  }) async* {
    final ids = await _manager.allWorkspaceIds();
    if (ids.isEmpty) {
      yield const [];
      return;
    }
    final latest = <String, List<T>>{};
    // Closed when the yielded stream is cancelled (`onCancel` below);
    // close_sinks cannot see that async* lifecycle.
    // ignore: close_sinks
    final controller = StreamController<List<T>>();
    final subs = <StreamSubscription<List<T>>>[];

    void emitIfReady() {
      if (latest.length < ids.length || controller.isClosed) {
        return;
      }
      final merged = [for (final id in ids) ...?latest[id]];
      if (sort != null) {
        merged.sort(sort);
      }
      controller.add(
        limit != null && merged.length > limit
            ? merged.sublist(0, limit)
            : merged,
      );
    }

    for (final id in ids) {
      subs.add(
        watch(_manager.of(id)).listen(
          (rows) {
            latest[id] = rows;
            emitIfReady();
          },
          onError: (Object e) {
            // A failing workspace contributes an empty list rather than killing
            // the merged stream for every other workspace.
            latest[id] ??= const [];
            emitIfReady();
          },
        ),
      );
    }
    controller.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
    };
    yield* controller.stream;
  }

  /// Fetches [limit] rows from every workspace, merges them with [compare] and
  /// returns the global top [limit].
  ///
  /// A global "most recent N" cannot be answered by one query any more, and
  /// taking N from each file before merging is what makes the answer correct:
  /// taking fewer would risk missing rows that outrank another workspace's.
  Future<List<T>> topN<T>(
    Future<List<T>> Function(WorkspaceDatabase db, int limit) read,
    int limit, {
    required int Function(T a, T b) compare,
    void Function(String workspaceId, Object error)? onError,
  }) async {
    final perWorkspace = await fanOut(
      (db) => read(db, limit),
      onError: onError,
    );
    final merged = [for (final rows in perWorkspace) ...rows]..sort(compare);
    return merged.length > limit ? merged.sublist(0, limit) : merged;
  }
}

sealed class _Result<T> {
  const _Result();
}

final class _Ok<T> extends _Result<T> {
  const _Ok(this.value);
  final T value;
}

final class _Failed<T> extends _Result<T> {
  const _Failed();
}
