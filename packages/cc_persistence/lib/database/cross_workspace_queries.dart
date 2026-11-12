import 'dart:async';

import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';

/// The only sanctioned way to read workspace-scoped data across workspaces.
///
/// Callers of [fanOut]/[mergeStreams]/etc. are the enumerable cross-workspace
/// surface (dashboards, startup reconcilers, retention/GC, event routing).
/// Everything else must use a workspace id. Routing ratchet asserts no other
/// import path.
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
  /// Only live workspaces are read: a deleted workspace has no database.
  ///
  /// A caller that reads in order to write back ([backgroundWriter], its
  /// name for the log) gets nothing from a read-only workspace: every write
  /// it attempted there would fail, on every tick. The skipped workspaces
  /// are logged once per call.
  Future<List<T>> fanOut<T>(
    Future<T> Function(WorkspaceDatabase db) read, {
    void Function(String workspaceId, Object error)? onError,
    String? backgroundWriter,
  }) async {
    final ids = await _manager.liveWorkspaceIds();
    final skipped = <String>[];
    final results = await _bounded(ids, (id) async {
      try {
        final value = await _manager.useTransiently(id, read);
        // The integrity check runs on a file's first query, so a damaged
        // file is only known once the read above has opened it.
        if (backgroundWriter != null && _manager.integrityFailure(id) != null) {
          skipped.add(id);
          return _Failed<T>();
        }
        return _Ok<T>(value);
      } on Object catch (e) {
        onError?.call(id, e);
        return _Failed<T>();
      }
    });
    _logSkipped(backgroundWriter, skipped);
    return [
      for (final r in results)
        if (r is _Ok<T>) r.value,
    ];
  }

  void _logSkipped(String? writer, List<String> skipped) {
    if (writer == null || skipped.isEmpty) {
      return;
    }
    _manager.onWarn?.call(
      'CrossWorkspaceQueries',
      '$writer skipped read-only workspaces: ${(skipped..sort()).join(', ')}',
    );
  }

  /// Like [fanOut] but keeps each result paired with its workspace id, for
  /// callers that need to attribute rows they merge.
  Future<Map<String, T>> fanOutKeyed<T>(
    Future<T> Function(WorkspaceDatabase db) read, {
    void Function(String workspaceId, Object error)? onError,
  }) async {
    final ids = await _manager.liveWorkspaceIds();
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
  /// Live workspaces only, like the read fan-outs: a deleted workspace has no
  /// database to maintain. A read-only workspace (its integrity check failed)
  /// is skipped too, and the skipped ones are logged once per pass under
  /// [backgroundWriter]: its file takes no writes, and a sweep that tried
  /// would fail there on every pass.
  Future<int> forEachWorkspace(
    Future<void> Function(WorkspaceDatabase db) write, {
    void Function(String workspaceId, Object error)? onError,
    String backgroundWriter = 'maintenance sweep',
  }) async {
    final ids = await _manager.liveWorkspaceIds();
    final skipped = <String>[];
    var ok = 0;
    for (final id in ids) {
      try {
        await _manager.useTransiently(id, (db) async {
          // The integrity check runs on a file's first query.
          await db.customSelect('SELECT 1').get();
          if (_manager.integrityFailure(id) != null) {
            skipped.add(id);
            return;
          }
          await write(db);
          ok++;
        });
      } on Object catch (e) {
        onError?.call(id, e);
      }
    }
    _logSkipped(backgroundWriter, skipped);
    return ok;
  }

  /// Merges one stream per workspace; re-emits when any emits.
  ///
  /// First emission waits for every workspace. Workspace set is subscribe-time
  /// only. Does not close opened files (live drift watches). Optional [sort]
  /// after concat.
  Stream<List<T>> mergeStreams<T>(
    Stream<List<T>> Function(WorkspaceDatabase db) watch, {
    int Function(T a, T b)? sort,
    int? limit,
  }) async* {
    final ids = await _manager.liveWorkspaceIds();
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
  }) async {
    final perWorkspace = await fanOut(
      (db) => read(db, limit),
      onError: onError,
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
