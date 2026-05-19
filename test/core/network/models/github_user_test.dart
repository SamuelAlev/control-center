import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubUser', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'login': 'octocat',
        'avatar_url': 'https://avatars.githubusercontent.com/u/1?v=4',
      };
      final user = GitHubUser.fromJson(json);
      expect(user.login, 'octocat');
      expect(user.avatarUrl, 'https://avatars.githubusercontent.com/u/1?v=4');
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final user = GitHubUser.fromJson(json);
      expect(user.login, '');
      expect(user.avatarUrl, '');
    });

    test('fromJson handles null values', () {
      final json = <String, dynamic>{'login': null, 'avatar_url': null};
      final user = GitHubUser.fromJson(json);
      expect(user.login, '');
      expect(user.avatarUrl, '');
    });

    test('toJson serializes all fields', () {
      const user = GitHubUser(
        login: 'octocat',
        avatarUrl: 'https://example.com/avatar.png',
      );
      final json = user.toJson();
      expect(json['login'], 'octocat');
      expect(json['avatar_url'], 'https://example.com/avatar.png');
    });

    test('fromJson toJson round-trip', () {
      const original = GitHubUser(
        login: 'testuser',
        avatarUrl: 'https://example.com/avatar.png',
      );
      final json = original.toJson();
      final restored = GitHubUser.fromJson(json);
      expect(restored.login, original.login);
      expect(restored.avatarUrl, original.avatarUrl);
    });

    test('fromJson toJson round-trip with empty strings', () {
      const original = GitHubUser(login: '', avatarUrl: '');
      final json = original.toJson();
      final restored = GitHubUser.fromJson(json);
      expect(restored.login, '');
      expect(restored.avatarUrl, '');
    });

    test('loginWithName matches formatGitHubLoginWithName', () {
      const user = GitHubUser(
        login: 'octocat',
        avatarUrl: '',
        name: 'The Octocat',
      );
      expect(user.loginWithName, 'octocat (The Octocat)');
    });
  });

  group('formatGitHubLoginWithName', () {
    test('appends name in parentheses when it differs from login', () {
      expect(
        formatGitHubLoginWithName('octocat', 'The Octocat'),
        'octocat (The Octocat)',
      );
    });

    test('omits empty, whitespace, or identical names', () {
      expect(formatGitHubLoginWithName('octocat', null), 'octocat');
      expect(formatGitHubLoginWithName('octocat', ''), 'octocat');
      expect(formatGitHubLoginWithName('octocat', '  '), 'octocat');
      expect(formatGitHubLoginWithName('octocat', 'Octocat'), 'octocat');
    });
  });

  group('isGitHubBotLogin', () {
    test('is true for GitHub App bot logins', () {
      expect(isGitHubBotLogin('renovate[bot]'), isTrue);
      expect(isGitHubBotLogin('dependabot[bot]'), isTrue);
      expect(isGitHubBotLogin('github-actions[bot]'), isTrue);
      expect(isGitHubBotLogin('codecov[bot]'), isTrue);
    });

    test('is case-insensitive on the suffix', () {
      expect(isGitHubBotLogin('Renovate[BOT]'), isTrue);
    });

    test('is false for human logins', () {
      expect(isGitHubBotLogin('octocat'), isFalse);
      expect(isGitHubBotLogin('renovate'), isFalse);
      expect(isGitHubBotLogin(''), isFalse);
    });
  });
}
