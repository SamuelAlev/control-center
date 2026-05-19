import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_infra/src/tickets/sync/clickup_ticket_sync_adapter.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [ClickUpTicketSyncAdapter] — pure vendor translation over an
/// injectable [Dio]. Pins the REST paths, the priority int mapping, the
/// status-by-name PUT, and the pull delta flattening.
void main() {
  late RecordingAdapter adapter;
  late Dio dio;
  late ClickUpTicketSyncAdapter sync;

  setUp(() {
    adapter = RecordingAdapter();
    dio = Dio()..httpClientAdapter = adapter;
    sync = ClickUpTicketSyncAdapter(dio);
  });

  Ticket ticket({
    String title = 't',
    String? description,
    TicketPriority priority = TicketPriority.none,
    TicketStatus status = TicketStatus.open,
  }) => Ticket(
    id: 'cc-1',
    workspaceId: 'ws',
    title: title,
    description: description,
    priority: priority,
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  group('metadata + mappers', () {
    test('vendorId + allowedDomains', () {
      expect(sync.vendorId, 'clickup');
      expect(sync.allowedDomains, ['clickup.com', 'api.clickup.com']);
    });

    test('mapCcStatus returns the status name', () {
      expect(sync.mapCcStatus(TicketStatus.inProgress), 'inProgress');
      expect(sync.mapCcStatus(TicketStatus.done), 'done');
    });

    test('mapVendorStatus delegates to the normalizer', () {
      expect(sync.mapVendorStatus('in progress'), TicketStatus.inProgress);
      expect(sync.mapVendorStatus(''), TicketStatus.open);
    });
  });

  group('resolveVendorUrl', () {
    test('extracts the task id (short form)', () async {
      expect(
        await sync.resolveVendorUrl('https://app.clickup.com/t/86abc123'),
        '86abc123',
      );
    });

    test('extracts the task id (team-prefixed form)', () async {
      expect(
        await sync.resolveVendorUrl('https://app.clickup.com/t/123/86abc123'),
        '86abc123',
      );
    });

    test('returns null for a non-matching URL', () async {
      expect(await sync.resolveVendorUrl('https://example.com/x'), isNull);
    });
  });

  group('pullChanges', () {
    test('GETs the list tasks endpoint and flattens the response', () async {
      adapter.nextJson({
        'tasks': [
          {
            'id': 't1',
            'name': 'Task one',
            'url': 'https://app.clickup.com/t/123/t1',
            'text_content': 'the body',
            'status': {'status': 'in progress'},
            'priority': {'priority': 'high'},
            'assignees': [
              {'id': 55},
            ],
            'date_updated': '1700000000000',
          },
          {
            'id': 't2',
            'name': 'Task two',
            'status': {'status': 'complete'},
          },
        ],
      });
      final deltas = await sync.pullChanges(
        workspaceId: 'ws',
        vendorProjectId: 'list-9',
      );
      expect(adapter.requests.single.path, '/api/v2/list/list-9/task');
      expect(adapter.requests.single.queryParameters['subtasks'], true);
      expect(adapter.requests.single.queryParameters['order_by'], 'updated');
      expect(deltas, hasLength(2));
      expect(deltas[0].externalId, 't1');
      expect(deltas[0].url, 'https://app.clickup.com/t/123/t1');
      expect(deltas[0].title, 'Task one');
      expect(deltas[0].description, 'the body');
      expect(deltas[0].priority, TicketPriority.high);
      expect(deltas[0].status, TicketStatus.inProgress);
      expect(deltas[0].rawStatus, 'in progress');
      expect(deltas[0].assigneeExternalId, '55');
      expect(deltas[0].updatedAt!.millisecondsSinceEpoch, 1700000000000);
      expect(deltas[1].status, TicketStatus.done);
    });

    test('forwards since as a millisecond date_updated_gt', () async {
      adapter.nextJson({'tasks': const []});
      await sync.pullChanges(
        workspaceId: 'ws',
        vendorProjectId: 'l',
        since: DateTime.utc(2023, 11, 14, 22, 13, 20),
      );
      expect(
        adapter.requests.single.queryParameters['date_updated_gt'],
        '1700000000000',
      );
    });

    test(
      'priority mapping covers all branches incl. medium-via-normal',
      () async {
        // Drive via pullChanges with each priority shape.
        Future<TicketPriority?> pri(String raw) async {
          adapter.nextJson({
            'tasks': [
              {
                'id': 'x',
                'status': {'status': 'open'},
                'priority': {'priority': raw},
              },
            ],
          });
          final d = await sync.pullChanges(
            workspaceId: 'ws',
            vendorProjectId: 'l',
          );
          return d.single.priority;
        }

        expect(await pri('URGENT'), TicketPriority.urgent);
        expect(await pri('high'), TicketPriority.high);
        expect(await pri('normal'), TicketPriority.medium);
        expect(await pri('medium'), TicketPriority.medium);
        expect(await pri('low'), TicketPriority.low);
        expect(await pri('weird'), isNull);
      },
    );
  });

  group('pushChange — create', () {
    test('POSTs the task with name/description/priority', () async {
      adapter.nextJson({
        'id': 'new1',
        'url': 'https://app.clickup.com/t/x/new1',
      });
      final outcome = await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(
          title: 'New',
          description: 'body',
          priority: TicketPriority.medium,
        ),
        changeType: TicketChangeType.created,
        vendorProjectId: 'list-9',
      );
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.path, '/api/v2/list/list-9/task');
      final data = adapter.requests.single.data as Map;
      expect(data['name'], 'New');
      expect(data['description'], 'body');
      expect(data['priority'], 3);
      expect(outcome!.externalId, 'new1');
      expect(outcome.url, 'https://app.clickup.com/t/x/new1');
    });

    test('omits description/priority when not set', () async {
      adapter.nextJson({'id': 'new1'});
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(),
        changeType: TicketChangeType.created,
        vendorProjectId: 'l',
      );
      expect(adapter.requests.single.data, {'name': 't'});
    });
  });

  group('pushChange — update existing', () {
    test('statusChanged PUTs the status name', () async {
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(status: TicketStatus.done),
        changeType: TicketChangeType.statusChanged,
        externalId: 't7',
        vendorProjectId: 'l',
      );
      final req = adapter.requests.single;
      expect(req.method, 'PUT');
      expect(req.path, '/api/v2/task/t7');
      expect(req.data, {'status': 'done'});
    });

    test('updated PUTs name/description', () async {
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(title: 'T2', description: 'd'),
        changeType: TicketChangeType.updated,
        externalId: 't7',
        vendorProjectId: 'l',
      );
      final data = adapter.requests.single.data as Map;
      expect(data['name'], 'T2');
      expect(data['description'], 'd');
    });

    test('assigned/commented/deleted are no-ops', () async {
      for (final ct in [
        TicketChangeType.assigned,
        TicketChangeType.commented,
        TicketChangeType.deleted,
      ]) {
        await sync.pushChange(
          workspaceId: 'ws',
          ticket: ticket(),
          changeType: ct,
          externalId: 't7',
          vendorProjectId: 'l',
        );
      }
      expect(adapter.requests, isEmpty);
    });
  });
}

class RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Object _nextBody = <String, dynamic>{};
  void nextJson(Object body) => _nextBody = body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(_nextBody),
      200,
      headers: const {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
