import 'package:drift/drift.dart';

/// Custom (workspace-defined) roles — SUBTRACTIVE restrictions of a built-in
/// preset.
///
/// A custom role names a base preset (`admin` / `member` / `viewer` / `guest`
/// — never `owner`) and a set of DENIED permissions removed from it. The
/// resolver grants `can(p)` iff the base preset grants it AND `p` is not in
/// [deniedPermissions] — so no custom role can ever exceed its base preset,
/// which is what keeps every hand-rolled `role.isAdmin` check a sound upper
/// bound during the catalog migration.
///
/// A member holding a custom role stores `custom:<id>` in
/// `workspace_members.role`. `WorkspaceRole.fromWire` returns null for the
/// unknown wire value on old clients and every caller fails safe to guest —
/// that fail-safe is load-bearing for rollout.
@TableIndex(name: 'idx_workspace_roles_workspace', columns: {#workspaceId})
class WorkspaceRolesTable extends Table {
  @override
  String get tableName => 'workspace_roles';

  /// Unique row id (UUID v4). The member wire form is `custom:<id>`.
  TextColumn get id => text()();

  /// The owning workspace.
  TextColumn get workspaceId => text()();

  /// Display name (unique per workspace).
  TextColumn get name => text()();

  /// The built-in preset this role restricts: `admin` / `member` / `viewer` /
  /// `guest`.
  TextColumn get basePreset => text()();

  /// JSON array of denied permission wire names (`domain:tier`).
  TextColumn get deniedPermissions =>
      text().withDefault(const Constant('[]'))();

  /// The user who created the role.
  TextColumn get createdBy => text().nullable()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, name},
  ];
}
