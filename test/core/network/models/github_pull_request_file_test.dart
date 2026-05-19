import 'package:cc_infra/src/network/models/github_pull_request_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubPullRequestFile', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'filename': 'src/main.dart',
        'status': 'modified',
        'additions': 10,
        'deletions': 5,
        'changes': 15,
        'patch': '@@ -1,3 +1,4 @@\n context\n+added',
        'previous_filename': null,
        'sha': 'abc123',
        'blob_url': 'https://github.com/owner/repo/blob/abc123/src/main.dart',
      };
      final file = GitHubPullRequestFile.fromJson(json);
      expect(file.filename, 'src/main.dart');
      expect(file.status, 'modified');
      expect(file.additions, 10);
      expect(file.deletions, 5);
      expect(file.changes, 15);
      expect(file.patch, '@@ -1,3 +1,4 @@\n context\n+added');
      expect(file.previousFilename, isNull);
      expect(file.sha, 'abc123');
      expect(
        file.blobUrl,
        'https://github.com/owner/repo/blob/abc123/src/main.dart',
      );
    });

    test('extension getter extracts file extension', () {
      const file = GitHubPullRequestFile(
        filename: 'src/main.dart',
        status: 'modified',
        additions: 1,
        deletions: 0,
        changes: 1,
        patch: '',
      );
      expect(file.extension, 'dart');
    });

    test('extension getter handles TypeScript file', () {
      const file = GitHubPullRequestFile(
        filename: 'src/components/App.tsx',
        status: 'modified',
        additions: 1,
        deletions: 0,
        changes: 1,
        patch: '',
      );
      expect(file.extension, 'tsx');
    });

    test('extension getter handles file without extension', () {
      const file = GitHubPullRequestFile(
        filename: 'Dockerfile',
        status: 'added',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
      );
      expect(file.extension, '');
    });

    test('extension getter handles file ending with dot', () {
      const file = GitHubPullRequestFile(
        filename: 'mystery.',
        status: 'modified',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
      );
      expect(file.extension, '');
    });

    test('extension getter lowercases extension', () {
      const file = GitHubPullRequestFile(
        filename: 'src/MAIN.DART',
        status: 'modified',
        additions: 1,
        deletions: 0,
        changes: 1,
        patch: '',
      );
      expect(file.extension, 'dart');
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final file = GitHubPullRequestFile.fromJson(json);
      expect(file.filename, '');
      expect(file.status, '');
      expect(file.additions, 0);
      expect(file.deletions, 0);
      expect(file.changes, 0);
      expect(file.patch, '');
      expect(file.sha, '');
      expect(file.blobUrl, '');
    });

    test('toJson serializes all fields', () {
      const file = GitHubPullRequestFile(
        filename: 'lib/app.dart',
        status: 'added',
        additions: 20,
        deletions: 0,
        changes: 20,
        patch: '@@ -0,0 +1,20 @@',
        previousFilename: 'lib/old_app.dart',
        sha: 'def456',
        blobUrl: 'https://example.com/blob',
      );
      final json = file.toJson();
      expect(json['filename'], 'lib/app.dart');
      expect(json['status'], 'added');
      expect(json['additions'], 20);
      expect(json['deletions'], 0);
      expect(json['changes'], 20);
      expect(json['patch'], '@@ -0,0 +1,20 @@');
      expect(json['previous_filename'], 'lib/old_app.dart');
      expect(json['sha'], 'def456');
      expect(json['blob_url'], 'https://example.com/blob');
    });

    test('fromJson toJson round-trip', () {
      const file = GitHubPullRequestFile(
        filename: 'src/main.rs',
        status: 'renamed',
        additions: 15,
        deletions: 3,
        changes: 18,
        patch: '@@ -5,4 +5,6 @@',
        previousFilename: 'src/old_main.rs',
        sha: '789abc',
        blobUrl: 'https://example.com/blob/789abc',
      );
      final json = file.toJson();
      final restored = GitHubPullRequestFile.fromJson(json);
      expect(restored.filename, file.filename);
      expect(restored.status, file.status);
      expect(restored.additions, file.additions);
      expect(restored.deletions, file.deletions);
      expect(restored.changes, file.changes);
      expect(restored.patch, file.patch);
      expect(restored.previousFilename, file.previousFilename);
      expect(restored.sha, file.sha);
      expect(restored.blobUrl, file.blobUrl);
    });

    test('fromJson handles null previous_filename', () {
      final json = <String, dynamic>{
        'filename': 'test.dart',
        'status': 'added',
        'additions': 1,
        'deletions': 0,
        'changes': 1,
        'patch': '',
        'previous_filename': null,
      };
      final file = GitHubPullRequestFile.fromJson(json);
      expect(file.previousFilename, isNull);
    });

    test('extension getter handles deeply nested path', () {
      const file = GitHubPullRequestFile(
        filename: 'a/b/c/d/e/f/g/h/i/file.ext',
        status: 'modified',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
      );
      expect(file.extension, 'ext');
    });

    test('extension getter handles dotfile', () {
      const file = GitHubPullRequestFile(
        filename: '.gitignore',
        status: 'modified',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
      );
      expect(file.extension, 'gitignore');
    });

    test('extension getter handles file with multiple dots', () {
      const file = GitHubPullRequestFile(
        filename: 'test.min.dart',
        status: 'modified',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
      );
      expect(file.extension, 'dart');
    });

    test('extension getter handles hidden directory file', () {
      const file = GitHubPullRequestFile(
        filename: '.github/workflows/ci.yml',
        status: 'modified',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
      );
      expect(file.extension, 'yml');
    });

    test('fromJson handles additions/deletions/changes as doubles', () {
      final json = <String, dynamic>{
        'filename': 'test.dart',
        'status': 'modified',
        'additions': 10.0,
        'deletions': 5.0,
        'changes': 15.0,
        'patch': '',
      };
      final file = GitHubPullRequestFile.fromJson(json);
      expect(file.additions, 10);
      expect(file.deletions, 5);
      expect(file.changes, 15);
    });

    test('fromJson handles missing additions/deletions/changes as null', () {
      final json = <String, dynamic>{
        'filename': 'test.dart',
        'status': 'modified',
        'additions': null,
        'deletions': null,
        'changes': null,
        'patch': '',
      };
      final file = GitHubPullRequestFile.fromJson(json);
      expect(file.additions, 0);
      expect(file.deletions, 0);
      expect(file.changes, 0);
    });

    test('toJson with all null fields', () {
      const file = GitHubPullRequestFile(
        filename: '',
        status: '',
        additions: 0,
        deletions: 0,
        changes: 0,
        patch: '',
        previousFilename: null,
        sha: '',
        blobUrl: '',
      );
      final json = file.toJson();
      expect(json['filename'], '');
      expect(json['previous_filename'], isNull);
    });
  });
}
