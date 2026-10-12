import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_infra/src/tickets/sync/clickup_ticket_sync_adapter.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhttp/rhttp.dart';

/// The JSON body the adapter sent, decoded from the recorded request.
Map<String, dynamic> _jsonBody(HttpRequest request) =>
    ((request.body! as HttpBodyJson).json as Map).cast<String, dynamic>();

Ticket _ticket({
  String title = 'Fix the thing',
  String? description = 'details',
  TicketStatus status = TicketStatus.inProgress,
  TicketPriority priority = TicketPriority.high,
}) => Ticket(
  id: 't1',
  workspaceId: 'ws1',
  title: title,
  description: description,
  status: status,
  priority: priority,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 7, 1),
);

void main() {
  // Canned transport capturing each outgoing request so we can assert the
  // method/path/body the ClickUp adapter builds, without any network.
  ({ClickUpTicketSyncAdapter adapter, TestHttpClient fake}) build(
    HttpResponse Function(HttpRequest) handler,
  ) {
    final fake = TestHttpClient(
      settings: const ClientSettings(baseUrl: 'https://api.clickup.com'),
      handler: handler,
    );
    return (adapter: ClickUpTicketSyncAdapter(fake), fake: fake);
  }

  group('ClickUpTicketSyncAdapter', () {
    test('vendorId + allowedDomains', () {
      final b = build((request) => httpTextResponse(request, const {}));
      expect(b.adapter.vendorId, 'clickup');
      expect(b.adapter.allowedDomains, contains('api.clickup.com'));
    });

    test('pullChanges parses tasks from the list into deltas', () async {
      final b = build(
        (request) => httpTextResponse(request, {
          'tasks': [
            {
              'id': '86a1',
              'name': 'Ship it',
              'text_content': 'the body',
              'status': {'status': 'in progress'},
              'priority': {'priority': 'urgent'},
              'assignees': [
                {'id': 42},
              ],
              'url': 'https://app.clickup.com/t/86a1',
              'date_updated': '1719792000000',
            },
          ],
        }),
      );
      final deltas = await b.adapter.pullChanges(
        workspaceId: 'ws1',
        vendorProjectId: 'list123',
      );
      // `.first`, not `.single`: pullChanges paginates now (it used to fetch
      // page 0 only and silently drop every change past the first hundred).
      // This fake answers every page identically, so the id-dedupe
      // terminator stops it after the repeat.
      expect(b.fake.requests.first.url, '/api/v2/list/list123/task');
      expect(b.fake.requests.first.query?['page'], '0');
      expect(deltas, hasLength(1), reason: 'the repeated task is deduped');
      final d = deltas.single;
      expect(d.externalId, '86a1');
      expect(d.title, 'Ship it');
      expect(d.description, 'the body');
      expect(d.status, TicketStatus.inProgress);
      expect(d.priority, TicketPriority.urgent);
      expect(d.assigneeExternalId, '42');
      expect(d.updatedAt, isNotNull);
    });

    test('pushChange creates a task when externalId is absent', () async {
      final b = build(
        (request) => httpTextResponse(request, {
          'id': 'new1',
          'url': 'https://app.clickup.com/t/new1',
        }),
      );
      final outcome = await b.adapter.pushChange(
        workspaceId: 'ws1',
        ticket: _ticket(),
        changeType: TicketChangeType.created,
        vendorProjectId: 'list123',
      );
      final req = b.fake.requests.single;
      expect(req.method, HttpMethod.post);
      expect(req.url, '/api/v2/list/list123/task');
      final body = _jsonBody(req);
      expect(body['name'], 'Fix the thing');
      expect(body['description'], 'details');
      expect(body['priority'], 2); // high → 2
      expect(outcome!.externalId, 'new1');
      expect(outcome.url, 'https://app.clickup.com/t/new1');
    });

    test('a status change PUTs the mapped status name by task id', () async {
      final b = build((request) => httpTextResponse(request, const {}));
      await b.adapter.pushChange(
        workspaceId: 'ws1',
        ticket: _ticket(status: TicketStatus.done),
        changeType: TicketChangeType.statusChanged,
        externalId: '86a1',
      );
      final req = b.fake.requests.single;
      expect(req.method, HttpMethod.put);
      expect(req.url, '/api/v2/task/86a1');
      expect(_jsonBody(req)['status'], 'done');
    });

    test('an update PUTs title + description, not status', () async {
      final b = build((request) => httpTextResponse(request, const {}));
      await b.adapter.pushChange(
        workspaceId: 'ws1',
        ticket: _ticket(title: 'Renamed'),
        changeType: TicketChangeType.updated,
        externalId: '86a1',
      );
      final body = _jsonBody(b.fake.requests.single);
      expect(body['name'], 'Renamed');
      expect(body.containsKey('status'), isFalse);
    });

    test('resolveVendorUrl extracts the task id from a ClickUp URL', () async {
      final b = build((request) => httpTextResponse(request, const {}));
      expect(
        await b.adapter.resolveVendorUrl('https://app.clickup.com/t/86a1xyz'),
        '86a1xyz',
      );
      expect(
        await b.adapter.resolveVendorUrl('https://example.com/not-clickup'),
        isNull,
      );
    });
  });
}
