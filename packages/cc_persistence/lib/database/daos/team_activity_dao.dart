import 'package:cc_persistence/database/tables/team_activity_log_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'team_activity_dao.g.dart';

/// Data access for the team-leader activity log.
@DriftAccessor(tables: [TeamActivityLogTable])
class TeamActivityDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$TeamActivityDaoMixin {
  /// Creates a [TeamActivityDao].
  TeamActivityDao(super.db);

  /// Records a leader evaluation.
  Future<void> record(TeamActivityLogTableCompanion activity) =>
      into(teamActivityLogTable).insert(activity);

  /// Evaluations for a ticket, newest first, workspace-scoped.
  Future<List<TeamActivityLogTableData>> forTicket(
    String workspaceId,
    String ticketId,
  ) =>
      (select(teamActivityLogTable)
            ..where(
              (a) =>
                  a.workspaceId.equals(workspaceId) &
                  a.ticketId.equals(ticketId),
            )
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
          .get();

  /// Streams a team's recent evaluations (newest first), workspace-scoped.
  Stream<List<TeamActivityLogTableData>> watchForTeam(
    String workspaceId,
    String teamId,
  ) =>
      (select(teamActivityLogTable)
            ..where(
              (a) =>
                  a.workspaceId.equals(workspaceId) & a.teamId.equals(teamId),
            )
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)]))
          .watch();

  /// Whether a `no_action` evaluation already exists for the ticket — the
  /// guard that stops the leader re-trigger loop.
  Future<bool> hasNoActionEvaluationForTicket(
    String workspaceId,
    String teamId,
    String ticketId,
  ) async {
    final row =
        await (select(teamActivityLogTable)
              ..where(
                (a) =>
                    a.workspaceId.equals(workspaceId) &
                    a.teamId.equals(teamId) &
                    a.ticketId.equals(ticketId) &
                    a.kind.equals('no_action'),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }
}
