import 'dart:io';

import 'package:test/test.dart';

/// Enforces workspace isolation as a CI ratchet.
///
/// What this test checks changed shape when the database was split into
/// `global.db` + one file per workspace, and the change is worth understanding
/// before editing it.
///
/// **Before:** one database held every workspace's rows, so isolation was a
/// query-level convention — every read of a workspace-scoped table had to
/// remember `WHERE workspace_id = ?`. This test policed that with a line-window
/// heuristic over the DAO sources, plus an allow-list of reviewed exceptions. It
/// worked, but it could only pattern-match: its own comment admitted it "will
/// occasionally miss a leak".
///
/// **Now:** a `WorkspaceDatabase` physically contains one workspace's rows and
/// does not declare any other workspace's tables, so a cross-workspace read is
/// not something you can write — it fails to compile. The WHERE clause is no
/// longer the isolation mechanism, and policing it would be theatre.
///
/// So the ratchet moved from *filtering* to **routing**. The remaining ways to
/// break isolation are structural, and all four are checked here:
///
///  1. A table lands in both databases, or in neither (its rows would be
///     duplicated across files, or unreachable).
///  2. A DAO on the workspace database reaches a global table, or vice versa —
///     the drift accessor would resolve, and the table would be silently
///     created in the wrong file.
///  3. A repository caches a resolved DAO in a field instead of resolving it per
///     call from the workspace id. A cached DAO pins the FIRST workspace it saw
///     and then serves every later caller from that workspace's file — the exact
///     leak the split is meant to make impossible.
///  4. Cross-workspace fan-out happens outside `CrossWorkspaceQueries`. Fan-out
///     is legitimate (dashboards, reconcilers, retention) but must stay
///     enumerable in one file rather than diffuse behind doc comments.
void main() {
  // Resolve relative to the package root whether the test is run from inside
  // the package (`dart test`, CWD = package) or from the workspace root
  // (`... packages/cc_persistence/test/...`, CWD = repo root).
  Directory pkgDir(String rel) {
    final fromPackage = Directory(rel);
    if (fromPackage.existsSync()) {
      return fromPackage;
    }
    return Directory('packages/cc_persistence/$rel');
  }

  File pkgFile(String rel) {
    final fromPackage = File(rel);
    if (fromPackage.existsSync()) {
      return fromPackage;
    }
    return File('packages/cc_persistence/$rel');
  }

  final tablesDir = pkgDir('lib/database/tables');
  final daosDir = pkgDir('lib/database/daos');
  final reposDir = pkgDir('lib/repositories');
  final globalSrc = pkgFile(
    'lib/database/global/global_database.dart',
  ).readAsStringSync();
  final workspaceSrc = pkgFile(
    'lib/database/workspace/workspace_database.dart',
  ).readAsStringSync();

  /// The `tables: [...]` / `daos: [...]` members of a `@DriftDatabase`.
  Set<String> members(String src, String key) {
    final block = RegExp('$key: \\[(.*?)\\],', dotAll: true).firstMatch(src);
    if (block == null) {
      throw StateError('no `$key: [...]` block found in the database source');
    }
    return {
      for (final line in block.group(1)!.split(','))
        if (line.trim().isNotEmpty) line.trim(),
    };
  }

  final globalTables = members(globalSrc, 'tables');
  final workspaceTables = members(workspaceSrc, 'tables');
  final globalDaos = members(globalSrc, 'daos');
  final workspaceDaos = members(workspaceSrc, 'daos');

  // ── Every declared table class in the schema ──────────────────────────────
  final allTableClasses = <String, String>{}; // class -> file
  for (final f in tablesDir.listSync().whereType<File>()) {
    if (!f.path.endsWith('.dart')) {
      continue;
    }
    final src = f.readAsStringSync();
    for (final m in RegExp(r'class (\w+) extends Table').allMatches(src)) {
      allTableClasses[m.group(1)!] = f.uri.pathSegments.last;
    }
  }

  test('the schema is non-trivially discovered', () {
    expect(allTableClasses.keys, contains('AgentsTable'));
    expect(allTableClasses.keys, contains('WorkspacesTable'));
    expect(allTableClasses.length, greaterThan(90));
    expect(globalTables, isNotEmpty);
    expect(workspaceTables.length, greaterThan(80));
  });

  test('every table belongs to exactly one database', () {
    final both = globalTables.intersection(workspaceTables);
    expect(
      both,
      isEmpty,
      reason:
          'These tables are declared in BOTH databases, so their rows would '
          'live in two files at once and neither would be authoritative: '
          '${both.join(', ')}',
    );

    final routed = {...globalTables, ...workspaceTables};
    final unrouted = allTableClasses.keys.toSet().difference(routed);
    expect(
      unrouted,
      isEmpty,
      reason:
          'These table classes exist but are declared in NEITHER database, so '
          'nothing creates them and every query against them fails at runtime. '
          'Add each to GlobalDatabase (server-wide state) or WorkspaceDatabase '
          "(a workspace's own data):\n  "
          '${unrouted.map((t) => '$t (${allTableClasses[t]})').join('\n  ')}',
    );

    final phantom = routed.difference(allTableClasses.keys.toSet());
    expect(
      phantom,
      isEmpty,
      reason:
          'These are declared in a database but define no `class X extends '
          'Table`: ${phantom.join(', ')}',
    );
  });

  test('the global database holds only genuinely server-wide tables', () {
    // Spelled out rather than derived: each of these is a deliberate decision
    // that a table is NOT workspace data, and each deserves to be argued for in
    // review rather than inferred from a column. Growing this set is the way
    // isolation would quietly erode, so growing it has to be explicit.
    expect(
      globalTables,
      unorderedEquals(<String>{
        // The registry itself — the switcher lists workspaces without opening
        // any of them.
        'WorkspacesTable',
        // Identity: one human is one user across every workspace, and a paired
        // device outlives any single workspace.
        'UsersTable',
        'UserPreferencesTable',
        'PairedDevicesTable',
        // The newsfeed is a server-wide pillar (its RPC ops are unscoped).
        'RssFeedsTable',
        'RssArticlesTable',
        // The fleet scheduler scans the whole queue every tick and matches it
        // against every worker. Jobs are ephemeral execution records and carry
        // ids, never workspace content.
        'WorkersTable',
        'JobsTable',
        'PlacementLogTable',
        // Pre-auth routing + install identity.
        'WorkspaceRoutesTable',
        'ServerMetaTable',
        // Install-wide settings that bound what any process on this HOST may
        // do (sandbox posture, per-adapter launch argv/env). One host serves
        // every workspace, so a per-workspace waiver would be a host-wide
        // waiver in practice — these belong to the operator of the install,
        // not to a workspace admin. See ServerSettingsTable's doc comment.
        'ServerSettingsTable',
      }),
      reason:
          'The global table set changed. A table here is visible to EVERY '
          'workspace, so adding one is an isolation decision, not a schema '
          'detail. If the addition is right, update this expectation and say '
          "why in the table's doc comment.",
    );
  });

  test('every DAO is declared in exactly one database', () {
    final both = globalDaos.intersection(workspaceDaos);
    expect(both, isEmpty, reason: 'DAOs in both databases: ${both.join(', ')}');
  });

  test('no DAO reaches across the database boundary', () {
    // A DAO declares the tables it touches in `@DriftAccessor(tables: [...])`.
    // If a workspace DAO names a global table, drift happily creates that table
    // inside every workspace file — a second, per-workspace copy of `users`
    // shadowing the real one, with no error anywhere.
    final offenders = <String>[];
    for (final f in daosDir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) {
        continue;
      }
      final src = f.readAsStringSync();
      final name = f.uri.pathSegments.last;
      final accessor = RegExp(
        r'@DriftAccessor\(\s*tables:\s*\[(.*?)\]',
        dotAll: true,
      ).firstMatch(src);
      if (accessor == null) {
        continue;
      }
      final declared = {
        for (final t in accessor.group(1)!.split(','))
          if (t.trim().isNotEmpty) t.trim(),
      };
      final isWorkspaceDao = src.contains(
        'DatabaseAccessor<WorkspaceDatabase>',
      );
      final isGlobalDao = src.contains('DatabaseAccessor<GlobalDatabase>');
      if (!isWorkspaceDao && !isGlobalDao) {
        offenders.add(
          '$name is neither a WorkspaceDatabase nor a GlobalDatabase accessor',
        );
        continue;
      }
      final wrongSide = isWorkspaceDao
          ? declared.intersection(globalTables)
          : declared.intersection(workspaceTables);
      if (wrongSide.isNotEmpty) {
        offenders.add(
          '$name (${isWorkspaceDao ? 'workspace' : 'global'} DAO) declares '
          '${wrongSide.join(', ')} from the other database',
        );
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'A DAO reaches across the global/per-workspace boundary. Drift would '
          'create the foreign table inside the wrong file and shadow the real '
          'one, silently:\n  ${offenders.join('\n  ')}',
    );
  });

  test('no repository caches a workspace-scoped DAO in a field', () {
    // The one mistake that reintroduces cross-workspace leakage after the split.
    // `final AgentDao _dao;` can only have been resolved from SOME workspace,
    // and every later call — for any workspace — is then served from that one
    // file. Resolving per call (`_dbs.of(workspaceId).agentDao`) makes the
    // workspace an argument again.
    final workspaceDaoNames = workspaceDaos.toSet();
    final offenders = <String>[];
    for (final f in reposDir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.dart')) {
        continue;
      }
      final src = f.readAsStringSync();
      final name = f.uri.pathSegments.last;
      for (final m in RegExp(
        r'^\s*final (\w+Dao) (\w+);',
        multiLine: true,
      ).allMatches(src)) {
        if (workspaceDaoNames.contains(m.group(1))) {
          offenders.add('$name holds `${m.group(1)} ${m.group(2)}` as a field');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'A repository stores a per-workspace DAO in a field. That DAO belongs '
          'to whichever workspace happened to resolve it first, and every later '
          'call is answered from that workspace regardless of the workspaceId '
          'passed in. Hold a WorkspaceDatabaseManager and resolve per call '
          'instead:\n  ${offenders.join('\n  ')}',
    );
  });

  test('cross-workspace fan-out stays inside CrossWorkspaceQueries', () {
    // Fan-out is legitimate — dashboards, startup reconcilers, retention — but
    // it must stay countable. Anything that enumerates workspaces itself has
    // reinvented the helper and escaped that inventory.
    final offenders = <String>[];
    for (final dir in [reposDir, daosDir]) {
      for (final f in dir.listSync().whereType<File>()) {
        if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) {
          continue;
        }
        final src = f.readAsStringSync();
        if (src.contains('allWorkspaceIds()') &&
            !src.contains('CrossWorkspaceQueries')) {
          offenders.add(
            '${f.uri.pathSegments.last} enumerates workspaces directly',
          );
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Cross-workspace fan-out belongs in CrossWorkspaceQueries, so the '
          'complete list of things that span workspaces stays readable in one '
          'place:\n  ${offenders.join('\n  ')}',
    );
  });

  test('a workspace id can never be smuggled into a filesystem path', () {
    // Workspace ids become filenames, so an id is validated as a single safe
    // path segment before it is joined. This asserts the guard rather than
    // trusting that ids happen to be uuids.
    final src = pkgFile(
      'lib/database/workspace_database_manager.dart',
    ).readAsStringSync();
    expect(src, contains('isValidWorkspaceId'));
    expect(
      src,
      contains("!workspaceId.contains('..')"),
      reason: 'traversal guard missing from workspace id validation',
    );
  });
}
