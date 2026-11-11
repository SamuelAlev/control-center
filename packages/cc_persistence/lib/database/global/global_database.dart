/// @docImport 'package:cc_persistence/database/workspace/workspace_database.dart';
library;

import 'package:cc_domain/core/domain/value_objects/username.dart';
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
import 'package:cc_persistence/database/migration_steps.dart';
import 'package:cc_persistence/database/tables/environment_slot_leases.dart';
import 'package:cc_persistence/database/tables/fleet_tables.dart';
import 'package:cc_persistence/database/tables/managed_action_policies_table.dart';
import 'package:cc_persistence/database/tables/paired_devices.dart';
import 'package:cc_persistence/database/tables/rss_articles.dart';
import 'package:cc_persistence/database/tables/rss_feeds.dart';
import 'package:cc_persistence/database/tables/server_audit_table.dart';
import 'package:cc_persistence/database/tables/server_meta_table.dart';
import 'package:cc_persistence/database/tables/server_settings_table.dart';
import 'package:cc_persistence/database/tables/sso_connections_table.dart';
import 'package:cc_persistence/database/tables/user_preferences_table.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

part 'global_database.g.dart';

/// Server-global DB (`<dataDir>/global.db`). Workspace content lives in
/// `<dataDir>/<workspaceId>/workspace.db` ([WorkspaceDatabase]).
///
/// Tables here must be server-wide: workspace registry; users / preferences /
/// paired devices; per-user RSS; fleet workers/jobs/placement (payloads carry
/// ids, never workspace content); workspace_routes + server_meta; environment
/// port leases (ports are host-wide; rows carry ids only); the server-scope
/// audit trail (calls no workspace owns). Boot opens only this file.
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
    EnvironmentSlotLeasesTable,
    ServerAuditTable,
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
  int get schemaVersion => 12;

  /// The `server_meta` key holding this install's uuid.
  static const installIdKey = 'install_id';

  /// The `server_meta` key holding the server owner's user id: the operator
  /// recorded when the server first booted, never derived again.
  static const serverOwnerKey = 'server_owner_user_id';

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
    // v2: `users.onboarding_finished_at` — first-run setup lives on the
    // identity itself. Starts null; the gate stamps it on a complete setup.
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
    // v4: the workspace's own GitHub App id. Typed because background polling
    // reads it on the credential path. Private keys stay in secrets.json. (Its
    // companion mode column was replaced by `connect_mode` at v9.)
    MigrationStep(3, 4, (m) async {
      await _addColumnIfMissing(
        m,
        workspacesTable,
        workspacesTable.githubAppId,
      );
    }),
    // v5: indexed public invite routes carry their private code hash only in
    // local storage. A pre-auth Noise hello transmits the route id, never the
    // stored SHA-256(code), because the latter is the handshake PSK.
    MigrationStep(4, 5, (m) => _createSecureInviteRoutes()),
    // v6: review publishing is opt-in. Existing installations must gain the
    // column before identity bootstrap reads their registered workspaces.
    MigrationStep(5, 6, (m) async {
      await _addColumnIfMissing(
        m,
        workspacesTable,
        workspacesTable.autoPublishReview,
      );
    }),
    // v7: host port leases for space environments. Purely additive; a fresh
    // database builds the table in `onCreate`.
    MigrationStep(6, 7, (m) async {
      final existing = await customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name = 'environment_slot_leases'",
      ).get();
      if (existing.isEmpty) {
        await m.createTable(environmentSlotLeasesTable);
      }
    }),
    // v8 rewrote the GitHub-only mode column, which v9 drops.
    MigrationStep(7, 8, (m) async {}),
    // v9: one per-workspace Connect choice replaces the GitHub-only mode.
    // Every workspace starts on the server's choice (`inherit`); the old
    // column is dropped so a migrated file matches a fresh one.
    MigrationStep(8, 9, (m) async {
      await _addColumnIfMissing(
        m,
        workspacesTable,
        workspacesTable.connectMode,
      );
      await _addColumnIfMissing(m, workspacesTable, workspacesTable.connectUrl);
      if (await _hasColumn('workspaces', 'github_auth_mode')) {
        await customStatement(
          'ALTER TABLE workspaces DROP COLUMN github_auth_mode',
        );
      }
    }),
    // v10: every handle is a username by the one rule (`Username`), which
    // `User` now enforces on construction, so a stored handle that breaks it
    // would make its row unreadable. No column changes; the existing unique
    // index stays the backstop.
    MigrationStep(9, 10, (m) => _conformHandles()),
    // v11: the server-scope audit trail. Purely additive; a fresh database
    // builds it in `onCreate`, and an upgraded one starts it empty.
    MigrationStep(10, 11, (m) async {
      if (!await _hasTable('server_audit')) {
        await m.createTable(serverAuditTable);
        await m.createIndex(idxServerAuditCreated);
      }
    }),
    // v12: `users.email_verified`, so an address a person typed about
    // themselves never matches an SSO login or a SCIM push. Every row starts
    // unverified; the next SSO login or SCIM push vouches for it.
    MigrationStep(11, 12, (m) async {
      await _addColumnIfMissing(m, usersTable, usersTable.emailVerified);
    }),
  ];

  /// Rewrites every stored handle to a valid, unique username.
  ///
  /// Two passes, oldest row first. A handle that is a valid username once
  /// lowercased keeps that name unless an older row already has it (names
  /// that differ only in case were the same name all along, so the oldest
  /// row keeps it). Every other row gets the free-text normalisation of its
  /// handle, moved to the next free name ([Username.candidates]) when
  /// claimed. The rows that change move to a placeholder first, all in one
  /// transaction, so no intermediate state can trip the unique index on
  /// `handle` or survive a crash. Each rename is reported through [onWarn].
  Future<void> _conformHandles() async {
    final rows = [
      for (final row in await customSelect(
        'SELECT id, handle FROM users ORDER BY created_at, id',
      ).get())
        (id: row.read<String>('id'), handle: row.read<String>('handle')),
    ];
    final claimed = <String>{};
    final names = <String, String>{};
    for (final row in rows) {
      final lowered = Username.normalizeInput(row.handle);
      if (Username.isValid(lowered) && claimed.add(lowered)) {
        names[row.id] = lowered;
      }
    }
    for (final row in rows) {
      if (names.containsKey(row.id)) {
        continue;
      }
      final name = Username.candidates(
        Username.fromFreeText(row.handle, fallback: 'member'),
      ).firstWhere((c) => !claimed.contains(c.value)).value;
      claimed.add(name);
      names[row.id] = name;
    }
    final renames = <String, ({String from, String to})>{
      for (final row in rows)
        if (names[row.id] != row.handle)
          row.id: (from: row.handle, to: names[row.id]!),
    };
    await transaction(() async {
      for (final id in renames.keys) {
        await customStatement('UPDATE users SET handle = ? WHERE id = ?', [
          'migrating:$id',
          id,
        ]);
      }
      for (final MapEntry(key: id, value: rename) in renames.entries) {
        await customStatement('UPDATE users SET handle = ? WHERE id = ?', [
          rename.to,
          id,
        ]);
      }
    });
    for (final MapEntry(key: id, value: rename) in renames.entries) {
      onWarn?.call(
        'GlobalDatabase',
        'users: handle of $id changed from "${rename.from}" to "${rename.to}" '
            '(not a valid or free username)',
      );
    }
  }

  /// Whether this file has a table named [table].
  Future<bool> _hasTable(String table) async => (await customSelect(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    variables: [Variable.withString(table)],
  ).get()).isNotEmpty;

  /// Whether [table] in this file has a column named [column].
  Future<bool> _hasColumn(String table, String column) async {
    final existing = await customSelect('PRAGMA table_info($table)').get();
    return existing.any((row) => row.read<String>('name') == column);
  }

  /// Adds [column] to [table] unless the file already has it.
  ///
  /// A replay from an older `user_version` (the v1→v2 tests rewind to 1 and
  /// then walk the whole chain) must not throw on a column `onCreate` already
  /// built. A crash mid-step would otherwise leave the file un-openable.
  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    final existing = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    final present = existing.any(
      (row) => row.read<String>('name') == column.name,
    );
    if (!present) {
      await m.addColumn(table, column);
    }
  }

  Future<void> _createSecureInviteRoutes() => customStatement(
    'CREATE TABLE IF NOT EXISTS invite_secure_routes ('
    'route_id TEXT PRIMARY KEY NOT NULL, '
    'code_hash TEXT NOT NULL, '
    'workspace_id TEXT NOT NULL)',
  );

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
      // onCreate does not replay migration steps; the dedicated index must
      // exist on fresh installations as well as upgraded ones.
      await _createSecureInviteRoutes();
      // Wait up to 5s for a lock instead of failing a contended write
      // immediately with SQLITE_BUSY. The fleet scheduler and presence writes
      // run concurrently with live user writes; WAL lets readers proceed, but
      // two writers still contend and without this a scheduler tick can abort a
      // user write outright.
      await customStatement('PRAGMA busy_timeout = 5000');
      // WAL + synchronous=NORMAL. FULL fsyncs every commit, and a burst of
      // small writes (identity, fleet, routing) pays that on the interaction
      // path. NORMAL syncs at checkpoint time: an app crash does not lose
      // committed transactions, a power loss can lose the ones not yet
      // checkpointed. That is the setting SQLite recommends for WAL.
      // temp_store=MEMORY keeps sorts and transient indexes off disk.
      // mmap_size caps how much of the file can be faulted into RAM. Those
      // pages stay resident while the connection is open; 8MB matches the
      // page cache so this file cannot also pin a 64MB window.
      await customStatement('PRAGMA synchronous = NORMAL');
      await customStatement('PRAGMA temp_store = MEMORY');
      await customStatement('PRAGMA mmap_size = 8388608');
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
