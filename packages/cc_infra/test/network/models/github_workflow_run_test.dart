import 'package:cc_infra/src/network/models/github_workflow_run.dart';
import 'package:test/test.dart';

/// Pins [GitHubWorkflowRun] fromJson/toJson — the GitHub Actions runs payload
/// is joined to individual check runs by `check_suite_id`, so a silent wire
/// change here would break CI attribution in the PR review surface.
void main() {
  group('GitHubWorkflowRun.fromJson', () {
    test('parses a fully-populated run', () {
      final run = GitHubWorkflowRun.fromJson({
        'id': 123,
        'name': 'Tests (Pull Request)',
        'check_suite_id': 456,
        'head_sha': 'abc',
        'html_url': 'https://x/runs/123',
        'path': '.github/workflows/tests-pr.yaml',
        'status': 'completed',
        'conclusion': 'success',
        'run_started_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:05:00Z',
      });
      expect(run.id, 123);
      expect(run.name, 'Tests (Pull Request)');
      expect(run.checkSuiteId, 456);
      expect(run.headSha, 'abc');
      expect(run.htmlUrl, 'https://x/runs/123');
      expect(run.path, '.github/workflows/tests-pr.yaml');
      expect(run.status, 'completed');
      expect(run.conclusion, 'success');
      expect(run.runStartedAt, DateTime.utc(2026, 1, 1));
      expect(run.updatedAt, DateTime.utc(2026, 1, 1, 0, 5));
    });

    test('coerces a numeric double id/suite to int', () {
      final run = GitHubWorkflowRun.fromJson({
        'id': 1.0,
        'check_suite_id': 2.0,
      });
      expect(run.id, 1);
      expect(run.checkSuiteId, 2);
    });

    test(
      'a non-numeric id string throws (malformed payload surfaces loudly)',
      () {
        expect(
          () => GitHubWorkflowRun.fromJson({'id': 'x'}),
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('defaults every string field to empty when missing', () {
      final run = GitHubWorkflowRun.fromJson({});
      expect(run.name, '');
      expect(run.headSha, '');
      expect(run.htmlUrl, '');
      expect(run.path, '');
      expect(run.status, '');
      expect(run.conclusion, isNull);
      expect(run.runStartedAt, isNull);
      expect(run.updatedAt, isNull);
    });
  });

  group('GitHubWorkflowRun.toJson round-trip', () {
    test('re-reads a run with every field set', () {
      final original = GitHubWorkflowRun.fromJson({
        'id': 1,
        'name': 'n',
        'check_suite_id': 2,
        'head_sha': 's',
        'html_url': 'u',
        'path': 'p',
        'status': 'in_progress',
        'conclusion': null,
        'run_started_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });
      final restored = GitHubWorkflowRun.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.checkSuiteId, original.checkSuiteId);
      expect(restored.headSha, original.headSha);
      expect(restored.htmlUrl, original.htmlUrl);
      expect(restored.path, original.path);
      expect(restored.status, original.status);
      expect(restored.conclusion, original.conclusion);
      expect(restored.runStartedAt, original.runStartedAt);
      expect(restored.updatedAt, original.updatedAt);
    });
  });
}
