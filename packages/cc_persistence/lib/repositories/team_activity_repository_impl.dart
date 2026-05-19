import 'package:cc_domain/features/teams/domain/entities/team_activity.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_activity_repository.dart';
import 'package:cc_persistence/database/daos/team_activity_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/team_activity_mappers.dart';

/// Drift-backed implementation of [TeamActivityRepository].
///
/// The activity log is workspace-scoped: it lives in the workspace's own
/// database file, which the `workspaceId` on each method (or on the
/// [TeamActivity] being recorded) selects.
class TeamActivityRepositoryImpl implements TeamActivityRepository {
  /// Creates a [TeamActivityRepositoryImpl] over the per-workspace databases.
  TeamActivityRepositoryImpl(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  TeamActivityDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).teamActivityDao;

  @override
  Future<void> record(TeamActivity activity) =>
      _dao(activity.workspaceId).record(teamActivityToCompanion(activity));

  @override
  Future<List<TeamActivity>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final rows = await _dao(workspaceId).forTicket(workspaceId, ticketId);
    return rows.map(teamActivityFromRow).toList();
  }

  @override
  Stream<List<TeamActivity>> watchForTeam(String workspaceId, String teamId) {
    return _dao(workspaceId)
        .watchForTeam(workspaceId, teamId)
        .map((rows) => rows.map(teamActivityFromRow).toList());
  }

  @override
  Future<bool> hasNoActionEvaluationForTicket(
    String workspaceId,
    String teamId,
    String ticketId,
  ) => _dao(
    workspaceId,
  ).hasNoActionEvaluationForTicket(workspaceId, teamId, ticketId);
}
