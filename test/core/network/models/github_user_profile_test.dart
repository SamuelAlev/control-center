import 'package:control_center/core/network/models/github_user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubContributionDay', () {
    test(
      'fromJson parses all fields',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'contributionCount': 5,
          'date': '2024-01-15T00:00:00Z',
        };
        final day = GitHubContributionDay.fromJson(json);

        expect(day.contributionCount, 5);
        expect(day.date, DateTime.parse('2024-01-15T00:00:00Z'));
      },
    );

    test(
      'fromJson defaults contributionCount to 0 when null',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'contributionCount': null,
          'date': '2024-01-15T00:00:00Z',
        };
        final day = GitHubContributionDay.fromJson(json);
        expect(day.contributionCount, 0);
      },
    );

    test(
      'toJson round-trip',
      timeout: const Timeout.factor(2),
      () {
        final day = GitHubContributionDay(
          contributionCount: 3,
          date: DateTime.parse('2024-06-01T00:00:00Z'),
        );
        final json = day.toJson();
        final restored = GitHubContributionDay.fromJson(json);

        expect(restored.contributionCount, 3);
        expect(restored.date, day.date);
      },
    );
  });

  group('GitHubContributionWeek', () {
    test(
      'fromJson parses contributionDays',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'contributionDays': [
            {'contributionCount': 2, 'date': '2024-01-15T00:00:00Z'},
            {'contributionCount': 0, 'date': '2024-01-16T00:00:00Z'},
          ],
        };
        final week = GitHubContributionWeek.fromJson(json);

        expect(week.contributionDays.length, 2);
        expect(week.contributionDays[0].contributionCount, 2);
        expect(week.contributionDays[1].contributionCount, 0);
      },
    );

    test(
      'fromJson handles null contributionDays',
      timeout: const Timeout.factor(2),
      () {
        final week = GitHubContributionWeek.fromJson({});
        expect(week.contributionDays, isEmpty);
      },
    );

    test(
      'toJson round-trip',
      timeout: const Timeout.factor(2),
      () {
        final week = GitHubContributionWeek(
          contributionDays: [
            GitHubContributionDay(
              contributionCount: 1,
              date: DateTime.parse('2024-03-01T00:00:00Z'),
            ),
          ],
        );
        final json = week.toJson();
        final restored = GitHubContributionWeek.fromJson(json);

        expect(restored.contributionDays.length, 1);
        expect(restored.contributionDays[0].contributionCount, 1);
      },
    );
  });

  group('GitHubContributionCalendar', () {
    test(
      'fromJson parses totalContributions and weeks',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'totalContributions': 365,
          'weeks': [
            {
              'contributionDays': [
                {'contributionCount': 5, 'date': '2024-01-01T00:00:00Z'},
              ],
            },
          ],
        };
        final cal = GitHubContributionCalendar.fromJson(
          json,
          restrictedContributions: 10,
        );

        expect(cal.totalContributions, 365);
        expect(cal.restrictedContributions, 10);
        expect(cal.grandTotal, 375);
        expect(cal.weeks.length, 1);
        expect(cal.weeks[0].contributionDays[0].contributionCount, 5);
      },
    );

    test(
      'grandTotal sums contributions correctly',
      timeout: const Timeout.factor(2),
      () {
        const cal = GitHubContributionCalendar(
          totalContributions: 100,
          restrictedContributions: 50,
          weeks: [],
        );
        expect(cal.grandTotal, 150);
      },
    );

    test(
      'toJson round-trip',
      timeout: const Timeout.factor(2),
      () {
        const cal = GitHubContributionCalendar(
          totalContributions: 200,
          restrictedContributions: 25,
          weeks: [],
        );
        final json = cal.toJson();
        final restored = GitHubContributionCalendar.fromJson(
          json,
          restrictedContributions: 25,
        );

        expect(restored.totalContributions, 200);
        expect(restored.restrictedContributions, 25);
        expect(restored.weeks, isEmpty);
      },
    );
  });

  group('GitHubOrganization', () {
    test(
      'fromJson parses all fields',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'login': 'my-org',
          'name': 'My Organization',
          'avatarUrl': 'https://example.com/org.png',
          'url': 'https://github.com/my-org',
        };
        final org = GitHubOrganization.fromJson(json);

        expect(org.login, 'my-org');
        expect(org.name, 'My Organization');
        expect(org.avatarUrl, 'https://example.com/org.png');
        expect(org.url, 'https://github.com/my-org');
      },
    );

    test(
      'fromJson handles null fields',
      timeout: const Timeout.factor(2),
      () {
        final org = GitHubOrganization.fromJson({});

        expect(org.login, '');
        expect(org.name, '');
        expect(org.avatarUrl, '');
        expect(org.url, '');
      },
    );
  });

  group('GitHubUserStatus', () {
    test(
      'fromJson parses all fields',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'indicatesLimitedAvailability': true,
          'message': 'On vacation',
          'emoji': ':palm_tree:',
        };
        final status = GitHubUserStatus.fromJson(json);

        expect(status.isBusy, true);
        expect(status.message, 'On vacation');
        expect(status.emoji, ':palm_tree:');
      },
    );

    test(
      'fromJson handles null fields',
      timeout: const Timeout.factor(2),
      () {
        final status = GitHubUserStatus.fromJson({});

        expect(status.isBusy, false);
        expect(status.message, isNull);
        expect(status.emoji, isNull);
      },
    );
  });

  group('GitHubUserProfile', () {
    final fullJson = <String, dynamic>{
      'login': 'octocat',
      'name': 'Octocat',
      'avatarUrl': 'https://example.com/avatar.png',
      'bio': 'I love coding',
      'location': 'San Francisco',
      'company': 'GitHub',
      'websiteUrl': 'https://octocat.dev',
      'twitterUsername': 'octocat',
      'status': {
        'indicatesLimitedAvailability': false,
        'message': 'Working',
        'emoji': ':computer:',
      },
      'organizations': {
        'nodes': [
          {
            'login': 'github',
            'name': 'GitHub',
            'avatarUrl': 'https://example.com/github.png',
            'url': 'https://github.com/github',
          },
          {
            'login': 'opensource',
            'name': 'Open Source',
            'avatarUrl': 'https://example.com/oss.png',
            'url': 'https://github.com/opensource',
          },
        ],
      },
      'contributionsCollection': {
        'restrictedContributionsCount': 15,
        'contributionCalendar': {
          'totalContributions': 500,
          'weeks': [
            {
              'contributionDays': [
                {'contributionCount': 10, 'date': '2024-06-01T00:00:00Z'},
              ],
            },
          ],
        },
      },
    };

    test(
      'fromJson parses all fields',
      timeout: const Timeout.factor(2),
      () {
        final profile = GitHubUserProfile.fromJson(fullJson);

        expect(profile.login, 'octocat');
        expect(profile.name, 'Octocat');
        expect(profile.avatarUrl, 'https://example.com/avatar.png');
        expect(profile.bio, 'I love coding');
        expect(profile.location, 'San Francisco');
        expect(profile.company, 'GitHub');
        expect(profile.websiteUrl, 'https://octocat.dev');
        expect(profile.twitterUsername, 'octocat');
      },
    );

    test(
      'fromJson parses status',
      timeout: const Timeout.factor(2),
      () {
        final profile = GitHubUserProfile.fromJson(fullJson);

        expect(profile.status, isNotNull);
        expect(profile.status!.isBusy, false);
        expect(profile.status!.message, 'Working');
        expect(profile.status!.emoji, ':computer:');
      },
    );

    test(
      'fromJson parses organizations',
      timeout: const Timeout.factor(2),
      () {
        final profile = GitHubUserProfile.fromJson(fullJson);

        expect(profile.organizations.length, 2);
        expect(profile.organizations[0].login, 'github');
        expect(profile.organizations[1].login, 'opensource');
      },
    );

    test(
      'fromJson parses orgTeams',
      timeout: const Timeout.factor(2),
      () {
        final profile = GitHubUserProfile.fromJson(fullJson);

        expect(profile.orgTeams, ['github', 'opensource']);
      },
    );

    test(
      'fromJson parses contributionCalendar',
      timeout: const Timeout.factor(2),
      () {
        final profile = GitHubUserProfile.fromJson(fullJson);

        expect(profile.contributionCalendar, isNotNull);
        expect(profile.contributionCalendar!.totalContributions, 500);
        expect(profile.contributionCalendar!.restrictedContributions, 15);
        expect(profile.contributionCalendar!.grandTotal, 515);
        expect(profile.contributionCalendar!.weeks.length, 1);
      },
    );

    test(
      'fromJson handles minimal JSON with null fields',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'login': 'minimal',
          'name': null,
          'avatarUrl': null,
        };
        final profile = GitHubUserProfile.fromJson(json);

        expect(profile.login, 'minimal');
        expect(profile.name, '');
        expect(profile.avatarUrl, '');
        expect(profile.bio, isNull);
        expect(profile.location, isNull);
        expect(profile.company, isNull);
        expect(profile.websiteUrl, isNull);
        expect(profile.twitterUsername, isNull);
        expect(profile.status, isNull);
        expect(profile.organizations, isEmpty);
        expect(profile.orgTeams, isEmpty);
        expect(profile.contributionCalendar, isNull);
      },
    );

    test(
      'fromJson handles completely empty JSON',
      timeout: const Timeout.factor(2),
      () {
        final profile = GitHubUserProfile.fromJson({});

        expect(profile.login, '');
        expect(profile.name, '');
        expect(profile.avatarUrl, '');
        expect(profile.bio, isNull);
        expect(profile.organizations, isEmpty);
        expect(profile.contributionCalendar, isNull);
      },
    );

    test(
      'fromJson filters organizations with empty login',
      timeout: const Timeout.factor(2),
      () {
        final json = <String, dynamic>{
          'login': 'test',
          'name': 'Test',
          'avatarUrl': '',
          'organizations': {
            'nodes': [
              {'login': '', 'name': 'Empty', 'avatarUrl': '', 'url': ''},
              {'login': 'valid-org', 'name': 'Valid', 'avatarUrl': '', 'url': ''},
            ],
          },
        };
        final profile = GitHubUserProfile.fromJson(json);

        expect(profile.organizations.length, 1);
        expect(profile.organizations[0].login, 'valid-org');
      },
    );

    test(
      'constructor creates profile directly',
      timeout: const Timeout.factor(2),
      () {
        const profile = GitHubUserProfile(
          login: 'direct',
          name: 'Direct User',
          avatarUrl: 'https://example.com/direct.png',
          bio: 'A bio',
          location: 'NYC',
        );

        expect(profile.login, 'direct');
        expect(profile.name, 'Direct User');
        expect(profile.bio, 'A bio');
        expect(profile.location, 'NYC');
        expect(profile.organizations, isEmpty);
        expect(profile.contributionCalendar, isNull);
      },
    );
  });
}
