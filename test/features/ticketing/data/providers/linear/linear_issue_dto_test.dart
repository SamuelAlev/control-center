import 'package:control_center/features/ticketing/data/providers/linear/linear_issue_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinearIssueDto.fromJson', () {
    test('parses a fully populated issue', () {
      final json = {
        'id': 'issue-1',
        'identifier': 'LIN-123',
        'title': 'Fix login bug',
        'description': 'Users cannot log in with SSO',
        'state': {'name': 'In Progress'},
        'priority': 2,
        'team': {'name': 'Engineering'},
        'url': 'https://linear.app/issue/LIN-123',
        'assignee': {'id': 'user-42'},
        'labels': {
          'nodes': [
            {'name': 'bug'},
            {'name': 'p1'},
          ],
        },
      };

      final dto = LinearIssueDto.fromJson(json);

      expect(dto.id, 'issue-1');
      expect(dto.identifier, 'LIN-123');
      expect(dto.title, 'Fix login bug');
      expect(dto.description, 'Users cannot log in with SSO');
      expect(dto.stateName, 'In Progress');
      expect(dto.priority, 2);
      expect(dto.teamName, 'Engineering');
      expect(dto.url, 'https://linear.app/issue/LIN-123');
      expect(dto.assigneeId, 'user-42');
      expect(dto.labels, ['bug', 'p1']);
    });

    test('handles missing optional fields with defaults', () {
      final json = <String, dynamic>{
        'id': 'issue-2',
        'identifier': 'LIN-456',
        'title': 'Add feature',
        'description': '',
      };

      final dto = LinearIssueDto.fromJson(json);

      expect(dto.stateName, '');
      expect(dto.priority, 0);
      expect(dto.teamName, '');
      expect(dto.url, null);
      expect(dto.assigneeId, null);
      expect(dto.labels, isEmpty);
    });

    test('handles completely empty JSON', () {
      final dto = LinearIssueDto.fromJson(<String, dynamic>{});

      expect(dto.id, '');
      expect(dto.identifier, '');
      expect(dto.title, '');
      expect(dto.description, '');
      expect(dto.stateName, '');
      expect(dto.priority, 0);
      expect(dto.teamName, '');
      expect(dto.url, null);
      expect(dto.assigneeId, null);
      expect(dto.labels, isEmpty);
    });

    test('state defaults when state map is null', () {
      final json = <String, dynamic>{
        'id': 'issue-3',
        'identifier': 'LIN-789',
        'title': 'Task',
        'description': '',
        'state': null,
      };

      final dto = LinearIssueDto.fromJson(json);
      expect(dto.stateName, '');
    });

    test('state defaults when state name is null', () {
      final json = <String, dynamic>{
        'id': 'issue-4',
        'identifier': 'LIN-000',
        'title': 'Task',
        'description': '',
        'state': <String, dynamic>{'name': null},
      };

      final dto = LinearIssueDto.fromJson(json);
      expect(dto.stateName, '');
    });

    test('handles labels with null nodes', () {
      final json = <String, dynamic>{
        'id': 'issue-5',
        'identifier': 'LIN-111',
        'title': 'Task',
        'description': '',
        'labels': <String, dynamic>{'nodes': null},
      };

      final dto = LinearIssueDto.fromJson(json);
      expect(dto.labels, isEmpty);
    });

    test('handles labels with empty nodes', () {
      final json = <String, dynamic>{
        'id': 'issue-6',
        'identifier': 'LIN-222',
        'title': 'Task',
        'description': '',
        'labels': {
          'nodes': <Map<String, dynamic>>[],
        },
      };

      final dto = LinearIssueDto.fromJson(json);
      expect(dto.labels, isEmpty);
    });

    test('filters out labels with null names', () {
      final json = <String, dynamic>{
        'id': 'issue-7',
        'identifier': 'LIN-333',
        'title': 'Task',
        'description': '',
        'labels': {
          'nodes': [
            {'name': 'valid'},
            {'other': 'not-a-name'},
            {'name': null},
          ],
        },
      };

      final dto = LinearIssueDto.fromJson(json);
      expect(dto.labels, ['valid']);
    });

    test('handles labels as non-Map-list (gracefully)', () {
      final json = <String, dynamic>{
        'id': 'issue-8',
        'identifier': 'LIN-444',
        'title': 'Task',
        'description': '',
        'labels': {
          'nodes': [
            'string instead of map',
            42,
          ],
        },
      };

      final dto = LinearIssueDto.fromJson(json);
      expect(dto.labels, isEmpty);
    });

    test('handles null team gracefully', () {
      final json = <String, dynamic>{
        'id': 'issue-9',
        'identifier': 'LIN-555',
        'title': 'Task',
        'description': '',
        'team': null,
      };

      final dto = LinearIssueDto.fromJson(json);
      expect(dto.teamName, '');
    });

    test('handles null priority gracefully', () {
      final json = <String, dynamic>{
        'id': 'issue-10',
        'identifier': 'LIN-666',
        'title': 'Task',
        'description': '',
        'priority': null,
      };

      final dto = LinearIssueDto.fromJson(json);
      expect(dto.priority, 0);
    });
  });

  group('LinearIssueDto const constructor', () {
    test('creates issue with all fields', () {
      const dto = LinearIssueDto(
        id: 'id-1',
        identifier: 'LIN-1',
        title: 'Title',
        description: 'Desc',
        stateName: 'Done',
        priority: 1,
        teamName: 'Team',
        url: 'https://example.com',
        labels: ['a', 'b'],
        assigneeId: 'user-1',
      );

      expect(dto.id, 'id-1');
      expect(dto.identifier, 'LIN-1');
      expect(dto.title, 'Title');
      expect(dto.description, 'Desc');
      expect(dto.stateName, 'Done');
      expect(dto.priority, 1);
      expect(dto.teamName, 'Team');
      expect(dto.url, 'https://example.com');
      expect(dto.labels, ['a', 'b']);
      expect(dto.assigneeId, 'user-1');
    });

    test('defaults labels to empty list', () {
      const dto = LinearIssueDto(
        id: 'id-2',
        identifier: 'LIN-2',
        title: 'Title',
        description: 'Desc',
        stateName: 'Done',
        priority: 0,
        teamName: 'Team',
      );

      expect(dto.labels, isEmpty);
      expect(dto.url, null);
      expect(dto.assigneeId, null);
    });
  });
}
