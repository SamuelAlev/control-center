import 'package:control_center/core/network/models/github_review_comment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubReviewComment', () {
    final baseJson = <String, dynamic>{
      'id': 98765,
      'body': 'Please consider using a guard clause here.',
      'path': 'src/utils/helpers.dart',
      'diff_hunk': '@@ -10,5 +10,7 @@\n context\n- old\n+ new\n context',
      'line': 12,
      'original_line': 12,
      'start_line': 10,
      'side': 'RIGHT',
      'in_reply_to_id': null,
      'user': <String, dynamic>{
        'login': 'commenter',
        'avatar_url': 'https://avatars.githubusercontent.com/u/3?v=4',
      },
      'created_at': '2024-01-15T10:00:00Z',
      'updated_at': '2024-01-16T12:00:00Z',
    };

    test('fromJson parses all fields', () {
      final comment = GitHubReviewComment.fromJson(baseJson);
      expect(comment.id, 98765);
      expect(comment.body, 'Please consider using a guard clause here.');
      expect(comment.path, 'src/utils/helpers.dart');
      expect(
        comment.diffHunk,
        '@@ -10,5 +10,7 @@\n context\n- old\n+ new\n context',
      );
      expect(comment.line, 12);
      expect(comment.originalLine, 12);
      expect(comment.startLine, 10);
      expect(comment.side, 'RIGHT');
      expect(comment.inReplyToId, isNull);
      expect(comment.user, isNotNull);
      expect(comment.user!.login, 'commenter');
      expect(comment.createdAt, isNotNull);
      expect(comment.updatedAt, isNotNull);
    });

    test('anchorLine returns line when set', () {
      final comment = GitHubReviewComment.fromJson(baseJson);
      expect(comment.anchorLine, 12);
    });

    test('anchorLine falls back to originalLine', () {
      final json = <String, dynamic>{
        'id': 1,
        'body': 'test',
        'path': 'file.dart',
        'diff_hunk': '',
        'line': null,
        'original_line': 45,
      };
      final comment = GitHubReviewComment.fromJson(json);
      expect(comment.anchorLine, 45);
    });

    test('anchorLine returns null when both are null', () {
      final json = <String, dynamic>{
        'id': 1,
        'body': '',
        'path': '',
        'diff_hunk': '',
      };
      final comment = GitHubReviewComment.fromJson(json);
      expect(comment.anchorLine, isNull);
    });

    test('fromJson handles LEFT side', () {
      final json = Map<String, dynamic>.from(baseJson)..['side'] = 'LEFT';
      final comment = GitHubReviewComment.fromJson(json);
      expect(comment.side, 'LEFT');
    });

    test('fromJson handles reply comment', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['in_reply_to_id'] = 54321;
      final comment = GitHubReviewComment.fromJson(json);
      expect(comment.inReplyToId, 54321);
    });

    test('fromJson handles missing fields', () {
      final json = <String, dynamic>{};
      final comment = GitHubReviewComment.fromJson(json);
      expect(comment.id, 0);
      expect(comment.body, '');
      expect(comment.path, '');
      expect(comment.diffHunk, '');
      expect(comment.line, isNull);
      expect(comment.originalLine, isNull);
      expect(comment.startLine, isNull);
      expect(comment.side, 'RIGHT');
      expect(comment.inReplyToId, isNull);
      expect(comment.user, isNull);
      expect(comment.createdAt, isNull);
      expect(comment.updatedAt, isNull);
    });

    test('toJson serializes all fields', () {
      final comment = GitHubReviewComment.fromJson(baseJson);
      final json = comment.toJson();
      expect(json['id'], 98765);
      expect(json['body'], 'Please consider using a guard clause here.');
      expect(json['path'], 'src/utils/helpers.dart');
      expect(
        json['diff_hunk'],
        '@@ -10,5 +10,7 @@\n context\n- old\n+ new\n context',
      );
      expect(json['line'], 12);
      expect(json['original_line'], 12);
      expect(json['start_line'], 10);
      expect(json['side'], 'RIGHT');
      expect(json['user'], isA<Map<String, dynamic>>());
    });

    test('toJson handles null fields', () {
      const comment = GitHubReviewComment(
        id: 1,
        body: '',
        path: '',
        diffHunk: '',
      );
      final json = comment.toJson();
      expect(json['id'], 1);
      expect(json['line'], isNull);
      expect(json['original_line'], isNull);
      expect(json['start_line'], isNull);
      expect(json['in_reply_to_id'], isNull);
      expect(json['user'], isNull);
    });

    test('fromJson toJson round-trip', () {
      const comment = GitHubReviewComment(
        id: 42,
        body: 'Nice code',
        path: 'src/main.dart',
        diffHunk: '@@ -1,1 +1,1 @@',
        line: 5,
        originalLine: 5,
        startLine: 3,
        side: 'RIGHT',
        inReplyToId: 10,
      );
      final json = comment.toJson();
      final restored = GitHubReviewComment.fromJson(json);
      expect(restored.id, comment.id);
      expect(restored.body, comment.body);
      expect(restored.path, comment.path);
      expect(restored.diffHunk, comment.diffHunk);
      expect(restored.line, comment.line);
      expect(restored.originalLine, comment.originalLine);
      expect(restored.startLine, comment.startLine);
      expect(restored.side, comment.side);
      expect(restored.inReplyToId, comment.inReplyToId);
    });

    test('anchorLine prefers originalLine when line is null', () {
      final json = <String, dynamic>{
        'id': 1,
        'body': 't',
        'path': 'f.dart',
        'diff_hunk': '',
        'line': null,
        'original_line': 10,
        'start_line': 8,
      };
      final comment = GitHubReviewComment.fromJson(json);
      expect(comment.anchorLine, 10);
      expect(comment.startLine, 8);
    });

    test('fromJson handles side default when null', () {
      final json = <String, dynamic>{
        'id': 1,
        'body': '',
        'path': '',
        'diff_hunk': '',
        'side': null,
      };
      final comment = GitHubReviewComment.fromJson(json);
      expect(comment.side, 'RIGHT');
    });

    test('fromJson handles line/startLine as doubles', () {
      final json = <String, dynamic>{
        'id': 1,
        'body': '',
        'path': '',
        'diff_hunk': '',
        'line': 10.0,
        'original_line': 8.0,
        'start_line': 5.0,
        'in_reply_to_id': 99.0,
      };
      final comment = GitHubReviewComment.fromJson(json);
      expect(comment.line, 10);
      expect(comment.originalLine, 8);
      expect(comment.startLine, 5);
      expect(comment.inReplyToId, 99);
    });

    test('toJson with dates preserves ISO strings', () {
      final date = DateTime(2024, 6, 15, 10, 30);
      final comment = GitHubReviewComment(
        id: 1,
        body: '',
        path: '',
        diffHunk: '',
        createdAt: date,
        updatedAt: date,
      );
      final json = comment.toJson();
      expect(json['created_at'], date.toIso8601String());
      expect(json['updated_at'], date.toIso8601String());
    });
  });
}
