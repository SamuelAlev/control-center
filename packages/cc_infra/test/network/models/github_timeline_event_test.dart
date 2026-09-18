import 'package:cc_infra/src/network/models/github_timeline_event.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubTimelineEvent.fromJson', () {
    test('maps a labeled event and round-trips the label', () {
      final e = GitHubTimelineEvent.fromJson({
        'event': 'labeled',
        'actor': {'login': 'renovate[bot]', 'avatar_url': ''},
        'label': {
          'name': 'dependencies',
          'color': '0366d6',
          'description': 'Pull requests that update a dependency file',
        },
        'created_at': '2026-07-01T12:00:00Z',
      });
      expect(e.event, 'labeled');
      expect(e.actor?.login, 'renovate[bot]');
      expect(e.label?.name, 'dependencies');
      expect(e.label?.color, '0366d6');
      expect(
        e.label?.description,
        'Pull requests that update a dependency file',
      );
      expect(e.createdAt, DateTime.utc(2026, 7, 1, 12));

      final restored = GitHubTimelineEvent.fromJson(e.toJson());
      expect(restored.label?.name, 'dependencies');
      expect(restored.label?.color, '0366d6');
    });

    test('maps unlabeled and leaves review-request fields empty', () {
      final e = GitHubTimelineEvent.fromJson({
        'event': 'unlabeled',
        'actor': {'login': 'alice', 'avatar_url': ''},
        'label': {'name': 'wip', 'color': 'eeeeee'},
      });
      expect(e.event, 'unlabeled');
      expect(e.label?.name, 'wip');
      expect(e.requestedReviewer, isNull);
      expect(e.requestedTeamName, isEmpty);
    });
  });
}
