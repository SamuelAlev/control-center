import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/webhook/vendor_webhook_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = VendorWebhookParser();

  test('parses a GitHub issue webhook', () {
    final result = parser.parse('github', {
      'action': 'opened',
      'issue': {
        'number': 789,
        'title': 'Bug: crash on save',
        'body': 'Steps to reproduce…',
        'state': 'open',
        'html_url': 'https://github.com/o/r/issues/789',
        'labels': [
          {'name': 'bug'},
          {'name': 'p1'},
        ],
        'assignee': {'login': 'octocat'},
        'updated_at': '2026-01-02T03:04:05Z',
      },
    }, deliveryId: 'gh-delivery-1');

    expect(result.vendor, 'github');
    expect(result.eventType, 'issues.opened');
    expect(result.deltas, hasLength(1));
    final d = result.deltas.single;
    expect(d.externalId, '789');
    expect(d.externalKey, '#789');
    expect(d.title, 'Bug: crash on save');
    expect(d.status, TicketStatus.open);
    expect(d.labels, containsAll(['bug', 'p1']));
    expect(d.assigneeExternalId, 'octocat');
    expect(d.dedupeKey, 'gh-delivery-1');
    expect(d.deleted, isFalse);
  });

  test('marks GitHub deleted action', () {
    final result = parser.parse('github', {
      'action': 'deleted',
      'issue': {'number': 1, 'state': 'open'},
    });
    expect(result.deltas.single.deleted, isTrue);
  });

  test('parses a Linear issue webhook', () {
    final result = parser.parse('linear', {
      'action': 'update',
      'type': 'Issue',
      'data': {
        'id': 'uuid-1',
        'identifier': 'ENG-123',
        'title': 'Implement retry',
        'description': 'desc',
        'state': {'name': 'In Progress'},
        'priority': 2,
        'assigneeId': 'lin-user-1',
        'labels': [
          {'name': 'backend'},
        ],
        'updatedAt': '2026-01-02T00:00:00Z',
      },
      'url': 'https://linear.app/x/ENG-123',
    }, deliveryId: 'lin-1');

    final d = result.deltas.single;
    expect(d.externalId, 'uuid-1');
    expect(d.externalKey, 'ENG-123');
    expect(d.status, TicketStatus.inProgress);
    expect(d.priority, TicketPriority.fromStorage(2));
    expect(d.url, 'https://linear.app/x/ENG-123');
    expect(d.assigneeExternalId, 'lin-user-1');
  });

  test('marks Linear remove action as deleted', () {
    final result = parser.parse('linear', {
      'action': 'remove',
      'data': {'id': 'uuid-9'},
    });
    expect(result.deltas.single.deleted, isTrue);
  });

  test('parses a Jira issue webhook', () {
    final result = parser.parse('jira', {
      'webhookEvent': 'jira:issue_updated',
      'issue': {
        'id': '10001',
        'key': 'PROJ-456',
        'fields': {
          'summary': 'Fix the thing',
          'description': 'details',
          'status': {'name': 'Done'},
          'priority': {'name': 'High'},
          'assignee': {'accountId': 'acc-1'},
          'labels': ['ops'],
          'updated': '2026-01-02T00:00:00.000+0000',
        },
      },
    });

    final d = result.deltas.single;
    expect(d.externalId, '10001');
    expect(d.externalKey, 'PROJ-456');
    expect(d.title, 'Fix the thing');
    expect(d.status, TicketStatus.done);
    expect(d.priority, TicketPriority.high);
    expect(d.assigneeExternalId, 'acc-1');
  });

  test('returns empty for a malformed body without throwing', () {
    final result = parser.parse('github', {'action': 'opened'});
    expect(result.deltas, isEmpty);
    final unknown = parser.parse('asana', {'whatever': true});
    expect(unknown.deltas, isEmpty);
  });
}
