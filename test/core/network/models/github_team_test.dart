import 'package:cc_infra/src/network/models/github_team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubTeam', () {
    test('fromJson parses name and slug', timeout: const Timeout.factor(2), () {
      final json = <String, dynamic>{
        'name': 'Frontend Platform',
        'slug': 'frontend-platform',
      };
      final team = GitHubTeam.fromJson(json);

      expect(team.name, 'Frontend Platform');
      expect(team.slug, 'frontend-platform');
    });

    test(
      'fromJson uses slug as name when name is empty',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{'name': '', 'slug': 'my-team'};
        final team = GitHubTeam.fromJson(json);

        expect(team.name, 'my-team');
        expect(team.slug, 'my-team');
      },
    );

    test(
      'fromJson uses slug as name when name is null',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{'name': null, 'slug': 'platform-team'};
        final team = GitHubTeam.fromJson(json);

        expect(team.name, 'platform-team');
        expect(team.slug, 'platform-team');
      },
    );

    test(
      'fromJson handles both null fields',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{};
        final team = GitHubTeam.fromJson(json);

        // Empty slug falls back to '', and name (empty) also falls back to slug ('')
        expect(team.name, '');
        expect(team.slug, '');
      },
    );

    test(
      'toJson serializes name and slug',
      timeout: const Timeout.factor(2),
      () {
        const team = GitHubTeam(name: 'Backend Team', slug: 'backend-team');
        final json = team.toJson();

        expect(json['name'], 'Backend Team');
        expect(json['slug'], 'backend-team');
      },
    );

    test('fromJson toJson round-trip', timeout: const Timeout.factor(2), () {
      const original = GitHubTeam(name: 'DevOps', slug: 'devops');
      final json = original.toJson();
      final restored = GitHubTeam.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.slug, original.slug);
      expect(restored.avatarUrl, original.avatarUrl);
    });

    test('fromJson synthesizes the CDN avatar URL from numeric id', () {
      final team = GitHubTeam.fromJson(const {
        'name': 'Eng',
        'slug': 'eng',
        'id': 42,
      });
      expect(team.avatarUrl, 'https://avatars.githubusercontent.com/t/42');
    });

    test('fromJson prefers explicit avatar_url over id', () {
      final team = GitHubTeam.fromJson(const {
        'name': 'Eng',
        'slug': 'eng',
        'id': 42,
        'avatar_url': 'https://avatars.githubusercontent.com/t/99',
      });
      expect(team.avatarUrl, 'https://avatars.githubusercontent.com/t/99');
    });

    test('fromJson reads GraphQL avatarUrl', () {
      final team = GitHubTeam.fromJson(const {
        'name': 'Eng',
        'slug': 'eng',
        'avatarUrl': 'https://avatars.githubusercontent.com/t/7',
      });
      expect(team.avatarUrl, 'https://avatars.githubusercontent.com/t/7');
    });

    test('fromJson synthesizes the CDN URL from GraphQL databaseId', () {
      final team = GitHubTeam.fromJson(const {
        'name': 'Eng',
        'slug': 'eng',
        'databaseId': 11,
      });
      expect(team.avatarUrl, 'https://avatars.githubusercontent.com/t/11');
    });

    test('fromJson parses a string numeric id', () {
      final team = GitHubTeam.fromJson(const {
        'name': 'Eng',
        'slug': 'eng',
        'id': '8',
      });
      expect(team.avatarUrl, 'https://avatars.githubusercontent.com/t/8');
    });
  });
}
