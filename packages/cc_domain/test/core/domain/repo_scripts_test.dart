import 'package:cc_domain/core/domain/entities/repo_script_run.dart';
import 'package:cc_domain/core/domain/value_objects/repo_scripts.dart';
import 'package:test/test.dart';

/// `RepoScripts` / `RepoScriptRun` — the per-repo lifecycle script contracts:
/// blank normalization, wire codec round-trips, and defensive decode.
void main() {
  group('RepoScripts', () {
    test('whitespace-only scripts normalize to unset', () {
      final scripts = RepoScripts(setup: '  \n ', archive: '\t');
      expect(scripts.setup, isNull);
      expect(scripts.archive, isNull);
      expect(scripts.isEmpty, isTrue);
      expect(scripts, const RepoScripts.empty());
    });

    test('trims configured scripts', () {
      expect(RepoScripts(setup: ' pnpm install\n').setup, 'pnpm install');
    });

    test('wire round-trip omits unset members', () {
      final json = const RepoScripts.empty().toJson();
      expect(json, isEmpty);

      final round =
          RepoScripts.fromJson(RepoScripts(setup: 'a', archive: 'b').toJson());
      expect(round.setup, 'a');
      expect(round.archive, 'b');
    });

    test('fromJson degrades defensively on junk', () {
      expect(RepoScripts.fromJson(null), const RepoScripts.empty());
      expect(
        RepoScripts.fromJson({'setup': 42, 'archive': true}),
        const RepoScripts.empty(),
      );
    });
  });

  group('RepoScriptRun', () {
    RepoScriptRun run() => RepoScriptRun(
      id: 'run-1',
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      repoId: 'repo-1',
      repoName: 'web-app',
      kind: RepoScriptKind.setup,
      status: RepoScriptRunStatus.running,
      startedAt: DateTime.utc(2026, 1, 1),
    );

    test('rejects empty scoping ids', () {
      expect(
        () => RepoScriptRun(
          id: 'r',
          workspaceId: '',
          spaceId: 'sp',
          repoId: 'repo',
          repoName: 'n',
          kind: RepoScriptKind.setup,
          status: RepoScriptRunStatus.running,
          startedAt: DateTime.utc(2026),
        ),
        throwsArgumentError,
      );
    });

    test('wire round-trip', () {
      final decoded = RepoScriptRun.fromJson(
        run()
            .copyWith(
              status: RepoScriptRunStatus.timedOut,
              completedAt: DateTime.utc(2026, 1, 1, 0, 5),
              error: 'timed out after 5 min',
              output: 'installing…',
            )
            .toJson(),
      );
      expect(decoded, isNotNull);
      expect(decoded!.kind, RepoScriptKind.setup);
      expect(decoded.status, RepoScriptRunStatus.timedOut);
      expect(decoded.error, 'timed out after 5 min');
      expect(decoded.output, 'installing…');
    });

    test('fromJson returns null on malformed payloads', () {
      expect(RepoScriptRun.fromJson(null), isNull);
      expect(RepoScriptRun.fromJson({'id': 'x'}), isNull);
      expect(
        RepoScriptRun.fromJson({
          ...run().toJson(),
          'status': ' vanished',
        }),
        isNull,
        reason: 'an unknown status must drop the row, not mislabel it',
      );
    });
  });

  group('enums', () {
    test('kind and status parse their wire names and reject unknowns', () {
      expect(RepoScriptKind.fromName('setup'), RepoScriptKind.setup);
      expect(RepoScriptKind.fromName('archive'), RepoScriptKind.archive);
      expect(RepoScriptKind.fromName('nope'), isNull);

      expect(
        RepoScriptRunStatus.fromName('timed_out'),
        RepoScriptRunStatus.timedOut,
      );
      expect(
        RepoScriptRunStatus.fromName('running'),
        RepoScriptRunStatus.running,
      );
      expect(RepoScriptRunStatus.fromName('nope'), isNull);
    });
  });
}
