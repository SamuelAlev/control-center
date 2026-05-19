import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/features/ticketing/data/providers/linear/linear_issue_dto.dart';
import 'package:control_center/features/ticketing/data/providers/linear/linear_ticket_adapter.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/ports/remote_ticket.dart';
import 'package:control_center/features/ticketing/domain/ports/ticket_query.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'mock_dio.dart';

/// Returns a minimal Linear issue JSON map suitable for GraphQL responses.
Map<String, dynamic> issueJson({
  String id = 'abc-123',
  String identifier = 'LIN-42',
  String title = 'Fix login bug',
  String description = 'Users cannot log in with SSO.',
  String stateName = 'In Progress',
  int priority = 2,
  String url = 'https://linear.app/issue/LIN-42',
  String? assigneeId = 'user-1',
  List<String>? labels,
}) {
  return {
    'id': id,
    'identifier': identifier,
    'title': title,
    'description': description,
    'state': {'name': stateName},
    'priority': priority,
    'url': url,
    'assignee': {'id': assigneeId},
    'labels': {
      'nodes': (labels ?? const ['bug', 'frontend'])
          .map((n) => {'name': n})
          .toList(),
    },
  };
}

/// Wraps [issueJson] in a GraphQL `data.issue` envelope.
Map<String, dynamic> issueResponse({
  String id = 'abc-123',
  String identifier = 'LIN-42',
  String title = 'Fix login bug',
  String description = 'Users cannot log in with SSO.',
  String stateName = 'In Progress',
  int priority = 2,
  String url = 'https://linear.app/issue/LIN-42',
  String? assigneeId = 'user-1',
  List<String>? labels,
}) {
  return {
    'data': {
      'issue': issueJson(
        id: id,
        identifier: identifier,
        title: title,
        description: description,
        stateName: stateName,
        priority: priority,
        url: url,
        assigneeId: assigneeId,
        labels: labels,
      ),
    },
  };
}

/// GraphQL response for `issues.filter` (assigned list).
Map<String, dynamic> issuesListResponse(List<Map<String, dynamic>> issues) {
  return {
    'data': {
      'issues': {'nodes': issues},
    },
  };
}

/// GraphQL response for `issueCreate`.
Map<String, dynamic> createIssueResponse(Map<String, dynamic> issue) {
  return {
    'data': {
      'issueCreate': {
        'success': true,
        'issue': issue,
      },
    },
  };
}

/// GraphQL response for `issueUpdate` (success only, no issue body).
Map<String, dynamic> updateIssueSuccessResponse() {
  return {
    'data': {
      'issueUpdate': {'success': true},
    },
  };
}

/// GraphQL response for workflow states.
Map<String, dynamic> workflowStatesResponse(
  List<Map<String, dynamic>> states,
) {
  return {
    'data': {
      'issue': {
        'team': {
          'states': {'nodes': states},
        },
      },
    },
  };
}

/// GraphQL error response.
Map<String, dynamic> graphqlErrorResponse(String message) {
  return {
    'errors': [
      {'message': message},
    ],
  };
}

/// Creates a [Response] with [data] for Dio stubbing.
Response<Map<String, dynamic>> mockResponse(
  Map<String, dynamic> data, {
  int statusCode = 200,
}) {
  return Response<Map<String, dynamic>>(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: statusCode,
  );
}

void main() {
  late MockDio dio;
  late LinearTicketAdapter adapter;

  setUp(() {
    dio = MockDio();
    adapter = LinearTicketAdapter(dio, defaultTeamId: 'team-default');
  });

  // ---------------------------------------------------------------------------
  // LinearIssueDto.fromJson
  // ---------------------------------------------------------------------------
  group('LinearIssueDto.fromJson', () {
    test('parses a full issue JSON map', () {
      final json = issueJson(
        id: 'i1',
        identifier: 'LIN-1',
        title: 'Title',
        description: 'Desc',
        stateName: 'Todo',
        priority: 3,
        url: 'https://linear.app/issue/LIN-1',
        assigneeId: 'u1',
        labels: ['bug'],
      );

      final dto = LinearIssueDto.fromJson(json);

      expect(dto.id, 'i1');
      expect(dto.identifier, 'LIN-1');
      expect(dto.title, 'Title');
      expect(dto.description, 'Desc');
      expect(dto.stateName, 'Todo');
      expect(dto.priority, 3);
      expect(dto.url, 'https://linear.app/issue/LIN-1');
      expect(dto.assigneeId, 'u1');
      expect(dto.labels, ['bug']);
    });

    test('defaults missing fields to sensible values', () {
      final json = <String, dynamic>{
        'id': 'i2',
        'identifier': 'LIN-2',
        'title': 'T',
        'priority': 0,
      };

      final dto = LinearIssueDto.fromJson(json);

      expect(dto.id, 'i2');
      expect(dto.title, 'T');
      expect(dto.description, '');
      expect(dto.stateName, '');
      expect(dto.priority, 0);
      expect(dto.url, isNull);
      expect(dto.assigneeId, isNull);
      expect(dto.labels, isEmpty);
    });

    test('handles missing state, team, and assignee maps', () {
      final json = <String, dynamic>{
        'id': 'i3',
        'identifier': 'LIN-3',
        'title': 'T',
        'priority': 1,
      };

      final dto = LinearIssueDto.fromJson(json);

      expect(dto.stateName, '');
      expect(dto.assigneeId, isNull);
      expect(dto.teamName, '');
    });


    test('handles labels nodes with null entries', () {
      final json = <String, dynamic>{
        'id': 'i5',
        'identifier': 'LIN-5',
        'title': 'T',
        'priority': 0,
        'labels': {
          'nodes': [
            {'name': 'valid'},
            null,
            {'name': 'also-valid'},
            123,
          ],
        },
      };

      final dto = LinearIssueDto.fromJson(json);

      expect(dto.labels, ['valid', 'also-valid']);
    });
  });

  // ---------------------------------------------------------------------------
  // getByExternalId — field mapping (_toRemote)
  // ---------------------------------------------------------------------------
  group('getByExternalId', () {
    test('maps all DTO fields to RemoteTicket', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse(issueResponse(
                id: 'abc',
                identifier: 'LIN-99',
                title: 'Map test',
                description: 'Description text',
                stateName: 'In Progress',
                priority: 1,
                url: 'https://linear.app/issue/LIN-99',
                assigneeId: 'user-7',
                labels: ['a', 'b'],
              )));

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket, isNotNull);
      expect(ticket!.externalId, 'abc');
      expect(ticket.externalKey, 'LIN-99');
      expect(ticket.title, 'Map test');
      expect(ticket.description, 'Description text');
      expect(ticket.priority, TicketPriority.urgent);
      expect(ticket.url, 'https://linear.app/issue/LIN-99');
      expect(ticket.assigneeExternalId, 'user-7');
      expect(ticket.labels, ['a', 'b']);
      expect(ticket.status, TicketStatus.inProgress);
      expect(ticket.rawStatus, 'In Progress');
    });

    test('returns null when issue not found', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse({'data': {'issue': null}}),
      );

      final ticket = await adapter.getByExternalId('nonexistent');

      expect(ticket, isNull);
    });

    test('maps priority 0 to TicketPriority.none', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse(issueResponse(priority: 0)));

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.priority, TicketPriority.none);
    });

    test('maps priority 1 to TicketPriority.urgent', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse(issueResponse(priority: 1)));

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.priority, TicketPriority.urgent);
    });

    test('maps priority 3 to TicketPriority.medium', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse(issueResponse(priority: 3)));

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.priority, TicketPriority.medium);
    });

    test('maps priority 4 to TicketPriority.low', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse(issueResponse(priority: 4)));

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.priority, TicketPriority.low);
    });
  });

  // ---------------------------------------------------------------------------
  // Status normalization (_normalizeStatus)
  // ---------------------------------------------------------------------------
  group('status normalization', () {
    test('"In Progress" -> inProgress', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'In Progress')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.inProgress);
      expect(ticket.rawStatus, 'In Progress');
    });

    test('"In Review" -> inReview', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'In Review')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.inReview);
    });

    test('"Done" -> done', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'Done')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.done);
    });

    test('"Completed" -> done', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'Completed')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.done);
    });

    test('"Merged" -> done', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'Merged')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.done);
    });

    test('"Cancelled" -> cancelled', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'Cancelled')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.cancelled);
    });

    test('"Duplicate" -> cancelled', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'Duplicate')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.cancelled);
    });

    test('"Blocked" -> blocked', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'Blocked')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.blocked);
    });

    test('"Backlog" -> backlog', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'Backlog')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.backlog);
    });

    test('unknown state -> open (default)', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'Triage')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.open);
    });

    test('case-insensitive matching', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issueResponse(stateName: 'IN PROGRESS')),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.status, TicketStatus.inProgress);
    });
  });

  // ---------------------------------------------------------------------------
  // list
  // ---------------------------------------------------------------------------
  group('list', () {
    test('returns all assigned issues mapped to RemoteTicket', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issuesListResponse([
              issueJson(
                id: 'i1',
                identifier: 'LIN-1',
                title: 'First',
                stateName: 'Todo',
              ),
              issueJson(
                id: 'i2',
                identifier: 'LIN-2',
                title: 'Second',
                stateName: 'In Progress',
              ),
            ])),
      );

      final tickets = await adapter.list();

      expect(tickets.length, 2);
      expect(tickets[0].externalId, 'i1');
      expect(tickets[1].externalId, 'i2');
    });

    test('empty list when no issues', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse(issuesListResponse([])));

      final tickets = await adapter.list();

      expect(tickets, isEmpty);
    });

    test('filters by status when query.statuses is set', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issuesListResponse([
              issueJson(id: 'i1', stateName: 'Done'),
              issueJson(id: 'i2', stateName: 'In Progress'),
              issueJson(id: 'i3', stateName: 'Done'),
            ])),
      );

      final tickets = await adapter.list(
        query: const TicketQuery(
          statuses: {TicketStatus.done},
        ),
      );

      expect(tickets.length, 2);
      expect(tickets.every((t) => t.status == TicketStatus.done), isTrue);
    });

    test('respects query.limit', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issuesListResponse([
              issueJson(id: 'i1'),
              issueJson(id: 'i2'),
              issueJson(id: 'i3'),
              issueJson(id: 'i4'),
              issueJson(id: 'i5'),
            ])),
      );

      final tickets = await adapter.list(
        query: const TicketQuery(limit: 3),
      );

      expect(tickets.length, 3);
    });

    test('no filter when query.statuses is null', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issuesListResponse([
              issueJson(id: 'i1'),
            ])),
      );

      final tickets = await adapter.list(query: const TicketQuery());

      expect(tickets.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // create
  // ---------------------------------------------------------------------------
  group('create', () {
    test('creates issue and returns mapped RemoteTicket', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(createIssueResponse(issueJson(
              id: 'new-1',
              identifier: 'LIN-100',
              title: 'New issue',
              stateName: 'Todo',
            ))),
      );

      final ticket = await adapter.create(
        const RemoteTicketDraft(
          title: 'New issue',
          description: 'desc',
          priority: TicketPriority.high,
          providerExtras: {'teamId': 'team-custom'},
        ),
      );

      expect(ticket.externalId, 'new-1');
      expect(ticket.title, 'New issue');
    });

    test('uses defaultTeamId when draft has no teamId', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(createIssueResponse(issueJson())),
      );

      final ticket = await adapter.create(
        const RemoteTicketDraft(title: 'No team override'),
      );

      expect(ticket.externalId, 'abc-123');
    });

    test('throws StateError when no teamId available', () async {
      final noDefault = LinearTicketAdapter(dio);

      await expectLater(
        () => noDefault.create(const RemoteTicketDraft(title: 'No team')),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('teamId'),
        )),
      );
    });

    test('throws StateError when teamId is empty', () async {
      await expectLater(
        () => adapter.create(
          const RemoteTicketDraft(
            title: 'Empty',
            providerExtras: {'teamId': ''},
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError when create returns null issue', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse({
          'data': {
            'issueCreate': {'success': true, 'issue': null},
          },
        }),
      );

      await expectLater(
        () => adapter.create(
          const RemoteTicketDraft(
            title: 'Will be null',
            providerExtras: {'teamId': 't1'},
          ),
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('returned no issue'),
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // update
  // ---------------------------------------------------------------------------
  group('update', () {
    test('updates and returns refreshed ticket', () async {
      var callCount = 0;
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return mockResponse(updateIssueSuccessResponse());
        }
        return mockResponse(issueResponse(id: 'upd-1', title: 'Updated Title'));
      });

      final ticket = await adapter.update(
        'upd-1',
        const RemoteTicketPatch(title: 'Updated Title'),
      );

      expect(ticket.externalId, 'upd-1');
      expect(ticket.title, 'Updated Title');
    });

    test('throws StateError when issue not found after update', () async {
      var callCount = 0;
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return mockResponse(updateIssueSuccessResponse());
        }
        return mockResponse({'data': {'issue': null}});
      });

      await expectLater(
        () => adapter.update('ghost', const RemoteTicketPatch()),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not found'),
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // transitionStatus
  // ---------------------------------------------------------------------------
  group('transitionStatus', () {
    test('transitions when a matching state exists', () async {
      var callCount = 0;
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return mockResponse(workflowStatesResponse([
                {'id': 's1', 'name': 'Todo'},
                {'id': 's2', 'name': 'In Progress'},
                {'id': 's3', 'name': 'Done'},
              ]));
        }
        if (callCount == 2) {
          return mockResponse({
            'data': {'issueUpdate': {'success': true}}
          });
        }
        return mockResponse(
          issueResponse(id: 'tr-1', stateName: 'In Progress'),
        );
      });

      final ticket = await adapter.transitionStatus(
        'tr-1',
        TicketStatus.inProgress,
      );

      expect(ticket.status, TicketStatus.inProgress);
      expect(ticket.rawStatus, 'In Progress');
    });

    test('skips state update when no matching state found', () async {
      var callCount = 0;
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return mockResponse(workflowStatesResponse([
                {'id': 's1', 'name': 'Todo'},
              ]));
        }
        return mockResponse(issueResponse(id: 'tr-2', stateName: 'Todo'));
      });

      final ticket = await adapter.transitionStatus(
        'tr-2',
        TicketStatus.done,
      );

      expect(ticket.externalId, 'tr-2');
      expect(callCount, 2);
    });

    test('throws StateError when issue not found after transition', () async {
      var callCount = 0;
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return mockResponse(workflowStatesResponse([
                {'id': 's1', 'name': 'Done'},
              ]));
        }
        if (callCount == 2) {
          return mockResponse({
            'data': {'issueUpdate': {'success': true}}
          });
        }
        return mockResponse({'data': {'issue': null}});
      });

      await expectLater(
        () => adapter.transitionStatus('ghost', TicketStatus.done),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('not found'),
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // assign
  // ---------------------------------------------------------------------------
  group('assign', () {
    test('assigns a user and returns refreshed ticket', () async {
      var callCount = 0;
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return mockResponse({
            'data': {'issueUpdate': {'success': true}}
          });
        }
        return mockResponse(
          issueResponse(id: 'asgn-1', assigneeId: 'user-9'),
        );
      });

      final ticket = await adapter.assign('asgn-1', 'user-9');

      expect(ticket.externalId, 'asgn-1');
      expect(ticket.assigneeExternalId, 'user-9');
    });

    test('clears assignee when assigneeExternalId is null', () async {
      var callCount = 0;
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return mockResponse({
            'data': {'issueUpdate': {'success': true}}
          });
        }
        return mockResponse(
          issueResponse(id: 'asgn-2', assigneeId: null),
        );
      });

      final ticket = await adapter.assign('asgn-2', null);

      expect(ticket.assigneeExternalId, isNull);
    });

    test('throws StateError when issue not found after assign', () async {
      var callCount = 0;
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return mockResponse({
            'data': {'issueUpdate': {'success': true}}
          });
        }
        return mockResponse({'data': {'issue': null}});
      });

      await expectLater(
        () => adapter.assign('ghost', 'user-1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // watchAssigned
  // ---------------------------------------------------------------------------
  group('watchAssigned', () {
    test('yields all assigned issues as RemoteTickets', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(issuesListResponse([
              issueJson(id: 'w1', title: 'Watch 1', stateName: 'Todo'),
              issueJson(id: 'w2', title: 'Watch 2', stateName: 'Done'),
            ])),
      );

      final tickets = await adapter.watchAssigned().toList();

      expect(tickets.length, 2);
      expect(tickets[0].externalId, 'w1');
      expect(tickets[1].externalId, 'w2');
    });

    test('yields empty when no assigned issues', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer((_) async => mockResponse(issuesListResponse([])));

      final tickets = await adapter.watchAssigned().toList();

      expect(tickets, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Error handling — DioException / GraphQL errors
  // ---------------------------------------------------------------------------
  group('error handling', () {
    test('getByExternalId propagates DioException (non-cancel)', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
          message: 'Timeout',
        ),
      );

      await expectLater(
        () => adapter.getByExternalId('abc'),
        throwsA(isA<AppException>()),
      );
    });

    test('create propagates GraphQL errors', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(graphqlErrorResponse('Team not found')),
      );

      await expectLater(
        () => adapter.create(
          const RemoteTicketDraft(
            title: 'Bad',
            providerExtras: {'teamId': 'bad-team'},
          ),
        ),
        throwsA(isA<NetworkException>().having(
          (e) => e.message,
          'message',
          contains('Team not found'),
        )),
      );
    });

    test('list propagates GraphQL errors', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse(graphqlErrorResponse('Unauthorized')),
      );

      await expectLater(
        () => adapter.list(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Provider metadata
  // ---------------------------------------------------------------------------
  group('provider metadata', () {
    test('provider returns TicketProvider.linear', () {
      expect(adapter.provider.name, 'linear');
    });

    test('capabilities reflect Linear support', () {
      final caps = adapter.capabilities;
      expect(caps.supportsCreate, isTrue);
      expect(caps.supportsUpdate, isTrue);
      expect(caps.supportsStatusUpdate, isTrue);
      expect(caps.supportsAssignee, isTrue);
      expect(caps.supportsLabels, isTrue);
      expect(caps.supportsPriority, isTrue);
      expect(caps.supportsHierarchy, isFalse);
      expect(caps.supportsList, isTrue);
      expect(caps.supportsRemoteSync, isTrue);
    });

    test('allowedDomains includes Linear domains', () {
      expect(adapter.allowedDomains, contains('linear.app'));
      expect(adapter.allowedDomains, contains('api.linear.app'));
    });
  });

  // ---------------------------------------------------------------------------
  // Edge cases
  // ---------------------------------------------------------------------------
  group('edge cases', () {
    test('handles issue with no assignee gracefully', () async {
      final json = issueJson(assigneeId: 'ignored');
      json.remove('assignee');

      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse({'data': {'issue': json}}),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.assigneeExternalId, isNull);
    });

    test('handles issue with no url field', () async {
      final json = issueJson();
      json.remove('url');

      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse({'data': {'issue': json}}),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.url, isNull);
    });

    test('handles issues without labels field', () async {
      final json = issueJson(labels: null);
      json.remove('labels');

      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse({'data': {'issue': json}}),
      );

      final ticket = await adapter.getByExternalId('abc');

      expect(ticket!.labels, isEmpty);
    });

    test('handles issues list response with non-list nodes', () async {
      when(dio.post<Map<String, dynamic>>('', data: anyNamed('data')))
          .thenAnswer(
        (_) async => mockResponse({
          'data': {
            'issues': {'nodes': 'not-a-list'},
          },
        }),
      );

      final tickets = await adapter.list();

      expect(tickets, isEmpty);
    });
  });
}
