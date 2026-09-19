import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:cc_server_core/src/demo/demo_script.dart';
import 'package:cc_server_core/src/demo/demo_world.dart';
import 'package:cc_server_core/src/demo/fixtures/demo_fixtures.g.dart';
import 'package:cc_server_core/src/pr_review/pr_cache_codec.dart';
import 'package:test/test.dart';

/// Finds the repo root by walking up until `tool/gen_demo_fixtures.dart` exists.
Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (File('${dir.path}/tool/gen_demo_fixtures.dart').existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }
  fail('could not locate the repo root from ${Directory.current.path}');
}

void main() {
  test(
    'the committed fixtures match their authored JSON',
    () {
      // Same discipline as `test/tooling/web_workers_test.dart`: the generated
      // file is committed, so a fixture edited without regenerating would ship a
      // demo that silently plays yesterday's script.
      final root = _repoRoot();
      final result = Process.runSync('dart', [
        'run',
        'tool/gen_demo_fixtures.dart',
        '--check',
      ], workingDirectory: root.path);
      expect(
        result.exitCode,
        0,
        reason:
            'demo fixtures are stale — run '
            '`fvm dart run tool/gen_demo_fixtures.dart`.\n'
            '${result.stdout}${result.stderr}',
      );
    },
    // `dart run` re-bundles this package's native assets into `.dart_tool/`
    // before it executes anything, and THIS process already has
    // `sqlite3.dll` loaded from exactly there. Windows refuses to replace an
    // open DLL, so the nested run dies with "Cannot delete file …
    // sqlite3.dll (Access is denied)" and the check reports the fixtures as
    // stale when they are current — a false failure about a file nobody
    // touched. Nothing here is platform-specific (it compares committed
    // bytes to regenerated ones), so the Linux and macOS jobs cover it.
    skip: Platform.isWindows
        ? 'nested `dart run` cannot re-bundle sqlite3.dll while this process '
              'holds it open'
        : null,
  );

  test('every authored script parses and is well formed', () {
    final decoded = jsonDecode(kDemoRunScriptsJson);
    expect(decoded, isA<List<dynamic>>());
    final scripts = [
      for (final raw in decoded as List)
        DemoRunScript.fromJson(Map<String, dynamic>.from(raw as Map)),
    ];

    expect(scripts, isNotEmpty);
    for (final script in scripts) {
      expect(script.id, isNotEmpty, reason: 'a script needs an addressable id');
      expect(
        script.steps,
        isNotEmpty,
        reason: '${script.id} would stream nothing at all',
      );
      // A run that never speaks reads as a hang, whatever else it does.
      expect(
        script.steps.whereType<DemoSayStep>(),
        isNotEmpty,
        reason: '${script.id} never says anything',
      );
    }

    // Ids are unique, or `[[demo:script=<id>]]` is ambiguous.
    final ids = scripts.map((s) => s.id).toList();
    expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate script id');

    // Exactly one catch-all (no triggers) so an unmatched message has a home
    // and the fallback is deliberate rather than alphabetical.
    final catchAll = scripts.where((s) => s.triggers.isEmpty).toList();
    expect(
      catchAll,
      hasLength(1),
      reason: 'expected exactly one trigger-less fallback script',
    );
  });

  test('tool steps pair a name with a result', () {
    final decoded = jsonDecode(kDemoRunScriptsJson) as List;
    for (final raw in decoded) {
      final script = DemoRunScript.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      for (final step in script.steps.whereType<DemoToolStep>()) {
        expect(step.tool, isNotEmpty, reason: '${script.id}: unnamed tool');
        expect(
          step.result,
          isNotEmpty,
          reason: '${script.id}: ${step.tool} renders an empty result card',
        );
      }
    }
  });

  test('the PR world is four helix repos and furnishes Maya\'s inbox', () {
    final world = jsonDecode(kDemoPullRequestsJson) as Map<String, dynamic>;
    final repoRows = (world['repos'] as List).cast<Map<String, dynamic>>();
    expect(
      {for (final r in repoRows) r['full_name'] as String},
      {for (final spec in kDemoRepos) spec.fullName},
    );
    expect(kDemoRepos, hasLength(4));

    final now = DateTime(2026, 9, 19, 12);
    final resolved = _resolveDates(world, now) as Map<String, dynamic>;
    final open = <String, List<PullRequest>>{};
    final merged = <String, List<PullRequest>>{};
    final issueCommentCount = <int, int>{};
    for (final raw in resolved['pull_requests'] as List) {
      final prJson = Map<String, dynamic>.from(raw as Map);
      final detail = Map<String, dynamic>.from(prJson['detail'] as Map);
      final pr = PrCacheCodec.pullRequestFromCache(detail);
      expect(pr, isNotNull, reason: 'every fixture PR must decode');
      issueCommentCount[pr!.number] =
          (prJson['issue_comments'] as List? ?? const []).length;
      if (pr.isOpen) {
        (open[pr.repoFullName] ??= []).add(pr);
      } else if (pr.isMerged) {
        (merged[pr.repoFullName] ??= []).add(pr);
      }
    }

    RepoPullRequests group(
      DemoRepoSpec spec,
      Map<String, List<PullRequest>> by,
    ) => RepoPullRequests(
      repo: Repo(
        id: spec.id,
        name: spec.fullName,
        path: '/demo/${spec.name}',
        remoteOwner: kDemoRepoOwner,
        remoteName: spec.name,
        createdAt: now,
        updatedAt: now,
      ),
      prs: by[spec.fullName] ?? const [],
    );

    final openByRepo = [for (final spec in kDemoRepos) group(spec, open)];
    final mergedByRepo = [for (final spec in kDemoRepos) group(spec, merged)];

    final inbox = const ClassifyPrInboxUseCase().execute(
      openByRepo: openByRepo,
      mergedByRepo: mergedByRepo,
      viewerLoginByForge: const {ForgeHost.github: 'maya-ok'},
      viewerTeamsByOrg: const {
        'helix': {'ml-eng'},
      },
      now: now,
    );

    List<int> numbers(PrInboxSection section) =>
        inbox.of(section).map((i) => i.pr.number).toList()..sort();

    expect(numbers(PrInboxSection.needsYourReview), [
      88,
      412,
    ], reason: '#412 names Maya; #88 names helix/ml-eng');
    expect(numbers(PrInboxSection.drafts), [409]);
    expect(numbers(PrInboxSection.returnedToYou), [81]);
    expect(numbers(PrInboxSection.waitingForReviewers), [54]);
    expect(numbers(PrInboxSection.approved), [23]);
    expect(numbers(PrInboxSection.waitingForAuthor), [49]);
    expect(numbers(PrInboxSection.mergingAndMerged), [
      201,
      380,
    ], reason: "Maya's merged #380 and #201 sit inside the 7-day window");
    expect(
      inbox.of(PrInboxSection.needsYourReview).map((i) => i.pr.number),
      isNot(contains(19)),
      reason: "Diego's draft is list-only, not in Maya's inbox",
    );
    expect(
      issueCommentCount[88],
      greaterThan(0),
      reason: '#88 needs a conversation, not just a team review request',
    );
    expect(
      issueCommentCount[81],
      greaterThan(0),
      reason: '#81 needs Maya on the conversation thread',
    );
  });

  test('the compiled-in Helix logo is present', () {
    expect(kDemoLogoBase64, isNotEmpty);
  });

  test('the visitor display name matches Maya', () {
    expect(kDemoVisitorDisplayName, 'Maya Okonkwo');
  });
}

/// Replaces `@-<n><unit>` markers with ISO-8601 timestamps relative to [now].
Object? _resolveDates(Object? value, DateTime now) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key as String: _resolveDates(entry.value, now),
    };
  }
  if (value is List) {
    return [for (final item in value) _resolveDates(item, now)];
  }
  if (value is String) {
    final match = RegExp(r'^@-(\d+)([mhd])$').firstMatch(value);
    if (match == null) {
      return value;
    }
    final amount = int.parse(match.group(1)!);
    final delta = switch (match.group(2)) {
      'm' => Duration(minutes: amount),
      'h' => Duration(hours: amount),
      _ => Duration(days: amount),
    };
    return now.subtract(delta).toIso8601String();
  }
  return value;
}
