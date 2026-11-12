import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:drift/drift.dart';

/// Drift table for single-use workspace invites.
///
/// Only the SHA-256 hash of the invite code is stored; the code itself is
/// shown once at creation. [repoGrantsJson] enumerates exactly which linked
/// repos the invite shares (repo id → grant level wire name) so membership
/// never silently out-privileges the forge. Workspace-scoped.
@TableIndex(
  name: 'uq_workspace_invites_codeHash',
  columns: {#codeHash},
  unique: true,
)
class WorkspaceInvitesTable extends Table {
  /// Unique invite identifier.
  TextColumn get id => text()();

  /// The workspace being shared (isolation boundary).
  TextColumn get workspaceId => text()();

  /// SHA-256 hex hash of the one-time invite code.
  TextColumn get codeHash => text()();

  /// Role granted on redemption: a preset `WorkspaceRole` wire name other
  /// than `owner`, or a custom role's `custom:<id>`.
  TextColumn get role => text()
      .check(
        // ignore: recursive_getters
        role.isIn(PlatformStoredValues.grantableWorkspaceRole) |
            // ignore: recursive_getters
            role.like('${PlatformStoredValues.customRolePrefix}_%'),
      )
      .withDefault(const Constant('member'))();

  /// JSON object mapping repo id → `RepoGrantLevel` wire name.
  TextColumn get repoGrantsJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(repoGrantsJson))
      .withDefault(const Constant('{}'))();

  /// The user who created the invite. No foreign key: users live in the
  /// global database.
  TextColumn get createdBy => text()();

  /// When the invite was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the invite stops being redeemable.
  DateTimeColumn get expiresAt => dateTime()();

  /// When the invite was redeemed, or null while open.
  DateTimeColumn get usedAt => dateTime().nullable()();

  /// The user provisioned/admitted by the redemption. No foreign key: users
  /// live in the global database.
  TextColumn get usedBy => text().nullable()();

  /// When the invite was revoked by an admin, or null.
  DateTimeColumn get revokedAt => dateTime().nullable()();

  @override
  String get tableName => 'workspace_invites';

  @override
  Set<Column> get primaryKey => {id};
}
