import 'dart:io';

import 'package:test/test.dart';

/// Guards the "works in tests, `opUnknown` in the app" footgun (FINDINGS §13.4).
///
/// The repo-RPC surface is a closed allow-list: the client (`cc_data`) reaches
/// the server by calling a stable op NAME (`_client.call('agents.get', …)`),
/// and the server routes that name to a `RepoOp` in `buildRemoteRpcCatalog`.
/// If a client calls an op the catalog never declares, the dispatcher returns
/// `opUnknown` at runtime — a silent break unit tests miss (see the documented
/// `repos.*`-unwired incident). And because the registry is a
/// `{for (o in ops) o.name: o}` map, two `RepoOp`s sharing a name silently
/// shadow one another.
///
/// This is a source-level (grep) test — no need to instantiate the ~40-dependency
/// catalog. It parses the op-name string literals on both sides and asserts:
///   1. no duplicate `RepoOp` name (silent-shadowing),
///   2. every client `.call('…')` op name is declared server-side.
///
/// It intentionally only checks statically-literal names (dynamic `'x.$y'` op
/// names — a handful of model/watch prefixes — are skipped, never false-flagged).
void main() {
  // Resolve the repo root whether the test runs from there or a package dir.
  Directory repoRoot() {
    var dir = Directory.current;
    while (true) {
      if (File(
        '${dir.path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
      ).existsSync()) {
        return dir;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        return Directory.current; // give up; assertions will surface it
      }
      dir = parent;
    }
  }

  final root = repoRoot();

  /// All files in `cc_server_core/lib/src/` that declare `RepoOp`s. The runtime
  /// catalog is assembled from `buildRemoteRpcCatalog` (the bulk of the ops) PLUS
  /// the `extraOps` builders it is called with (the fleet + evals op packs live
  /// in `fleet_rpc_ops.dart` / `evals_rpc_ops.dart` and are spliced in from
  /// `cc_server_runtime.dart`). Every file that can contribute a `RepoOp` must be
  /// scanned here, or its ops false-flag as `opUnknown`.
  final serverOpFiles =
      Directory('${root.path}/packages/cc_server_core/lib/src')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) {
            final src = f.readAsStringSync();
            // Only files that actually declare a RepoOp literal contribute ops.
            return src.contains('RepoOp(');
          })
          .toList();

  // `name:` is matched through ANY intervening content — a `RepoOp(` very often
  // carries a leading comment explaining the op — but never across a following
  // `RepoOp(`, so each match binds to its own op. The earlier
  // `RepoOp\(\s*name:` form required `name:` to sit immediately after the paren,
  // which silently skipped every commented op: `providers.saveGenerationDefaults`
  // was invisible to BOTH assertions below, so a client calling it read as
  // undeclared and a duplicate of it would not have been caught either. A guard
  // whose job is finding `opUnknown` must not have blind spots of its own.
  final repoOpNameRe = RegExp(
    r"""RepoOp\((?:(?!RepoOp\()[\s\S])*?name:\s*(['"])([^'"$]+)\1""",
  );
  final clientCallRe = RegExp(r"""\.call\(\s*(['"])([^'"$]+)\1""");

  test('remote_rpc_catalog declares no duplicate RepoOp name', () {
    final names = <String>[];
    for (final f in serverOpFiles) {
      for (final m in repoOpNameRe.allMatches(f.readAsStringSync())) {
        names.add(m.group(2)!);
      }
    }
    expect(names, isNotEmpty, reason: 'catalog parse found no RepoOp names');

    final seen = <String>{};
    final dups = <String>{};
    for (final n in names) {
      if (!seen.add(n)) {
        dups.add(n);
      }
    }
    expect(
      dups,
      isEmpty,
      reason:
          'Duplicate RepoOp name(s) — the registry map silently keeps only '
          'the last, shadowing the other handler: ${dups.join(", ")}',
    );
  });

  test('every client .call op name is declared as a server RepoOp', () {
    final serverOps = <String>{};
    for (final f in serverOpFiles) {
      for (final m in repoOpNameRe.allMatches(f.readAsStringSync())) {
        serverOps.add(m.group(2)!);
      }
    }

    final ccData = Directory('${root.path}/packages/cc_data/lib');
    final missing = <String, Set<String>>{};
    for (final entity in ccData.listSync(recursive: true)) {
      if (entity is! File ||
          !entity.path.endsWith('.dart') ||
          entity.path.endsWith('.g.dart')) {
        continue;
      }
      final src = entity.readAsStringSync();
      for (final m in clientCallRe.allMatches(src)) {
        final op = m.group(2)!;
        // Op names are dotted (`agents.get`); a bare word is some other
        // `.call(...)` (e.g. a Function call), not a repo-RPC op.
        if (!op.contains('.')) {
          continue;
        }
        if (!serverOps.contains(op)) {
          missing
              .putIfAbsent(op, () => <String>{})
              .add(entity.uri.pathSegments.last);
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'Client calls op(s) with no matching server RepoOp — these hit '
          '`opUnknown` at runtime. Declare the op in buildRemoteRpcCatalog (and '
          'rebuild the cc_server binary), or fix the client op name:\n'
          '${missing.entries.map((e) => "  ${e.key}  (in ${e.value.join(", ")})").join("\n")}',
    );
  });

  // `RepoOpDispatcher` evaluates the role gate inside
  // `if (op.workspaceScoped && resolveRole != null)`. On an op declared
  // `workspaceScoped: false` the floor is therefore NEVER checked — a
  // `minRole:` there reads as protection in review and enforces nothing, which
  // is the worst possible combination on exactly the ops that need it most
  // (install-wide settings, sandbox posture, the argv agents launch with).
  //
  // Such an op must carry an explicit in-handler guard instead; see
  // `requireServerAdmin`.
  test('no RepoOp declares both workspaceScoped: false and minRole', () {
    // Comments are stripped first: the prose explaining this very rule names
    // `workspaceScoped: false`, and a comment sitting between two ops would
    // otherwise be attributed to the preceding one.
    final src =
        File(
              '${repoRoot().path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
            )
            .readAsStringSync()
            .replaceAll(RegExp(r'^\s*//.*', multiLine: true), '');

    // Each `RepoOp(` … `)` body, shallowly: stop at the next `RepoOp(` or
    // `WatchQuery(` so one op's fields never bleed into the next.
    final opRe = RegExp(
      r'RepoOp\((.*?)(?=RepoOp\(|WatchQuery\(|\Z)',
      dotAll: true,
    );
    final nameRe = RegExp(r"name:\s*'([^']+)'");

    final offenders = <String>[];
    for (final m in opRe.allMatches(src)) {
      final body = m.group(1)!;
      if (!body.contains('workspaceScoped: false')) {
        continue;
      }
      if (!body.contains('minRole:')) {
        continue;
      }
      offenders.add(nameRe.firstMatch(body)?.group(1) ?? '<unnamed>');
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These ops declare a minRole the dispatcher never evaluates, because '
          'the role gate only runs for workspace-scoped ops. Remove the '
          'minRole and add an explicit in-handler check (requireServerAdmin), '
          'or make the op workspace-scoped:\n'
          '${offenders.map((o) => "  $o").join("\n")}',
    );
  });
}
