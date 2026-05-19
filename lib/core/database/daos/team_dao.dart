import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/teams_table.dart';
import 'package:drift/drift.dart';

part 'team_dao.g.dart';

@DriftAccessor(tables: [TeamsTable, TeamMembersTable])
class TeamDao extends DatabaseAccessor<AppDatabase> with _$TeamDaoMixin {
  TeamDao(super.db);

  // ── Teams ──────────────────────────────────────────────────────

  Future<void> insertTeam(TeamsTableCompanion team) =>
      into(teamsTable).insert(team);

  Future<void> updateTeam(TeamsTableCompanion team) =>
      update(teamsTable).replace(team);

  Future<void> deleteTeam(String id) =>
      (delete(teamsTable)..where((t) => t.id.equals(id))).go();

  Future<TeamsTableData?> getTeam(String id) =>
      (select(teamsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TeamsTableData>> teamsForWorkspace(String workspaceId) =>
      (select(teamsTable)..where((t) => t.workspaceId.equals(workspaceId)))
          .get();

  Stream<List<TeamsTableData>> watchTeamsForWorkspace(String workspaceId) =>
      (select(teamsTable)..where((t) => t.workspaceId.equals(workspaceId)))
          .watch();

  // ── Members ────────────────────────────────────────────────────

  Future<void> addMember(TeamMembersTableCompanion member) =>
      into(teamMembersTable).insert(member,
          mode: InsertMode.insertOrIgnore);

  Future<void> removeMember(String teamId, String agentId) =>
      (delete(teamMembersTable)
            ..where((m) => m.teamId.equals(teamId) & m.agentId.equals(agentId)))
          .go();

  Future<List<TeamMembersTableData>> membersOf(String teamId) =>
      (select(teamMembersTable)..where((m) => m.teamId.equals(teamId))).get();

  Stream<List<TeamMembersTableData>> watchMembersOf(String teamId) =>
      (select(teamMembersTable)..where((m) => m.teamId.equals(teamId))).watch();
}
