import 'dart:io';

import 'package:test/test.dart';

/// Enforces workspace isolation as a CI ratchet.
///
/// What this test checks changed shape when the database was split into
/// `global.db` + one file per workspace and the change is worth understanding
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
/// longer the isolation mechanism and policing it would be theatre.
///
/// So the ratchet moved from *filtering* to **routing**. The remaining ways to
/// break isolation are structural and all four are checked here:
///
///  1. A table lands in both databases, or in neither (its rows would be
///     duplicated across files, or unreachable).
///  2. A DAO on the workspace database reaches a global table, or vice versa —
///     the drift accessor would resolve and the table would be silently
///     created in the wrong file.
///  3. Anything server-side caches a resolved DAO in a field instead of
///     resolving it per call from the workspace id. A cached DAO pins the FIRST
///     workspace it saw and then serves every later caller from that
///     workspace's file — the exact leak the split is meant to make impossible.
///  4. Cross-workspace fan-out happens outside `CrossWorkspaceQueries` without
///     saying why. Fan-out is legitimate (dashboards, reconcilers, retention,
///     backup) but must stay enumerable rather than diffuse.
///
/// Checks 3 and 4 scan every server-side package, not just this one, and each
/// carries a companion test asserting that its own detector still matches the
/// shapes it claims to — a ratchet whose regex quietly stopped matching is
/// worse than no ratchet, because the suite goes on passing.
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

  /// Every server-side package that can hold a `WorkspaceDatabaseManager`.
  ///
  /// The DAO-caching and fan-out checks used to look only at this package's
  /// `lib/repositories/`, which is where repositories live but not where the
  /// leak has to live: a service in `cc_server_core` that takes an
  /// `ActivityLogDao` in its constructor pins a workspace exactly as hard as a
  /// repository field does, and the original scope could not see it. (One did:
  /// `ActivityLogPersister` held a single DAO and wrote every workspace's audit
  /// rows into whichever file resolved it first.) Clients are deliberately
  /// absent — they cannot import `cc_persistence` at all, which the
  /// architecture ratchet already enforces.
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
    // The one mistake that reintroduces cross-workspace leakage after the split.
    // `final AgentDao _dao;` can only have been resolved from SOME workspace,
    // and every later call — for any workspace — is then served from that one
    // file. Resolving per call (`_dbs.of(workspaceId).agentDao`) makes the
    // workspace an argument again.
    //
    // The declaration forms below all pin a workspace identically, and the
    // first version of this check only saw the first one:
    //
    //     final AgentDao _dao;                    // caught before
    //     late final AgentDao _dao;               // `late` — missed
    //     AgentDao? _dao;                         // nullable, non-final — missed
    //     final Map<String, AgentDao> _byThing;   // a cache — missed
    //
    // A `Map<String, XDao>` counts even when it looks keyed by workspace:
    // `WorkspaceDatabaseManager` already memoizes one database per workspace,
    // so a second cache in front of it is redundant at best and keyed on
    // something else at worst — and nothing in a field declaration says which.
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
        reason: 'the field detector no longer catches `\${decl.trim()}`',
      );
    }
    for (final decl in [
      '  final Map<String, $dao> _byWorkspace = {};',
      '  late final List<$dao> _daos;',
    ]) {
      expect(
        collectionPattern.hasMatch(decl),
        isTrue,
        reason: 'the collection detector no longer catches `\${decl.trim()}`',
      );
    }
    // The correct per-call shape is a LOCAL and must not be flagged.
    expect(
      fieldPattern.hasMatch('    final dao = _dbs.of(workspaceId).agentDao;'),
      isFalse,
    );
  });

  test('every cross-workspace enumeration is accounted for', () {
    // Fan-out is legitimate — dashboards, startup reconcilers, retention,
    // backup — but it must stay COUNTABLE: the point of the rule is that the
    // complete list of things spanning workspaces can be read in one sitting.
    //
    // The first version of this check grepped two directories for the literal
    // string `allWorkspaceIds()` and treated a file-level mention of
    // `CrossWorkspaceQueries` as absolution. Both halves leaked. It could not
    // see `openIds` or `orphanedDatabaseFiles()`, it never looked outside
    // `cc_persistence` (where `IdentityBootstrap` enumerates every workspace),
    // and a file that legitimately uses the helper ONCE was thereafter free to
    // hand-roll a fan-out anywhere else in the same file.
    //
    // So: every enumeration SITE is found, and each is justified within the 15
    // lines above it — either by routing through the helper or by the
    // `CROSS-WORKSPACE BY DESIGN:` marker the project convention requires. The
    // marker is not a rubber stamp; it is a comment someone has to write a
    // reason into, next to the code, where review sees it.
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
