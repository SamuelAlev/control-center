import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/teams/domain/entities/team.dart';
import 'package:control_center/features/teams/domain/entities/team_member.dart';
import 'package:drift/drift.dart' show Value;

TeamsTableCompanion teamToCompanion(Team t) {
  return TeamsTableCompanion(
    id: Value(t.id),
    workspaceId: Value(t.workspaceId),
    name: Value(t.name),
    description: Value(t.description),
    createdAt: Value(t.createdAt),
  );
}

Team teamFromRow(TeamsTableData row) {
  return Team(
    id: row.id,
    workspaceId: row.workspaceId,
    name: row.name,
    description: row.description,
    createdAt: row.createdAt,
  );
}

TeamMembersTableCompanion teamMemberToCompanion(TeamMember m) {
  return TeamMembersTableCompanion(
    teamId: Value(m.teamId),
    agentId: Value(m.agentId),
    role: Value(m.role.toStorageString()),
  );
}

TeamMember teamMemberFromRow(TeamMembersTableData row) {
  return TeamMember(
    teamId: row.teamId,
    agentId: row.agentId,
    role: TeamMemberRole.fromString(row.role),
  );
}
