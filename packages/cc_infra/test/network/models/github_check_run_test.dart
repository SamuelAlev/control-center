import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:test/test.dart';

/// Exercises [GitHubCheckRun]'s full fromJson/toJson round-trip and every
/// status/conclusion enum branch. The existing `github_models_test.dart`
/// only parses a handful of conclusions; this file pins the whole wire map so
/// the two private switches never drift from GitHub's string values.
void main() {
  group('GitHubCheckRun.fromJson', () {
    test('parses a fully-populated completed check with app + suite', () {
      final cr = GitHubCheckRun.fromJson({
        'id': 987,
        'name': 'Tests',
        'status': 'completed',
        'conclusion': 'success',
        'app': {'name': 'GitHub Actions'},
        'html_url': 'https://x/check/987',
        'started_at': '2026-01-01T00:00:00Z',
        'completed_at': '2026-01-01T00:10:00Z',
        'output': {
          'title': '1 test',
          'summary': 'all green',
          'text': 'long text',
        },
        'check_suite': {'id': 4242},
      });
      expect(cr.id, 987);
      expect(cr.appName, 'GitHub Actions');
      expect(cr.output, 'all green');
      expect(cr.outputTitle, '1 test');
      expect(cr.checkSuiteId, 4242);
      expect(cr.startedAt, DateTime.utc(2026, 1, 1));
      expect(cr.completedAt, DateTime.utc(2026, 1, 1, 0, 10));
      expect(cr.isComplete, isTrue);
      expect(cr.isSuccess, isTrue);
      expect(cr.isFailing, isFalse);
    });

    test('output falls back to text when summary is missing', () {
      final cr = GitHubCheckRun.fromJson({
        'name': 'n',
        'output': {'text': 'only-text'},
      });
      expect(cr.output, 'only-text');
    });

    test('missing output map leaves output empty', () {
      final cr = GitHubCheckRun.fromJson({'name': 'n'});
      expect(cr.output, '');
      expect(cr.outputTitle, '');
      expect(cr.checkSuiteId, isNull);
    });

    test('id defaults to 0 when missing, coerces a double to int', () {
      expect(GitHubCheckRun.fromJson({}).id, 0);
      expect(GitHubCheckRun.fromJson({'id': 1.0}).id, 1);
      // A non-numeric id is a malformed payload — the cast surfaces it loudly
      // rather than silently zeroing it out.
      expect(
        () => GitHubCheckRun.fromJson({'id': 'x'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('GitHubCheckRun status enum', () {
    for (final entry in {
      'queued': GitHubCheckStatus.queued,
      'in_progress': GitHubCheckStatus.inProgress,
      'completed': GitHubCheckStatus.completed,
      'bogus': GitHubCheckStatus.unknown,
    }.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(
          GitHubCheckRun.fromJson({'status': entry.key}).status,
          entry.value,
        );
      });
    }
  });

  group('GitHubCheckRun conclusion enum', () {
    const map = {
      'success': GitHubCheckConclusion.success,
      'failure': GitHubCheckConclusion.failure,
      'neutral': GitHubCheckConclusion.neutral,
      'cancelled': GitHubCheckConclusion.cancelled,
      'timed_out': GitHubCheckConclusion.timedOut,
      'action_required': GitHubCheckConclusion.actionRequired,
      'skipped': GitHubCheckConclusion.skipped,
      'stale': GitHubCheckConclusion.stale,
      'bogus': GitHubCheckConclusion.none,
    };
    for (final entry in map.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(
          GitHubCheckRun.fromJson({'conclusion': entry.key}).conclusion,
          entry.value,
        );
      });
    }

    test('isFailing covers failure / timedOut / actionRequired', () {
      for (final c in [
        GitHubCheckConclusion.failure,
        GitHubCheckConclusion.timedOut,
        GitHubCheckConclusion.actionRequired,
      ]) {
        final cr = GitHubCheckRun(
          id: 1,
          name: 'n',
          status: GitHubCheckStatus.completed,
          conclusion: c,
          appName: '',
          htmlUrl: '',
        );
        expect(cr.isFailing, isTrue, reason: '$c should be failing');
      }
    });
  });

  group('GitHubCheckRun.toJson round-trip', () {
    test('re-reads a check with every field set', () {
      final original = GitHubCheckRun.fromJson({
        'id': 11,
        'name': 'lint',
        'status': 'completed',
        'conclusion': 'failure',
        'app': {'name': 'CC'},
        'html_url': 'u',
        'started_at': '2026-02-02T00:00:00Z',
        'completed_at': '2026-02-02T00:05:00Z',
        'output': {'summary': 'sum', 'title': 't'},
        'check_suite': {'id': 99},
      });
      final restored = GitHubCheckRun.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.status, original.status);
      expect(restored.conclusion, original.conclusion);
      expect(restored.appName, original.appName);
      expect(restored.htmlUrl, original.htmlUrl);
      expect(restored.startedAt, original.startedAt);
      expect(restored.completedAt, original.completedAt);
      expect(restored.output, original.output);
      expect(restored.outputTitle, original.outputTitle);
      expect(restored.checkSuiteId, original.checkSuiteId);
    });

    test('serializes unknown status as null and none conclusion as null', () {
      const cr = GitHubCheckRun(
        id: 1,
        name: 'n',
        status: GitHubCheckStatus.unknown,
        conclusion: GitHubCheckConclusion.none,
        appName: 'a',
        htmlUrl: 'h',
      );
      final json = cr.toJson();
      expect(json['status'], isNull);
      expect(json['conclusion'], isNull);
      // check_suite only emitted when checkSuiteId is non-null.
      expect(json.containsKey('check_suite'), isFalse);
    });
  });
}
