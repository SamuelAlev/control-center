@TestOn('!windows')
library;

import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/backup/snapshot_manifest.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

/// Restoring a workspace: the incoming file is staged beside the live one and
/// checked, stripped and converged there, so a refusal changes nothing; the
/// file it replaces is kept as a backup; and what it claims about who may do
/// what waits for the server owner.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late GlobalDatabase global;
  late WorkspaceDatabaseManager workspaces;
  late WebhookSecretVault vault;
  late DomainEventBus bus;
  late List<DomainEvent> events;
  var now = DateTime.utc(2026, 11, 1, 9);

  WorkspaceDatabaseManager manager() => WorkspaceDatabaseManager(
    dataDir: tmp.path,
    global: global,
    executorFactory: (id) =>
        NativeDatabase(File(workspaceDatabasePath(tmp.path, id))),
  );

  AppDatabaseBackupService service() => AppDatabaseBackupService(
    global: global,
    workspaces: workspaces,
    backupsDir: '${tmp.path}/backups',
    webhookSecrets: vault,
    eventBus: bus,
    now: () => now,
  );

  Matcher refusedAs(WorkspaceImportRefusal refusal) => throwsA(
    isA<WorkspaceImportRefusedException>().having(
      (e) => e.refusal,
      'refusal',
      refusal,
    ),
  );

  Future<void> sql(String id, String statement, [List<Object?>? args]) =>
      workspaces.of(id).customStatement(statement, args);

  Future<List<Map<String, Object?>>> select(String id, String query) async => [
    for (final row in await workspaces.of(id).customSelect(query).get())
      row.data,
  ];

  Future<void> seed(String id) async {
    await global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: id, name: 'WS $id'),
    );
    final db = await workspaces.create(id);
    await db.agentDao.upsert(
      AgentsTableCompanion.insert(
        id: 'a-$id',
        name: 'Ada',
        title: 't',
        agentMdPath: '/a.md',
        workspaceId: id,
        skills: '',
      ),
    );
  }

  /// Files the workspace keeps beside its database, which a restore must
  /// leave alone, and a code index, which it must drop.
  void addSiblings(String id) {
    final dir = workspaces.dirFor(id);
    File('$dir/attachments/photo.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3, 4]);
    File('$dir/notes.txt').writeAsStringSync('keep me');
    File('$dir/code_index.db').writeAsBytesSync([9, 9, 9]);
    File('$dir/code_index.db-wal').writeAsBytesSync([8]);
  }

  /// Every file under [id]'s directory, by relative path.
  Map<String, List<int>> filesOf(String id) {
    final dir = workspaces.dirFor(id);
    return {
      for (final entity in Directory(
        dir,
      ).listSync(recursive: true, followLinks: false))
        if (entity is File)
          entity.path.substring(dir.length + 1): entity.readAsBytesSync(),
    };
  }

  /// Edits [path] the way a file from elsewhere could be, with no server
  /// connection involved.
  void rawEdit(String path, void Function(sqlite.Database db) edit) {
    final db = sqlite.sqlite3.open(path);
    try {
      edit(db);
    } finally {
      db.close();
    }
  }

  setUp(() async {
    now = DateTime.utc(2026, 11, 1, 9);
    tmp = Directory.systemTemp.createTempSync('db_restore');
    global = GlobalDatabase(NativeDatabase(File('${tmp.path}/global.db')));
    workspaces = manager();
    await workspaces.loadInstallId();
    vault = WebhookSecretVault(InMemorySecretStore());
    bus = DomainEventBus();
    events = [];
    bus.on<DomainEvent>().listen(events.add);
  });

  tearDown(() async {
    bus.dispose();
    await workspaces.closeAll();
    await global.close();
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  group('a refused import', () {
    late String target;

    setUp(() async {
      target = 'ws1';
      await seed(target);
      addSiblings(target);
    });

    /// Imports [source] into the target and expects [refusal], with the
    /// target's directory exactly as it was and nothing staged or kept.
    Future<void> expectUntouched(
      String source,
      WorkspaceImportRefusal refusal,
    ) async {
      await workspaces.close(target);
      final before = filesOf(target);
      final routesBefore = await global
          .customSelect('SELECT * FROM workspace_routes ORDER BY key_hash')
          .get();

      await expectLater(
        service().importWorkspace(
          workspaceId: target,
          sourcePath: source,
          importedBy: 'owner',
        ),
        refusedAs(refusal),
      );

      expect(filesOf(target), equals(before), reason: refusal.kind);
      expect(
        File(
          '${workspaces.pathFor(target)}'
          '${AppDatabaseBackupService.importingSuffix}',
        ).existsSync(),
        isFalse,
      );
      expect(await service().listWorkspaceBackups(target), isEmpty);
      expect(
        (await global
                .customSelect(
                  'SELECT * FROM workspace_routes ORDER BY key_hash',
                )
                .get())
            .map((r) => r.data),
        routesBefore.map((r) => r.data),
      );
      expect(events.whereType<WorkspaceRestored>(), isEmpty);
    }

    test('a file that is not a database', () async {
      final bogus = File('${tmp.path}/bogus.db')
        ..writeAsBytesSync(List<int>.filled(8192, 7));
      await expectUntouched(bogus.path, WorkspaceImportRefusal.damaged);
    });

    test('a file written by a newer schema', () async {
      final exported = await service().exportWorkspace(target);
      rawEdit(exported, (db) {
        db.execute(
          'PRAGMA user_version = '
          '${WorkspaceDatabase.currentSchemaVersion + 1}',
        );
      });
      await expectUntouched(exported, WorkspaceImportRefusal.newerSchema);
    });

    test('a database some other program wrote', () async {
      final exported = await service().exportWorkspace(target);
      rawEdit(exported, (db) => db.execute('PRAGMA application_id = 4242'));
      await expectUntouched(exported, WorkspaceImportRefusal.foreignFile);
    });

    test('a snapshot copy that was truncated', () async {
      final backup = await service().backupWorkspace(target);
      final bytes = File(backup).readAsBytesSync();
      File(backup).writeAsBytesSync(bytes.sublist(0, bytes.length ~/ 2));
      // The listing already says so, before anyone tries it.
      final listed = (await service().listWorkspaceBackups(target)).single;
      expect(listed.complete, isFalse);
      // Its own backup is the one thing in the scope; drop it from the
      // comparison by moving the scope aside.
      final scope = Directory('${tmp.path}/backups/workspace-backups/$target');
      final aside = scope.renameSync('${tmp.path}/aside');
      await expectUntouched(
        '${aside.path}/${backup.split('/').reversed.elementAt(1)}/'
        '$workspaceDatabaseFileName',
        WorkspaceImportRefusal.checksumMismatch,
      );
    });

    test('a snapshot copy edited in place, size unchanged', () async {
      final snapshot = await service().backupNow();
      final copy = '$snapshot/$target/$workspaceDatabaseFileName';
      final file = File(copy).openSync(mode: FileMode.append);
      try {
        // One byte, the size unchanged. The recorded hash is checked before
        // the file is opened at all.
        file
          ..setPositionSync(file.lengthSync() - 1)
          ..writeByteSync(0x5a);
      } finally {
        file.closeSync();
      }
      await expectUntouched(copy, WorkspaceImportRefusal.checksumMismatch);
    });

    test('a key that already routes to another workspace', () async {
      await seed('other');
      await sql(
        'other',
        'INSERT INTO pipeline_runs (id, template_id, workspace_id) '
            "VALUES ('run-1', 'tpl', 'other')",
      );
      await global.workspaceRouteDao.put(
        WorkspaceRouteKind.pipelineRun,
        'run-1',
        'other',
      );
      final exported = await service().exportWorkspace('other');
      await expectUntouched(exported, WorkspaceImportRefusal.routeConflict);
    });
  });

  /// [ws1] as a file from elsewhere could describe it: approved host
  /// execution, allowing rules, elevated people and invites to elevated
  /// roles. Returns its export.
  Future<String> seedAuthority() async {
    await seed('ws1');
    addSiblings('ws1');
    const at = 1767225600; // 2026-01-01
    await sql(
      'ws1',
      'INSERT INTO environment_definitions '
          '(id, name, definition_json, host_approved_by, created_at, '
          'updated_at) '
          "VALUES ('env', 'Env', '{}', 'someone-else', $at, $at)",
    );
    await sql(
      'ws1',
      'INSERT INTO mcp_servers '
          '(id, name, transport, command, host_approved_by, created_at, '
          'updated_at) '
          "VALUES ('mcp', 'files', 'stdio', 'npx', 'someone-else', $at, $at)",
    );
    await sql(
      'ws1',
      'INSERT INTO mcp_servers '
          '(id, user_id, name, transport, url, created_at, updated_at) '
          "VALUES ('mine', 'user-1', 'figma', 'http', 'https://mcp.example.com', "
          '$at, $at)',
    );
    for (final (id, decision) in [('p-allow', 'allow'), ('p-deny', 'deny')]) {
      await sql(
        'ws1',
        'INSERT INTO action_policies '
            '(id, workspace_id, scope_type, command_prefix, decision) '
            "VALUES ('$id', 'ws1', 'workspace', 'git $id', '$decision')",
      );
    }
    for (final (id, decision) in [('s-allow', 'allow'), ('s-deny', 'deny')]) {
      await sql(
        'ws1',
        'INSERT INTO sandbox_exec_grants (id, workspace_id, path, decision) '
            "VALUES ('$id', 'ws1', '/usr/bin/$id', '$decision')",
      );
    }
    await sql(
      'ws1',
      "INSERT INTO repos (id, name, path) VALUES ('repo', 'Repo', '/repo')",
    );
    await sql(
      'ws1',
      'INSERT INTO workspace_roles '
          '(id, workspace_id, name, base_preset, denied_permissions) '
          "VALUES ('ops', 'ws1', 'Ops', 'admin', '[]')",
    );
    for (final (user, role) in [
      ('u-old-owner', 'owner'),
      ('u-admin', 'admin'),
      ('u-custom', 'custom:ops'),
      ('u-member', 'member'),
      ('importer', 'member'),
    ]) {
      await sql(
        'ws1',
        'INSERT INTO workspace_members (id, workspace_id, user_id, role) '
            "VALUES ('m-$user', 'ws1', '$user', '$role')",
      );
    }
    for (final (id, user, level) in [
      ('g-write', 'u-member', 'write'),
      ('g-read', 'u-admin', 'read'),
    ]) {
      await sql(
        'ws1',
        'INSERT INTO workspace_member_repo_grants '
            '(id, workspace_id, user_id, repo_id, level) '
            "VALUES ('$id', 'ws1', '$user', 'repo', '$level')",
      );
    }
    for (final (id, role, grants) in [
      ('inv-admin', 'admin', '{}'),
      ('inv-writer', 'member', '{"repo":"write"}'),
      ('inv-member', 'member', '{}'),
    ]) {
      await sql(
        'ws1',
        'INSERT INTO workspace_invites '
            '(id, workspace_id, code_hash, role, repo_grants_json, '
            'created_by, expires_at) '
            "VALUES ('$id', 'ws1', 'code-$id', '$role', '$grants', "
            "'u-old-owner', 4102444800)",
      );
    }
    return service().exportWorkspace('ws1');
  }

  group('a successful import', () {
    test('keeps the siblings, drops the code index and keeps the replaced '
        'file as a backup', () async {
      final exported = await seedAuthority();
      final siblingsBefore = filesOf('ws1')
        ..removeWhere(
          (path, _) =>
              path.startsWith(workspaceDatabaseFileName) ||
              path.startsWith(AppDatabaseBackupService.codeIndexFileName),
        );
      now = now.add(const Duration(minutes: 1));

      await service().importWorkspace(
        workspaceId: 'ws1',
        sourcePath: exported,
        importedBy: 'importer',
      );

      final after = filesOf('ws1');
      for (final MapEntry(key: path, value: bytes) in siblingsBefore.entries) {
        expect(after[path], bytes, reason: path);
      }
      expect(after.keys, isNot(contains(startsWith('code_index.db'))));
      expect(after.keys, isNot(contains(endsWith('.importing'))));

      final backups = await service().listWorkspaceBackups('ws1');
      final kept = backups.singleWhere(
        (b) => b.name.endsWith(AppDatabaseBackupService.preRestoreSuffix),
      );
      expect(kept.complete, isTrue);
      // The kept copy is the file as it was, approvals and all: the restore
      // can be undone.
      final copy = sqlite.sqlite3.open(
        kept.workspaces.single.path,
        mode: sqlite.OpenMode.readOnly,
      );
      addTearDown(copy.close);
      expect(
        copy.select('SELECT host_approved_by FROM environment_definitions'),
        [
          {'host_approved_by': 'someone-else'},
        ],
      );
      expect(events.whereType<WorkspaceRestored>().single.workspaceId, 'ws1');
    });

    test('clears host approvals and holds every grant the file made', () async {
      final exported = await seedAuthority();
      now = now.add(const Duration(minutes: 1));

      await service().importWorkspace(
        workspaceId: 'ws1',
        sourcePath: exported,
        importedBy: 'importer',
      );

      expect(
        await select(
          'ws1',
          'SELECT host_approved_by FROM environment_definitions',
        ),
        [
          {'host_approved_by': null},
        ],
      );
      expect(
        await select('ws1', 'SELECT id, host_approved_by FROM mcp_servers'),
        [
          {'id': 'mcp', 'host_approved_by': null},
        ],
        reason: 'a member\'s own server does not travel with the file',
      );
      expect(await select('ws1', 'SELECT id FROM action_policies'), [
        {'id': 'p-deny'},
      ], reason: 'a deny only narrows what runs');
      expect(await select('ws1', 'SELECT id FROM sandbox_exec_grants'), [
        {'id': 's-deny'},
      ]);
      expect(
        await select(
          'ws1',
          'SELECT id, level FROM workspace_member_repo_grants ORDER BY id',
        ),
        [
          {'id': 'g-read', 'level': 'read'},
          {'id': 'g-write', 'level': 'read'},
        ],
      );
      expect(
        await select(
          'ws1',
          'SELECT user_id, role FROM workspace_members ORDER BY user_id',
        ),
        [
          {'user_id': 'importer', 'role': 'owner'},
          {'user_id': 'u-admin', 'role': 'member'},
          {'user_id': 'u-custom', 'role': 'member'},
          {'user_id': 'u-member', 'role': 'member'},
          {'user_id': 'u-old-owner', 'role': 'member'},
        ],
      );
      expect(await select('ws1', 'SELECT id FROM workspace_invites'), [
        {'id': 'inv-member'},
      ]);
      // A held invite's code routes nowhere until it is accepted.
      expect(
        await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.inviteCode,
          'code-inv-admin',
        ),
        isNull,
      );
      expect(
        await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.inviteCode,
          'code-inv-member',
        ),
        'ws1',
      );

      final holds = await service().listImportHolds('ws1');
      final kinds = holds.map((h) => h.kind).toList()
        ..sort((a, b) => a.wire.compareTo(b.wire));
      expect(kinds, [
        ImportHoldKind.actionPolicy,
        ImportHoldKind.invite,
        ImportHoldKind.invite,
        ImportHoldKind.membershipRole,
        ImportHoldKind.membershipRole,
        ImportHoldKind.membershipRole,
        ImportHoldKind.repoGrant,
        ImportHoldKind.sandboxExecGrant,
      ]);
      expect(
        holds
            .where((h) => h.kind == ImportHoldKind.invite)
            .map((h) => h.payload.containsKey('code_hash')),
        everyElement(isFalse),
        reason: 'an invite code is a credential, even hashed',
      );

      // Every member whose role moved hears about it.
      final changed = {
        for (final e in events.whereType<WorkspaceMemberRoleChanged>())
          e.userId: e.role,
      };
      expect(changed, {
        'importer': WorkspaceRole.owner,
        'u-admin': WorkspaceRole.member,
        'u-custom': WorkspaceRole.member,
        'u-old-owner': WorkspaceRole.member,
      });
    });

    test('the server owner accepts or discards each hold', () async {
      final exported = await seedAuthority();
      now = now.add(const Duration(minutes: 1));
      final backups = service();
      await backups.importWorkspace(
        workspaceId: 'ws1',
        sourcePath: exported,
        importedBy: 'importer',
      );
      Future<ImportedAuthorityHold> holdOf(
        ImportHoldKind kind,
        bool Function(Map<String, Object?> payload) where,
      ) async => (await backups.listImportHolds(
        'ws1',
      )).singleWhere((h) => h.kind == kind && where(h.payload));

      final admin = await holdOf(
        ImportHoldKind.membershipRole,
        (p) => p['user_id'] == 'u-admin',
      );
      events.clear();
      expect(
        await backups.resolveImportHold(
          workspaceId: 'ws1',
          holdId: admin.id,
          accept: true,
        ),
        isTrue,
      );
      expect(
        await select(
          'ws1',
          "SELECT role FROM workspace_members WHERE user_id = 'u-admin'",
        ),
        [
          {'role': 'admin'},
        ],
      );
      expect(events.whereType<ImportedAuthorityAccepted>(), hasLength(1));
      expect(
        events.whereType<WorkspaceMemberRoleChanged>().single.role,
        WorkspaceRole.admin,
      );

      final invite = await holdOf(
        ImportHoldKind.invite,
        (p) => p['id'] == 'inv-admin',
      );
      await backups.resolveImportHold(
        workspaceId: 'ws1',
        holdId: invite.id,
        accept: true,
      );
      expect(
        await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.inviteCode,
          'code-inv-admin',
        ),
        'ws1',
      );
      expect(
        await select(
          'ws1',
          "SELECT role FROM workspace_invites WHERE id = 'inv-admin'",
        ),
        [
          {'role': 'admin'},
        ],
      );

      final policy = await holdOf(ImportHoldKind.actionPolicy, (_) => true);
      expect(
        await backups.resolveImportHold(
          workspaceId: 'ws1',
          holdId: policy.id,
          accept: false,
        ),
        isFalse,
      );
      expect(await select('ws1', 'SELECT id FROM action_policies'), [
        {'id': 'p-deny'},
      ]);

      final remaining = await backups.listImportHolds('ws1');
      expect(remaining.map((h) => h.id), isNot(contains(admin.id)));
      expect(remaining.map((h) => h.id), isNot(contains(policy.id)));
      expect(remaining, hasLength(5));
      await expectLater(
        backups.resolveImportHold(
          workspaceId: 'ws1',
          holdId: policy.id,
          accept: true,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('drops every planted schema object, constraints included', () async {
      await seed('ws1');
      final exported = await service().exportWorkspace('ws1');
      rawEdit(exported, (db) {
        final repos =
            db
                    .select(
                      "SELECT sql FROM sqlite_master WHERE name = 'repos'",
                    )
                    .single['sql']!
                as String;
        final planted =
            '${repos.substring(0, repos.lastIndexOf(')'))}, '
            "CHECK (name <> 'blocked'))";
        db
          ..execute('PRAGMA foreign_keys = OFF')
          // Other tables' triggers name `repos`; the rename must not check
          // them against the dropped table.
          ..execute('PRAGMA legacy_alter_table = ON')
          ..execute(
            planted.replaceFirst(
              RegExp(r'CREATE TABLE (IF NOT EXISTS )?"?repos"?'),
              'CREATE TABLE repos_planted',
            ),
          )
          ..execute('INSERT INTO repos_planted SELECT * FROM repos')
          ..execute('DROP TABLE repos')
          ..execute('ALTER TABLE repos_planted RENAME TO repos')
          ..execute(
            'ALTER TABLE agents ADD COLUMN planted_gen TEXT '
            'GENERATED ALWAYS AS (upper(name)) VIRTUAL',
          )
          ..execute('CREATE INDEX planted_idx ON agents (lower(name))')
          ..execute('CREATE TABLE planted_table (x)')
          // A row pointing at a repository the file does not have.
          ..execute(
            'INSERT INTO workspace_member_repo_grants '
            '(id, workspace_id, user_id, repo_id, level) '
            "VALUES ('orphan', 'ws1', 'u', 'no-such-repo', 'write')",
          )
          ..execute('CREATE VIEW planted_view AS SELECT 1')
          ..execute(
            'CREATE TRIGGER planted AFTER INSERT ON agents BEGIN '
            "UPDATE agents SET name = 'pwned' WHERE id = NEW.id; END",
          );
      });

      await service().importWorkspace(
        workspaceId: 'ws1',
        sourcePath: exported,
        importedBy: 'owner',
      );

      final names = [
        for (final row in await select('ws1', 'SELECT name FROM sqlite_master'))
          row['name'],
      ];
      expect(names, isNot(contains(startsWith('planted'))));
      final reposSql =
          (await select(
                'ws1',
                "SELECT sql FROM sqlite_master WHERE name = 'repos'",
              )).single['sql']!
              as String;
      expect(reposSql, isNot(contains('blocked')));
      expect([
        for (final row in await select('ws1', 'PRAGMA table_xinfo(agents)'))
          row['name'],
      ], isNot(contains('planted_gen')));
      await sql(
        'ws1',
        "INSERT INTO repos (id, name, path) VALUES ('b', 'blocked', '/b')",
      );
      expect(await workspaces.of('ws1').schemaDifferences(), isEmpty);
      expect(
        await select('ws1', 'SELECT id FROM workspace_member_repo_grants'),
        isEmpty,
      );
      expect(await select('ws1', 'PRAGMA foreign_key_check'), isEmpty);
    });
  });

  group('a damaged workspace', () {
    /// Overwrites the root page of one table of [id]'s file and starts a
    /// fresh manager, as a new process would.
    Future<void> damage(String id) async {
      await workspaces.close(id);
      final raw = sqlite.sqlite3.open(workspaces.pathFor(id));
      final page =
          raw
                  .select(
                    'SELECT rootpage FROM sqlite_master '
                    "WHERE type = 'table' AND name = 'agent_run_logs'",
                  )
                  .single['rootpage']!
              as int;
      final pageSize =
          raw.select('PRAGMA page_size').single.values.single! as int;
      raw
        ..execute('PRAGMA wal_checkpoint(TRUNCATE)')
        ..close();
      final file = File(workspaces.pathFor(id)).openSync(mode: FileMode.append);
      try {
        file
          ..setPositionSync((page - 1) * pageSize)
          ..writeFromSync(List<int>.filled(pageSize, 0xff));
      } finally {
        file.closeSync();
      }
      await workspaces.closeAll();
      workspaces = manager();
      await workspaces.loadInstallId();
    }

    test('is left out of a snapshot, and its last good copy outlives '
        'retention until it is restored from it', () async {
      await seed('ws1');
      await seed('ws2');
      final good = await service().backupNow();
      final goodScoped = await service().backupWorkspace('ws1');
      await damage('ws1');

      now = now.add(const Duration(days: 10));
      final later = await service().backupNow();
      final manifest = SnapshotManifest.read(Directory(later))!;
      expect(manifest.skipped, [
        (workspaceId: 'ws1', reason: SnapshotSkipReason.damaged),
      ]);
      expect(manifest.workspaces.map((e) => e.workspaceId), ['ws2']);
      expect(Directory('$later/ws1').existsSync(), isFalse);
      await expectLater(
        service().backupWorkspace('ws1'),
        throwsA(isA<DatabaseDamagedException>()),
      );

      expect(
        await service().deleteBackupsOlderThan(age: const Duration(days: 7)),
        0,
      );
      expect(
        await service().deleteBackupsOlderThan(
          age: const Duration(days: 7),
          workspaceId: 'ws1',
        ),
        0,
      );
      expect(Directory(good).existsSync(), isTrue);
      expect(File(goodScoped).existsSync(), isTrue);
      final listed = await service().listBackups();
      expect(
        {for (final s in listed) s.path: s.pinnedReason},
        {later: null, good: BackupSnapshot.lastGoodCopyPin},
      );
      expect(
        (await service().listWorkspaceBackups('ws1')).single.pinnedReason,
        BackupSnapshot.lastGoodCopyPin,
      );

      // Restoring from the pinned copy, end to end.
      final source = listed
          .singleWhere((s) => s.path == good)
          .workspaces
          .singleWhere((w) => w.workspaceId == 'ws1')
          .path;
      await service().importWorkspace(
        workspaceId: 'ws1',
        sourcePath: source,
        importedBy: 'owner',
      );
      expect(workspaces.integrityFailure('ws1'), isNull);
      expect((await workspaces.of('ws1').agentDao.getAll()).single.name, 'Ada');
      // The damaged file was kept as it was, and says so.
      final keptDamaged = (await service().listWorkspaceBackups('ws1'))
          .singleWhere(
            (b) => b.name.endsWith(AppDatabaseBackupService.preRestoreSuffix),
          );
      expect(keptDamaged.complete, isFalse);

      // With the workspace whole again the pin is released.
      expect(
        await service().deleteBackupsOlderThan(age: const Duration(days: 7)),
        1,
      );
      expect(Directory(good).existsSync(), isFalse);
      expect(Directory(later).existsSync(), isTrue);
    });
  });

  group('snapshot pruning', () {
    test('removes a directory that never got its manifest, whatever its '
        'age', () async {
      await seed('ws1');
      final unfinished = await service().backupNow();
      File(
        '$unfinished/${AppDatabaseBackupService.manifestFileName}',
      ).deleteSync();
      now = now.add(const Duration(minutes: 30));
      // Young enough that it may still be being written.
      expect(
        await service().deleteBackupsOlderThan(age: const Duration(days: 7)),
        0,
      );
      now = now.add(const Duration(hours: 1));
      expect(
        await service().deleteBackupsOlderThan(age: const Duration(days: 7)),
        1,
      );
      expect(Directory(unfinished).existsSync(), isFalse);
    });

    test('keeps a snapshot whose manifest this build cannot read until it '
        'ages out, and lists it as incomplete', () async {
      await seed('ws1');
      final older = await service().backupNow();
      // What a snapshot taken before the manifest carried checksums holds.
      File(
        '$older/${AppDatabaseBackupService.manifestFileName}',
      ).writeAsStringSync('{"created_at":"2026-01-01T00:00:00Z","files":[]}');
      now = now.add(const Duration(days: 2));

      expect(
        await service().deleteBackupsOlderThan(age: const Duration(days: 7)),
        0,
      );
      expect(Directory(older).existsSync(), isTrue);
      expect((await service().listBackups()).single.complete, isFalse);

      now = now.add(const Duration(days: 6));
      expect(
        await service().deleteBackupsOlderThan(age: const Duration(days: 7)),
        1,
      );
      expect(Directory(older).existsSync(), isFalse);
    });
  });

  test('a crashed import leaves nothing a boot does not sweep', () async {
    await seed('ws1');
    await workspaces.close('ws1');
    final live = workspaces.pathFor('ws1');
    final liveBytes = File(live).readAsBytesSync();
    final staged = '$live${AppDatabaseBackupService.importingSuffix}';
    File(staged).writeAsBytesSync([1, 2, 3]);
    File('$staged-wal').writeAsBytesSync([4]);

    expect(await service().removeStaleImportFiles(), 1);

    expect(File(staged).existsSync(), isFalse);
    expect(File('$staged-wal').existsSync(), isFalse);
    expect(File(live).readAsBytesSync(), liveBytes);
  });
}
