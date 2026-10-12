import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_infra/src/tickets/sync/jira_ticket_sync_adapter.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// The decoded JSON body of a captured request.
Map<String, dynamic> jsonBody(HttpRequest request) =>
    ((request.body! as HttpBodyJson).json as Map).cast<String, dynamic>();

/// Exercises [JiraTicketSyncAdapter] — pure vendor translation over an
/// injectable [RhttpClient]. Pins the JQL search, the ADF wrapping on create,
/// the transition workflow for status changes and the ADF→text flattening on
/// pull.
void main() {
  late TestHttpClient httpClient;
  late JiraTicketSyncAdapter sync;
  var queued = <Object?>[];

  // Enqueues a canned response body. Multiple calls queue multiple bodies,
  // consumed FIFO (one per request).
  void nextJson(Object body) => queued.add(body);

  setUp(() {
    queued = <Object?>[];
    httpClient = TestHttpClient(
      handler: (request) => httpTextResponse(
        request,
        queued.isEmpty ? const <String, dynamic>{} : queued.removeAt(0),
      ),
    );
    sync = JiraTicketSyncAdapter(httpClient);
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
      expect(sync.vendorId, 'jira');
      expect(sync.allowedDomains, ['atlassian.net']);
    });

    test('issueTypeName defaults to Task and is overridable', () {
      expect(JiraTicketSyncAdapter(httpClient).issueTypeName, 'Task');
      expect(
        JiraTicketSyncAdapter(httpClient, issueTypeName: 'Story').issueTypeName,
        'Story',
      );
    });

    test('mapCcStatus returns the status name', () {
      expect(sync.mapCcStatus(TicketStatus.inReview), 'inReview');
    });

    test('mapVendorStatus delegates to the normalizer', () {
      expect(sync.mapVendorStatus('in review'), TicketStatus.inReview);
      expect(sync.mapVendorStatus(''), TicketStatus.open);
    });
  });

  group('resolveVendorUrl', () {
    test('extracts a Jira issue key', () async {
      expect(
        await sync.resolveVendorUrl(
          'https://acme.atlassian.net/browse/PROJ-42',
        ),
        'PROJ-42',
      );
    });

    test('returns null for non-matching URLs', () async {
      expect(await sync.resolveVendorUrl('https://example.com/x'), isNull);
      expect(
        await sync.resolveVendorUrl(
          'https://acme.atlassian.net/browse/lower-1',
        ),
        isNull,
      );
    });
  });

  group('pullChanges', () {
    test('GETs the search endpoint and flattens issues', () async {
      nextJson({
        'issues': [
          {
            'id': '10001',
            'key': 'PROJ-1',
            'fields': {
              'summary': 'Do thing',
              'description': {
                'type': 'doc',
                'version': 1,
                'content': [
                  {
                    'type': 'paragraph',
                    'content': [
                      {'type': 'text', 'text': 'Hello '},
                      {'type': 'text', 'text': 'world'},
                    ],
                  },
                ],
              },
              'status': {'name': 'In Progress'},
              'priority': {'name': 'High'},
              'labels': ['bug', '', 'frontend'],
              'assignee': {'accountId': 'u-1'},
              'updated': '2026-02-02T00:00:00.000+0000',
            },
          },
        ],
      });
      final deltas = await sync.pullChanges(
        workspaceId: 'ws',
        vendorProjectId: 'PROJ',
      );
      final req = httpClient.requests.single;
      expect(req.url, '/rest/api/3/search');
      expect(req.query!['jql'], 'project = "PROJ" ORDER BY updated DESC');
      expect(req.query!['maxResults'], '100');
      expect(deltas, hasLength(1));
      final d = deltas.single;
      expect(d.externalId, '10001');
      expect(d.externalKey, 'PROJ-1');
      expect(d.title, 'Do thing');
      // ADF flattened to plain text.
      expect(d.description, 'Hello world');
      expect(d.priority, TicketPriority.high);
      expect(d.labels, ['bug', 'frontend']);
      expect(d.status, TicketStatus.inProgress);
      expect(d.rawStatus, 'In Progress');
      expect(d.assigneeExternalId, 'u-1');
      expect(d.updatedAt, DateTime.utc(2026, 2, 2));
    });

    test('a plain-string description is passed through', () async {
      nextJson({
        'issues': [
          {
            'id': '1',
            'key': 'P-1',
            'fields': {
              'summary': 's',
              'description': 'plain text body',
              'status': {'name': 'Open'},
            },
          },
        ],
      });
      final d = await sync.pullChanges(workspaceId: 'ws', vendorProjectId: 'P');
      expect(d.single.description, 'plain text body');
    });

    test('priority mapping covers all branches', () async {
      Future<TicketPriority?> pri(String name) async {
        nextJson({
          'issues': [
            {
              'id': 'x',
              'fields': {
                'status': {'name': 'open'},
                'priority': {'name': name},
              },
            },
          ],
        });
        return (await sync.pullChanges(
          workspaceId: 'ws',
          vendorProjectId: 'P',
        )).single.priority;
      }

      expect(await pri('Highest'), TicketPriority.urgent);
      expect(await pri('Critical priority'), TicketPriority.urgent);
      expect(await pri('High'), TicketPriority.high);
      expect(await pri('Medium'), TicketPriority.medium);
      expect(await pri('Low'), TicketPriority.low);
      expect(await pri('Weird'), isNull);
    });
  });

  group('pushChange — create', () {
    test(
      'POSTs with project/summary/adf description/issuetype/priority',
      () async {
        nextJson({
          'id': '10002',
          'key': 'PROJ-2',
          'self': 'https://x/rest/api/3/issue/10002',
        });
        final outcome = await sync.pushChange(
          workspaceId: 'ws',
          ticket: ticket(
            title: 'New issue',
            description: 'body text',
            priority: TicketPriority.urgent,
          ),
          changeType: TicketChangeType.created,
          vendorProjectId: 'PROJ',
        );
        expect(httpClient.requests.single.method.value, 'POST');
        expect(httpClient.requests.single.url, '/rest/api/3/issue');
        final fields = jsonBody(httpClient.requests.single)['fields'] as Map;
        expect((fields['project'] as Map)['key'], 'PROJ');
        expect(fields['summary'], 'New issue');
        // Description wrapped in ADF.
        final adf = fields['description'] as Map;
        expect(adf['type'], 'doc');
        final paragraph = (adf['content'] as List).first as Map;
        final textNode = (paragraph['content'] as List).first as Map;
        expect(textNode['text'], 'body text');
        expect((fields['issuetype'] as Map)['name'], 'Task');
        expect((fields['priority'] as Map)['name'], 'Highest');
        expect(outcome!.externalId, '10002');
        expect(outcome.externalKey, 'PROJ-2');
        expect(outcome.url, 'https://x/rest/api/3/issue/10002');
      },
    );

    test('omits description + priority when absent', () async {
      nextJson({'id': '1', 'key': 'P-1'});
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(),
        changeType: TicketChangeType.created,
        vendorProjectId: 'P',
      );
      final fields = jsonBody(httpClient.requests.single)['fields'] as Map;
      expect(fields.containsKey('description'), isFalse);
      expect(fields.containsKey('priority'), isFalse);
    });
  });

  group('pushChange — update existing', () {
    test(
      'statusChanged transitions through the matching workflow id',
      () async {
        // First call returns the transitions list; second POSTs the transition.
        nextJson({
          'transitions': [
            {
              'id': '11',
              'to': {'name': 'To Do'},
            },
            {
              'id': '21',
              'to': {'name': 'Done'},
            },
            {
              'id': '31',
              'to': {'name': 'Won\'t Fix'},
            },
          ],
        });
        nextJson(const {});
        await sync.pushChange(
          workspaceId: 'ws',
          ticket: ticket(status: TicketStatus.done),
          changeType: TicketChangeType.statusChanged,
          externalId: 'PROJ-2',
          vendorProjectId: 'P',
        );
        expect(httpClient.requests, hasLength(2));
        expect(httpClient.requests[0].method.value, 'GET');
        expect(
          httpClient.requests[0].url,
          '/rest/api/3/issue/PROJ-2/transitions',
        );
        expect(httpClient.requests[1].method.value, 'POST');
        expect(
          httpClient.requests[1].url,
          '/rest/api/3/issue/PROJ-2/transitions',
        );
        expect(jsonBody(httpClient.requests[1]), {
          'transition': {'id': '21'},
        });
      },
    );

    test('statusChanged with no matching transition issues no POST', () async {
      nextJson({
        'transitions': [
          {
            'id': '11',
            'to': {'name': 'To Do'},
          },
        ],
      });
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(status: TicketStatus.done),
        changeType: TicketChangeType.statusChanged,
        externalId: 'PROJ-2',
        vendorProjectId: 'P',
      );
      // Only the GET — no POST.
      expect(httpClient.requests.single.method.value, 'GET');
    });

    test('updated PUTs summary + adf description', () async {
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(title: 'T2', description: 'd'),
        changeType: TicketChangeType.updated,
        externalId: 'PROJ-2',
        vendorProjectId: 'P',
      );
      final req = httpClient.requests.single;
      expect(req.method.value, 'PUT');
      expect(req.url, '/rest/api/3/issue/PROJ-2');
      final fields = jsonBody(req)['fields'] as Map;
      expect(fields['summary'], 'T2');
      expect((fields['description'] as Map)['type'], 'doc');
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
          externalId: 'PROJ-2',
          vendorProjectId: 'P',
        );
      }
      expect(httpClient.requests, isEmpty);
    });
  });
}
