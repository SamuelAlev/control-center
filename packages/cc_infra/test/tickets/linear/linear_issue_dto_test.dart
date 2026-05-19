import 'package:cc_infra/src/tickets/linear/linear_issue_dto.dart';
import 'package:test/test.dart';

/// Exercises [LinearIssueDto.fromJson]. Linear's GraphQL nests state/team/
/// assignee/labels in objects and the adapter flattens them — this pins the
/// flattening and the null-tolerance so a schema change doesn't silently null
/// out fields on the ticket surface.
void main() {
  group('LinearIssueDto.fromJson', () {
    test('parses a fully-populated issue', () {
      final issue = LinearIssueDto.fromJson({
        'id': 'lin-uuid',
        'identifier': 'LIN-42',
        'title': 'Ship it',
        'description': 'do the thing',
        'priority': 2,
        'url': 'https://linear.app/issue/LIN-42',
        'state': {'name': 'In Progress'},
        'team': {'name': 'Backend'},
        'assignee': {'id': 'user-1'},
        'labels': {
          'nodes': [
            {'name': 'bug'},
            {'name': 'urgent'},
          ],
        },
      });
      expect(issue.id, 'lin-uuid');
      expect(issue.identifier, 'LIN-42');
      expect(issue.title, 'Ship it');
      expect(issue.description, 'do the thing');
      expect(issue.stateName, 'In Progress');
      expect(issue.priority, 2);
      expect(issue.teamName, 'Backend');
      expect(issue.url, 'https://linear.app/issue/LIN-42');
      expect(issue.assigneeId, 'user-1');
      expect(issue.labels, ['bug', 'urgent']);
    });

    test('defaults every field when given an empty map', () {
      final issue = LinearIssueDto.fromJson({});
      expect(issue.id, '');
      expect(issue.identifier, '');
      expect(issue.title, '');
      expect(issue.description, '');
      expect(issue.stateName, '');
      expect(issue.priority, 0);
      expect(issue.teamName, '');
      expect(issue.url, isNull);
      expect(issue.assigneeId, isNull);
      expect(issue.labels, isEmpty);
    });

    test('labels nodes that are not maps are skipped, null names dropped', () {
      final issue = LinearIssueDto.fromJson({
        'id': 'x',
        'labels': {
          'nodes': [
            {'name': 'keep'},
            'not-a-map',
            {'name': null},
            {'name': 'other'},
          ],
        },
      });
      expect(issue.labels, ['keep', 'other']);
    });

    test('labels.nodes as a non-list yields empty labels', () {
      final issue = LinearIssueDto.fromJson({
        'id': 'x',
        'labels': {'nodes': 'nope'},
      });
      expect(issue.labels, isEmpty);
    });

    test('missing nested objects do not crash', () {
      final issue = LinearIssueDto.fromJson({
        'id': 'x',
        'identifier': 'X-1',
        'title': 't',
      });
      expect(issue.stateName, '');
      expect(issue.teamName, '');
      expect(issue.assigneeId, isNull);
      expect(issue.labels, isEmpty);
    });
  });
}
