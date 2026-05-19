import 'package:cc_domain/features/teams/domain/entities/team_activity.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart' show Value;

/// Converts a [TeamActivity] entity to a Drift companion.
TeamActivityLogTableCompanion teamActivityToCompanion(TeamActivity a) {
  return TeamActivityLogTableCompanion(
    id: Value(a.id),
    workspaceId: Value(a.workspaceId),
    teamId: Value(a.teamId),
    ticketId: Value(a.ticketId),
    kind: Value(a.kind.toStorageString()),
    leaderId: Value(a.leaderId),
    memberId: Value(a.memberId),
    summary: Value(a.summary),
    createdAt: Value(a.createdAt),
  );
}

/// Reconstructs a [TeamActivity] from a database row.
TeamActivity teamActivityFromRow(TeamActivityLogTableData row) {
  return TeamActivity(
    id: row.id,
    workspaceId: row.workspaceId,
    teamId: row.teamId,
    ticketId: row.ticketId,
    kind: TeamActivityKind.fromString(row.kind),
    leaderId: row.leaderId,
    memberId: row.memberId,
    summary: row.summary,
    createdAt: row.createdAt,
  );
}
