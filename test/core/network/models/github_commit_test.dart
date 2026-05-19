// ignore_for_file: avoid_dynamic_calls

import 'package:control_center/core/network/models/github_commit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubCommit', () {
    final baseJson = <String, dynamic>{
      'sha': 'abc123def456abc123def456abc123def456abc1',
      'commit': <String, dynamic>{
        'message': 'feat: add new feature\n\nDetailed body text',
        'author': <String, dynamic>{
          'name': 'Dev User',
          'email': 'dev@example.com',
          'date': '2024-01-15T10:00:00Z',
        },
      },
      'author': <String, dynamic>{
        'login': 'devuser',
        'avatar_url': 'https://avatars.githubusercontent.com/u/1?v=4',
      },
    };

    test('fromJson parses all fields', () {
      final commit = GitHubCommit.fromJson(baseJson);
      expect(commit.sha, 'abc123def456abc123def456abc123def456abc1');
      expect(commit.message, 'feat: add new feature\n\nDetailed body text');
      expect(commit.authorName, 'Dev User');
      expect(commit.authorEmail, 'dev@example.com');
      expect(commit.author, isNotNull);
      expect(commit.author!.login, 'devuser');
      expect(commit.committedAt, isNotNull);
      expect(commit.committedAt!.year, 2024);
    });

    test('shortSha returns first 7 characters', () {
      final commit = GitHubCommit.fromJson(baseJson);
      expect(commit.shortSha, 'abc123d');
    });

    test('shortSha returns full sha if shorter than 7', () {
      const commit = GitHubCommit(
        sha: 'abc12',
        message: '',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.shortSha, 'abc12');
    });

    test('title returns first line of message', () {
      final commit = GitHubCommit.fromJson(baseJson);
      expect(commit.title, 'feat: add new feature');
    });

    test('title returns full message when no newline', () {
      const commit = GitHubCommit(
        sha: 'a',
        message: 'single line message',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.title, 'single line message');
    });

    test('bodyText returns message after first line', () {
      final commit = GitHubCommit.fromJson(baseJson);
      expect(commit.bodyText, 'Detailed body text');
    });

    test('bodyText returns empty when no body', () {
      const commit = GitHubCommit(
        sha: 'a',
        message: 'title only',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.bodyText, '');
    });

    test('bodyText strips surrounding whitespace after extracting body', () {
      const commit = GitHubCommit(
        sha: 'a',
        message: 'title\n\n  body with spaces  \n',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.bodyText, 'body with spaces');
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final commit = GitHubCommit.fromJson(json);
      expect(commit.sha, '');
      expect(commit.message, '');
      expect(commit.authorName, '');
      expect(commit.authorEmail, '');
      expect(commit.author, isNull);
      expect(commit.committedAt, isNull);
    });

    test('fromJson handles null commit and author', () {
      final json = <String, dynamic>{
        'sha': 'abc123',
        'commit': null,
        'author': null,
      };
      final commit = GitHubCommit.fromJson(json);
      expect(commit.sha, 'abc123');
      expect(commit.message, '');
      expect(commit.author, isNull);
    });

    test('fromJson handles null commit author', () {
      final json = <String, dynamic>{
        'sha': 'abc',
        'commit': <String, dynamic>{'message': 'msg', 'author': null},
      };
      final commit = GitHubCommit.fromJson(json);
      expect(commit.authorName, '');
      expect(commit.authorEmail, '');
    });

    test('toJson serializes all fields', () {
      final commit = GitHubCommit.fromJson(baseJson);
      final json = commit.toJson();
      expect(json['sha'], 'abc123def456abc123def456abc123def456abc1');
      expect(json['commit'], isA<Map<String, dynamic>>());
      expect(
        json['commit']['message'],
        'feat: add new feature\n\nDetailed body text',
      );
      expect(json['commit']['author']['name'], 'Dev User');
      expect(json['commit']['author']['email'], 'dev@example.com');
      expect(json['author']['login'], 'devuser');
    });

    test('fromJson toJson round-trip', () {
      const commit = GitHubCommit(
        sha: 'abcdef1234567890abcdef1234567890abcdef',
        message: 'fix: resolve bug',
        authorName: 'Tester',
        authorEmail: 'test@test.com',
      );
      final json = commit.toJson();
      final restored = GitHubCommit.fromJson(json);
      expect(restored.sha, commit.sha);
      expect(restored.message, commit.message);
      expect(restored.authorName, commit.authorName);
      expect(restored.authorEmail, commit.authorEmail);
    });

    test('toJson handles null fields', () {
      const commit = GitHubCommit(
        sha: 'abc',
        message: '',
        authorName: '',
        authorEmail: '',
      );
      final json = commit.toJson();
      expect(json['sha'], 'abc');
      expect(json['author'], isNull);
    });

    test('bodyText handles message with only newlines', () {
      const commit = GitHubCommit(
        sha: 'a',
        message: '\n\n\n',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.bodyText, '');
    });

    test('title handles message with leading newline', () {
      const commit = GitHubCommit(
        sha: 'a',
        message: '\nbody here',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.title, '');
    });

    test('shortSha handles exactly 7 characters', () {
      const commit = GitHubCommit(
        sha: 'abcdefg',
        message: '',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.shortSha, 'abcdefg');
    });

    test('shortSha handles 8 characters', () {
      const commit = GitHubCommit(
        sha: 'abcdefgh',
        message: '',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.shortSha, 'abcdefg');
    });

    test('shortSha handles single character', () {
      const commit = GitHubCommit(
        sha: 'a',
        message: '',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.shortSha, 'a');
    });

    test('fromJson handles author nested field but null', () {
      final json = <String, dynamic>{
        'sha': 'abc',
        'commit': <String, dynamic>{
          'message': 'msg',
          'author': <String, dynamic>{
            'name': null,
            'email': null,
            'date': null,
          },
        },
      };
      final commit = GitHubCommit.fromJson(json);
      expect(commit.authorName, '');
      expect(commit.authorEmail, '');
      expect(commit.committedAt, isNull);
    });

    test('toJson with committedAt preserves ISO string', () {
      final date = DateTime(2024, 6, 15, 10, 30);
      final commit = GitHubCommit(
        sha: 'abc',
        message: 'fix',
        authorName: 'Dev',
        authorEmail: 'dev@t.com',
        committedAt: date,
      );
      final json = commit.toJson();
      expect(json['commit']['author']['date'], date.toIso8601String());
    });

    test('bodyText trims trailing whitespace properly', () {
      const commit = GitHubCommit(
        sha: 'a',
        message: 'title\n  body with spaces  \n  \n',
        authorName: '',
        authorEmail: '',
      );
      expect(commit.bodyText, 'body with spaces');
    });
  });
}
