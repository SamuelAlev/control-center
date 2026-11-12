import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:drift/drift.dart';

/// Drift table for workspace membership.
///
/// One row per user: the workspace access boundary. [userId] is unique in
/// the file, and writing a membership is one upsert on it. Role is one of
/// `owner` / `admin` / `member` / `viewer` / `guest`, or a custom role.
/// Deleting the workspace removes its file and every membership with it;
/// users live in the global database, so a membership names its user without
/// a foreign key.
@TableIndex(
  name: 'uq_workspace_members_user',
  columns: {#userId},
  unique: true,
)
class WorkspaceMembersTable extends Table {
  /// Unique membership identifier.
  TextColumn get id => text()();

  /// The workspace (isolation boundary).
  TextColumn get workspaceId => text()();

  /// The member. No foreign key: users live in the global database.
  TextColumn get userId => text()();

  /// Membership role: a `WorkspaceRole` wire name, or a custom role's
  /// `custom:<id>`.
  TextColumn get role => text()
      .check(
        // ignore: recursive_getters
        role.isIn(PlatformStoredValues.workspaceRole) |
            // ignore: recursive_getters
            role.like('${PlatformStoredValues.customRolePrefix}_%'),
      )
      .withDefault(const Constant('member'))();

  /// The user who invited this member (null for the bootstrap owner). No
  /// foreign key: users live in the global database.
  TextColumn get invitedBy => text().nullable()();

  /// When the membership was created.
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  /// Display name in this workspace. Null inherits the global user row.
  TextColumn get displayName => text().nullable()();

  /// Email in this workspace. Null inherits the global user row.
  TextColumn get email => text().nullable()();

  /// Git author name in this workspace. Null inherits the global user row.
  TextColumn get gitAuthorName => text().nullable()();

  /// Git author email in this workspace. Null inherits the global user row.
  TextColumn get gitAuthorEmail => text().nullable()();

  @override
  String get tableName => 'workspace_members';

  @override
  Set<Column> get primaryKey => {id};
}
