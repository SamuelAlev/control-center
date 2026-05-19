import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 5, 18, 9, 0);
  const user = PrUser(login: 'commenter', avatarUrl: 'https://avat.ar/c');

  IssueComment createComment({
    int id = 1,
    String body = 'Looks good to me',
    PrUser? userParam,
    DateTime? createdAt,
  }) {
    return IssueComment(
      id: id,
      body: body,
      user: userParam ?? user,
      createdAt: createdAt ?? now,
    );
  }

  group('IssueComment constructor', () {
    test('creates instance with all fields', () {
      final comment = IssueComment(
        id: 100,
        body: 'Great work!',
        user: user,
        createdAt: now,
      );
      expect(comment.id, 100);
      expect(comment.body, 'Great work!');
      expect(comment.user, user);
      expect(comment.createdAt, now);
    });

    test('allows nullable user and createdAt', () {
      const comment = IssueComment(
        id: 1,
        body: 'Bot comment',
        user: null,
        createdAt: null,
      );
      expect(comment.user, isNull);
      expect(comment.createdAt, isNull);
    });

    test('is const constructable', () {
      const comment = IssueComment(
        id: 1,
        body: '',
        user: null,
        createdAt: null,
      );
      expect(comment.id, 1);
      expect(comment.body, '');
    });
  });

  group('IssueComment == and hashCode', () {
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

    test('same id but different user are equal (identity by id)', () {
      final a = createComment(id: 1, userParam: const PrUser(login: 'a', avatarUrl: ''));
      final b = createComment(id: 1, userParam: const PrUser(login: 'b', avatarUrl: ''));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('self equality', () {
      final a = createComment();
      expect(a, equals(a));
    });
  });
}
