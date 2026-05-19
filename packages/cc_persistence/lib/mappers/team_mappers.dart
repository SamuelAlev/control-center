import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:drift/drift.dart' show Value;

/// Converts a [Team] entity to a Drift companion for persistence.
TeamsTableCompanion teamToCompanion(Team t) {
  return TeamsTableCompanion(
    id: Value(t.id),
    workspaceId: Value(t.workspaceId),
    name: Value(t.name),
    description: Value(t.description),
    createdAt: Value(t.createdAt),
  );
}

/// Reconstructs a [Team] from a database row.
Team teamFromRow(TeamsTableData row) {
  return Team(
    id: row.id,
    workspaceId: row.workspaceId,
    name: row.name,
    description: row.description,
    createdAt: row.createdAt,
  );
}

/// Converts a [TeamMember] entity to a Drift companion for persistence.
TeamMembersTableCompanion teamMemberToCompanion(TeamMember m) {
  return TeamMembersTableCompanion(
    teamId: Value(m.teamId),
    agentId: Value(m.agentId),
    role: Value(m.role.toStorageString()),
  );
}

/// Reconstructs a [TeamMember] from a database row.
TeamMember teamMemberFromRow(TeamMembersTableData row) {
  return TeamMember(
    teamId: row.teamId,
    agentId: row.agentId,
    role: TeamMemberRole.fromString(row.role),
  );
}
