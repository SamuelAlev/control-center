import 'package:drift/drift.dart';

/// Drift table for workspace membership.
///
/// One row per (workspace, user): the workspace access boundary. Role is one
/// of `owner` / `admin` / `member` / `viewer` / `guest`. Every read filters by
/// [workspaceId] or [userId]; deleting a workspace or user cascades its
/// memberships.
@TableIndex(name: 'idx_workspace_members_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_workspace_members_userId', columns: {#userId})
@TableIndex(
  name: 'uq_workspace_members_workspace_user',
  columns: {#workspaceId, #userId},
  unique: true,
)
class WorkspaceMembersTable extends Table {
  /// Unique membership identifier.
  TextColumn get id => text()();

  /// The workspace (isolation boundary).
  TextColumn get workspaceId => text()();

  /// The member.
  TextColumn get userId => text()();

  /// Membership role wire name (`WorkspaceRole`).
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// The user who invited this member (null for the bootstrap owner).
  TextColumn get invitedBy => text().nullable()();

  /// When the membership was created.
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'workspace_members';

  @override
  Set<Column> get primaryKey => {id};
}
