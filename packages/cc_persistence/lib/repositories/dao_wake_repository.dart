import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/wake_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/wake_mapper.dart';
import 'package:cc_persistence/repositories/refused_rows.dart';
import 'package:drift/drift.dart';

/// Drift-backed [WakeRepository].
///
/// Resolves `_dbs.of(workspaceId).wakeDao` per call: wakes live in their
/// workspace's own file, so the workspace id picks the file before any SQL
/// runs and a foreign id is simply not found. [workspacesWithOpenWakes] is
/// the one read that spans files.
///
/// A row the entity refuses is left out of reads and reported once per read
/// through the manager's warning sink, so one bad row never stalls the queue;
/// when it is still pending, held or claimed the read settles it as
/// `skipped` (`invalid_row`), so neither [listDue] nor
/// [earliestPendingNotBefore] keeps returning it.
class DaoWakeRepository implements WakeRepository {
  /// Creates a [DaoWakeRepository] over the per-workspace databases. `clock`
  /// stamps the `settled_at` of a refused row a read settles.
  DaoWakeRepository(this._dbs, {this._clock = DateTime.now})
    : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final DateTime Function() _clock;
  final WakeMapper _mapper = const WakeMapper();

  /// The `state_reason` of a stored wake the entity refused.
  static const String invalidRowReason = 'invalid_row';

  WakeDao _dao(String workspaceId) => _dbs.of(workspaceId).wakeDao;

  Future<List<Wake>> _list(
    String workspaceId,
    Iterable<AgentWakesTableData> rows,
  ) => mapSettlingRefused(
    dbs: _dbs,
    workspaceId: workspaceId,
    repository: 'WakeRepository',
    table: 'agent_wakes',
    rows: rows,
    map: _mapper.tryToDomain,
    isOpen: (row) => _open.contains(row.state),
    idOf: (row) => row.id,
    settle: (ids) => _dao(workspaceId).move(
      ids,
      from: _open,
      to: AgentWakesTableCompanion(
        state: Value(WakeState.skipped.wire),
        stateReason: const Value(invalidRowReason),
        settledAt: Value(_clock()),
      ),
    ),
    settledAs: 'skipped ($invalidRowReason)',
  );

  Future<Wake?> _one(String workspaceId, AgentWakesTableData? row) async =>
      row == null ? null : (await _list(workspaceId, [row])).firstOrNull;

  @override
  Future<bool> insertIfAbsent(Wake wake) =>
      // The wake carries its workspace; the file is picked from the entity.
      _dao(wake.workspaceId).insertIfAbsent(_mapper.toCompanion(wake));

  @override
  Future<Wake?> getById(String workspaceId, String id) async =>
      _one(workspaceId, await _dao(workspaceId).getById(id));

  @override
  Future<Wake?> getByDedupKey(String workspaceId, String dedupKey) async =>
      _one(workspaceId, await _dao(workspaceId).getByDedupKey(dedupKey));

  @override
  Future<List<Wake>> listDue(
    String workspaceId, {
    required DateTime now,
    int limit = 100,
  }) async => _list(workspaceId, await _dao(workspaceId).listDue(now, limit));

  @override
  Future<bool> hasExpiringHeld(String workspaceId) =>
      _dao(workspaceId).hasExpiringHeld();

  @override
  Future<DateTime?> earliestPendingNotBefore(String workspaceId) async {
    final dao = _dao(workspaceId);
    // A refused row is settled by the read, so the next one is looked at:
    // the queue never arms its timer from a wake nobody can deliver.
    while (true) {
      final row = await dao.earliestPending();
      if (row == null) {
        return null;
      }
      final wake = await _one(workspaceId, row);
      if (wake != null) {
        return wake.notBefore;
      }
      if ((await dao.getById(row.id))?.state == WakeDao.pending) {
        // Settling lost to nothing that should exist; never spin.
        return row.notBefore;
      }
    }
  }

  @override
  Future<List<Wake>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeState>? states,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).listForConversation(
      conversationId,
      states: states == null ? null : {for (final s in states) s.wire},
    ),
  );

  @override
  Future<List<Wake>> listForRule(
    String workspaceId, {
    required String conversationId,
    required String ruleId,
    required int limit,
    ({DateTime createdAt, String id})? before,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).listForRule(
      conversationId,
      ruleId,
      limit: limit,
      before: before,
    ),
  );

  @override
  Future<List<Wake>> listPendingFor(
    String workspaceId, {
    required String conversationId,
    required String agentId,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).listPendingFor(conversationId, agentId),
  );

  @override
  Stream<List<Wake>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => _dao(workspaceId)
      .watchOpenForConversation(conversationId)
      .asyncMap((rows) => _list(workspaceId, rows));

  @override
  Future<List<String>> claim(
    String workspaceId, {
    required List<String> ids,
    required DateTime now,
  }) async {
    final dao = _dao(workspaceId);
    final claimed = <String>[];
    // One conditional UPDATE per id: each answers for itself, so a racing
    // claimer that moved an id first makes this call leave exactly that id
    // out.
    for (final id in ids.toSet()) {
      if (await dao.claimOne(id, now)) {
        claimed.add(id);
      }
    }
    return claimed;
  }

  static const _open = [WakeDao.pending, WakeDao.held, WakeDao.claimed];

  /// Refuses a reason the entity would refuse to read back.
  static String _reason(String reason) {
    if (reason.isEmpty || reason.length > Wake.maxStateReasonLength) {
      throw ArgumentError.value(
        reason,
        'reason',
        'must be 1 to ${Wake.maxStateReasonLength} characters',
      );
    }
    return reason;
  }

  @override
  Future<int> markDelivered(
    String workspaceId, {
    required List<String> ids,
    required String? runId,
    required DateTime now,
  }) => _dao(workspaceId).move(
    ids,
    from: const [WakeDao.pending, WakeDao.claimed],
    to: AgentWakesTableCompanion(
      state: Value(WakeState.delivered.wire),
      deliveredRunId: Value(runId),
      settledAt: Value(now),
    ),
  );

  Future<int> _settle(
    String workspaceId,
    List<String> ids,
    WakeState state,
    String reason,
    DateTime now,
  ) => _dao(workspaceId).move(
    ids,
    from: _open,
    to: AgentWakesTableCompanion(
      state: Value(state.wire),
      stateReason: Value(_reason(reason)),
      settledAt: Value(now),
    ),
  );

  @override
  Future<int> markSkipped(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  }) => _settle(workspaceId, ids, WakeState.skipped, reason, now);

  @override
  Future<int> markExpired(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  }) => _settle(workspaceId, ids, WakeState.expired, reason, now);

  @override
  Future<int> cancel(
    String workspaceId, {
    required List<String> ids,
    required String reason,
    required DateTime now,
  }) => _settle(workspaceId, ids, WakeState.cancelled, reason, now);

  @override
  Future<int> hold(
    String workspaceId, {
    required List<String> ids,
    required String reason,
  }) => _dao(workspaceId).move(
    ids,
    from: const [WakeDao.pending],
    to: AgentWakesTableCompanion(
      state: Value(WakeState.held.wire),
      stateReason: Value(_reason(reason)),
    ),
  );

  @override
  Future<int> release(String workspaceId, {required List<String> ids}) =>
      _dao(workspaceId).move(
        ids,
        from: const [WakeDao.held],
        to: AgentWakesTableCompanion(
          state: Value(WakeState.pending.wire),
          stateReason: const Value(null),
        ),
      );

  @override
  Future<int> releaseClaim(String workspaceId, {required List<String> ids}) =>
      _dao(workspaceId).move(
        ids,
        from: const [WakeDao.claimed],
        to: AgentWakesTableCompanion(
          state: Value(WakeState.pending.wire),
          claimedAt: const Value(null),
        ),
      );

  @override
  Future<List<Wake>> reclaimStaleClaims(
    String workspaceId, {
    required DateTime claimedBefore,
  }) async {
    // One statement whose condition holds the age it reclaims by: a wake
    // delivered, or released and claimed afresh, in the meantime is left
    // alone.
    final moved = await _dao(workspaceId).reclaimStale(claimedBefore);
    return _list(workspaceId, moved);
  }

  @override
  Future<List<Wake>> expireDue(
    String workspaceId, {
    required DateTime now,
  }) async => _list(workspaceId, await _dao(workspaceId).expireDue(now));

  @override
  Future<int> defer(
    String workspaceId, {
    required List<String> ids,
    required DateTime until,
    required String reason,
  }) => _dao(workspaceId).move(
    ids,
    from: const [WakeDao.pending, WakeDao.claimed],
    to: AgentWakesTableCompanion(
      state: Value(WakeState.pending.wire),
      notBefore: Value(until),
      stateReason: Value(_reason(reason)),
      claimedAt: const Value(null),
    ),
  );

  @override
  Future<int> deferWaiting(
    String workspaceId, {
    required String id,
    required DateTime until,
    required String reason,
    required DateTime expiresAt,
  }) => _dao(workspaceId).move(
    [id],
    from: const [WakeDao.pending, WakeDao.claimed],
    to: AgentWakesTableCompanion(
      state: Value(WakeState.pending.wire),
      notBefore: Value(until),
      stateReason: Value(_reason(reason)),
      claimedAt: const Value(null),
      expiresAt: Value(expiresAt),
    ),
  );

  @override
  Future<List<Wake>> expireWaiting(
    String workspaceId, {
    required DateTime now,
    required Set<String> reasons,
  }) async => reasons.isEmpty
      ? const []
      : _list(
          workspaceId,
          await _dao(workspaceId).expireWaiting(now, reasons.toList()),
        );

  @override
  Future<int> refreshClaims(
    String workspaceId, {
    required List<String> ids,
    required DateTime now,
  }) => _dao(workspaceId).move(
    ids,
    from: const [WakeDao.claimed],
    to: AgentWakesTableCompanion(claimedAt: Value(now)),
  );

  @override
  Future<int> reopenDelivered(
    String workspaceId, {
    required List<String> ids,
    required String reason,
  }) => _dao(workspaceId).move(
    ids,
    from: [WakeState.delivered.wire],
    to: AgentWakesTableCompanion(
      state: Value(WakeState.pending.wire),
      stateReason: Value(_reason(reason)),
      deliveredRunId: const Value(null),
      claimedAt: const Value(null),
      settledAt: const Value(null),
    ),
  );

  @override
  Future<int> deleteSettledBefore(
    String workspaceId, {
    required DateTime cutoff,
  }) => _dao(workspaceId).deleteSettledBefore(cutoff);

  @override
  Future<int> countDeliveredRunsSince(
    String workspaceId, {
    required DateTime since,
    String? conversationId,
  }) => _dao(
    workspaceId,
  ).countDeliveredRunsSince(since, conversationId: conversationId);

  @override
  Future<List<Wake>> cancelWhere(
    String workspaceId, {
    String? goalId,
    String? ruleId,
    String? askId,
    String? requestedByUserId,
    String? conversationId,
    required String reason,
    required DateTime now,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).cancelWhere(
      goalId: goalId,
      ruleId: ruleId,
      askId: askId,
      requestedByUserId: requestedByUserId,
      conversationId: conversationId,
      reason: _reason(reason),
      now: now,
    ),
  );

  /// CROSS-WORKSPACE BY DESIGN: the wake queue arms its single timer at boot
  /// from every workspace's open wakes; everything it then reads or writes is
  /// workspace-scoped. Read-only workspaces are skipped (the queue would
  /// fail every write there).
  @override
  Future<List<String>> workspacesWithOpenWakes() async {
    final ids = await _cross.fanOut(
      (db) async => await db.wakeDao.hasOpenWakes() ? db.workspaceId : null,
      backgroundWriter: 'wake queue',
    );
    return [for (final id in ids) ?id];
  }
}
