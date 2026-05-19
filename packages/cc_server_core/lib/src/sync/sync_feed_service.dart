import 'dart:async';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/daos/sync_dao.dart';
import 'package:drift/drift.dart';

/// Loads one changed row as its wire map (the SAME shape the snapshot watch
/// queries emit, produced by the same mappers), or null when the row is gone
/// (a delete raced the load — the feed's later `delete` entry wins).
typedef SyncRowLoader =
    Future<Map<String, dynamic>?> Function(
      String workspaceId,
      String pk,
      String? ctx,
    );

/// The authoritative delta feed (PRD 16 §6): evolves subscriptions from
/// full-snapshot to **delta packets ordered by the per-workspace monotonic
/// sync id**.
///
/// The SQLite triggers (see `WorkspaceDatabase._createSyncTriggers`) append every
/// adopted-store mutation to `sync_changes` atomically; this service tails
/// that feed and emits wire frames:
///
///  * `{v, kind:'seed', store, seq}` — the subscription's starting point;
///    the client fetches its snapshot separately and trusts deltas from
///    `seq` on.
///  * `{v, kind:'delta', store, from, seq, changes:[{tbl, pk, op, ctx?,
///    row?}]}` — everything in `(from, seq]` touching this store. `from`
///    always equals the previous frame's `seq`, so a client that sees
///    `from != lastSeq` detected a GAP and issues a ranged [pull]; a failed
///    pull drops that store to snapshot mode (the §6 kill-switch path).
///
/// Ordering never trusts a clock: the seq is allocated in the writing
/// transaction, in server receipt order. Frames carry [wireVersion]; a
/// client seeing an unknown version falls back to snapshot mode instead of
/// misapplying.
class SyncFeedService {
  /// Creates the feed over the per-workspace databases in [workspaces], with
  /// per-table row [loaders].
  SyncFeedService({
    required WorkspaceDatabaseManager workspaces,
    required Map<String, SyncRowLoader> loaders,
    this.retention = const Duration(days: 7),
    this.pollInterval = const Duration(seconds: 3),
  }) : _dbs = workspaces,
       _cross = CrossWorkspaceQueries(workspaces),
       _loaders = loaders;

  /// Delta wire-format version (PRD 16 §6: versioned deltas).
  static const int wireVersion = 1;

  /// The per-workspace databases whose change feeds are tailed.
  ///
  /// Each workspace has its own `sync_changes` table and its own monotonic
  /// sequence, which is what the delta protocol always meant by "per-workspace
  /// seq" — the split made it literal, so `sync_sequences` is now a single row
  /// per file instead of one row per workspace in a shared table.
  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;

  /// How long feed rows are retained for ranged pulls.
  final Duration retention;

  /// Fallback poll cadence (safety net beside Drift's table notifications).
  final Duration pollInterval;

  final Map<String, SyncRowLoader> _loaders;
  Timer? _retentionTimer;

  /// The change-feed DAO for [workspaceId].
  SyncDao _sync(String workspaceId) => _dbs.of(workspaceId).syncDao;

  /// Starts the retention sweep. Idempotent.
  void start() {
    _retentionTimer ??= Timer.periodic(
      const Duration(hours: 6),
      (_) => unawaited(_pruneAll()),
    );
  }

  /// Prunes every workspace's feed. CROSS-WORKSPACE BY DESIGN: retention is a
  /// server-wide maintenance sweep, so it visits each workspace's file in turn.
  Future<void> _pruneAll() async {
    final cutoff = DateTime.now().subtract(retention);
    await _cross.forEachWorkspace((db) => db.syncDao.pruneBefore(cutoff));
  }

  /// Stops the retention sweep.
  void dispose() {
    _retentionTimer?.cancel();
    _retentionTimer = null;
  }

  /// The live delta stream for one [store] in [workspaceId].
  Stream<Map<String, dynamic>> watch(String workspaceId, String store) {
    late StreamController<Map<String, dynamic>> controller;
    StreamSubscription<void>? tableSub;
    Timer? poll;
    var last = 0;
    var draining = false;
    var pendingSignal = false;
    var cancelled = false;

    Future<void> drain() async {
      if (draining) {
        pendingSignal = true;
        return;
      }
      draining = true;
      try {
        do {
          pendingSignal = false;
          final changes = await _sync(
            workspaceId,
          ).changesSince(workspaceId, last);
          if (changes.isEmpty || cancelled) {
            return;
          }
          final from = last;
          last = changes.last.seq;
          final wireChanges = <Map<String, dynamic>>[];
          for (final change in changes) {
            if (change.store != store) {
              continue;
            }
            Map<String, dynamic>? row;
            if (change.op == 'upsert') {
              final loader = _loaders[change.tbl];
              row = loader == null
                  ? null
                  : await loader(workspaceId, change.pk, change.ctx);
              if (row == null) {
                // Row already gone (a later delete will follow) — skip.
                continue;
              }
            }
            wireChanges.add({
              'tbl': change.tbl,
              'pk': change.pk,
              'op': change.op,
              'ctx': ?change.ctx,
              'row': ?row,
            });
          }
          if (cancelled || controller.isClosed) {
            return;
          }
          // Emit even when no change touched THIS store: the frame advances
          // `seq` so the client's contiguity check (`from == lastSeq`) stays
          // true while other stores consume sequence numbers.
          controller.add({
            'v': wireVersion,
            'kind': 'delta',
            'store': store,
            'from': from,
            'seq': last,
            'changes': wireChanges,
          });
        } while (pendingSignal);
      } finally {
        draining = false;
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () async {
        last = await _sync(workspaceId).currentSeq(workspaceId);
        if (cancelled || controller.isClosed) {
          return;
        }
        controller.add({
          'v': wireVersion,
          'kind': 'seed',
          'store': store,
          'seq': last,
        });
        // Table notifications come from this workspace's own database, so a
        // write in another workspace no longer wakes this subscriber at all —
        // the drain that used to run and find nothing is gone.
        final wsDb = _dbs.of(workspaceId);
        tableSub = wsDb
            .tableUpdates(
              TableUpdateQuery.onAllTables([
                wsDb.ticketsTable,
                wsDb.spacesTable,
                wsDb.conversationMessagesTable,
                wsDb.spaceParticipantsTable,
                wsDb.spaceNotesTable,
                wsDb.messageReactionsTable,
              ]),
            )
            .listen((_) => unawaited(drain()));
        poll = Timer.periodic(pollInterval, (_) => unawaited(drain()));
      },
      onCancel: () async {
        cancelled = true;
        poll?.cancel();
        await tableSub?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// Ranged gap-fill: everything in `(fromSeq, current]` for [store].
  /// Answers `snapshot_required: true` when the requested range fell off the
  /// retained horizon — the client then drops that store to snapshot mode.
  Future<Map<String, dynamic>> pull(
    String workspaceId,
    String store,
    int fromSeq, {
    int limit = 2000,
  }) async {
    final current = await _sync(workspaceId).currentSeq(workspaceId);
    if (current > fromSeq) {
      final oldest = await _sync(workspaceId).oldestSeq(workspaceId);
      if (oldest == null || fromSeq + 1 < oldest) {
        return {
          'v': wireVersion,
          'store': store,
          'from': fromSeq,
          'seq': current,
          'snapshot_required': true,
          'changes': const <Map<String, dynamic>>[],
        };
      }
    }
    final changes = await _sync(
      workspaceId,
    ).changesSince(workspaceId, fromSeq, limit: limit);
    final wireChanges = <Map<String, dynamic>>[];
    for (final change in changes) {
      if (change.store != store) {
        continue;
      }
      Map<String, dynamic>? row;
      if (change.op == 'upsert') {
        final loader = _loaders[change.tbl];
        row = loader == null
            ? null
            : await loader(workspaceId, change.pk, change.ctx);
        if (row == null) {
          continue;
        }
      }
      wireChanges.add({
        'tbl': change.tbl,
        'pk': change.pk,
        'op': change.op,
        'ctx': ?change.ctx,
        'row': ?row,
      });
    }
    return {
      'v': wireVersion,
      'store': store,
      'from': fromSeq,
      'seq': changes.isEmpty ? current : changes.last.seq,
      'snapshot_required': false,
      'changes': wireChanges,
    };
  }
}
