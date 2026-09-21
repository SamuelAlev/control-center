import 'dart:io';

import 'package:test/test.dart';

/// CI ratchet for workspace isolation after the `global.db` + per-workspace
/// file split (isolation is structural, not WHERE-clause filtering).
///
/// Checks: (1) each table in exactly one database; (2) no DAO reaches across
/// the global/workspace boundary; (3) no server-side cached per-workspace DAO
/// field (would pin the first workspace); (4) cross-workspace fan-out only via
/// `CrossWorkspaceQueries`. Checks 3–4 scan all server packages; companion
/// tests assert the detectors still match.
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

  /// Server-side packages that may hold a `WorkspaceDatabaseManager`.
  ///
  /// DAO-cache and fan-out checks scan these (not only this package's
  /// repositories) — a constructor-injected DAO in `cc_server_core` pins a
  /// workspace the same way.
  final serverLibDirs = <Directory>[
    for (final rel in const [
      'cc_persistence/lib',
      'cc_server_core/lib',
      'cc_infra/lib',
      'cc_host/lib',
      'cc_mcp/lib',
    ])
      () {
        final fromPackage = Directory('../$rel');
        return fromPackage.existsSync()
            ? fromPackage
            : Directory('packages/$rel');
      }(),
  ];

  /// Non-generated Dart sources under [dirs], recursively.
  List<File> dartSources(List<Directory> dirs) => [
    for (final dir in dirs)
      if (dir.existsSync())
        for (final f in dir.listSync(recursive: true).whereType<File>())
          if (f.path.endsWith('.dart') && !f.path.endsWith('.g.dart')) f,
  ];

  /// A path short enough to read in a failure message, and long enough to
  /// find: `cc_server_core/lib/src/foo.dart`, never a bare `foo.dart` that
  /// three packages could each own.
  String shortPath(File f) {
    final parts = f.uri.pathSegments;
    final start = parts.indexWhere((p) => p.startsWith('cc_'));
    return start < 0 ? parts.last : parts.sublist(start).join('/');
  }

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
    // that a table is NOT workspace data and each deserves to be argued for in
    // review rather than inferred from a column. Growing this set is the way
    // isolation would quietly erode, so growing it has to be explicit.
    expect(
      globalTables,
      unorderedEquals(<String>{
        // The registry itself — the switcher lists workspaces without opening
        // any of them.
        'WorkspacesTable',
        // Identity: one human is one user across every workspace and a paired
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
        // SSO connections: authentication is server-wide (one IdP
        // authenticates every workspace's humans); *membership* stays
        // workspace-scoped behind each connection's auto-member policy. See
        // SsoConnectionsTable's doc comment.
        'SsoConnectionsTable',
        // The managed action-policy tier: the OPERATOR's clamp over every
        // workspace's guardrails ("no workspace on this install may
        // auto-approve git push"). It is install-wide by definition — a
        // per-workspace copy would be a policy each workspace admin could
        // edit away, the opposite of a managed tier. Merged into resolution
        // as most-restrictive, so it can only tighten what a workspace
        // decided. See ManagedActionPoliciesTable's doc comment.
        'ManagedActionPoliciesTable',
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

  test('nothing caches a workspace-scoped DAO in a field', () {
    // Cached per-workspace DAO fields reintroduce leaks: `final AgentDao _dao`
    // (also `late final`, nullable, or `Map<…, XDao>`) pins the first workspace.
    // Resolve per call: `_dbs.of(workspaceId).agentDao`.
    final workspaceDaoNames = workspaceDaos.toSet();
    final daoAlternation = workspaceDaoNames.join('|');
    // A FIELD, not a local: class-body indentation (two spaces), and never
    // inside a method — which is why `final dao = _dbs.of(workspaceId).xDao;`
    // (the CORRECT per-call shape, always more deeply indented) is not a hit.
    final fieldPattern = RegExp(
      '^  (?:late )?(?:final )?($daoAlternation)[?]? (\\w+)\\s*[;=]',
      multiLine: true,
    );
    final collectionPattern = RegExp(
      '^  (?:late )?(?:final )?(?:Map|List|Set|Iterable)<[^>]*'
      '\\b($daoAlternation)\\b[^>]*> (\\w+)',
      multiLine: true,
    );

    final offenders = <String>[];
    for (final f in dartSources(serverLibDirs)) {
      final src = f.readAsStringSync();
      final name = shortPath(f);
      for (final m in fieldPattern.allMatches(src)) {
        offenders.add('$name holds `${m.group(1)} ${m.group(2)}` as a field');
      }
      for (final m in collectionPattern.allMatches(src)) {
        offenders.add(
          '$name caches ${m.group(1)} in a collection field `${m.group(2)}`',
        );
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Something stores a per-workspace DAO in a field. That DAO belongs '
          'to whichever workspace happened to resolve it first and every later '
          'call is answered from that workspace regardless of the workspaceId '
          'passed in. Hold a WorkspaceDatabaseManager and resolve per call '
          'instead:\n  ${offenders.join('\n  ')}',
    );
  });

  test('the cached-DAO detector sees every declaration form', () {
    // A ratchet whose regex silently stopped matching is worse than no
    // ratchet, so the shapes it must catch are asserted directly rather than
    // inferred from the suite passing.
    final dao = workspaceDaos.first;
    final daoAlternation = workspaceDaos.join('|');
    final fieldPattern = RegExp(
      '^  (?:late )?(?:final )?($daoAlternation)[?]? (\\w+)\\s*[;=]',
      multiLine: true,
    );
    final collectionPattern = RegExp(
      '^  (?:late )?(?:final )?(?:Map|List|Set|Iterable)<[^>]*'
      '\\b($daoAlternation)\\b[^>]*> (\\w+)',
      multiLine: true,
    );

    for (final decl in [
      '  final $dao _dao;',
      '  late final $dao _dao;',
      '  late $dao _dao;',
      '  $dao? _dao;',
      '  final $dao? _dao;',
      '  final $dao _dao = other;',
    ]) {
      expect(
        fieldPattern.hasMatch(decl),
        isTrue,
        reason: 'the field detector no longer catches `${decl.trim()}`',
      );
    }
    for (final decl in [
      '  final Map<String, $dao> _byWorkspace = {};',
      '  late final List<$dao> _daos;',
    ]) {
      expect(
        collectionPattern.hasMatch(decl),
        isTrue,
        reason: 'the collection detector no longer catches `${decl.trim()}`',
      );
    }
    // The correct per-call shape is a LOCAL and must not be flagged.
    expect(
      fieldPattern.hasMatch('    final dao = _dbs.of(workspaceId).agentDao;'),
      isFalse,
    );
  });

  test('every cross-workspace enumeration is accounted for', () {
    // Fan-out is legitimate but must stay countable via CrossWorkspaceQueries
    // (or an allow-listed site with CROSS-WORKSPACE BY DESIGN). Grepping
    // `allWorkspaceIds()` or a file-level CrossWorkspaceQueries mention is not
    // enough — call sites must go through the helper.
    final enumeration = RegExp(
      r'allWorkspaceIds\(|\.openIds\b|orphanedDatabaseFiles\(',
    );
    const owners = {
      // These two DEFINE the enumeration primitives; the rule is about callers.
      'cross_workspace_queries.dart',
      'workspace_database_manager.dart',
    };

    final offenders = <String>[];
    for (final f in dartSources(serverLibDirs)) {
      if (owners.contains(f.uri.pathSegments.last)) {
        continue;
      }
      final lines = f.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (!enumeration.hasMatch(lines[i])) {
          continue;
        }
        final window = lines.sublist(i < 15 ? 0 : i - 15, i + 1).join('\n');
        if (window.contains('CROSS-WORKSPACE BY DESIGN') ||
            window.contains('CrossWorkspaceQueries')) {
          continue;
        }
        offenders.add('${shortPath(f)}:${i + 1}: ${lines[i].trim()}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'These enumerate every workspace without saying why. Route the '
          'fan-out through CrossWorkspaceQueries, or — if the shape genuinely '
          'does not fit the helper (a per-FILE operation like backup, a boot '
          'migration that must finish before the RPC surface opens) — put a '
          '`CROSS-WORKSPACE BY DESIGN:` comment directly above it explaining '
          'which and why:\n  ${offenders.join('\n  ')}',
    );
  });

  test('the fan-out detector is looking at real code', () {
    // A path typo or a moved package would empty the scan and turn the check
    // above into a test that always passes. Pin that it can see both the
    // primitive's definition and at least one justified caller.
    final sources = dartSources(serverLibDirs);
    expect(sources.length, greaterThan(200));
    final justified = sources.where(
      (f) => f.readAsStringSync().contains('CROSS-WORKSPACE BY DESIGN'),
    );
    expect(
      justified,
      isNotEmpty,
      reason:
          'no file carries the marker — the scan is probably looking at the '
          'wrong directories',
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
