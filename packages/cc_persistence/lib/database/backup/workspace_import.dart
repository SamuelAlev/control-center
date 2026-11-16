import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/database/daos/imported_authority_hold_dao.dart';
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:uuid/uuid.dart';

/// A pre-auth key a workspace file's rows claim in `workspace_routes`.
typedef WorkspaceRoute = ({WorkspaceRouteKind kind, String key});

/// What validating a staged workspace file found.
final class StagedWorkspace {
  /// Creates the result.
  const StagedWorkspace({
    required this.recordedWorkspaceId,
    required this.sourceInstallId,
    required this.routes,
    required this.heldCount,
  });

  /// The workspace id the file named before it was re-keyed.
  final String recordedWorkspaceId;

  /// The install the file names.
  final String sourceInstallId;

  /// The pre-auth keys its rows claim, computed with this server's keys.
  final List<WorkspaceRoute> routes;

  /// How many grants were moved into holds.
  final int heldCount;
}

/// Validates the copy of an imported workspace file at [stagedPath], in
/// place, and leaves it ready to be renamed over a live file.
///
/// The file is data, not authority, whoever made it: an export edited by an
/// admin and this server's own snapshot are treated alike. In order:
///
/// 1. a plain connection with `trusted_schema` and foreign keys off reads it;
/// 2. `quick_check` must pass;
/// 3. its `application_id` and `user_version` must name a workspace file
///    this build can read, and it must name its workspace;
/// 4. its rows are re-keyed to [workspaceId] if it named another;
/// 5. it is converged to the declared schema and must then match it: no
///    trigger, view, table, column, constraint or index it brought survives;
/// 6. its foreign keys must hold;
/// 7. grants it may not give itself are taken away: host approvals are
///    cleared, and allowing policies, elevated roles, repository grants
///    above read and invites to them are moved to `imported_authority_holds`
///    for the server owner; [importedBy] keeps or gets the owner role;
/// 8. its search indexes are rebuilt and its log folded into the file.
///
/// Throws [WorkspaceImportRefusedException] on any failure. The caller owns
/// the staged file and removes it on failure.
Future<StagedWorkspace> prepareStagedWorkspace({
  required String stagedPath,
  required String workspaceId,
  required String importedBy,
  required WebhookSecretVault webhookSecrets,
  required DateTime now,
}) async {
  // Unopened: only its declarations are read here.
  final declared = WorkspaceDatabase(
    NativeDatabase.memory(),
    workspaceId: workspaceId,
  );
  final ({String workspaceId, String installId}) meta;
  try {
    meta = _checkRawFile(
      stagedPath,
      lastUnidentifiedVersion: declared.lastUnidentifiedVersion,
      identityTable: declared.identityTable,
    );
  } finally {
    await declared.close();
  }
  if (meta.workspaceId != workspaceId) {
    _rekey(stagedPath, meta.workspaceId, workspaceId);
  }

  var db = _open(stagedPath, workspaceId);
  var closed = false;
  try {
    try {
      await db.customSelect('SELECT 1').get();
      // Unconditionally: a file already at the current version is exactly
      // the one that would otherwise keep whatever someone added to it.
      await db.convergeSchema();
      // Converging drops every trigger, the server's own FTS triggers with
      // them; they are installed again by the next open.
      final converged = db;
      db = _open(stagedPath, workspaceId);
      await converged.close();
      final differences = await db.schemaDifferences();
      if (differences.isNotEmpty) {
        throw const WorkspaceImportRefusedException(
          WorkspaceImportRefusal.schemaMismatch,
          'The file does not match the workspace schema',
        );
      }
      final orphans = await db.customSelect('PRAGMA foreign_key_check').get();
      if (orphans.isNotEmpty) {
        throw const WorkspaceImportRefusedException(
          WorkspaceImportRefusal.schemaMismatch,
          'The file holds rows whose references point nowhere',
        );
      }
    } on WorkspaceImportRefusedException {
      rethrow;
    } on Object catch (error) {
      throw _refusalOf(error);
    }
    final held = await _stripAuthority(
      db,
      workspaceId: workspaceId,
      importedBy: importedBy,
      sourceInstallId: meta.installId,
      now: now,
    );
    final routes = await routesOf(db, webhookSecrets);
    await db.rebuildFtsIndexes();
    await db.checkpoint();
    await db.close();
    closed = true;
    _foldLogIntoFile(stagedPath);
    return StagedWorkspace(
      recordedWorkspaceId: meta.workspaceId,
      sourceInstallId: meta.installId,
      routes: routes,
      heldCount: held,
    );
  } finally {
    if (!closed) {
      await db.close();
    }
  }
}

/// The pre-auth keys the rows of [db] claim.
///
/// A webhook route is the HMAC of the trigger's token under this server's
/// route key, so it is computed here from the token the reference names. A
/// reference whose secret this server does not hold (a file from another
/// install) routes nothing: that trigger reads as having no token until its
/// next save mints one.
Future<List<WorkspaceRoute>> routesOf(
  WorkspaceDatabase db,
  WebhookSecretVault webhookSecrets,
) async {
  final routes = <WorkspaceRoute>[];
  Future<void> add(WorkspaceRouteKind kind, String sql) async {
    for (final row in await db.customSelect(sql).get()) {
      routes.add((kind: kind, key: row.data.values.first! as String));
    }
  }

  await add(
    WorkspaceRouteKind.inviteCode,
    'SELECT code_hash FROM workspace_invites '
    'WHERE used_at IS NULL AND revoked_at IS NULL',
  );
  final refs = await db
      .customSelect(
        'SELECT webhook_token_ref FROM pipeline_triggers '
        "WHERE webhook_token_ref IS NOT NULL AND webhook_token_ref <> ''",
      )
      .get();
  for (final row in refs) {
    final token = await webhookSecrets.read(
      row.read<String>('webhook_token_ref'),
    );
    if (token == null || token.isEmpty) {
      continue;
    }
    routes.add((
      kind: WorkspaceRouteKind.webhookToken,
      key: await webhookSecrets.webhookRouteKey(token),
    ));
  }
  await add(WorkspaceRouteKind.pipelineRun, 'SELECT id FROM pipeline_runs');
  await add(WorkspaceRouteKind.space, 'SELECT id FROM spaces');
  await add(
    WorkspaceRouteKind.ticketExternalKey,
    "SELECT provider || ':' || external_key FROM tickets "
    'WHERE external_key IS NOT NULL',
  );
  await add(WorkspaceRouteKind.isolatedRepo, 'SELECT id FROM isolated_repos');
  return routes;
}

/// The live table an accepted hold of [kind] is written back to.
String holdTable(ImportHoldKind kind) => switch (kind) {
  ImportHoldKind.actionPolicy => 'action_policies',
  ImportHoldKind.sandboxExecGrant => 'sandbox_exec_grants',
  ImportHoldKind.repoGrant => 'workspace_member_repo_grants',
  ImportHoldKind.membershipRole => 'workspace_members',
  ImportHoldKind.invite => 'workspace_invites',
};

/// Whether a stored role wire grants more than a plain member: `owner`,
/// `admin`, or a custom role built on either ([customPresets] maps a custom
/// role id to its base preset).
bool isElevatedRole(String? role, Map<String, String> customPresets) {
  final custom = role != null && role.startsWith('custom:')
      ? customPresets[role.substring(7)]
      : role;
  final preset = WorkspaceRole.fromWire(custom);
  return preset != null && preset.isAdmin;
}

/// Opens the staged file as a workspace database that trusts nothing in it.
WorkspaceDatabase _open(String path, String workspaceId) => WorkspaceDatabase(
  NativeDatabase(File(path), setup: _distrustSchema),
  workspaceId: workspaceId,
  // `quick_check` already passed on this file, on a plain connection.
  skipIntegrityCheck: true,
);

/// Runs before drift touches the file: functions its schema calls (in a
/// CHECK, a generated column, an index, a trigger) must be innocuous.
void _distrustSchema(sqlite.Database db) =>
    db.execute('PRAGMA trusted_schema = OFF');

/// Steps 1 to 3, on a plain connection. Returns what `workspace_meta` says.
({String workspaceId, String installId}) _checkRawFile(
  String path, {
  required int lastUnidentifiedVersion,
  required String identityTable,
}) {
  sqlite.Database? raw;
  try {
    raw = sqlite.sqlite3.open(path);
    raw
      ..execute('PRAGMA trusted_schema = OFF')
      ..execute('PRAGMA foreign_keys = OFF');
    final check = raw.select('PRAGMA quick_check');
    if (check.isEmpty || check.first.values.first != 'ok') {
      throw const WorkspaceImportRefusedException(
        WorkspaceImportRefusal.damaged,
        'The file is damaged',
      );
    }
    int pragma(String name) =>
        raw!.select('PRAGMA $name').single.values.single! as int;
    final version = pragma('user_version');
    final applicationId = pragma('application_id');
    if (version > WorkspaceDatabase.currentSchemaVersion) {
      throw WorkspaceImportRefusedException(
        WorkspaceImportRefusal.newerSchema,
        'A newer server version wrote this file',
        fileVersion: version,
        serverVersion: WorkspaceDatabase.currentSchemaVersion,
      );
    }
    final hasIdentityTable = raw.select(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      [identityTable],
    ).isNotEmpty;
    final identified =
        applicationId == WorkspaceDatabase.fileApplicationId ||
        (applicationId == 0 &&
            version >= 1 &&
            version <= lastUnidentifiedVersion);
    if (!identified || !hasIdentityTable || version < 1) {
      throw const WorkspaceImportRefusedException(
        WorkspaceImportRefusal.foreignFile,
        'The file is not a workspace database',
      );
    }
    final rows = raw.select(
      'SELECT workspace_id, install_id FROM workspace_meta LIMIT 1',
    );
    if (rows.isEmpty || rows.first['workspace_id'] is! String) {
      throw const WorkspaceImportRefusedException(
        WorkspaceImportRefusal.foreignFile,
        'The file does not name its workspace',
      );
    }
    final installId = rows.first['install_id'];
    return (
      workspaceId: rows.first['workspace_id'] as String,
      installId: installId is String ? installId : 'unknown',
    );
  } on WorkspaceImportRefusedException {
    rethrow;
  } on sqlite.SqliteException {
    // Not a database at all, or damage bad enough to stop the check itself.
    throw const WorkspaceImportRefusedException(
      WorkspaceImportRefusal.damaged,
      'The file is damaged or is not a database',
    );
  } finally {
    raw?.close();
  }
}

/// Step 4: rewrites every `workspace_id` in the file from [oldId] to
/// [newId], in one transaction.
///
/// Generic over every ordinary table that has the column, so a table added
/// later is covered without being named. Webhook secret references keep the
/// workspace id they were minted under: the secret is stored under that
/// reference, so rewriting it would point the row at nothing.
void _rekey(String path, String oldId, String newId) {
  final db = sqlite.sqlite3.open(path);
  try {
    db
      ..execute('PRAGMA trusted_schema = OFF')
      ..execute('PRAGMA foreign_keys = OFF')
      ..execute('BEGIN IMMEDIATE');
    try {
      for (final row in db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' "
        "AND sql NOT LIKE 'CREATE VIRTUAL TABLE%'",
      )) {
        final name = (row['name'] as String).replaceAll('"', '""');
        if (db
            .select('PRAGMA table_info("$name")')
            .any((column) => column['name'] == 'workspace_id')) {
          db.execute(
            'UPDATE "$name" SET workspace_id = ? WHERE workspace_id = ?',
            [newId, oldId],
          );
        }
      }
      db.execute('COMMIT');
    } on Object {
      db.execute('ROLLBACK');
      rethrow;
    }
  } on sqlite.SqliteException {
    throw const WorkspaceImportRefusedException(
      WorkspaceImportRefusal.schemaMismatch,
      'The file could not be assigned to this workspace',
    );
  } finally {
    db.close();
  }
}

/// Maps a failure while opening or converging the staged file.
WorkspaceImportRefusedException _refusalOf(Object error) {
  if (error is DatabaseNewerThanBinaryException) {
    return WorkspaceImportRefusedException(
      WorkspaceImportRefusal.newerSchema,
      'A newer server version wrote this file',
      fileVersion: error.fileVersion,
      serverVersion: error.binaryVersion,
    );
  }
  if (error is ForeignDatabaseFileException) {
    return const WorkspaceImportRefusedException(
      WorkspaceImportRefusal.foreignFile,
      'The file is not a workspace database',
    );
  }
  if (storageFailureOf(error) == StorageFailure.damaged) {
    return const WorkspaceImportRefusedException(
      WorkspaceImportRefusal.damaged,
      'The file is damaged',
    );
  }
  return const WorkspaceImportRefusedException(
    WorkspaceImportRefusal.schemaMismatch,
    'The file could not be brought to the workspace schema',
  );
}

/// Step 7. Returns how many rows were held.
Future<int> _stripAuthority(
  WorkspaceDatabase db, {
  required String workspaceId,
  required String importedBy,
  required String sourceInstallId,
  required DateTime now,
}) async {
  final holds = ImportedAuthorityHoldDao(db);
  const uuid = Uuid();
  var held = 0;
  Future<void> hold(ImportHoldKind kind, Map<String, Object?> row) async {
    await holds.insert(
      ImportedAuthorityHoldsTableCompanion.insert(
        id: uuid.v4(),
        kind: kind.wire,
        payloadJson: jsonEncode(row),
        importedAt: now,
        sourceInstallId: sourceInstallId,
      ),
    );
    held++;
  }

  Future<List<Map<String, Object?>>> rows(String sql) async => [
    for (final row in await db.customSelect(sql).get()) row.data,
  ];

  await db.transaction(() async {
    // Host execution runs as the server's OS user; only the current owner's
    // own recorded approval admits it.
    await db.customStatement(
      'UPDATE environment_definitions SET host_approved_by = NULL '
      'WHERE host_approved_by IS NOT NULL',
    );
    await db.customStatement(
      'UPDATE mcp_servers SET host_approved_by = NULL '
      'WHERE host_approved_by IS NOT NULL',
    );
    // A deny only ever narrows what runs, so it stays. Everything else is
    // a rule somebody could have added to let something through.
    for (final row in await rows(
      "SELECT * FROM action_policies WHERE decision <> 'deny'",
    )) {
      await hold(ImportHoldKind.actionPolicy, row);
      await db.customStatement('DELETE FROM action_policies WHERE id = ?', [
        row['id'],
      ]);
    }
    for (final row in await rows(
      "SELECT * FROM sandbox_exec_grants WHERE decision <> 'deny'",
    )) {
      await hold(ImportHoldKind.sandboxExecGrant, row);
      await db.customStatement('DELETE FROM sandbox_exec_grants WHERE id = ?', [
        row['id'],
      ]);
    }
    for (final row in await rows(
      'SELECT * FROM workspace_member_repo_grants',
    )) {
      final level = RepoGrantLevel.fromWire(row['level'] as String?);
      if (level != null && !level.atLeast(RepoGrantLevel.review)) {
        continue;
      }
      await hold(ImportHoldKind.repoGrant, row);
      await db.customStatement(
        'UPDATE workspace_member_repo_grants SET level = ? WHERE id = ?',
        [RepoGrantLevel.read.wireName, row['id']],
      );
    }

    final customPresets = {
      for (final row in await rows(
        'SELECT id, base_preset FROM workspace_roles',
      ))
        row['id']! as String: row['base_preset']! as String,
    };
    for (final row in await rows('SELECT * FROM workspace_members')) {
      if (row['user_id'] == importedBy ||
          !isElevatedRole(row['role'] as String?, customPresets)) {
        continue;
      }
      await hold(ImportHoldKind.membershipRole, row);
      await db.customStatement(
        'UPDATE workspace_members SET role = ? WHERE id = ?',
        [WorkspaceRole.member.wireName, row['id']],
      );
    }
    final updated = await db.customUpdate(
      'UPDATE workspace_members SET role = ? WHERE user_id = ?',
      variables: [
        Variable.withString(WorkspaceRole.owner.wireName),
        Variable.withString(importedBy),
      ],
    );
    if (updated == 0) {
      await db.customStatement(
        'INSERT INTO workspace_members (id, workspace_id, user_id, role) '
        'VALUES (?, ?, ?, ?)',
        [uuid.v4(), workspaceId, importedBy, WorkspaceRole.owner.wireName],
      );
    }

    for (final row in await rows(
      'SELECT * FROM workspace_invites '
      'WHERE used_at IS NULL AND revoked_at IS NULL',
    )) {
      if (!isElevatedRole(row['role'] as String?, customPresets) &&
          !_grantsAboveRead(row['repo_grants_json'])) {
        continue;
      }
      await hold(ImportHoldKind.invite, row);
      await db.customStatement('DELETE FROM workspace_invites WHERE id = ?', [
        row['id'],
      ]);
    }
  });
  return held;
}

/// Whether an invite's repository grants give anything above read. A value
/// that does not parse is treated as if it did: it is held, not trusted.
bool _grantsAboveRead(Object? json) {
  if (json is! String || json.isEmpty) {
    return false;
  }
  try {
    final grants = jsonDecode(json);
    if (grants is! Map) {
      return true;
    }
    return grants.values.any((level) {
      final parsed = RepoGrantLevel.fromWire(level is String ? level : null);
      return parsed == null || parsed.atLeast(RepoGrantLevel.review);
    });
  } on FormatException {
    return true;
  }
}

/// Step 8's last half: the staged file is renamed alone, so whatever its
/// write-ahead log holds is folded into it and the log removed.
void _foldLogIntoFile(String path) {
  final db = sqlite.sqlite3.open(path);
  try {
    db
      ..execute('PRAGMA wal_checkpoint(TRUNCATE)')
      ..execute('PRAGMA journal_mode = DELETE');
  } finally {
    db.close();
  }
  for (final suffix in const ['-wal', '-shm']) {
    final sidecar = File('$path$suffix');
    if (sidecar.existsSync()) {
      sidecar.deleteSync();
    }
  }
}
