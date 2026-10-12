import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/sync/ticket_change_type.dart';
import 'package:cc_infra/src/tickets/sync/github_issues_ticket_sync_adapter.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// The decoded JSON body of a captured request.
Map<String, dynamic> jsonBody(HttpRequest request) =>
    ((request.body! as HttpBodyJson).json as Map).cast<String, dynamic>();

/// Exercises [GitHubIssuesTicketSyncAdapter]. The adapter is pure
/// vendor-shape translation over an injectable [RhttpClient], so a
/// [TestHttpClient] pins the REST paths, the PR-vs-issue filter, the status
/// mapping and the push-change branches without touching GitHub.
void main() {
  late TestHttpClient httpClient;
  late GitHubIssuesTicketSyncAdapter sync;
  Object? next = <Object?>[];

  void nextJson(Object body) => next = body;

  setUp(() {
    next = <Object?>[];
    httpClient = TestHttpClient(
      handler: (request) => httpTextResponse(request, next),
    );
    sync = GitHubIssuesTicketSyncAdapter(httpClient);
  });

  Ticket ticket({
    String title = 't',
    String? description,
    List<String> labels = const [],
    TicketStatus status = TicketStatus.open,
  }) => Ticket(
    id: 'cc-1',
    workspaceId: 'ws',
    title: title,
    description: description,
    labels: labels,
    status: status,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  group('metadata', () {
    test('vendorId + allowedDomains', () {
      expect(sync.vendorId, 'github');
      expect(sync.allowedDomains, ['github.com', 'api.github.com']);
    });

    test('mapCcStatus: terminal → closed, others → open', () {
      expect(sync.mapCcStatus(TicketStatus.done), 'closed');
      expect(sync.mapCcStatus(TicketStatus.cancelled), 'closed');
      expect(sync.mapCcStatus(TicketStatus.failed), 'closed');
      expect(sync.mapCcStatus(TicketStatus.open), 'open');
      expect(sync.mapCcStatus(TicketStatus.inProgress), 'open');
      expect(sync.mapCcStatus(TicketStatus.inReview), 'open');
    });

    test('mapVendorStatus delegates to the shared normalizer', () {
      expect(sync.mapVendorStatus('in progress'), TicketStatus.inProgress);
      expect(sync.mapVendorStatus('closed'), TicketStatus.done);
      expect(sync.mapVendorStatus(''), TicketStatus.open);
    });
  });

  group('resolveVendorUrl', () {
    test('extracts the issue number from a github issues URL', () async {
      expect(
        await sync.resolveVendorUrl(
          'https://github.com/acme/widget/issues/4242',
        ),
        '4242',
      );
    });

    test('returns null for a non-matching URL', () async {
      expect(await sync.resolveVendorUrl('https://example.com/x'), isNull);
      expect(
        await sync.resolveVendorUrl('https://github.com/acme/widget/pull/1'),
        isNull,
      );
    });
  });

  group('pullChanges', () {
    test('GETs the issues endpoint and excludes PRs', () async {
      nextJson([
        {'number': 1, 'title': 'issue one', 'state': 'open'},
        // A PR — has a `pull_request` key — must be filtered out.
        {
          'number': 2,
          'title': 'a PR',
          'state': 'open',
          'pull_request': {'url': 'x'},
        },
        {
          'number': 3,
          'title': 'closed issue',
          'state': 'closed',
          'html_url': 'https://github.com/o/r/issues/3',
          'body': 'the body',
          'labels': [
            {'name': 'bug'},
            {'name': ''},
            'not-a-map',
          ],
          'assignee': {'login': 'sam'},
          'updated_at': '2026-02-02T00:00:00Z',
        },
      ]);
      final deltas = await sync.pullChanges(
        workspaceId: 'ws',
        vendorProjectId: 'acme/widget',
      );
      expect(httpClient.requests.single.url, '/repos/acme/widget/issues');
      expect(httpClient.requests.single.query!['state'], 'all');
      expect(httpClient.requests.single.query!['per_page'], '100');
      expect(deltas, hasLength(2));
      expect(deltas[0].externalId, '1');
      expect(deltas[0].externalKey, '#1');
      expect(deltas[0].title, 'issue one');
      expect(deltas[1].externalKey, '#3');
      expect(deltas[1].url, 'https://github.com/o/r/issues/3');
      expect(deltas[1].description, 'the body');
      // Empty-name labels and non-map entries are dropped.
      expect(deltas[1].labels, ['bug']);
      expect(deltas[1].assigneeExternalId, 'sam');
      expect(deltas[1].updatedAt, DateTime.utc(2026, 2, 2));
      expect(deltas[1].status, TicketStatus.done);
    });

    test('forwards the `since` cursor as an ISO UTC timestamp', () async {
      nextJson(const []);
      await sync.pullChanges(
        workspaceId: 'ws',
        vendorProjectId: 'o/r',
        since: DateTime.utc(2026, 3, 3, 4, 5, 6),
      );
      expect(
        httpClient.requests.single.query!['since'],
        '2026-03-03T04:05:06.000Z',
      );
    });

    test('tolerates missing/odd fields', () async {
      nextJson([
        {'number': null, 'state': null},
        'not-a-map',
      ]);
      final deltas = await sync.pullChanges(
        workspaceId: 'ws',
        vendorProjectId: 'o/r',
      );
      expect(deltas, hasLength(1));
      expect(deltas.single.externalId, '');
      expect(deltas.single.externalKey, isNull);
      expect(deltas.single.status, TicketStatus.open);
      expect(deltas.single.rawStatus, 'open');
    });
  });

  group('pushChange — create', () {
    test('POSTs to the issues endpoint and reads the number', () async {
      nextJson({'number': 42, 'html_url': 'https://github.com/o/r/issues/42'});
      final outcome = await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(title: 'New', description: 'body', labels: ['bug']),
        changeType: TicketChangeType.created,
        vendorProjectId: 'o/r',
      );
      expect(httpClient.requests.single.method.value, 'POST');
      expect(httpClient.requests.single.url, '/repos/o/r/issues');
      final data = jsonBody(httpClient.requests.single);
      expect(data['title'], 'New');
      expect(data['body'], 'body');
      expect(data['labels'], ['bug']);
      expect(outcome!.externalId, '42');
      expect(outcome.externalKey, '#42');
      expect(outcome.url, 'https://github.com/o/r/issues/42');
    });

    test('omits body/labels when empty', () async {
      nextJson({'number': 1});
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(title: 't'),
        changeType: TicketChangeType.created,
        vendorProjectId: 'o/r',
      );
      final data = jsonBody(httpClient.requests.single);
      expect(data.keys, ['title']);
    });

    test('returns an empty externalId when the API omits number', () async {
      nextJson({});
      final outcome = await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(),
        changeType: TicketChangeType.created,
        vendorProjectId: 'o/r',
      );
      expect(outcome!.externalId, '');
      expect(outcome.externalKey, isNull);
    });

    test('rejects a malformed vendorProjectId', () async {
      expect(
        () => sync.pushChange(
          workspaceId: 'ws',
          ticket: ticket(),
          changeType: TicketChangeType.created,
          vendorProjectId: 'no-slash',
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => sync.pushChange(
          workspaceId: 'ws',
          ticket: ticket(),
          changeType: TicketChangeType.created,
          vendorProjectId: '/repo',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('pushChange — update existing', () {
    test('statusChanged patches only the state', () async {
      nextJson(const {});
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(status: TicketStatus.done),
        changeType: TicketChangeType.statusChanged,
        externalId: '7',
        vendorProjectId: 'o/r',
      );
      final req = httpClient.requests.single;
      expect(req.method.value, 'PATCH');
      expect(req.url, '/repos/o/r/issues/7');
      expect(jsonBody(req), {'state': 'closed', 'state_reason': 'completed'});
    });

    test('cancelled status maps to not_planned', () async {
      nextJson(const {});
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(status: TicketStatus.cancelled),
        changeType: TicketChangeType.statusChanged,
        externalId: '7',
        vendorProjectId: 'o/r',
      );
      expect(jsonBody(httpClient.requests.single), {
        'state': 'closed',
        'state_reason': 'not_planned',
      });
    });

    test('a non-terminal status patches to state:open', () async {
      nextJson(const {});
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(status: TicketStatus.inProgress),
        changeType: TicketChangeType.statusChanged,
        externalId: '7',
        vendorProjectId: 'o/r',
      );
      expect(jsonBody(httpClient.requests.single), {'state': 'open'});
    });

    test('updated patches title/body/labels', () async {
      nextJson(const {});
      await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(title: 'T2', description: 'd', labels: ['x']),
        changeType: TicketChangeType.updated,
        externalId: '7',
        vendorProjectId: 'o/r',
      );
      final data = jsonBody(httpClient.requests.single);
      expect(data['title'], 'T2');
      expect(data['body'], 'd');
      expect(data['labels'], ['x']);
    });

    test('deleted closes the issue as not_planned', () async {
      nextJson(const {});
      final outcome = await sync.pushChange(
        workspaceId: 'ws',
        ticket: ticket(),
        changeType: TicketChangeType.deleted,
        externalId: '7',
        vendorProjectId: 'o/r',
      );
      expect(httpClient.requests.single.method.value, 'PATCH');
      expect(jsonBody(httpClient.requests.single), {
        'state': 'closed',
        'state_reason': 'not_planned',
      });
      expect(outcome!.externalId, '7');
      expect(outcome.externalKey, '#7');
    });

    test('commented / assigned are no-ops (no request issued)', () async {
      nextJson(const {});
      for (final ct in [
        TicketChangeType.commented,
        TicketChangeType.assigned,
      ]) {
        await sync.pushChange(
          workspaceId: 'ws',
          ticket: ticket(),
          changeType: ct,
          externalId: '7',
          vendorProjectId: 'o/r',
        );
      }
      expect(httpClient.requests, isEmpty);
    });
  });

  group('resolving', () {
    test('asks for a client per workspace and owner', () async {
      final seen = <({String workspaceId, String owner})>[];
      final resolving = GitHubIssuesTicketSyncAdapter.resolving(({
        required String workspaceId,
        required String owner,
      }) async {
        seen.add((workspaceId: workspaceId, owner: owner));
        return httpClient;
      });
      nextJson(const []);
      await resolving.pullChanges(
        workspaceId: 'ws-a',
        vendorProjectId: 'acme/widget',
      );
      expect(seen, [(workspaceId: 'ws-a', owner: 'acme')]);
    });
  });
}
