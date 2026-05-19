import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubCliStatus constructor', () {
    test('creates with all default false/empty', () {
      const status = GitHubCliStatus();
      expect(status.isInstalled, isFalse);
      expect(status.isAuthenticated, isFalse);
      expect(status.username, '');
      expect(status.token, '');
    });

    test('creates with all fields populated', () {
      const status = GitHubCliStatus(
        isInstalled: true,
        isAuthenticated: true,
        username: 'octocat',
        token: 'ghp_secret',
      );
      expect(status.isInstalled, isTrue);
      expect(status.isAuthenticated, isTrue);
      expect(status.username, 'octocat');
      expect(status.token, 'ghp_secret');
    });

    test('creates installed but not authenticated', () {
      const status = GitHubCliStatus(
        isInstalled: true,
        isAuthenticated: false,
      );
      expect(status.isInstalled, isTrue);
      expect(status.isAuthenticated, isFalse);
    });
  });

  group('GitHubCliStatus == and hashCode', () {
    test('identical statuses are equal', () {
      const a = GitHubCliStatus(
        isInstalled: true,
        isAuthenticated: true,
        username: 'octocat',
        token: 'xyz',
      );
      const b = GitHubCliStatus(
        isInstalled: true,
        isAuthenticated: true,
        username: 'octocat',
        token: 'xyz',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different isInstalled makes unequal', () {
      const a = GitHubCliStatus(isInstalled: true);
      const b = GitHubCliStatus(isInstalled: false);
      expect(a, isNot(equals(b)));
    });

    test('different username makes unequal', () {
      const a = GitHubCliStatus(username: 'user1');
      const b = GitHubCliStatus(username: 'user2');
      expect(a, isNot(equals(b)));
    });

    test('different token makes unequal', () {
      const a = GitHubCliStatus(token: 'tok1');
      const b = GitHubCliStatus(token: 'tok2');
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      const a = GitHubCliStatus(isInstalled: true);
      expect(a, equals(a));
    });
  });

  group('GitHubCliStatus copyWith', () {
    test('returns new instance with updated isInstalled', () {
      const status = GitHubCliStatus();
      final updated = status.copyWith(isInstalled: true);
      expect(updated.isInstalled, isTrue);
      expect(updated.isAuthenticated, isFalse);
    });

    test('returns new instance with updated username and token', () {
      const status = GitHubCliStatus();
      final updated = status.copyWith(
        username: 'new_user',
        token: 'new_token',
      );
      expect(updated.username, 'new_user');
      expect(updated.token, 'new_token');
    });

    test('copyWith without changes returns equal status', () {
      const status = GitHubCliStatus(isInstalled: true, username: 'test');
      final updated = status.copyWith();
      expect(updated, equals(status));
    });
  });

  group('GitHubCliStatus toString', () {
    test('masks token value', () {
      const status = GitHubCliStatus(token: 'secret_token');
      expect(status.toString(), contains('****'));
      expect(status.toString(), isNot(contains('secret_token')));
    });

    test('includes isInstalled and isAuthenticated', () {
      const status = GitHubCliStatus(
        isInstalled: true,
        isAuthenticated: false,
        username: 'dev',
      );
      final str = status.toString();
      expect(str, contains('isInstalled: true'));
      expect(str, contains('isAuthenticated: false'));
      expect(str, contains('username: dev'));
    });
  });
}
