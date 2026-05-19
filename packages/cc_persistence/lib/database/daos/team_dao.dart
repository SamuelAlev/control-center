import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/teams_table.dart';
import 'package:drift/drift.dart';

part 'team_dao.g.dart';

@DriftAccessor(tables: [TeamsTable, TeamMembersTable])
/// Data access for teams and their members.
class TeamDao extends DatabaseAccessor<AppDatabase> with _$TeamDaoMixin {
  /// Creates a [TeamDao].
  TeamDao(super.db);

  // ── Teams ──────────────────────────────────────────────────────

  /// Inserts a new team row.
  Future<void> insertTeam(TeamsTableCompanion team) =>
      into(teamsTable).insert(team);

  /// Replaces a team row.
  Future<void> updateTeam(TeamsTableCompanion team) =>
      update(teamsTable).replace(team);

  /// Deletes a team by id.
  Future<void> deleteTeam(String id) =>
      (delete(teamsTable)..where((t) => t.id.equals(id))).go();

  /// Reads a team by id.
  Future<TeamsTableData?> getTeam(String id) =>
      (select(teamsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Reads all teams in a workspace.
  Future<List<TeamsTableData>> teamsForWorkspace(String workspaceId) =>
      (select(teamsTable)..where((t) => t.workspaceId.equals(workspaceId)))
          .get();

  /// Watches teams in a workspace.
  Stream<List<TeamsTableData>> watchTeamsForWorkspace(String workspaceId) =>
      (select(teamsTable)..where((t) => t.workspaceId.equals(workspaceId)))
          .watch();

  // ── Members ────────────────────────────────────────────────────

  /// Adds an agent to a team, ignoring duplicates.
  Future<void> addMember(TeamMembersTableCompanion member) =>
      into(teamMembersTable).insert(member,
          mode: InsertMode.insertOrIgnore);

  /// Removes an agent from a team.
  Future<void> removeMember(String teamId, String agentId) =>
      (delete(teamMembersTable)
            ..where((m) => m.teamId.equals(teamId) & m.agentId.equals(agentId)))
          .go();

  /// Reads members of a team.
  Future<List<TeamMembersTableData>> membersOf(String teamId) =>
      (select(teamMembersTable)..where((m) => m.teamId.equals(teamId))).get();

  /// Watches members of a team.
  Stream<List<TeamMembersTableData>> watchMembersOf(String teamId) =>
      (select(teamMembersTable)..where((m) => m.teamId.equals(teamId))).watch();
}
