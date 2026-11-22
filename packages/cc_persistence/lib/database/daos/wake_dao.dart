import 'package:cc_persistence/database/tables/wake_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'wake_dao.g.dart';

/// Data access for the wake queue's outbox (`agent_wakes`) in ONE workspace.
///
/// Scoped by hanging off a [WorkspaceDatabase]: the isolation boundary is the
/// database file. Every state change is a conditional `UPDATE` from the
/// states it leaves, so two racing callers never both move a wake.
@DriftAccessor(tables: [AgentWakesTable])
class WakeDao extends DatabaseAccessor<WorkspaceDatabase> with _$WakeDaoMixin {
  /// Creates a [WakeDao] bound to one workspace's database.
  WakeDao(super.attachedDatabase);

  /// The `state` values a wake is in before it settles.
  static const String pending = 'pending';

  /// See [pending].
  static const String held = 'held';

  /// See [pending].
  static const String claimed = 'claimed';

  /// The settled `state` values.
  static const List<String> settled = [
    'delivered',
    'skipped',
    'expired',
    'cancelled',
  ];

  /// Inserts [wake] unless its `dedup_key` exists (`ON CONFLICT DO NOTHING`
  /// on the unique key, never read-then-write). True when it was written.
  Future<bool> insertIfAbsent(AgentWakesTableCompanion wake) async =>
      await into(agentWakesTable).insertReturningOrNull(
        wake,
        onConflict: DoNothing(target: [agentWakesTable.dedupKey]),
      ) !=
      null;

  /// The wake [id], or null.
  Future<AgentWakesTableData?> getById(String id) => (select(
    agentWakesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The wake with [dedupKey], or null.
  Future<AgentWakesTableData?> getByDedupKey(String dedupKey) => (select(
    agentWakesTable,
  )..where((t) => t.dedupKey.equals(dedupKey))).getSingleOrNull();

  List<OrderingTerm Function($AgentWakesTableTable)> get _oldestDueFirst => [
    (t) => OrderingTerm.asc(t.notBefore),
    (t) => OrderingTerm.asc(t.createdAt),
    (t) => OrderingTerm.asc(t.id),
  ];

  /// Pending wakes due at [now], oldest `not_before` first.
  Future<List<AgentWakesTableData>> listDue(DateTime now, int limit) =>
      (select(agentWakesTable)
            ..where(
              (t) =>
                  t.state.equals(pending) &
                  t.notBefore.isSmallerOrEqualValue(now),
            )
            ..orderBy(_oldestDueFirst)
            ..limit(limit))
          .get();

  /// The pending wake with the earliest `not_before`, or null.
  Future<AgentWakesTableData?> earliestPending() =>
      (select(agentWakesTable)
            ..where((t) => t.state.equals(pending))
            ..orderBy(_oldestDueFirst)
            ..limit(1))
          .getSingleOrNull();

  /// The conversation's wakes, newest first, narrowed to [states].
  Future<List<AgentWakesTableData>> listForConversation(
    String conversationId, {
    Set<String>? states,
  }) =>
      (select(agentWakesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  (states == null
                      ? const Constant(true)
                      : t.state.isIn(states)),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .get();

  /// The wakes of the rule [ruleId] in [conversationId], newest first, at
  /// most [limit], those after [before] when given.
  Future<List<AgentWakesTableData>> listForRule(
    String conversationId,
    String ruleId, {
    required int limit,
    ({DateTime createdAt, String id})? before,
  }) =>
      (select(agentWakesTable)
            ..where((t) {
              var where =
                  t.conversationId.equals(conversationId) &
                  detailField(t, 'ruleId').equals(ruleId);
              if (before != null) {
                where &=
                    t.createdAt.isSmallerThanValue(before.createdAt) |
                    (t.createdAt.equals(before.createdAt) &
                        t.id.isSmallerThanValue(before.id));
              }
              return where;
            })
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit))
          .get();

  /// Every `held` wake, oldest first: what the daily digest lists as
  /// waiting for a person to release or deliver it.
  Future<List<AgentWakesTableData>> listHeld() =>
      (select(agentWakesTable)
            ..where((t) => t.state.equals('held'))
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// The pending wakes aimed at [agentId] in [conversationId], oldest
  /// `not_before` first.
  Future<List<AgentWakesTableData>> listPendingFor(
    String conversationId,
    String agentId,
  ) =>
      (select(agentWakesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  t.agentId.equals(agentId) &
                  t.state.equals(pending),
            )
            ..orderBy(_oldestDueFirst))
          .get();

  /// Watches the conversation's pending and held wakes by `not_before`.
  Stream<List<AgentWakesTableData>> watchOpenForConversation(
    String conversationId,
  ) =>
      (select(agentWakesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  t.state.isIn(const [pending, held]),
            )
            ..orderBy(_oldestDueFirst))
          .watch();

  /// Claims [id] (pending to claimed, `attempt` + 1, `claimed_at` = [now]).
  /// True when this call moved it.
  Future<bool> claimOne(String id, DateTime now) async =>
      await (update(
        agentWakesTable,
      )..where((t) => t.id.equals(id) & t.state.equals(pending))).write(
        AgentWakesTableCompanion.custom(
          state: const Constant(claimed),
          claimedAt: Variable(now),
          attempt: agentWakesTable.attempt + const Constant(1),
        ),
      ) ==
      1;

  /// Moves those of [ids] that are in one of [from] to the values of [to].
  /// Returns how many moved.
  ///
  /// The `claimed_at` refresh of a claim still in flight is [move] from
  /// claimed to claimed.
  Future<int> move(
    Iterable<String> ids, {
    required List<String> from,
    required AgentWakesTableCompanion to,
  }) {
    final list = ids.toSet().toList();
    if (list.isEmpty) {
      return Future.value(0);
    }
    return (update(
      agentWakesTable,
    )..where((t) => t.id.isIn(list) & t.state.isIn(from))).write(to);
  }

  /// Moves every wake claimed before [claimedBefore] back to pending in one
  /// statement and returns the rows it moved. The age is part of the
  /// condition, so a claim that was released and taken afresh is left alone.
  Future<List<AgentWakesTableData>> reclaimStale(DateTime claimedBefore) =>
      (update(agentWakesTable)..where(
            (t) =>
                t.state.equals(claimed) &
                t.claimedAt.isSmallerThanValue(claimedBefore),
          ))
          .writeReturning(
            const AgentWakesTableCompanion(
              state: Value(pending),
              claimedAt: Value(null),
            ),
          );

  /// Expires pending and held wakes whose `expires_at` is at or before
  /// [now]. Returns the rows it moved.
  Future<List<AgentWakesTableData>> expireDue(DateTime now) =>
      (update(agentWakesTable)..where(
            (t) =>
                t.state.isIn(const [pending, held]) &
                t.expiresAt.isSmallerOrEqualValue(now),
          ))
          .writeReturning(
            AgentWakesTableCompanion(
              state: const Value('expired'),
              stateReason: const Value('expires_at_passed'),
              settledAt: Value(now),
            ),
          );

  /// Expires pending wakes waiting out one of [reasons] whose `expires_at`
  /// is at or before [now], keeping that reason as the expired state's
  /// reason, and returns the rows it moved.
  Future<List<AgentWakesTableData>> expireWaiting(
    DateTime now,
    List<String> reasons,
  ) =>
      (update(agentWakesTable)..where(
            (t) =>
                t.state.equals(pending) &
                t.stateReason.isIn(reasons) &
                t.expiresAt.isSmallerOrEqualValue(now),
          ))
          .writeReturning(
            AgentWakesTableCompanion(
              state: const Value('expired'),
              settledAt: Value(now),
            ),
          );

  /// Deletes settled wakes that settled before [cutoff]. Returns how many.
  Future<int> deleteSettledBefore(DateTime cutoff) =>
      (delete(agentWakesTable)..where(
            (t) =>
                t.state.isIn(settled) & t.settledAt.isSmallerThanValue(cutoff),
          ))
          .go();

  /// Distinct runs wakes were delivered to since [since], in the file or in
  /// [conversationId].
  Future<int> countDeliveredRunsSince(
    DateTime since, {
    String? conversationId,
  }) {
    final runs = agentWakesTable.deliveredRunId.count(distinct: true);
    final t = agentWakesTable;
    return (selectOnly(t)
          ..addColumns([runs])
          ..where(
            t.state.equals('delivered') &
                t.deliveredRunId.isNotNull() &
                t.settledAt.isBiggerOrEqualValue(since) &
                (conversationId == null
                    ? const Constant(true)
                    : t.conversationId.equals(conversationId)),
          ))
        .map((row) => row.read(runs) ?? 0)
        .getSingle();
  }

  /// The `json_extract` of [key] from a wake's detail.
  static Expression<String> detailField($AgentWakesTableTable t, String key) =>
      FunctionCallExpression<String>('json_extract', [
        t.detail,
        Constant('\$.$key'),
      ]);

  /// Cancels the pending and held wakes matching every given filter with
  /// [reason]. At least one filter must be given. Returns the rows it moved.
  Future<List<AgentWakesTableData>> cancelWhere({
    String? goalId,
    String? ruleId,
    String? askId,
    String? requestedByUserId,
    String? conversationId,
    required String reason,
    required DateTime now,
  }) {
    if (goalId == null &&
        ruleId == null &&
        askId == null &&
        requestedByUserId == null &&
        conversationId == null) {
      throw ArgumentError('cancelWhere needs at least one filter');
    }
    return (update(agentWakesTable)..where((t) {
          Expression<bool> where = t.state.isIn(const [pending, held]);
          if (goalId != null) {
            where &= detailField(t, 'goalId').equals(goalId);
          }
          if (ruleId != null) {
            where &= detailField(t, 'ruleId').equals(ruleId);
          }
          if (askId != null) {
            where &= detailField(t, 'askId').equals(askId);
          }
          if (requestedByUserId != null) {
            where &= t.requestedByUserId.equals(requestedByUserId);
          }
          if (conversationId != null) {
            where &= t.conversationId.equals(conversationId);
          }
          return where;
        }))
        .writeReturning(
          AgentWakesTableCompanion(
            state: const Value('cancelled'),
            stateReason: Value(reason),
            settledAt: Value(now),
          ),
        );
  }

  /// Whether this file holds a pending or claimed wake, or a held one with
  /// an expiry ([hasExpiringHeld]).
  Future<bool> hasOpenWakes() async =>
      await (selectOnly(agentWakesTable)
            ..addColumns([agentWakesTable.id])
            ..where(agentWakesTable.state.isIn(const [pending, claimed]))
            ..limit(1))
          .getSingleOrNull() !=
          null ||
      await hasExpiringHeld();

  /// Whether this file holds a held wake with an `expires_at`.
  Future<bool> hasExpiringHeld() async =>
      await (selectOnly(agentWakesTable)
            ..addColumns([agentWakesTable.id])
            ..where(
              agentWakesTable.state.equals(held) &
                  agentWakesTable.expiresAt.isNotNull(),
            )
            ..limit(1))
          .getSingleOrNull() !=
      null;
}
