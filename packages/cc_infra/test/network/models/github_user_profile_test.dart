import 'package:cc_infra/src/network/models/github_user_profile.dart';
import 'package:test/test.dart';

/// Round-trips the GitHub user-profile DTOs against their wire shapes — these
/// feed the `github.userProfile` RPC op, so the GraphQL `fromJson` and the
/// flat `toWire`/`fromWire` pair must agree.
void main() {
  group('GitHubContributionDay / Week', () {
    test('parses counts + dates and round-trips toJson', () {
      final day = GitHubContributionDay.fromJson({
        'contributionCount': 7,
        'date': '2026-01-02',
      });
      expect(day.contributionCount, 7);
      expect(day.date, DateTime.parse('2026-01-02'));
      final json = day.toJson();
      expect(json['contributionCount'], 7);
      expect(json['date'], day.date.toIso8601String());
    });

    test('tolerates a missing contributionCount (defaults to 0)', () {
      final day = GitHubContributionDay.fromJson({'date': '2026-01-02'});
      expect(day.contributionCount, 0);
    });

    test('week parses its days', () {
      final week = GitHubContributionWeek.fromJson({
        'contributionDays': [
          {'contributionCount': 1, 'date': '2026-01-01'},
          {'contributionCount': 2, 'date': '2026-01-02'},
        ],
      });
      expect(week.contributionDays.map((d) => d.contributionCount), [1, 2]);
    });

    test('week toJson round-trips', () {
      final week = GitHubContributionWeek.fromJson({
        'contributionDays': [
          {'contributionCount': 5, 'date': '2026-01-01'},
        ],
      });
      final json = week.toJson();
      expect(json['contributionDays'] as List, hasLength(1));
    });
  });

  group('GitHubContributionCalendar', () {
    test('fromJson decodes totals + weeks', () {
      final cal = GitHubContributionCalendar.fromJson({
        'totalContributions': 100,
        'weeks': [
          {
            'contributionDays': [
              {'contributionCount': 1, 'date': '2026-01-01'},
            ],
          },
        ],
      }, restrictedContributions: 5);
      expect(cal.totalContributions, 100);
      expect(cal.restrictedContributions, 5);
      expect(cal.grandTotal, 105);
      expect(cal.weeks.single.contributionDays.single.contributionCount, 1);
    });

    test('toJson round-trips through fromJson', () {
      final cal = GitHubContributionCalendar(
        totalContributions: 10,
        restrictedContributions: 2,
        weeks: [
          GitHubContributionWeek(
            contributionDays: [
              GitHubContributionDay(
                contributionCount: 3,
                date: DateTime(2026, 1, 1),
              ),
            ],
          ),
        ],
      );
      final decoded = GitHubContributionCalendar.fromJson(
        cal.toJson(),
        restrictedContributions: cal.restrictedContributions,
      );
      expect(decoded.totalContributions, 10);
      expect(decoded.restrictedContributions, 2);
      expect(decoded.weeks.single.contributionDays.single.contributionCount, 3);
    });

    test('tolerates a non-list weeks field', () {
      final cal = GitHubContributionCalendar.fromJson({
        'totalContributions': 1,
      });
      expect(cal.weeks, isEmpty);
    });
  });

  group('GitHubOrganization', () {
    test('parses + toWire round-trips', () {
      final org = GitHubOrganization.fromJson({
        'login': 'acme',
        'name': 'Acme Inc',
        'avatarUrl': 'a',
        'url': 'https://acme.com',
      });
      expect(org.login, 'acme');
      final wire = org.toWire();
      expect(wire['login'], 'acme');
      expect(GitHubOrganization.fromJson(wire).name, 'Acme Inc');
    });

    test('tolerates missing fields (defaults to empty strings)', () {
      final org = GitHubOrganization.fromJson({});
      expect(org.login, '');
      expect(org.name, '');
    });
  });

  group('GitHubUserStatus', () {
    test('parses isBusy + optional fields', () {
      final s = GitHubUserStatus.fromJson({
        'indicatesLimitedAvailability': true,
        'message': 'ooo',
        'emoji': '🌴',
      });
      expect(s.isBusy, isTrue);
      expect(s.message, 'ooo');
      expect(s.emoji, '🌴');
    });

    test('toWire/fromJson round-trips a busy status', () {
      const s = GitHubUserStatus(isBusy: true, message: 'away', emoji: '🏖');
      final decoded = GitHubUserStatus.fromJson(s.toWire());
      expect(decoded.isBusy, isTrue);
      expect(decoded.message, 'away');
      expect(decoded.emoji, '🏖');
    });

    test('toWire omits null message/emoji via ?-spread', () {
      final wire = const GitHubUserStatus(isBusy: false).toWire();
      expect(wire['indicatesLimitedAvailability'], false);
      expect(wire.containsKey('message'), isFalse);
      expect(wire.containsKey('emoji'), isFalse);
    });
  });

  group('GitHubUserProfile.fromJson (GraphQL shape)', () {
    test('parses a full profile', () {
      final p = GitHubUserProfile.fromJson({
        'login': 'sam',
        'name': 'Sam',
        'avatarUrl': 'a',
        'bio': 'hi',
        'location': 'Earth',
        'company': 'Acme',
        'websiteUrl': 'https://x',
        'twitterUsername': 'sam',
        'status': {'indicatesLimitedAvailability': false, 'emoji': '🟢'},
        'organizations': {
          'nodes': [
            {
              'login': 'acme',
              'name': 'Acme',
              'avatarUrl': 'a',
              'url': 'u',
              'teams': {
                'nodes': [
                  {'name': 'Frontend platform', 'slug': 'frontend-platform'},
                  {'name': 'Brand Fundamentals', 'slug': 'brand-fundamentals'},
                ],
              },
            },
            {'login': '', 'name': 'skipped'}, // empty login filtered
          ],
        },
        'contributionsCollection': {
          'restrictedContributionsCount': 4,
          'contributionCalendar': {'totalContributions': 50, 'weeks': []},
        },
      });
      expect(p.login, 'sam');
      expect(p.status?.emoji, '🟢');
      expect(p.organizations.single.login, 'acme');
      // orgTeams now flattens the team names across the user's orgs.
      expect(p.orgTeams, ['Frontend platform', 'Brand Fundamentals']);
      expect(p.contributionCalendar?.grandTotal, 54);
    });

    test('tolerates missing nested structures', () {
      final p = GitHubUserProfile.fromJson({'login': 'x', 'name': 'X'});
      expect(p.status, isNull);
      expect(p.organizations, isEmpty);
      expect(p.contributionCalendar, isNull);
    });

    test('status only decoded when it is a Map<String,dynamic>', () {
      final p = GitHubUserProfile.fromJson({'status': 'busy'});
      expect(p.status, isNull);
    });
  });

  group('GitHubUserProfile wire round-trip', () {
    test('toWire → fromWire round-trips the flat RPC shape', () {
      const original = GitHubUserProfile(
        login: 'sam',
        name: 'Sam',
        avatarUrl: 'a',
        bio: 'b',
        location: 'l',
        company: 'c',
        websiteUrl: 'w',
        twitterUsername: 't',
        status: GitHubUserStatus(isBusy: true),
        organizations: [
          GitHubOrganization(
            login: 'acme',
            name: 'Acme',
            avatarUrl: 'a',
            url: 'u',
          ),
        ],
        orgTeams: ['acme'],
        contributionCalendar: GitHubContributionCalendar(
          totalContributions: 9,
          restrictedContributions: 1,
          weeks: [],
        ),
      );
      final wire = original.toWire();
      // snake_case keys for the RPC op.
      expect(wire['avatar_url'], 'a');
      expect(wire['website_url'], 'w');
      expect(wire['twitter_username'], 't');
      expect(wire['contribution_calendar'], isA<Map>());
      final decoded = GitHubUserProfile.fromWire(wire);
      expect(decoded.login, 'sam');
      expect(decoded.bio, 'b');
      expect(decoded.status?.isBusy, isTrue);
      expect(decoded.organizations.single.login, 'acme');
      expect(decoded.orgTeams, ['acme']);
      expect(decoded.contributionCalendar?.grandTotal, 10);
    });

    test('fromWire tolerates missing nested fields', () {
      final p = GitHubUserProfile.fromWire({'login': 'x'});
      expect(p.login, 'x');
      expect(p.status, isNull);
      expect(p.organizations, isEmpty);
      expect(p.orgTeams, isEmpty);
      expect(p.contributionCalendar, isNull);
    });
  });
}
