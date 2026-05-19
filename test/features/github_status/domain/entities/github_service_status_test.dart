import 'package:control_center/features/github_status/domain/entities/github_service_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubStatusIndicator', () {
    group('fromApi', () {
      test('parses none', timeout: const Timeout.factor(2), () {
        expect(GitHubStatusIndicator.fromApi('none'), GitHubStatusIndicator.none);
      });

      test('parses minor', timeout: const Timeout.factor(2), () {
        expect(GitHubStatusIndicator.fromApi('minor'), GitHubStatusIndicator.minor);
      });

      test('parses major', timeout: const Timeout.factor(2), () {
        expect(GitHubStatusIndicator.fromApi('major'), GitHubStatusIndicator.major);
      });

      test('parses critical', timeout: const Timeout.factor(2), () {
        expect(GitHubStatusIndicator.fromApi('critical'), GitHubStatusIndicator.critical);
      });

      test('parses maintenance', timeout: const Timeout.factor(2), () {
        expect(GitHubStatusIndicator.fromApi('maintenance'), GitHubStatusIndicator.maintenance);
      });

      test('returns unknown for null', timeout: const Timeout.factor(2), () {
        expect(GitHubStatusIndicator.fromApi(null), GitHubStatusIndicator.unknown);
      });

      test('returns unknown for unrecognized values', timeout: const Timeout.factor(2), () {
        expect(GitHubStatusIndicator.fromApi('something_else'), GitHubStatusIndicator.unknown);
        expect(GitHubStatusIndicator.fromApi(''), GitHubStatusIndicator.unknown);
      });
    });
  });

  group('GitHubComponentStatus', () {
    group('fromApi', () {
      test('parses operational', timeout: const Timeout.factor(2), () {
        expect(
          GitHubComponentStatus.fromApi('operational'),
          GitHubComponentStatus.operational,
        );
      });

      test('parses degraded_performance', timeout: const Timeout.factor(2), () {
        expect(
          GitHubComponentStatus.fromApi('degraded_performance'),
          GitHubComponentStatus.degradedPerformance,
        );
      });

      test('parses partial_outage', timeout: const Timeout.factor(2), () {
        expect(
          GitHubComponentStatus.fromApi('partial_outage'),
          GitHubComponentStatus.partialOutage,
        );
      });

      test('parses major_outage', timeout: const Timeout.factor(2), () {
        expect(
          GitHubComponentStatus.fromApi('major_outage'),
          GitHubComponentStatus.majorOutage,
        );
      });

      test('parses under_maintenance', timeout: const Timeout.factor(2), () {
        expect(
          GitHubComponentStatus.fromApi('under_maintenance'),
          GitHubComponentStatus.underMaintenance,
        );
      });

      test('returns unknown for null', timeout: const Timeout.factor(2), () {
        expect(GitHubComponentStatus.fromApi(null), GitHubComponentStatus.unknown);
      });

      test('returns unknown for unrecognized values', timeout: const Timeout.factor(2), () {
        expect(GitHubComponentStatus.fromApi('broken'), GitHubComponentStatus.unknown);
      });
    });
  });

  group('GitHubStatusComponent', () {
    group('constructor', () {
      test('creates with all fields', timeout: const Timeout.factor(2), () {
        const c = GitHubStatusComponent(
          id: 'comp-1',
          name: 'Git Operations',
          status: GitHubComponentStatus.operational,
          position: 1,
        );
        expect(c.id, 'comp-1');
        expect(c.name, 'Git Operations');
        expect(c.status, GitHubComponentStatus.operational);
        expect(c.position, 1);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        const c1 = GitHubStatusComponent(
          id: 'c1', name: 'A', status: GitHubComponentStatus.operational, position: 1,
        );
        const c2 = GitHubStatusComponent(
          id: 'c1', name: 'A', status: GitHubComponentStatus.operational, position: 1,
        );
        expect(c1, equals(c2));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        const c1 = GitHubStatusComponent(
          id: 'c1', name: 'A', status: GitHubComponentStatus.operational, position: 1,
        );
        const c2 = GitHubStatusComponent(
          id: 'c2', name: 'A', status: GitHubComponentStatus.operational, position: 1,
        );
        expect(c1, isNot(equals(c2)));
      });

      test('== returns false for different status', timeout: const Timeout.factor(2), () {
        const c1 = GitHubStatusComponent(
          id: 'c1', name: 'A', status: GitHubComponentStatus.operational, position: 1,
        );
        const c2 = GitHubStatusComponent(
          id: 'c1', name: 'A', status: GitHubComponentStatus.degradedPerformance, position: 1,
        );
        expect(c1, isNot(equals(c2)));
      });

      test('hashCode matches for equal components', timeout: const Timeout.factor(2), () {
        const c1 = GitHubStatusComponent(
          id: 'c1', name: 'A', status: GitHubComponentStatus.operational, position: 1,
        );
        const c2 = GitHubStatusComponent(
          id: 'c1', name: 'A', status: GitHubComponentStatus.operational, position: 1,
        );
        expect(c1.hashCode, equals(c2.hashCode));
      });
    });
  });

  group('GitHubStatusIncident', () {
    final testCreatedAt = DateTime(2024, 6, 1);
    final testUpdatedAt = DateTime(2024, 6, 2);

    test('creates with all fields', timeout: const Timeout.factor(2), () {
      final inc = GitHubStatusIncident(
        id: 'inc-1',
        name: 'API Issues',
        status: 'investigating',
        shortlink: 'https://githubstatus.com/incidents/1',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );
      expect(inc.id, 'inc-1');
      expect(inc.name, 'API Issues');
      expect(inc.status, 'investigating');
      expect(inc.shortlink, 'https://githubstatus.com/incidents/1');
      expect(inc.createdAt, testCreatedAt);
      expect(inc.updatedAt, testUpdatedAt);
    });

    test('== and hashCode work correctly', timeout: const Timeout.factor(2), () {
      final inc1 = GitHubStatusIncident(
        id: 'inc-1', name: 'A', status: 'open', shortlink: 'url',
        createdAt: testCreatedAt, updatedAt: testUpdatedAt,
      );
      final inc2 = GitHubStatusIncident(
        id: 'inc-1', name: 'A', status: 'open', shortlink: 'url',
        createdAt: testCreatedAt, updatedAt: testUpdatedAt,
      );
      expect(inc1, equals(inc2));
      expect(inc1.hashCode, equals(inc2.hashCode));
    });

    test('== returns false for different id', timeout: const Timeout.factor(2), () {
      final inc1 = GitHubStatusIncident(
        id: 'inc-1', name: 'A', status: 'open', shortlink: 'url',
        createdAt: testCreatedAt, updatedAt: testUpdatedAt,
      );
      final inc2 = GitHubStatusIncident(
        id: 'inc-2', name: 'A', status: 'open', shortlink: 'url',
        createdAt: testCreatedAt, updatedAt: testUpdatedAt,
      );
      expect(inc1, isNot(equals(inc2)));
    });
  });

  group('GitHubServiceStatus', () {
    final testFetchedAt = DateTime(2024, 6, 1);

    test('creates with all fields', timeout: const Timeout.factor(2), () {
      final status = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.none,
        description: 'All Systems Operational',
        components: [],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      expect(status.indicator, GitHubStatusIndicator.none);
      expect(status.description, 'All Systems Operational');
      expect(status.components, isEmpty);
      expect(status.incidents, isEmpty);
      expect(status.fetchedAt, testFetchedAt);
    });

    test('== returns true for identical values', timeout: const Timeout.factor(2), () {
      final s1 = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.minor,
        description: 'Partial Issues',
        components: [],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      final s2 = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.minor,
        description: 'Partial Issues',
        components: [],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      expect(s1, equals(s2));
    });

    test('== returns false for different indicator', timeout: const Timeout.factor(2), () {
      final s1 = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.none,
        description: 'Ok',
        components: [],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      final s2 = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.major,
        description: 'Ok',
        components: [],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      expect(s1, isNot(equals(s2)));
    });

    test('== returns false for different components', timeout: const Timeout.factor(2), () {
      const comp = GitHubStatusComponent(
        id: 'c1', name: 'API', status: GitHubComponentStatus.operational, position: 1,
      );
      final s1 = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.none,
        description: 'Ok',
        components: [comp],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      final s2 = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.none,
        description: 'Ok',
        components: [],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      expect(s1, isNot(equals(s2)));
    });

    test('hashCode matches for equal statuses', timeout: const Timeout.factor(2), () {
      final s1 = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.none,
        description: 'Ok',
        components: [],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      final s2 = GitHubServiceStatus(
        indicator: GitHubStatusIndicator.none,
        description: 'Ok',
        components: [],
        incidents: [],
        fetchedAt: testFetchedAt,
      );
      expect(s1.hashCode, equals(s2.hashCode));
    });
  });
}
