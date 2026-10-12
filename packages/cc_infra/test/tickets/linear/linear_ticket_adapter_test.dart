import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:cc_domain/features/ticketing/domain/ports/ticket_query.dart';
import 'package:cc_infra/src/tickets/linear/linear_ticket_adapter.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// The decoded JSON body of a captured request.
Map<String, dynamic> jsonBody(HttpRequest request) =>
    ((request.body! as HttpBodyJson).json as Map).cast<String, dynamic>();

/// Exercises [LinearTicketAdapter] — the provider-port glue around the
/// GraphQL client. Pins status normalization, capabilities, the teamId
/// resolution rules (extras → default → throw) and the
/// get-after-each-mutation pattern.
void main() {
  late TestHttpClient fake;
  late LinearTicketAdapter ticketAdapter;

  /// Queues a Linear issue node returned by getIssue / createIssue /
  /// getAssignedIssues. We push responses in the order the adapter consumes
  /// them; the adapter issues GET-after-mutate so most methods need two
  /// responses (mutate ack + refreshed issue). An exhausted queue answers an
  /// empty `data` envelope, as the old fake did.
  final queue = <Object>[];

  void nextBody(Object body) => queue.add(body);

  setUp(() {
    queue.clear();
    fake = TestHttpClient(
      handler: (request) => httpTextResponse(
        request,
        queue.isEmpty ? const <String, dynamic>{} : queue.removeAt(0),
      ),
    );
    ticketAdapter = LinearTicketAdapter(fake, defaultTeamId: 'default-team');
  });

  Map<String, dynamic> issueNode({
    String id = 'abc',
    String identifier = 'LIN-1',
    String state = 'In Progress',
    int priority = 2,
  }) => {
    'id': id,
    'identifier': identifier,
    'title': 'T',
    'description': 'D',
    'url': 'https://linear.app/issue/LIN-1',
    'state': {'name': state},
    'priority': priority,
    'team': {'name': 'Eng'},
    'assignee': {'id': 'u1'},
    'labels': {
      'nodes': [
        {'name': 'bug'},
      ],
    },
  };

  group('static metadata', () {
    test('provider id is linear', () {
      expect(ticketAdapter.provider, TicketProvider.linear);
    });

    test('allowedDomains covers linear.app and the API host', () {
      expect(ticketAdapter.allowedDomains, ['linear.app', 'api.linear.app']);
    });

    test('capabilities advertise full CRUD + status + assignee + labels', () {
      final caps = ticketAdapter.capabilities;
      expect(caps.provider, TicketProvider.linear);
      expect(caps.supportsCreate, isTrue);
      expect(caps.supportsUpdate, isTrue);
      expect(caps.supportsStatusUpdate, isTrue);
      expect(caps.supportsAssignee, isTrue);
      expect(caps.supportsLabels, isTrue);
      expect(caps.supportsPriority, isTrue);
      expect(caps.supportsList, isTrue);
      expect(caps.supportsRemoteSync, isTrue);
      expect(caps.supportsHierarchy, isFalse);
    });
  });

  group('create', () {
    test('uses providerExtras teamId when present', () async {
      // createIssue mutation ack, then nothing else needed.
      nextBody({
        'data': {
          'issueCreate': {'success': true, 'issue': issueNode()},
        },
      });
      final ticket = await ticketAdapter.create(
        const RemoteTicketDraft(
          title: 'T',
          description: 'D',
          providerExtras: {'teamId': 'extras-team'},
        ),
      );
      expect(ticket.externalId, 'abc');
      // Verify the mutation carried the extras teamId.
      final input =
          (jsonBody(fake.requests.first)['variables'] as Map)['input'] as Map;
      expect(input['teamId'], 'extras-team');
    });

    test('falls back to defaultTeamId when extras has no teamId', () async {
      nextBody({
        'data': {
          'issueCreate': {'success': true, 'issue': issueNode()},
        },
      });
      await ticketAdapter.create(const RemoteTicketDraft(title: 'T'));
      final input =
          (jsonBody(fake.requests.first)['variables'] as Map)['input'] as Map;
      expect(input['teamId'], 'default-team');
    });

    test(
      'throws StateError when neither extras teamId nor default is set',
      () async {
        final noDefault = LinearTicketAdapter(fake);
        expect(
          () => noDefault.create(const RemoteTicketDraft(title: 'T')),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('throws StateError when createIssue returns no issue', () async {
      nextBody({'data': <String, dynamic>{}});
      expect(
        () => ticketAdapter.create(const RemoteTicketDraft(title: 'T')),
        throwsA(isA<StateError>()),
      );
    });

    test('priority is converted via toStorageInt', () async {
      nextBody({
        'data': {
          'issueCreate': {'success': true, 'issue': issueNode()},
        },
      });
      await ticketAdapter.create(
        const RemoteTicketDraft(
          title: 'T',
          priority: TicketPriority.urgent,
          providerExtras: {'teamId': 't'},
        ),
      );
      final input =
          (jsonBody(fake.requests.first)['variables'] as Map)['input'] as Map;
      expect(input['priority'], TicketPriority.urgent.toStorageInt());
    });
  });

  group('getByExternalId', () {
    test('returns null when the client returns no issue', () async {
      nextBody({'data': <String, dynamic>{}});
      expect(await ticketAdapter.getByExternalId('x'), isNull);
    });

    test('maps the issue into a RemoteTicket with normalized status', () async {
      nextBody({
        'data': {'issue': issueNode(state: 'In Review')},
      });
      final t = await ticketAdapter.getByExternalId('x');
      expect(t!.status, TicketStatus.inReview);
      expect(t.rawStatus, 'In Review');
      expect(t.priority, TicketPriority.high);
      expect(t.labels, ['bug']);
    });
  });

  group('list', () {
    test('returns mapped tickets filtered by status and limited', () async {
      nextBody({
        'data': {
          'issues': {
            'nodes': [
              issueNode(id: '1', identifier: 'LIN-1', state: 'In Progress'),
              issueNode(id: '2', identifier: 'LIN-2', state: 'In Review'),
              issueNode(id: '3', identifier: 'LIN-3', state: 'Done'),
              issueNode(id: '4', identifier: 'LIN-4', state: 'In Review'),
            ],
          },
        },
      });
      final out = await ticketAdapter.list(
        query: const TicketQuery(statuses: {TicketStatus.inReview}, limit: 1),
      );
      expect(out, hasLength(1));
      expect(out.single.status, TicketStatus.inReview);
    });

    test('returns all when no status filter is set', () async {
      nextBody({
        'data': {
          'issues': {
            'nodes': [
              issueNode(id: '1', state: 'In Progress'),
              issueNode(id: '2', state: 'Done'),
            ],
          },
        },
      });
      final out = await ticketAdapter.list();
      expect(out, hasLength(2));
    });
  });

  group('update', () {
    test('issues updateIssue then re-fetches the issue', () async {
      // First: updateIssue ack (no GraphQL errors). Second: getIssue response.
      nextBody({'data': <String, dynamic>{}});
      nextBody({
        'data': {'issue': issueNode(state: 'Done')},
      });
      final t = await ticketAdapter.update(
        'abc',
        const RemoteTicketPatch(title: 'New'),
      );
      expect(t.status, TicketStatus.done);
      expect(fake.requests, hasLength(2));
    });

    test('throws StateError when the re-fetch returns no issue', () async {
      nextBody({'data': <String, dynamic>{}});
      nextBody({'data': <String, dynamic>{}});
      expect(
        () =>
            ticketAdapter.update('abc', const RemoteTicketPatch(title: 'New')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('transitionStatus', () {
    test(
      'picks a matching workflow state and calls updateIssueState',
      () async {
        nextBody({
          // getWorkflowStatesForIssue
          'data': {
            'issue': {
              'team': {
                'states': {
                  'nodes': [
                    {'id': 's-todo', 'name': 'Todo'},
                    {'id': 's-done', 'name': 'Done'},
                  ],
                },
              },
            },
          },
        });
        nextBody({'data': <String, dynamic>{}}); // updateIssueState ack
        nextBody({
          'data': {'issue': issueNode(state: 'Done')},
        }); // getIssue
        final t = await ticketAdapter.transitionStatus(
          'abc',
          TicketStatus.done,
        );
        expect(t.status, TicketStatus.done);
        // The updateIssueState mutation should carry the matching state id.
        final stateMutationVars =
            jsonBody(fake.requests[1])['variables'] as Map;
        expect(stateMutationVars['stateId'], 's-done');
      },
    );

    test('skips updateIssueState when no state matches', () async {
      nextBody({
        'data': {
          'issue': {
            'team': {
              'states': {
                'nodes': [
                  {'id': 's-todo', 'name': 'Todo'},
                ],
              },
            },
          },
        },
      });
      nextBody({
        'data': {'issue': issueNode(state: 'Todo')},
      }); // getIssue only
      final t = await ticketAdapter.transitionStatus('abc', TicketStatus.done);
      expect(t.status, TicketStatus.open); // 'Todo' has no keyword → open
      expect(fake.requests, hasLength(2));
    });
  });

  group('assign', () {
    test('issues assignIssue then re-fetches', () async {
      nextBody({'data': <String, dynamic>{}}); // assignIssue ack
      nextBody({
        'data': {'issue': issueNode()},
      }); // getIssue
      final t = await ticketAdapter.assign('abc', 'u9');
      expect(t.externalId, 'abc');
      expect(fake.requests, hasLength(2));
    });

    test('clears assignee when null is passed', () async {
      nextBody({'data': <String, dynamic>{}});
      nextBody({
        'data': {'issue': issueNode()},
      });
      await ticketAdapter.assign('abc', null);
      final vars = jsonBody(fake.requests.first)['variables'] as Map;
      expect(vars['assigneeId'], isNull);
    });

    test('throws StateError when re-fetch returns nothing', () async {
      nextBody({'data': <String, dynamic>{}});
      nextBody({'data': <String, dynamic>{}});
      expect(
        () => ticketAdapter.assign('abc', null),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('watchAssigned', () {
    test('emits one RemoteTicket per assigned issue then completes', () async {
      nextBody({
        'data': {
          'issues': {
            'nodes': [
              issueNode(id: '1', identifier: 'LIN-1'),
              issueNode(id: '2', identifier: 'LIN-2'),
            ],
          },
        },
      });
      final out = await ticketAdapter.watchAssigned().toList();
      expect(out.map((t) => t.externalId).toList(), ['1', '2']);
    });
  });

  group('status normalization heuristics', () {
    // Drive the normalization through the public getByExternalId path so we
    // exercise the real _normalizeStatus logic.
    Future<TicketStatus> statusFor(String stateName) async {
      nextBody({
        'data': {'issue': issueNode(state: stateName)},
      });
      final t = await ticketAdapter.getByExternalId('x');
      return t!.status;
    }

    test('progress → inProgress', () async {
      expect(await statusFor('In Progress'), TicketStatus.inProgress);
    });

    test('review → inReview', () async {
      expect(await statusFor('In Review'), TicketStatus.inReview);
    });

    test('done/complete/merged → done', () async {
      expect(await statusFor('Done'), TicketStatus.done);
      expect(await statusFor('Completed'), TicketStatus.done);
      expect(await statusFor('Merged'), TicketStatus.done);
    });

    test('cancel/duplicate → cancelled', () async {
      expect(await statusFor('Cancelled'), TicketStatus.cancelled);
      expect(await statusFor('Duplicate'), TicketStatus.cancelled);
    });

    test('block → blocked', () async {
      expect(await statusFor('Blocked'), TicketStatus.blocked);
    });

    test('backlog → backlog', () async {
      expect(await statusFor('Backlog'), TicketStatus.backlog);
    });

    test('unknown → open', () async {
      expect(await statusFor('Triage'), TicketStatus.open);
    });
  });
}
