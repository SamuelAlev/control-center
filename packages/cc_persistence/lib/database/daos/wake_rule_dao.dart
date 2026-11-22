import 'package:cc_persistence/database/tables/wake_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'wake_rule_dao.g.dart';

/// Data access for wake rules (`wake_rules`) in ONE workspace.
///
/// Scoped by hanging off a [WorkspaceDatabase]: the isolation boundary is the
/// database file.
@DriftAccessor(tables: [WakeRulesTable])
class WakeRuleDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$WakeRuleDaoMixin {
  /// Creates a [WakeRuleDao] bound to one workspace's database.
  WakeRuleDao(super.attachedDatabase);

  List<OrderingTerm Function($WakeRulesTableTable)> get _newestFirst => [
    (t) => OrderingTerm.desc(t.createdAt),
    (t) => OrderingTerm.desc(t.id),
  ];

  /// Inserts a new rule; throws when its id exists.
  Future<void> insert(WakeRulesTableCompanion rule) =>
      into(wakeRulesTable).insert(rule);

  /// Writes [values] on the rule [id] when [condition] holds for its stored
  /// row, as one statement. True when this call changed it.
  Future<bool> writeIf(
    String id,
    Expression<bool> Function($WakeRulesTableTable t) condition,
    Insertable<WakeRulesTableData> values,
  ) async =>
      await (update(
        wakeRulesTable,
      )..where((t) => t.id.equals(id) & condition(t))).write(values) ==
      1;

  /// Adds [micros] to the rule's `cost_micros` in one statement and returns
  /// the new total, or null when there is no rule [id].
  Future<int?> addCost(String id, int micros, DateTime now) async {
    final rows = await (update(wakeRulesTable)..where((t) => t.id.equals(id)))
        .writeReturning(
          WakeRulesTableCompanion.custom(
            costMicros: wakeRulesTable.costMicros + Variable(micros),
            updatedAt: Variable(now),
          ),
        );
    return rows.firstOrNull?.costMicros;
  }

  /// The rules that have not ended (active and paused), oldest first.
  Future<List<WakeRulesTableData>> listNotEnded() =>
      (select(wakeRulesTable)
            ..where((t) => t.status.isIn(const ['active', 'paused']))
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// The active rules, oldest first, narrowed by [agentId] and
  /// [conversationId].
  Future<List<WakeRulesTableData>> listActive({
    String? agentId,
    String? conversationId,
  }) =>
      (select(wakeRulesTable)
            ..where(
              (t) =>
                  t.status.equals('active') &
                  (agentId == null
                      ? const Constant(true)
                      : t.agentId.equals(agentId)) &
                  (conversationId == null
                      ? const Constant(true)
                      : t.conversationId.equals(conversationId)),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// The rule [id], or null.
  Future<WakeRulesTableData?> getById(String id) =>
      (select(wakeRulesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The conversation's rules, newest first, narrowed to [statuses].
  Future<List<WakeRulesTableData>> listForConversation(
    String conversationId, {
    Set<String>? statuses,
  }) =>
      (select(wakeRulesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  (statuses == null
                      ? const Constant(true)
                      : t.status.isIn(statuses)),
            )
            ..orderBy(_newestFirst))
          .get();

  /// The agent's rules, newest first, narrowed to [statuses].
  Future<List<WakeRulesTableData>> listForAgent(
    String agentId, {
    Set<String>? statuses,
  }) =>
      (select(wakeRulesTable)
            ..where(
              (t) =>
                  t.agentId.equals(agentId) &
                  (statuses == null
                      ? const Constant(true)
                      : t.status.isIn(statuses)),
            )
            ..orderBy(_newestFirst))
          .get();

  /// The active watches of [eventKind], oldest first.
  Future<List<WakeRulesTableData>> listActiveByEvent(String eventKind) =>
      (select(wakeRulesTable)
            ..where(
              (t) => t.status.equals('active') & t.eventKind.equals(eventKind),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// The rules the run [runId] created for [agentId] in [conversationId],
  /// newest first (read through the conversation/agent index).
  Future<List<WakeRulesTableData>> listCreatedByRun({
    required String conversationId,
    required String agentId,
    required String runId,
  }) =>
      (select(wakeRulesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  t.agentId.equals(agentId) &
                  t.createdByRunId.equals(runId),
            )
            ..orderBy(_newestFirst))
          .get();

  /// The rules bound to [goalId], newest first.
  Future<List<WakeRulesTableData>> listByGoal(String goalId) =>
      (select(wakeRulesTable)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy(_newestFirst))
          .get();

  /// The runs and cost of the lineage rooted at [rootRuleId]: the root's row
  /// and every row naming it as root (`idx_wake_rules_root_rule`), whatever
  /// their status.
  Future<({int runs, int costMicros})> lineageTotals(String rootRuleId) async {
    final runs = wakeRulesTable.runCount.sum();
    final cost = wakeRulesTable.costMicros.sum();
    final row =
        await (selectOnly(wakeRulesTable)
              ..addColumns([runs, cost])
              ..where(
                wakeRulesTable.id.equals(rootRuleId) |
                    wakeRulesTable.rootRuleId.equals(rootRuleId),
              ))
            .getSingle();
    return (runs: row.read(runs) ?? 0, costMicros: row.read(cost) ?? 0);
  }

  /// The rows naming [rootRuleId] as their lineage's root
  /// (`idx_wake_rules_root_rule`), newest first.
  Future<List<WakeRulesTableData>> listByRoot(String rootRuleId) =>
      (select(wakeRulesTable)
            ..where((t) => t.rootRuleId.equals(rootRuleId))
            ..orderBy(_newestFirst))
          .get();

  /// The rules [userId] is accountable for, newest first.
  Future<List<WakeRulesTableData>> listByRequester(String userId) =>
      (select(wakeRulesTable)
            ..where((t) => t.requestedByUserId.equals(userId))
            ..orderBy(_newestFirst))
          .get();

  /// Watches the conversation's rules that are not ended, newest first.
  Stream<List<WakeRulesTableData>> watchForConversation(
    String conversationId,
  ) =>
      (select(wakeRulesTable)
            ..where(
              (t) =>
                  t.conversationId.equals(conversationId) &
                  t.status.isIn(const ['active', 'paused']),
            )
            ..orderBy(_newestFirst))
          .watch();

  /// Watches every rule, newest first.
  Stream<List<WakeRulesTableData>> watchAll() =>
      (select(wakeRulesTable)..orderBy(_newestFirst)).watch();

  /// Deletes the rule [id]. Returns whether it existed.
  Future<bool> deleteById(String id) async =>
      await (delete(wakeRulesTable)..where((t) => t.id.equals(id))).go() == 1;

  /// Whether this file holds an active rule.
  Future<bool> hasActiveRules() async =>
      await (selectOnly(wakeRulesTable)
            ..addColumns([wakeRulesTable.id])
            ..where(wakeRulesTable.status.equals('active'))
            ..limit(1))
          .getSingleOrNull() !=
      null;
}
