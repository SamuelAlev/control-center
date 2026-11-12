/// @docImport 'package:cc_persistence/database/workspace/workspace_database.dart';
library;

import 'package:cc_persistence/database/daos/environment_lease_dao.dart';
import 'package:cc_persistence/database/daos/fleet_dao.dart';
import 'package:cc_persistence/database/daos/managed_action_policy_dao.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/daos/rss_dao.dart';
import 'package:cc_persistence/database/daos/server_audit_dao.dart';
import 'package:cc_persistence/database/daos/server_setting_dao.dart';
import 'package:cc_persistence/database/daos/sso_connection_dao.dart';
import 'package:cc_persistence/database/daos/user_dao.dart';
import 'package:cc_persistence/database/daos/user_preference_dao.dart';
import 'package:cc_persistence/database/daos/workspace_registry_dao.dart';
import 'package:cc_persistence/database/daos/workspace_route_dao.dart';
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/schema/schema_converge.dart';
import 'package:cc_persistence/database/tables/agent_pull_request_requesters_table.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/environment_slot_leases.dart';
import 'package:cc_persistence/database/tables/fleet_tables.dart';
import 'package:cc_persistence/database/tables/invite_secure_routes_table.dart';
import 'package:cc_persistence/database/tables/managed_action_policies_table.dart';
import 'package:cc_persistence/database/tables/paired_devices.dart';
import 'package:cc_persistence/database/tables/rss_articles.dart';
import 'package:cc_persistence/database/tables/rss_feeds.dart';
import 'package:cc_persistence/database/tables/server_audit_table.dart';
import 'package:cc_persistence/database/tables/server_meta_table.dart';
import 'package:cc_persistence/database/tables/server_notices_table.dart';
import 'package:cc_persistence/database/tables/server_settings_table.dart';
import 'package:cc_persistence/database/tables/sso_connections_table.dart';
import 'package:cc_persistence/database/tables/user_preferences_table.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:cc_persistence/src/server_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'global_database.g.dart';

/// Server-global DB (`<dataDir>/global.db`). Workspace content lives in
/// `<dataDir>/<workspaceId>/workspace.db` ([WorkspaceDatabase]).
///
/// Tables here must be server-wide: workspace registry; users / preferences /
/// paired devices; per-user RSS; fleet workers/jobs/placement (payloads carry
/// ids, never workspace content); workspace_routes + server_meta; environment
/// port leases (ports are host-wide; rows carry ids only); the server-scope
/// audit trail (calls no workspace owns). Boot opens only this file.
///
/// There is no migration ladder: an existing file is converged to the
/// declared schema when its version differs (see [ConvergedDatabase]).
@DriftDatabase(
  tables: [
    WorkspacesTable,
    UsersTable,
    UserPreferencesTable,
    PairedDevicesTable,
    RssFeedsTable,
    RssArticlesTable,
    WorkersTable,
    JobsTable,
    PlacementLogTable,
    WorkspaceRoutesTable,
    InviteSecureRoutesTable,
    ServerMetaTable,
    ServerSettingsTable,
    SsoConnectionsTable,
    ManagedActionPoliciesTable,
    EnvironmentSlotLeasesTable,
    ServerAuditTable,
    ServerNoticesTable,
    AgentPullRequestRequestersTable,
  ],
  daos: [
    WorkspaceRegistryDao,
    UserDao,
    UserPreferenceDao,
    PairedDeviceDao,
    RssDao,
    FleetDao,
    WorkspaceRouteDao,
    ServerSettingDao,
    SsoConnectionDao,
    ManagedActionPolicyDao,
    EnvironmentLeaseDao,
    ServerAuditDao,
  ],
)
class GlobalDatabase extends _$GlobalDatabase with ConvergedDatabase {
  /// Creates the global database over a host-supplied [QueryExecutor].
  ///
  /// The connection is injected so the database stays Flutter-free: the
  /// headless server passes `openGlobalDatabase(dataDir:)`. Diagnostics route
  /// through the optional [onWarn]/[onError] sinks for the same reason.
  GlobalDatabase(
    super.e, {
    this.onWarn,
    this.onError,
    this.upgradeSnapshotDirectory,
  });

  /// Opens the global database of the install at [dataDir]
  /// (`<dataDir>/global.db`), copying the file aside before any schema
  /// upgrade. Every process that opens an install's data goes through this,
  /// so whichever one meets an older file first upgrades it the same way.
  GlobalDatabase.atDataDir(
    String dataDir, {
    void Function(String tag, String message)? onWarn,
    void Function(String tag, String message)? onError,
  }) : this(
         openGlobalDatabase(dataDir: dataDir),
         onWarn: onWarn,
         onError: onError,
         upgradeSnapshotDirectory: globalUpgradeSnapshotDir(dataDir),
       );

  /// Creates an in-memory global database for testing.
  GlobalDatabase.forTesting(super.e)
    : onWarn = null,
      onError = null,
      upgradeSnapshotDirectory = null;

  /// Warning sink (schema convergence, a slow integrity check). Host-injected.
  @override
  final void Function(String tag, String message)? onWarn;

  /// Error sink (e.g. a failed integrity check). Host-injected.
  final void Function(String tag, String message)? onError;

  @override
  final String? upgradeSnapshotDirectory;

  /// The current global schema version.
  ///
  /// Bump it whenever the declared schema changes (a table class, an index,
  /// a constraint): the version differing is what makes an existing file
  /// converge on its next open. There are no migration steps to write.
  static const int currentSchemaVersion = 14;

  /// `PRAGMA application_id` of the global database: "CCGL".
  static const int fileApplicationId = 0x4343474C;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  int get applicationId => fileApplicationId;

  @override
  int get lastUnidentifiedVersion => 12;

  @override
  String get identityTable => 'server_meta';

  /// Nothing in this file is vector-indexed.
  @override
  bool get usesExtensionTables => false;

  @override
  String get databaseLabel => 'global';

  /// The `server_meta` key holding this install's uuid.
  static const installIdKey = 'install_id';

  /// The `server_meta` key holding the server owner's user id: the operator
  /// recorded when the server first booted, never derived again.
  static const serverOwnerKey = 'server_owner_user_id';

  static Future<SchemaSnapshot>? _declaredSchema;

  /// The schema a fresh global file holds, read once per process from an
  /// in-memory instance.
  static Future<SchemaSnapshot> declaredSchema() =>
      _declaredSchema ??= _readDeclaredSchema();

  static Future<SchemaSnapshot> _readDeclaredSchema() async {
    final db = GlobalDatabase(NativeDatabase.memory());
    try {
      return await SchemaSnapshot.read(db);
    } on Object {
      _declaredSchema = null;
      rethrow;
    } finally {
      await db.close();
    }
  }

  @override
  Future<SchemaSnapshot> loadDeclaredSchema() => declaredSchema();

  /// Writes a consistent, defragmented snapshot of this database to [path]
  /// using `VACUUM INTO`, on this database's own connection. Safe on a live
  /// WAL database. For a file on disk prefer `snapshotDatabaseFile`, which
  /// copies on a connection of its own. The caller owns the destination and
  /// rotation.
  Future<void> backupTo(String path) =>
      customStatement('VACUUM INTO ?', [path]);

  /// One account per `(issuer, subject)` SSO pin. Partial, so a table class
  /// cannot declare it.
  Future<void> _createSsoSubjectIndex() => customStatement(
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_sso_subject '
    'ON users(sso_issuer, sso_subject) '
    'WHERE sso_issuer IS NOT NULL AND sso_subject IS NOT NULL',
  );

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => createFresh(() async {
      await m.createAll();
      await _createSsoSubjectIndex();
    }),
    onUpgrade: (Migrator m, int from, int to) => upgradeByConverging(from, to),
    beforeOpen: (details) async {
      await applyConnectionPragmas();
      await verifyIdentity();
      await optimize(onOpen: true);
      // Corruption check on open — `quick_check`, NOT `integrity_check` (which
      // walks every b-tree page and gated boot for tens of seconds on a large
      // file). This database is deliberately small, so the check is cheap; the
      // per-workspace files pay their own check lazily on first touch.
      final startedAt = DateTime.now();
      final result = await customSelect('PRAGMA quick_check').get();
      final status = result.first.read<String>('quick_check');
      if (status != 'ok') {
        onError?.call('GlobalDatabase', 'SQLite quick_check failed: $status');
        // Every workspace hangs off this file (the registry, the accounts,
        // the routes), so there is no partial service to offer from a
        // damaged one: the open fails and the operator restores a snapshot.
        throw DatabaseDamagedException(
          database: databaseLabel,
          finding: status,
        );
      }
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed > const Duration(seconds: 2)) {
        onWarn?.call(
          'GlobalDatabase',
          'quick_check took ${elapsed.inMilliseconds}ms — global.db should be '
              'small; this suggests the fleet job/placement tables need pruning',
        );
      }
    },
  );
}
