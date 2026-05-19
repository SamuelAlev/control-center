import 'package:cc_infra/src/network/models/github_issue_comment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubIssueComment', () {
    final baseJson = <String, dynamic>{
      'id': 54321,
      'body': 'Great work on this PR!',
      'user': <String, dynamic>{
        'login': 'commenter1',
        'avatar_url': 'https://avatars.githubusercontent.com/u/5?v=4',
      },
      'created_at': '2024-01-15T10:00:00Z',
      'updated_at': '2024-01-16T12:00:00Z',
    };

    test('fromJson parses all fields', () {
      final comment = GitHubIssueComment.fromJson(baseJson);
      expect(comment.id, 54321);
      expect(comment.body, 'Great work on this PR!');
      expect(comment.user, isNotNull);
      expect(comment.user!.login, 'commenter1');
      expect(comment.createdAt, isNotNull);
      expect(comment.updatedAt, isNotNull);
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final comment = GitHubIssueComment.fromJson(json);
      expect(comment.id, 0);
      expect(comment.body, '');
      expect(comment.user, isNull);
      expect(comment.createdAt, isNull);
      expect(comment.updatedAt, isNull);
    });

    test('fromJson handles null user', () {
      final json = <String, dynamic>{
        'id': 1,
        'body': 'Anonymous comment',
        'user': null,
      };
      final comment = GitHubIssueComment.fromJson(json);
      expect(comment.body, 'Anonymous comment');
      expect(comment.user, isNull);
    });

    test('fromJson handles markdown body', () {
      final json = <String, dynamic>{
        'id': 2,
        'body': '## Summary\n\nThis is a **markdown** comment.',
        'user': null,
      };
      final comment = GitHubIssueComment.fromJson(json);
      expect(comment.body, contains('## Summary'));
      expect(comment.body, contains('**markdown**'));
    });

    test('toJson serializes all fields', () {
      final comment = GitHubIssueComment.fromJson(baseJson);
      final json = comment.toJson();
      expect(json['id'], 54321);
      expect(json['body'], 'Great work on this PR!');
      expect(json['user'], isA<Map<String, dynamic>>());
      expect(json['created_at'], isA<String>());
      expect(json['updated_at'], isA<String>());
    });

    test('toJson handles null fields', () {
      const comment = GitHubIssueComment(id: 99, body: 'Just a comment');
      final json = comment.toJson();
      expect(json['id'], 99);
      expect(json['body'], 'Just a comment');
      expect(json['user'], isNull);
      expect(json['created_at'], isNull);
      expect(json['updated_at'], isNull);
    });

    test('fromJson toJson round-trip', () {
      const comment = GitHubIssueComment(id: 42, body: 'Hello World');
      final json = comment.toJson();
      final restored = GitHubIssueComment.fromJson(json);
      expect(restored.id, comment.id);
      expect(restored.body, comment.body);
      expect(restored.user, comment.user);
      expect(restored.createdAt, comment.createdAt);
      expect(restored.updatedAt, comment.updatedAt);
    });

    test('fromJson toJson round-trip with user', () {
      final original = GitHubIssueComment.fromJson(baseJson);
      final json = original.toJson();
      final restored = GitHubIssueComment.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.body, original.body);
      expect(restored.user?.login, original.user?.login);
    });

    test('fromJson handles id as double', () {
      final json = <String, dynamic>{'id': 99.0, 'body': 'double id test'};
      final comment = GitHubIssueComment.fromJson(json);
      expect(comment.id, 99);
    });

    test('fromJson handles empty body', () {
      final json = <String, dynamic>{'id': 1, 'body': ''};
      final comment = GitHubIssueComment.fromJson(json);
      expect(comment.body, '');
    });

    test('toJson with dates preserves ISO strings', () {
      final date = DateTime(2024, 6, 15, 10, 30);
      final comment = GitHubIssueComment(
        id: 1,
        body: 'test',
        createdAt: date,
        updatedAt: date,
      );
      final json = comment.toJson();
      expect(json['created_at'], date.toIso8601String());
      expect(json['updated_at'], date.toIso8601String());
    });
  });
}
