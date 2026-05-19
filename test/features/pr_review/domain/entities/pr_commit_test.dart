import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 5, 18, 9, 0);
  const author = PrUser(login: 'dev', avatarUrl: '');

  PrCommit createCommit({
    String sha = 'abc123def456',
    String message = 'Fix bug',
    PrUser? authorParam,
    DateTime? date,
  }) {
    return PrCommit(
      sha: sha,
      message: message,
      author: authorParam ?? author,
      date: date ?? now,
    );
  }

  group('PrCommit constructor', () {
    test('creates instance with all fields', () {
      final commit = createCommit();
      expect(commit.sha, 'abc123def456');
      expect(commit.message, 'Fix bug');
      expect(commit.author, author);
      expect(commit.date, now);
    });

    test('allows nullable author and date', () {
      const commit = PrCommit(
        sha: 'sha',
        message: 'msg',
        author: null,
        date: null,
      );
      expect(commit.author, isNull);
      expect(commit.date, isNull);
    });

    test('is const constructable', () {
      const commit = PrCommit(
        sha: 'abc',
        message: 'msg',
        author: PrUser(login: 'x', avatarUrl: ''),
        date: null,
      );
      expect(commit.sha, 'abc');
    });
  });

  group('PrCommit computed properties', () {
    test('shortSha returns first 7 chars', () {
      expect(createCommit(sha: 'abcdef1234567890').shortSha, 'abcdef1');
    });

    test('shortSha returns full sha when shorter than 7', () {
      expect(createCommit(sha: 'abc').shortSha, 'abc');
    });

    test('shortSha returns full sha when exactly 7', () {
      expect(createCommit(sha: 'abcdefg').shortSha, 'abcdefg');
    });

    test('title returns full message when single line', () {
      expect(createCommit(message: 'feat: add widget').title, 'feat: add widget');
    });

    test('title returns first line when multi-line', () {
      expect(
        createCommit(message: 'feat: add widget\n\nDetails here').title,
        'feat: add widget',
      );
    });

    test('title returns first line with only newline separator', () {
      expect(
        createCommit(message: 'Line1\nLine2\nLine3').title,
        'Line1',
      );
    });
  });

  group('PrCommit == and hashCode', () {
    test('identical commits are equal', () {
      final a = createCommit();
      final b = createCommit();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different sha makes unequal', () {
      final a = createCommit(sha: 'aaa');
      final b = createCommit(sha: 'bbb');
      expect(a, isNot(equals(b)));
    });

    test('same sha but different message are equal (identity by sha)', () {
      final a = createCommit(sha: 'sha', message: 'A');
      final b = createCommit(sha: 'sha', message: 'B');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('self equality', () {
      final a = createCommit();
      expect(a, equals(a));
    });
  });
}
