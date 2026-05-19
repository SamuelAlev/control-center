import 'package:cc_persistence/database/tables/guard_decisions_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'guard_decision_dao.g.dart';

/// Data access object for the [GuardDecisionsTable] — the hash-chained
/// authorization audit spine.
///
/// The chain invariant lives HERE, not in callers: [append] allocates the
/// next `seq` and reads the previous row's `entryHash` inside one
/// transaction, then hands both to the caller-supplied builder that computes
/// the new row (including its own hash). Two concurrent appends therefore
/// serialize instead of forking the chain.
@DriftAccessor(tables: [GuardDecisionsTable])
class GuardDecisionDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$GuardDecisionDaoMixin {
  /// Creates a [GuardDecisionDao] bound to the given database.
  GuardDecisionDao(super.attachedDatabase);

  /// Appends one decision row. [build] receives the allocated `seq` and the
  /// previous row's `entryHash` ('' for a fresh chain) and returns the
  /// complete companion (which must carry that seq/prevHash and the computed
  /// entryHash).
  Future<void> append(
    String workspaceId,
    GuardDecisionsTableCompanion Function(int seq, String prevHash) build,
  ) => transaction(() async {
    final last =
        await (select(guardDecisionsTable)
              ..where((t) => t.workspaceId.equals(workspaceId))
              ..orderBy([(t) => OrderingTerm.desc(t.seq)])
              ..limit(1))
            .getSingleOrNull();
    final seq = (last?.seq ?? 0) + 1;
    final prevHash = last?.entryHash ?? '';
    await into(guardDecisionsTable).insert(build(seq, prevHash));
  });

  /// The most recent [limit] rows, newest first, optionally only those at or
  /// before [beforeSeq] (exclusive) for paging.
  Future<List<GuardDecisionsTableData>> recent(
    String workspaceId, {
    int limit = 100,
    int? beforeSeq,
  }) {
    final q = select(guardDecisionsTable)
      ..where((t) => t.workspaceId.equals(workspaceId))
      ..orderBy([(t) => OrderingTerm.desc(t.seq)])
      ..limit(limit);
    if (beforeSeq != null) {
      q.where((t) => t.seq.isSmallerThanValue(beforeSeq));
    }
    return q.get();
  }

  /// Streams the most recent [limit] rows, newest first.
  Stream<List<GuardDecisionsTableData>> watchRecent(
    String workspaceId, {
    int limit = 100,
  }) =>
      (select(guardDecisionsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.seq)])
            ..limit(limit))
          .watch();

  /// All rows in chain order starting at [fromSeq] (inclusive), page-sized
  /// for export/verification sweeps.
  Future<List<GuardDecisionsTableData>> pageFrom(
    String workspaceId,
    int fromSeq, {
    int limit = 500,
  }) =>
      (select(guardDecisionsTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.seq.isBiggerOrEqualValue(fromSeq),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.seq)])
            ..limit(limit))
          .get();

  /// Export-then-truncate: deletes every row with `seq <= [uptoSeq]` and
  /// writes a checkpoint row carrying [terminalHash] (the deleted segment's
  /// last `entryHash`) so the surviving chain still verifies. The checkpoint
  /// takes `seq = uptoSeq` — the slot the last deleted row held.
  Future<void> truncateWithCheckpoint(
    String workspaceId, {
    required int uptoSeq,
    required String terminalHash,
    required String checkpointId,
    required String checkpointEntryHash,
    required DateTime at,
  }) => transaction(() async {
    await (delete(guardDecisionsTable)..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              t.seq.isSmallerOrEqualValue(uptoSeq),
        ))
        .go();
    await into(guardDecisionsTable).insert(
      GuardDecisionsTableCompanion.insert(
        id: checkpointId,
        workspaceId: workspaceId,
        seq: uptoSeq,
        occurredAt: at,
        actorType: 'system',
        actorId: 'retention',
        surface: 'audit',
        actionName: 'audit.truncate',
        decision: 'allow',
        prevHash: terminalHash,
        entryHash: checkpointEntryHash,
        kind: const Value('checkpoint'),
      ),
    );
  });
}
