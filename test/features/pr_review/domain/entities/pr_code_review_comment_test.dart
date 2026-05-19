import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 5, 18, 9, 0);
  const user = PrUser(login: 'reviewer', avatarUrl: 'https://avat.ar/r');

  PrCodeReviewComment createComment({
    int id = 1,
    String body = 'Please fix this',
    PrUser? userParam,
    String path = 'src/main.dart',
    int? position = 5,
    DateTime? createdAt,
    String side = 'RIGHT',
    int? inReplyToId,
    int? startLine,
    String diffHunk = '',
    int? line = 10,
    int? originalLine = 8,
  }) {
    return PrCodeReviewComment(
      id: id,
      body: body,
      user: userParam ?? user,
      path: path,
      position: position,
      createdAt: createdAt ?? now,
      side: side,
      inReplyToId: inReplyToId,
      startLine: startLine,
      diffHunk: diffHunk,
      line: line,
      originalLine: originalLine,
    );
  }

  group('PrCodeReviewComment constructor', () {
    test('creates instance with all fields', () {
      final comment = PrCodeReviewComment(
        id: 42,
        body: 'Consider using a const',
        user: user,
        path: 'lib/app.dart',
        position: 3,
        createdAt: now,
        side: 'LEFT',
        inReplyToId: 10,
        startLine: 1,
        diffHunk: '@@ -1,2 +1,3 @@',
        line: 5,
        originalLine: 4,
      );

      expect(comment.id, 42);
      expect(comment.body, 'Consider using a const');
      expect(comment.user, user);
      expect(comment.path, 'lib/app.dart');
      expect(comment.position, 3);
      expect(comment.createdAt, now);
      expect(comment.side, 'LEFT');
      expect(comment.inReplyToId, 10);
      expect(comment.startLine, 1);
      expect(comment.diffHunk, '@@ -1,2 +1,3 @@');
      expect(comment.line, 5);
      expect(comment.originalLine, 4);
    });

    test('default values for optional fields', () {
      const comment = PrCodeReviewComment(
        id: 1,
        body: '',
        user: null,
        path: '',
        position: null,
        createdAt: null,
      );
      expect(comment.side, 'RIGHT');
      expect(comment.inReplyToId, isNull);
      expect(comment.startLine, isNull);
      expect(comment.diffHunk, '');
      expect(comment.line, isNull);
      expect(comment.originalLine, isNull);
    });

    test('is const constructable', () {
      const comment = PrCodeReviewComment(
        id: 1,
        body: '',
        user: null,
        path: '',
        position: null,
        createdAt: null,
      );
      expect(comment.id, 1);
    });
  });

  group('PrCodeReviewComment computed properties', () {
    test('anchorLine returns line when line is set', () {
      final comment = createComment(line: 10, originalLine: 8);
      expect(comment.anchorLine, 10);
    });

    test('anchorLine returns originalLine when line is null', () {
      final comment = createComment(line: null, originalLine: 8);
      expect(comment.anchorLine, 8);
    });

    test('anchorLine returns null when both are null', () {
      final comment = createComment(line: null, originalLine: null);
      expect(comment.anchorLine, isNull);
    });
  });

  group('PrCodeReviewComment == and hashCode', () {
    test('identical comments are equal', () {
      final a = createComment();
      final b = createComment();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      final a = createComment(id: 1);
      final b = createComment(id: 2);
      expect(a, isNot(equals(b)));
    });

    test('same id but different body are equal (identity by id)', () {
      final a = createComment(id: 1, body: 'A');
      final b = createComment(id: 1, body: 'B');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('self equality', () {
      final a = createComment();
      expect(a, equals(a));
    });
  });
}
