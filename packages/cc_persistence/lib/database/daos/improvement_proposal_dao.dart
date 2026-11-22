import 'package:cc_persistence/database/tables/improvement_proposals_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'improvement_proposal_dao.g.dart';

/// Data access for improvement proposals (`improvement_proposals`) in ONE
/// workspace.
///
/// Scoped by hanging off a [WorkspaceDatabase]: the isolation boundary is the
/// database file.
@DriftAccessor(tables: [ImprovementProposalsTable])
class ImprovementProposalDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ImprovementProposalDaoMixin {
  /// Creates an [ImprovementProposalDao] bound to one workspace's database.
  ImprovementProposalDao(super.attachedDatabase);

  List<OrderingTerm Function($ImprovementProposalsTableTable)>
  get _newestFirst => [
    (t) => OrderingTerm.desc(t.createdAt),
    (t) => OrderingTerm.desc(t.id),
  ];

  /// Inserts a new proposal; throws when its id exists.
  Future<void> insert(ImprovementProposalsTableCompanion proposal) =>
      into(improvementProposalsTable).insert(proposal);

  /// Writes [values] on the proposal [id] when [condition] holds for its
  /// stored row, as one statement. True only for the caller that changed it.
  Future<bool> writeIf(
    String id,
    Expression<bool> Function($ImprovementProposalsTableTable t) condition,
    ImprovementProposalsTableCompanion values,
  ) async =>
      await (update(
        improvementProposalsTable,
      )..where((t) => t.id.equals(id) & condition(t))).write(values) ==
      1;

  /// The proposal [id], or null.
  Future<ImprovementProposalsTableData?> getById(String id) => (select(
    improvementProposalsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Every proposal, newest first, narrowed to [statuses].
  Future<List<ImprovementProposalsTableData>> list({Set<String>? statuses}) =>
      (select(improvementProposalsTable)
            ..where(
              (t) => statuses == null
                  ? const Constant(true)
                  : t.status.isIn(statuses),
            )
            ..orderBy(_newestFirst))
          .get();

  /// Watches every proposal, newest first.
  Stream<List<ImprovementProposalsTableData>> watchAll() =>
      (select(improvementProposalsTable)..orderBy(_newestFirst)).watch();

  /// The proposals made for [goalId], newest first.
  Future<List<ImprovementProposalsTableData>> listByGoal(String goalId) =>
      (select(improvementProposalsTable)
            ..where((t) => t.goalId.equals(goalId))
            ..orderBy(_newestFirst))
          .get();

  /// The newest proposal made in [conversationId], or null.
  Future<ImprovementProposalsTableData?> latestForConversation(
    String conversationId,
  ) =>
      (select(improvementProposalsTable)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy(_newestFirst)
            ..limit(1))
          .getSingleOrNull();

  /// Expires proposed proposals whose `expires_at` is at or before [now],
  /// except the ids in [except]. Returns how many.
  Future<int> expireDue(DateTime now, {required Set<String> except}) =>
      (update(improvementProposalsTable)..where(
            (t) =>
                t.status.equals('proposed') &
                t.expiresAt.isSmallerOrEqualValue(now) &
                t.id.isNotIn(except),
          ))
          .write(
            const ImprovementProposalsTableCompanion(status: Value('expired')),
          );
}
