import 'dart:async';

import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// The ONE place workspace-scoped data is read across workspaces.
///
/// Before the database was split, a cross-workspace query was an ordinary
/// `SELECT` with no `WHERE workspace_id`, marked with a `CROSS-WORKSPACE BY
/// DESIGN` doc comment and enforced by a ratchet test's allow-list. That worked,
/// but the surface was diffuse: 87 marked sites spread across 40 DAOs and
/// nothing stopped an 88th appearing.
///
/// Now crossing workspaces requires opening several database files and doing
/// that requires this class. The surface is therefore *enumerable*: the callers
/// of [fanOut] and [mergeStreams] are the complete list of everything in the
/// product that legitimately spans workspaces. A routing ratchet test asserts
/// nothing else imports it.
///
/// The legitimate callers fall into four groups:
///
///  * **Operator-facing all-workspace views** — the dashboard's all-agents and
///    all-spaces lists, the workspace-health pulse.
///  * **Startup reconcilers** — the orphan-run reaper, the stranded-ticket
///    reconciler, pipeline resume, stranded space provisioning.
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
  /// Reads run [_maxConcurrentReads] at a time and go through
  /// `useTransiently`, so a workspace this call had to open is closed again
  /// afterwards — a dashboard render does not leave every workspace's database
  /// resident for the process's lifetime. A workspace someone is actually in
  /// stays open, because an ordinary `of()` claims it.
  ///
  /// Soft-deleted workspaces are skipped unless [includeDeleted]: opening one
  /// costs a cold open to contribute rows the operator asked to stop seeing.
  Future<List<T>> fanOut<T>(
    Future<T> Function(WorkspaceDatabase db) read, {
    void Function(String workspaceId, Object error)? onError,
    bool includeDeleted = false,
  }) async {
    final ids = await _idsFor(includeDeleted: includeDeleted);
    final results = await _bounded(
      ids,
      (id) async {
        try {
          return _Ok<T>(await _manager.useTransiently(id, read));
        } on Object catch (e) {
          onError?.call(id, e);
          return _Failed<T>();
        }
      },
    );
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
    bool includeDeleted = false,
  }) async {
    final ids = await _idsFor(includeDeleted: includeDeleted);
    final out = <String, T>{};
    await _bounded(ids, (id) async {
      try {
        out[id] = await _manager.useTransiently(id, read);
      } on Object catch (e) {
        onError?.call(id, e);
      }
      return null;
    });
    return out;
  }

  /// Runs [write] against every workspace, sequentially.
  ///
  /// Sequential on purpose: the callers are maintenance sweeps (retention, GC,
  /// vacuum) and running ten write transactions at once would spike I/O while
  /// the server is trying to serve. Returns the number of workspaces that
  /// succeeded.
  ///
  /// Includes soft-deleted workspaces by default, unlike the read fan-outs:
  /// their files are still on disk and skipping them would leave them un-swept
  /// and un-backed-up, which is the reason maintenance runs at all.
  Future<int> forEachWorkspace(
    Future<void> Function(WorkspaceDatabase db) write, {
    void Function(String workspaceId, Object error)? onError,
    bool includeDeleted = true,
  }) async {
    final ids = await _idsFor(includeDeleted: includeDeleted);
    var ok = 0;
    for (final id in ids) {
      try {
        await _manager.useTransiently(id, (db) async => write(db));
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
  ///    workspace-registry stream is what changes and callers that care watch
  ///    that too.
  ///
  /// [sort] is applied to the merged list — pass one whenever the per-workspace
  /// streams were ordered, because concatenation does not preserve a global
  /// order.
  /// Unlike the one-shot fan-outs this does NOT close the files it opened: a
  /// live merged view holds one drift subscription per workspace, and closing
  /// the connection under a subscription kills it. The workspaces are open
  /// because something is watching them, which is the definition of in use.
  Stream<List<T>> mergeStreams<T>(
    Stream<List<T>> Function(WorkspaceDatabase db) watch, {
    int Function(T a, T b)? sort,
    int? limit,
    bool includeDeleted = false,
  }) async* {
    final ids = await _idsFor(includeDeleted: includeDeleted);
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

  Future<List<String>> _idsFor({required bool includeDeleted}) => includeDeleted
      ? _manager.allWorkspaceIds()
      : _manager.liveWorkspaceIds();

  /// Runs [body] over [ids] with at most [_maxConcurrentReads] in flight,
  /// preserving input order in the result.
  Future<List<R>> _bounded<R>(
    List<String> ids,
    Future<R> Function(String id) body,
  ) async {
    final out = List<R?>.filled(ids.length, null);
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= ids.length) {
          return;
        }
        out[i] = await body(ids[i]);
      }
    }

    await Future.wait([
      for (var i = 0; i < _maxConcurrentReads && i < ids.length; i++) worker(),
    ]);
    return [for (final r in out) r as R];
  }

  /// Fetches [limit] rows from every workspace, merges them with [compare] and
  /// returns the global top [limit].
  ///
  /// A global "most recent N" cannot be answered by one query any more and
  /// taking N from each file before merging is what makes the answer correct:
  /// taking fewer would risk missing rows that outrank another workspace's.
  Future<List<T>> topN<T>(
    Future<List<T>> Function(WorkspaceDatabase db, int limit) read,
    int limit, {
    required int Function(T a, T b) compare,
    void Function(String workspaceId, Object error)? onError,
    bool includeDeleted = false,
  }) async {
    final perWorkspace = await fanOut(
      (db) => read(db, limit),
      onError: onError,
      includeDeleted: includeDeleted,
    );
    final merged = [for (final rows in perWorkspace) ...rows]..sort(compare);
    return merged.length > limit ? merged.sublist(0, limit) : merged;
  }
}

/// How many workspace files a read fan-out touches at once.
///
/// Unbounded `Future.wait` meant N concurrent COLD opens — N background
/// isolates spinning up, N page caches allocating and N files being read at
/// once — which on a spinning disk or a contended SSD is slower than doing a
/// few at a time. Not serialized either: the finding proposed that and it
/// would make the first dashboard load strictly slower by construction.
const _maxConcurrentReads = 4;

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
