import 'package:cc_infra/src/network/models/github_user.dart';
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

    test('const constructor works', () {
      const user = GitHubUser(login: 'test', avatarUrl: 'url');
      expect(user.login, 'test');
    });
  });
}
