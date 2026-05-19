import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/demo/demo_profile.dart';
import 'package:test/test.dart';

/// Layer 3 of the demo lockdown: the ratchet.
///
/// Layer 1 is structural absence (the runtime passes `null` for every
/// execution port, so those ops are never built). Layer 2 is [DemoProfile]'s
/// name allowlist. This is the test that keeps them honest as the catalog
/// grows: an op added tomorrow that nobody classified fails HERE, by name,
/// instead of quietly becoming reachable on a public endpoint.
///
/// It reads the catalog source rather than building a live registry: building
/// one needs the whole server composition (databases, ports, natives), and the
/// question being asked — "is every op name accounted for?" — is a source-level
/// question. Same approach as `action_class_coverage_test.dart`.
/// Every Dart source under `lib/src/` that could declare a `RepoOp`.
///
/// NOT just `remote_rpc_catalog.dart`: ops reach the registry from other files
/// too, through the catalog's `extraOps` (soundscape, chat, evals…). Scanning
/// the one big file left those entirely unclassified — `soundscape.setTune`
/// was reachable-or-not by accident rather than by decision.
List<File> _catalogSources() {
  for (final candidate in ['lib/src', 'packages/cc_server_core/lib/src']) {
    final dir = Directory(candidate);
    if (dir.existsSync()) {
      return dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    }
  }
  fail('cc_server_core sources not found from ${Directory.current.path}');
}

/// Every `RepoOp` literal in the catalog, as `name -> kind`.
Map<String, String> _catalogOps() {
  final ops = <String, String>{};
  for (final file in _catalogSources()) {
    final source = file.readAsStringSync();
    for (final match in RegExp(r'RepoOp\(').allMatches(source)) {
      final end = match.end;
      // 2000, not 700: an op literal can carry a long explanatory comment
      // between `RepoOp(` and its `kind:`, and a short window silently
      // SKIPPED those ops — `pr_review.setFindingStatus` sits 667 chars in.
      // A scan that quietly misses rows is worse than no scan.
      final segment = source.substring(
        end,
        end + 2000 > source.length ? source.length : end + 2000,
      );
      final name = RegExp(r"name:\s*'([^']+)'").firstMatch(segment);
      final kind = RegExp(r'kind:\s*RepoOpKind\.(\w+)').firstMatch(segment);
      if (name != null && kind != null) {
        ops[name.group(1)!] = kind.group(1)!;
      }
    }
  }
  return ops;
}

/// Every statically-nameable `WatchQuery` across the same sources.
Set<String> _catalogWatchQueries() {
  final names = <String>{};
  for (final file in _catalogSources()) {
    final source = file.readAsStringSync();
    for (final match in RegExp(r'WatchQuery\(').allMatches(source)) {
      final end = match.end;
      final segment = source.substring(
        end,
        end + 2000 > source.length ? source.length : end + 2000,
      );
      final name = RegExp(r"name:\s*'([^']+)'").firstMatch(segment);
      if (name != null && !name.group(1)!.contains(r'$')) {
        // Names built by string interpolation (the on-device model families'
        // `models.watch$capitalized`) cannot be enumerated statically; they
        // are workspace-scoped status streams for a subsystem whose OPS the
        // demo denies, so they are excluded rather than pinned one by one.
        names.add(name.group(1)!);
      }
    }
  }
  return names;
}

/// A bare [RepoOp] for admission checks — only the name and kind matter here.
RepoOp _op(String name, RepoOpKind kind) => RepoOp(
  name: name,
  kind: kind,
  handler: (_) async => const <String, dynamic>{},
);

void main() {
  const profile = DemoProfile();
  final ops = _catalogOps();

  test('the catalog parsed at all', () {
    // Guards the regex itself: a refactor that changed how ops are declared
    // would otherwise make every assertion below vacuously pass.
    expect(
      ops.length,
      greaterThan(400),
      reason: 'expected the full op catalog; the source scan probably broke',
    );
    expect(ops['terminal.spawn'], 'mutate');
    expect(ops['messaging.sendMessage'], 'mutate');
  });

  test('every mutating op is classified — allowed or denied, never implicit', () {
    final unclassified = <String>[];
    for (final entry in ops.entries) {
      if (entry.value == 'read') {
        continue;
      }
      final name = entry.key;
      final classified =
          profile.allowedMutations.contains(name) ||
          profile.deniedMutations.contains(name) ||
          profile.deniedPrefixes.any(name.startsWith);
      if (!classified) {
        unclassified.add(name);
      }
    }
    expect(
      unclassified..sort(),
      isEmpty,
      reason:
          'These mutating ops are new to the catalog and nobody has decided '
          'whether a public demo visitor may call them. Add each to '
          'DemoProfile.defaultAllowedMutations or defaultDeniedMutations '
          '(or cover it with a denied prefix). Default-deny means they are '
          'unreachable until you do — this test just makes that a decision '
          'instead of an accident.',
    );
  });

  test('allow and deny never overlap, and every name is real', () {
    expect(
      profile.allowedMutations.intersection(profile.deniedMutations),
      isEmpty,
    );
    // A name that matches nothing is inert — the same class of typo that once
    // shipped a resident tool list referring to a tool that did not exist.
    final unknownAllow = profile.allowedMutations
        .where((n) => !ops.containsKey(n))
        .toList();
    final unknownDeny = profile.deniedMutations
        .where((n) => !ops.containsKey(n))
        .toList();
    final unknownFetch = profile.deniedReads
        .where((n) => ops[n] != 'read')
        .toList();
    expect(unknownAllow..sort(), isEmpty, reason: 'allowlist names a dead op');
    expect(unknownDeny..sort(), isEmpty, reason: 'denylist names a dead op');
    expect(
      unknownFetch..sort(),
      isEmpty,
      reason: 'deniedReads names something that is not a read op',
    );
  });

  test('an allowed op is never also covered by a denied prefix', () {
    // Both would "work" (deny wins) but it means the two lists disagree about
    // intent, and the next person cannot tell which one is the mistake.
    final contradictory = profile.allowedMutations
        .where(
          (n) =>
              !profile.prefixExceptions.contains(n) &&
              profile.deniedPrefixes.any(n.startsWith),
        )
        .toList();
    expect(contradictory..sort(), isEmpty);
  });

  test('the execution surface is refused by name, not merely absent', () {
    // Layer 1 already removes these by passing null ports. This asserts the
    // belt: even if a port were wired by mistake, the profile still refuses.
    for (final name in [
      'terminal.spawn',
      'terminal.write',
      'terminal.kill',
      'fs.writeString',
      'fs.writeAgentFile',
      'rig.open',
      'codeServer.ensure',
      'mcp.callTool',
      'oauth.begin',
      'credentials.set',
      'providerApps.setGitHub',
      'pairing.createInvite',
      'worktree.commitAndPush',
      'server.backupNow',
      'server.listBackups',
      'workspace.export',
      'workspace.import',
      'repos.add',
      'skills.install',
    ]) {
      final kind = ops[name];
      if (kind == null) {
        // The op was renamed or removed; the prefix rules still cover its
        // family, so this is not a failure — but the list should be refreshed.
        continue;
      }
      expect(
        profile.admits(
          RepoOp(
            name: name,
            kind: kind == 'read' ? RepoOpKind.read : RepoOpKind.mutate,
            handler: (_) async => const <String, dynamic>{},
          ),
        ),
        isFalse,
        reason: '$name must be unreachable in the demo',
      );
    }
  });

  test('a forbidden ActionClass is refused even if the name is allowed', () {
    // The second net: an allowed name that later declares, say, processSpawn
    // stops being reachable without anyone having to notice the name.
    final op = RepoOp(
      name: 'messaging.sendMessage',
      kind: RepoOpKind.mutate,
      handler: (_) async => const <String, dynamic>{},
      actionClasses: const {ActionClass.processSpawn},
    );
    expect(profile.admits(op), isFalse);
    expect(
      profile.admits(
        RepoOp(
          name: 'messaging.sendMessage',
          kind: RepoOpKind.mutate,
          handler: (_) async => const <String, dynamic>{},
        ),
      ),
      isTrue,
    );
  });

  test('workspaceMutation stays allowed — a visitor owns their workspace', () {
    expect(
      DemoProfile.forbiddenClasses.contains(ActionClass.workspaceMutation),
      isFalse,
    );
    // Every other class is forbidden; if a new one is added to the enum it must
    // be classified here too.
    final unclassified = ActionClass.values
        .where(
          (c) =>
              c != ActionClass.workspaceMutation &&
              !DemoProfile.forbiddenClasses.contains(c),
        )
        .toList();
    expect(
      unclassified,
      isEmpty,
      reason:
          'A new ActionClass must be added to DemoProfile.forbiddenClasses '
          '(or consciously exempted like workspaceMutation).',
    );
  });

  test('lockdown() removes refused ops from the registry entirely', () {
    RepoOp op(String name, RepoOpKind kind) => RepoOp(
      name: name,
      kind: kind,
      handler: (_) async => const <String, dynamic>{},
    );
    final registry = RepoOpRegistry([
      op('messaging.sendMessage', RepoOpKind.mutate),
      op('terminal.spawn', RepoOpKind.mutate),
      op('tickets.insert', RepoOpKind.mutate),
      op('agents.killProcesses', RepoOpKind.mutate),
      op('tickets.list', RepoOpKind.read),
      op('pr.listOpenForWorkspace', RepoOpKind.read),
    ], catalogVersion: 42);

    final locked = profile.lockdown(registry);
    final names = locked.ops.map((o) => o.name).toSet();

    expect(names, contains('messaging.sendMessage'));
    expect(names, contains('tickets.insert'));
    expect(names, contains('tickets.list'));
    // Absent, not filtered at call time: lookup returns null so the dispatcher
    // answers `opUnknown`, exactly as for an op that was never built.
    expect(locked.lookup('terminal.spawn'), isNull);
    expect(locked.lookup('agents.killProcesses'), isNull);
    expect(locked.lookup('pr.listOpenForWorkspace'), isNull);
    expect(locked.catalogVersion, 42);
  });

  test('every watch query is reviewed - a new one fails here', () {
    final watches = _catalogWatchQueries();
    // Guard the regex itself, same as the op parser above.
    expect(
      watches.length,
      greaterThan(80),
      reason: 'expected the full watch catalog; the scan probably broke',
    );

    final unreviewed = watches
        .where(
          (name) =>
              !profile.reviewedWatchQueries.contains(name) &&
              !profile.deniedWatchQueries.contains(name),
        )
        .toList()
      ..sort();
    expect(unreviewed, isEmpty,
        reason: 'These watch queries are new to the catalog. A demo visitor '
            'can sub/subscribe to any of them, so each must be checked '
            '(workspace-scoped, DB-only or individually gated) and added to '
            'DemoProfile.defaultReviewedWatchQueries — or, if it must stay '
            'absent, defaultDeniedWatchQueries.');

    // Dead entries are inert, same class of typo as a dead allowlist name.
    final dead = profile.reviewedWatchQueries
        .where((name) => !watches.contains(name))
        .toList()
      ..sort();
    expect(dead, isEmpty,
        reason: 'reviewedWatchQueries names a watch that does not exist');
  });

  test('prefix exceptions lift a prefix without escaping the kind rules', () {
    for (final name in profile.prefixExceptions) {
      final kind = ops[name];
      // An exception naming nothing is inert.
      expect(kind, isNotNull,
          reason: 'prefix exception names an op that does not exist: '
              '\${profile.prefixExceptions.lookup(name) ?? name}');
      if (kind == 'read') {
        // A read exception must still not be one that dials out.
        expect(profile.admits(_op(name, RepoOpKind.read)), isTrue,
            reason: 'was lifted from its prefix but is still refused - check '
                'deniedReads');
      } else {
        // A mutating exception must ALSO sit in allowedMutations: lifting
        // the prefix is not permission to mutate.
        expect(profile.allowedMutations.contains(name), isTrue,
            reason: 'lifts a denied prefix and mutates, but is not in '
                'allowedMutations');
      }
    }
  });

  test('an unlisted mutating op is denied by default', () {
    expect(
      profile.admits(
        RepoOp(
          name: 'something.brandNew',
          kind: RepoOpKind.mutate,
          handler: (_) async => const <String, dynamic>{},
        ),
      ),
      isFalse,
    );
    // …while an unlisted plain read is fine: reads are the demo's whole point,
    // and the ones that dial out are named explicitly.
    expect(
      profile.admits(
        RepoOp(
          name: 'something.brandNew',
          kind: RepoOpKind.read,
          handler: (_) async => const <String, dynamic>{},
        ),
      ),
      isTrue,
    );
  });
}
