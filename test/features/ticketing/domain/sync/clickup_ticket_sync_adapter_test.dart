import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_infra/src/tickets/sync/clickup_ticket_sync_adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canned-response adapter capturing each outgoing request so we can assert the
/// method/path/body the ClickUp adapter builds, without any network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

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
  ({ClickUpTicketSyncAdapter adapter, _FakeAdapter fake}) build(
    ResponseBody Function(RequestOptions) handler,
  ) {
    final fake = _FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.clickup.com'))
      ..httpClientAdapter = fake;
    return (adapter: ClickUpTicketSyncAdapter(dio), fake: fake);
  }

  group('ClickUpTicketSyncAdapter', () {
    test('vendorId + allowedDomains', () {
      final b = build((_) => _json(const {}));
      expect(b.adapter.vendorId, 'clickup');
      expect(b.adapter.allowedDomains, contains('api.clickup.com'));
    });

    test('pullChanges parses tasks from the list into deltas', () async {
      final b = build(
        (_) => _json({
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
      expect(b.fake.requests.single.path, '/api/v2/list/list123/task');
      expect(deltas, hasLength(1));
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
        (_) => _json({'id': 'new1', 'url': 'https://app.clickup.com/t/new1'}),
      );
      final outcome = await b.adapter.pushChange(
        workspaceId: 'ws1',
        ticket: _ticket(),
        changeType: TicketChangeType.created,
        vendorProjectId: 'list123',
      );
      final req = b.fake.requests.single;
      expect(req.method, 'POST');
      expect(req.path, '/api/v2/list/list123/task');
      final body = req.data as Map<String, dynamic>;
      expect(body['name'], 'Fix the thing');
      expect(body['description'], 'details');
      expect(body['priority'], 2); // high → 2
      expect(outcome!.externalId, 'new1');
      expect(outcome.url, 'https://app.clickup.com/t/new1');
    });

    test('a status change PUTs the mapped status name by task id', () async {
      final b = build((_) => _json(const {}));
      await b.adapter.pushChange(
        workspaceId: 'ws1',
        ticket: _ticket(status: TicketStatus.done),
        changeType: TicketChangeType.statusChanged,
        externalId: '86a1',
      );
      final req = b.fake.requests.single;
      expect(req.method, 'PUT');
      expect(req.path, '/api/v2/task/86a1');
      expect((req.data as Map)['status'], 'done');
    });

    test('an update PUTs title + description, not status', () async {
      final b = build((_) => _json(const {}));
      await b.adapter.pushChange(
        workspaceId: 'ws1',
        ticket: _ticket(title: 'Renamed'),
        changeType: TicketChangeType.updated,
        externalId: '86a1',
      );
      final body = b.fake.requests.single.data as Map;
      expect(body['name'], 'Renamed');
      expect(body.containsKey('status'), isFalse);
    });

    test('resolveVendorUrl extracts the task id from a ClickUp URL', () async {
      final b = build((_) => _json(const {}));
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
