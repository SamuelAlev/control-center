import 'package:cc_persistence/database/daos/fleet_dao.dart';
import 'package:cc_persistence/database/daos/managed_action_policy_dao.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/daos/rss_dao.dart';
import 'package:cc_persistence/database/daos/server_setting_dao.dart';
import 'package:cc_persistence/database/daos/sso_connection_dao.dart';
import 'package:cc_persistence/database/daos/user_dao.dart';
import 'package:cc_persistence/database/daos/user_preference_dao.dart';
import 'package:cc_persistence/database/daos/workspace_registry_dao.dart';
import 'package:cc_persistence/database/daos/workspace_route_dao.dart';
import 'package:cc_persistence/database/migration_steps.dart';
import 'package:cc_persistence/database/tables/fleet_tables.dart';
import 'package:cc_persistence/database/tables/managed_action_policies_table.dart';
import 'package:cc_persistence/database/tables/paired_devices.dart';
import 'package:cc_persistence/database/tables/rss_articles.dart';
import 'package:cc_persistence/database/tables/rss_feeds.dart';
import 'package:cc_persistence/database/tables/server_meta_table.dart';
import 'package:cc_persistence/database/tables/server_settings_table.dart';
import 'package:cc_persistence/database/tables/sso_connections_table.dart';
import 'package:cc_persistence/database/tables/user_preferences_table.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

part 'global_database.g.dart';

/// The server-global database (`<dataDir>/global.db`).
///
/// One of the two halves of Control Center's persistence. This file holds only
/// what is genuinely **server-wide**; every workspace's content lives in its own
/// `workspaces/<id>.db` (see `WorkspaceDatabase`). The split is what makes
/// workspace isolation a *compile-time* property rather than a WHERE-clause
/// convention: this class simply has no agents/spaces/tickets to leak.
///
/// What earns a table a place here:
///
///  * **[WorkspacesTable]** — the registry. The switcher must list every
///    workspace without opening a single workspace file.
///  * **[UsersTable] / [UserPreferencesTable] / [PairedDevicesTable]** —
///    identity is global. One human is one user across every workspace and a
///    paired device survives a workspace being deleted.
///  * **[RssFeedsTable] / [RssArticlesTable]** — the newsfeed is a per-USER
///    pillar (each user curates their own feeds); its RPC ops are
///    `workspaceScoped: false` and scope by the session's user, not a
///    workspace.
///  * **[WorkersTable] / [JobsTable] / [PlacementLogTable]** — the fleet
///    scheduler scans the whole queue on every tick and matches it against
///    every worker. Jobs are ephemeral execution records, so they carry a
///    `workspaceId` as a plain attribute rather than living in the workspace
///    file. The rule that keeps this honest: **a job payload carries ids, never
///    workspace content.**
///  * **[WorkspaceRoutesTable] / [ServerMetaTable]** — the pre-auth "which
///    workspace owns this key?" index and the install identity.
///
/// Boot opens only this file and it stays small, so the `quick_check` on open
/// is cheap no matter how much history the workspaces accumulate.
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
    ServerMetaTable,
    ServerSettingsTable,
    SsoConnectionsTable,
    ManagedActionPoliciesTable,
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
  ],
)
class GlobalDatabase extends _$GlobalDatabase {
  /// Creates the global database over a host-supplied [QueryExecutor].
  ///
  /// The connection is injected so the database stays Flutter-free: the
  /// headless server passes `openGlobalDatabase(dataDir:)`. Diagnostics route
  /// through the optional [onWarn]/[onError] sinks for the same reason.
  GlobalDatabase(super.e, {this.onWarn, this.onError});

  /// Creates an in-memory global database for testing.
  GlobalDatabase.forTesting(super.e) : onWarn = null, onError = null;

  /// Warning sink (e.g. a missing optional extension). Host-injected.
  final void Function(String tag, String message)? onWarn;

  /// Error sink (e.g. a failed integrity check). Host-injected.
  final void Function(String tag, String message)? onError;

  @override
  int get schemaVersion => 3;

  /// The `server_meta` key holding this install's uuid.
  static const installIdKey = 'install_id';

  /// Writes a consistent, defragmented snapshot of this database to [path]
  /// using `VACUUM INTO`. Safe on a live WAL database (it takes a read
  /// transaction and writes a clean copy), so it can be called while the server
  /// is running. The caller owns the destination and rotation.
  Future<void> backupTo(String path) =>
      customStatement('VACUUM INTO ?', [path]);

  /// Schema evolution for the global half.
  ///
  /// Version 1 IS the baseline: `onCreate` builds everything current, so a
  /// fresh file never replays this chain. Append a [MigrationStep] here (and
  /// bump [schemaVersion]) for every schema change from now on.
  List<MigrationStep> get _migrationSteps => <MigrationStep>[
    // v2: `users.onboarding_finished_at` — first-run setup moved off the
    // device-local/synced-preference lane onto the identity itself.
    //
    // Deliberately NOT backfilled from the old `user_preferences` row. That
    // row is exactly what could not be trusted: the preference promotion pass
    // seeds the server from a device's local store, so an account could carry
    // `onboarding_finished = true` purely because some machine it was first
    // opened on had onboarded a *different* install. Starting at null costs a
    // real returning operator nothing — the gate re-stamps the flag the moment
    // it observes a complete setup — while anyone wrongly marked gets the
    // first-run flow they were owed.
    //
    // The stale `user_preferences` row is left in place: nothing reads that
    // key any more, and deleting a user's rows in a schema migration is a
    // heavier promise than this change needs to make.
    MigrationStep(1, 2, (m) async {
      await m.addColumn(usersTable, usersTable.onboardingFinishedAt);
    }),
    // v3: the managed (install-wide) action-policy tier — the operator's
    // clamp over every workspace, merged most-restrictive into guardrail
    // resolution. CROSS-WORKSPACE BY DESIGN (see the table doc); purely
    // additive, a fresh database builds it in `onCreate`.
    MigrationStep(2, 3, (m) async {
      await m.createTable(managedActionPoliciesTable);
    }),
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      for (final step in _migrationSteps) {
        if (from < step.to) {
          await step.migrate(m);
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      // Partial unique index over the SSO subject pin — one account per
      // (issuer, subject). A @TableIndex cannot express the WHERE clause,
      // and onCreate (createAll) does not run migration steps, so this is
      // (re)declared here idempotently for both fresh and migrated files.
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_users_sso_subject '
        'ON users(sso_issuer, sso_subject) '
        'WHERE sso_issuer IS NOT NULL AND sso_subject IS NOT NULL',
      );
      // Wait up to 5s for a lock instead of failing a contended write
      // immediately with SQLITE_BUSY. The fleet scheduler and presence writes
      // run concurrently with live user writes; WAL lets readers proceed, but
      // two writers still contend and without this a scheduler tick can abort a
      // user write outright.
      await customStatement('PRAGMA busy_timeout = 5000');
      // Cap the per-connection page cache at 8MB (negative = KiB units).
      await customStatement('PRAGMA cache_size = -8192');
      // Bound the WAL file so a long-running server doesn't accumulate an
      // unbounded -wal that gets mmapped/paged in on every checkpoint.
      await customStatement('PRAGMA journal_size_limit = 67108864');
      // Corruption check on open — `quick_check`, NOT `integrity_check` (which
      // walks every b-tree page and gated boot for tens of seconds on a large
      // file). This database is deliberately small, so the check is cheap; the
      // per-workspace files pay their own check lazily on first touch.
      final startedAt = DateTime.now();
      final result = await customSelect('PRAGMA quick_check').get();
      final status = result.first.read<String>('quick_check');
      if (status != 'ok') {
        onError?.call('GlobalDatabase', 'SQLite quick_check failed: $status');
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
