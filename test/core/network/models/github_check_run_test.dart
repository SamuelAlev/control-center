// ignore_for_file: avoid_dynamic_calls

import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubCheckStatus', () {
    test('has all expected values', () {
      expect(GitHubCheckStatus.values.length, 4);
      expect(GitHubCheckStatus.values, contains(GitHubCheckStatus.queued));
      expect(GitHubCheckStatus.values, contains(GitHubCheckStatus.inProgress));
      expect(GitHubCheckStatus.values, contains(GitHubCheckStatus.completed));
      expect(GitHubCheckStatus.values, contains(GitHubCheckStatus.unknown));
    });
  });

  group('GitHubCheckConclusion', () {
    test('has all expected values', () {
      expect(GitHubCheckConclusion.values.length, 9);
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.success),
      );
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.failure),
      );
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.neutral),
      );
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.cancelled),
      );
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.timedOut),
      );
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.actionRequired),
      );
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.skipped),
      );
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.stale),
      );
      expect(
        GitHubCheckConclusion.values,
        contains(GitHubCheckConclusion.none),
      );
    });
  });

  group('GitHubCheckRun', () {
    final baseJson = <String, dynamic>{
      'id': 123456,
      'name': 'build-and-test',
      'status': 'completed',
      'conclusion': 'success',
      'app': <String, dynamic>{'name': 'GitHub Actions'},
      'html_url': 'https://github.com/owner/repo/runs/123456',
      'started_at': '2024-01-15T10:00:00Z',
      'completed_at': '2024-01-15T10:05:00Z',
      'output': <String, dynamic>{
        'title': 'All tests passed',
        'summary': '42 tests passed, 0 failed',
        'text': 'Detailed log...',
      },
    };

    test('fromJson parses completed success check', () {
      final check = GitHubCheckRun.fromJson(baseJson);
      expect(check.id, 123456);
      expect(check.name, 'build-and-test');
      expect(check.status, GitHubCheckStatus.completed);
      expect(check.conclusion, GitHubCheckConclusion.success);
      expect(check.appName, 'GitHub Actions');
      expect(check.htmlUrl, 'https://github.com/owner/repo/runs/123456');
      expect(check.startedAt, isNotNull);
      expect(check.completedAt, isNotNull);
      expect(check.output, '42 tests passed, 0 failed');
      expect(check.outputTitle, 'All tests passed');
    });

    test('isComplete returns true for completed status', () {
      final check = GitHubCheckRun.fromJson(baseJson);
      expect(check.isComplete, true);
    });

    test('isComplete returns false for in_progress', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'test',
        'status': 'in_progress',
        'conclusion': null,
        'app': null,
        'html_url': '',
      };
      final check = GitHubCheckRun.fromJson(json);
      expect(check.isComplete, false);
    });

    test('isFailing returns true for failure', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['conclusion'] = 'failure';
      final check = GitHubCheckRun.fromJson(json);
      expect(check.isFailing, true);
    });

    test('isFailing returns true for timed_out', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['conclusion'] = 'timed_out';
      final check = GitHubCheckRun.fromJson(json);
      expect(check.isFailing, true);
    });

    test('isFailing returns true for action_required', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['conclusion'] = 'action_required';
      final check = GitHubCheckRun.fromJson(json);
      expect(check.isFailing, true);
    });

    test('isFailing returns false for success', () {
      final check = GitHubCheckRun.fromJson(baseJson);
      expect(check.isFailing, false);
    });

    test('isSuccess returns true for success conclusion', () {
      final check = GitHubCheckRun.fromJson(baseJson);
      expect(check.isSuccess, true);
    });

    test('isSuccess returns false for neutral', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['conclusion'] = 'neutral';
      final check = GitHubCheckRun.fromJson(json);
      expect(check.isSuccess, false);
    });

    test('fromJson parses queued status', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'lint',
        'status': 'queued',
        'conclusion': null,
        'app': null,
        'html_url': '',
      };
      final check = GitHubCheckRun.fromJson(json);
      expect(check.status, GitHubCheckStatus.queued);
    });

    test('fromJson parses in_progress status', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'lint',
        'status': 'in_progress',
        'conclusion': null,
        'app': null,
        'html_url': '',
      };
      final check = GitHubCheckRun.fromJson(json);
      expect(check.status, GitHubCheckStatus.inProgress);
    });

    test('fromJson parses all conclusions', () {
      final conclusions = {
        'success': GitHubCheckConclusion.success,
        'failure': GitHubCheckConclusion.failure,
        'neutral': GitHubCheckConclusion.neutral,
        'cancelled': GitHubCheckConclusion.cancelled,
        'timed_out': GitHubCheckConclusion.timedOut,
        'action_required': GitHubCheckConclusion.actionRequired,
        'skipped': GitHubCheckConclusion.skipped,
        'stale': GitHubCheckConclusion.stale,
      };
      for (final entry in conclusions.entries) {
        final json = <String, dynamic>{
          'id': 1,
          'name': 'test',
          'status': 'completed',
          'conclusion': entry.key,
          'app': null,
          'html_url': '',
        };
        final check = GitHubCheckRun.fromJson(json);
        expect(check.conclusion, entry.value);
      }
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final check = GitHubCheckRun.fromJson(json);
      expect(check.id, 0);
      expect(check.name, '');
      expect(check.status, GitHubCheckStatus.unknown);
      expect(check.conclusion, GitHubCheckConclusion.none);
      expect(check.appName, '');
      expect(check.htmlUrl, '');
      expect(check.startedAt, isNull);
      expect(check.completedAt, isNull);
      expect(check.output, '');
      expect(check.outputTitle, '');
    });

    test('fromJson handles null output with text fallback', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'test',
        'status': 'completed',
        'conclusion': 'success',
        'app': null,
        'html_url': '',
        'output': <String, dynamic>{
          'title': null,
          'summary': null,
          'text': 'Text output',
        },
      };
      final check = GitHubCheckRun.fromJson(json);
      expect(check.output, 'Text output');
    });

    test('toJson serializes all fields', () {
      final check = GitHubCheckRun.fromJson(baseJson);
      final json = check.toJson();
      expect(json['id'], 123456);
      expect(json['name'], 'build-and-test');
      expect(json['status'], 'completed');
      expect(json['conclusion'], 'success');
      expect(json['app'], isA<Map<String, dynamic>>());
      expect(json['app']['name'], 'GitHub Actions');
      expect(json['html_url'], 'https://github.com/owner/repo/runs/123456');
      expect(json['output'], isA<Map<String, dynamic>>());
    });

    test('toJson handles null status', () {
      const check = GitHubCheckRun(
        id: 1,
        name: '',
        status: GitHubCheckStatus.unknown,
        conclusion: GitHubCheckConclusion.none,
        appName: '',
        htmlUrl: '',
      );
      final json = check.toJson();
      expect(json['status'], isNull);
      expect(json['conclusion'], isNull);
    });

    test('fromJson toJson round-trip', () {
      const check = GitHubCheckRun(
        id: 42,
        name: 'typecheck',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.success,
        appName: 'CI',
        htmlUrl: 'https://example.com',
        output: 'All good',
        outputTitle: 'Success',
      );
      final json = check.toJson();
      final restored = GitHubCheckRun.fromJson(json);
      expect(restored.id, check.id);
      expect(restored.name, check.name);
      expect(restored.status, check.status);
      expect(restored.conclusion, check.conclusion);
      expect(restored.appName, check.appName);
      expect(restored.htmlUrl, check.htmlUrl);
      expect(restored.output, check.output);
      expect(restored.outputTitle, check.outputTitle);
    });

    test('isFailing returns true for action_required conclusion', () {
      const check = GitHubCheckRun(
        id: 1,
        name: 'test',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.actionRequired,
        appName: '',
        htmlUrl: '',
      );
      expect(check.isFailing, true);
    });

    test('isFailing returns false for skipped conclusion', () {
      const check = GitHubCheckRun(
        id: 1,
        name: 'test',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.skipped,
        appName: '',
        htmlUrl: '',
      );
      expect(check.isFailing, false);
    });

    test('isFailing returns false for stale conclusion', () {
      const check = GitHubCheckRun(
        id: 1,
        name: 'test',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.stale,
        appName: '',
        htmlUrl: '',
      );
      expect(check.isFailing, false);
    });

    test('isSuccess returns true only for success', () {
      const success = GitHubCheckRun(
        id: 1,
        name: '',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.success,
        appName: '',
        htmlUrl: '',
      );
      const neutral = GitHubCheckRun(
        id: 2,
        name: '',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.neutral,
        appName: '',
        htmlUrl: '',
      );
      expect(success.isSuccess, true);
      expect(neutral.isSuccess, false);
    });

    test('fromJson handles output with only text field', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'test',
        'status': 'completed',
        'conclusion': 'success',
        'app': null,
        'html_url': '',
        'output': <String, dynamic>{'text': 'Only text output'},
      };
      final check = GitHubCheckRun.fromJson(json);
      expect(check.output, 'Only text output');
      expect(check.outputTitle, '');
    });

    test('fromJson handles output as null', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': 'test',
        'status': 'completed',
        'conclusion': 'success',
        'app': null,
        'html_url': '',
        'output': null,
      };
      final check = GitHubCheckRun.fromJson(json);
      expect(check.output, '');
      expect(check.outputTitle, '');
    });

    test('toJson with dates preserves ISO strings', () {
      final started = DateTime(2024, 1, 15, 10, 0);
      final completed = DateTime(2024, 1, 15, 10, 5);
      final check = GitHubCheckRun(
        id: 1,
        name: 'ci',
        status: GitHubCheckStatus.completed,
        conclusion: GitHubCheckConclusion.success,
        appName: 'Actions',
        htmlUrl: '',
        startedAt: started,
        completedAt: completed,
        output: 'ok',
        outputTitle: 'Passed',
      );
      final json = check.toJson();
      expect(json['started_at'], started.toIso8601String());
      expect(json['completed_at'], completed.toIso8601String());
    });

    test('fromJson handles queued and in_progress status', () {
      expect(
        GitHubCheckRun.fromJson(<String, dynamic>{
          'id': 1,
          'name': '',
          'status': 'queued',
          'conclusion': null,
          'app': null,
          'html_url': '',
        }).status,
        GitHubCheckStatus.queued,
      );
      expect(
        GitHubCheckRun.fromJson(<String, dynamic>{
          'id': 1,
          'name': '',
          'status': 'in_progress',
          'conclusion': null,
          'app': null,
          'html_url': '',
        }).status,
        GitHubCheckStatus.inProgress,
      );
    });

    test('fromJson handles unknown status', () {
      final check = GitHubCheckRun.fromJson(<String, dynamic>{
        'id': 1,
        'name': '',
        'status': 'something_weird',
        'conclusion': null,
        'app': null,
        'html_url': '',
      });
      expect(check.status, GitHubCheckStatus.unknown);
    });

    test('fromJson handles unknown conclusion', () {
      final check = GitHubCheckRun.fromJson(<String, dynamic>{
        'id': 1,
        'name': '',
        'status': 'completed',
        'conclusion': 'something_weird',
        'app': null,
        'html_url': '',
      });
      expect(check.conclusion, GitHubCheckConclusion.none);
    });
  });
}
