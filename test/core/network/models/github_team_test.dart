import 'package:cc_infra/src/network/models/github_team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubTeam', () {
    test(
      'fromJson parses name and slug',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'name': 'Frontend Platform',
          'slug': 'frontend-platform',
        };
        final team = GitHubTeam.fromJson(json);

        expect(team.name, 'Frontend Platform');
        expect(team.slug, 'frontend-platform');
      },
    );

    test(
      'fromJson uses slug as name when name is empty',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'name': '',
          'slug': 'my-team',
        };
        final team = GitHubTeam.fromJson(json);

        expect(team.name, 'my-team');
        expect(team.slug, 'my-team');
      },
    );

    test(
      'fromJson uses slug as name when name is null',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'name': null,
          'slug': 'platform-team',
        };
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

    test(
      'fromJson toJson round-trip',
      timeout: const Timeout.factor(2),
      () {
        const original = GitHubTeam(name: 'DevOps', slug: 'devops');
        final json = original.toJson();
        final restored = GitHubTeam.fromJson(json);

        expect(restored.name, original.name);
        expect(restored.slug, original.slug);
      },
    );

    test(
      'const constructor',
      timeout: const Timeout.factor(2),
      () {
        const team = GitHubTeam(name: 'Core', slug: 'core');
        expect(team.name, 'Core');
        expect(team.slug, 'core');
      },
    );
  });
}
