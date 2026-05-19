import 'package:control_center/core/network/models/github_workflow_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubWorkflowRun', () {
    final fullJson = <String, dynamic>{
      'id': 12345678,
      'name': 'Tests (Pull Request)',
      'check_suite_id': 98765,
      'head_sha': 'abc123def456',
      'html_url': 'https://github.com/owner/repo/actions/runs/12345678',
      'path': '.github/workflows/tests-pr.yaml',
      'status': 'completed',
      'conclusion': 'success',
      'run_started_at': '2024-06-01T10:30:00Z',
      'updated_at': '2024-06-01T10:45:00Z',
    };

    test(
      'fromJson parses all fields',
      timeout: const Timeout.factor(2),
      () {
        final run = GitHubWorkflowRun.fromJson(fullJson);

        expect(run.id, 12345678);
        expect(run.name, 'Tests (Pull Request)');
        expect(run.checkSuiteId, 98765);
        expect(run.headSha, 'abc123def456');
        expect(run.htmlUrl, 'https://github.com/owner/repo/actions/runs/12345678');
        expect(run.path, '.github/workflows/tests-pr.yaml');
        expect(run.status, 'completed');
        expect(run.conclusion, 'success');
        expect(run.runStartedAt, DateTime.parse('2024-06-01T10:30:00Z'));
        expect(run.updatedAt, DateTime.parse('2024-06-01T10:45:00Z'));
      },
    );

    test(
      'fromJson handles missing optional fields',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'id': 1,
          'name': 'CI',
          'check_suite_id': 2,
          'head_sha': 'sha',
          'html_url': 'url',
          'path': 'path',
          'status': 'queued',
        };
        final run = GitHubWorkflowRun.fromJson(json);

        expect(run.conclusion, isNull);
        expect(run.runStartedAt, isNull);
        expect(run.updatedAt, isNull);
      },
    );

    test(
      'fromJson handles null and missing required fields with defaults',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{};
        final run = GitHubWorkflowRun.fromJson(json);

        expect(run.id, 0);
        expect(run.name, '');
        expect(run.checkSuiteId, 0);
        expect(run.headSha, '');
        expect(run.htmlUrl, '');
        expect(run.path, '');
        expect(run.status, '');
      },
    );

    test(
      'fromJson handles null values for required fields',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'id': null,
          'name': null,
          'check_suite_id': null,
          'head_sha': null,
          'html_url': null,
          'path': null,
          'status': null,
        };
        final run = GitHubWorkflowRun.fromJson(json);

        expect(run.id, 0);
        expect(run.name, '');
        expect(run.checkSuiteId, 0);
        expect(run.headSha, '');
        expect(run.htmlUrl, '');
        expect(run.path, '');
        expect(run.status, '');
      },
    );

    test(
      'toJson serializes all fields',
      timeout: const Timeout.factor(2),
      () {
        final run = GitHubWorkflowRun(
          id: 42,
          name: 'Build',
          checkSuiteId: 100,
          headSha: 'deadbeef',
          htmlUrl: 'https://github.com/o/r/actions/runs/42',
          path: '.github/workflows/build.yaml',
          status: 'in_progress',
          conclusion: null,
          runStartedAt: DateTime.parse('2024-01-01T00:00:00Z'),
          updatedAt: DateTime.parse('2024-01-01T00:10:00Z'),
        );
        final json = run.toJson();

        expect(json['id'], 42);
        expect(json['name'], 'Build');
        expect(json['check_suite_id'], 100);
        expect(json['head_sha'], 'deadbeef');
        expect(json['html_url'], 'https://github.com/o/r/actions/runs/42');
        expect(json['path'], '.github/workflows/build.yaml');
        expect(json['status'], 'in_progress');
        expect(json['conclusion'], isNull);
        expect(json['run_started_at'], '2024-01-01T00:00:00.000Z');
        expect(json['updated_at'], '2024-01-01T00:10:00.000Z');
      },
    );

    test(
      'toJson handles nullable dates as null',
      timeout: const Timeout.factor(2),
      () {
        const run = GitHubWorkflowRun(
          id: 1,
          name: 'Lint',
          checkSuiteId: 2,
          headSha: 'sha',
          htmlUrl: 'url',
          path: 'path',
          status: 'queued',
          runStartedAt: null,
          updatedAt: null,
        );
        final json = run.toJson();

        expect(json['run_started_at'], isNull);
        expect(json['updated_at'], isNull);
      },
    );

    test(
      'fromJson toJson round-trip',
      timeout: const Timeout.factor(2),
      () {
        final original = GitHubWorkflowRun(
          id: 999,
          name: 'Deploy',
          checkSuiteId: 888,
          headSha: 'cafe1234',
          htmlUrl: 'https://github.com/o/r/actions/runs/999',
          path: '.github/workflows/deploy.yaml',
          status: 'completed',
          conclusion: 'failure',
          runStartedAt: DateTime.parse('2024-03-15T12:00:00Z'),
          updatedAt: DateTime.parse('2024-03-15T12:30:00Z'),
        );
        final json = original.toJson();
        final restored = GitHubWorkflowRun.fromJson(json);

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
      },
    );

    test(
      'status parses all known GitHub Actions status values',
      timeout: const Timeout.factor(2),
      () {
        const statuses = ['queued', 'in_progress', 'completed'];
        for (final status in statuses) {
          final run = GitHubWorkflowRun(
            id: 1,
            name: 'Test',
            checkSuiteId: 1,
            headSha: '',
            htmlUrl: '',
            path: '',
            status: status,
          );
          expect(run.status, status);
        }
      },
    );

    test(
      'conclusion parses all known GitHub Actions conclusion values',
      timeout: const Timeout.factor(2),
      () {
        const conclusions = [
          'success',
          'failure',
          'cancelled',
          'timed_out',
          'action_required',
          'neutral',
          'skipped',
        ];
        for (final conclusion in conclusions) {
          final run = GitHubWorkflowRun(
            id: 1,
            name: '',
            checkSuiteId: 0,
            headSha: '',
            htmlUrl: '',
            path: '',
            status: 'completed',
            conclusion: conclusion,
          );
          expect(run.conclusion, conclusion);
        }
      },
    );
  });
}
