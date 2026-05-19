import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/tickets/linear/linear_graphql_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [LinearGraphQlClient] over an injectable [Dio]. Pins the
/// GraphQL response-shape flattening, the variables passed on each
/// mutation and the cancel-rethrow / Dio→NetworkException mapping.
void main() {
  late FakeAdapter adapter;
  late LinearGraphQlClient client;

  setUp(() {
    adapter = FakeAdapter();
    client = LinearGraphQlClient(Dio()..httpClientAdapter = adapter);
  });

  Map<String, dynamic> issueNode({String? id, String? identifier}) => {
    'id': id ?? 'abc',
    'identifier': identifier ?? 'LIN-1',
    'title': 'T',
    'description': 'D',
    'url': 'https://linear.app/issue/LIN-1',
    'state': {'name': 'In Progress'},
    'priority': 2,
    'team': {'name': 'Eng'},
    'assignee': {'id': 'u1'},
    'labels': {
      'nodes': [
        {'name': 'bug'},
        {'name': 'p1'},
      ],
    },
  };

  group('getAssignedIssues', () {
    test('parses the nested issues.nodes array', () async {
      adapter.nextBody({
        'data': {
          'issues': {
            'nodes': [
              issueNode(),
              'not-a-map',
              issueNode(id: 'two', identifier: 'LIN-2'),
            ],
          },
        },
      });
      final issues = await client.getAssignedIssues();
      expect(issues.map((i) => i.id).toList(), ['abc', 'two']);
      expect(issues.first.labels, ['bug', 'p1']);
      expect(issues.first.assigneeId, 'u1');
      expect(issues.first.teamName, 'Eng');
    });

    test('returns empty when issues is missing or not a list', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      expect(await client.getAssignedIssues(), isEmpty);
    });

    test('query payload carries the GraphQL query string', () async {
      adapter.nextBody({
        'data': {
          'issues': {'nodes': const []},
        },
      });
      await client.getAssignedIssues();
      final data = adapter.requests.single.data as Map<String, dynamic>;
      expect(data['query'], isA<String>());
    });

    test('rethrows a cancel DioException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.cancel,
      );
      await expectLater(
        client.getAssignedIssues(),
        throwsA(isA<DioException>()),
      );
    });

    test('maps a non-cancel DioException to NetworkException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 500),
      );
      await expectLater(
        client.getAssignedIssues(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('surfaces GraphQL errors as a NetworkException', () async {
      adapter.nextBody({
        'errors': [
          {'message': 'not authenticated'},
        ],
      });
      await expectLater(
        client.getAssignedIssues(),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.message,
            'message',
            contains('not authenticated'),
          ),
        ),
      );
    });
  });

  group('getIssue', () {
    test('parses the data.issue node', () async {
      adapter.nextBody({
        'data': {'issue': issueNode()},
      });
      final issue = await client.getIssue('abc');
      expect(issue!.identifier, 'LIN-1');
    });

    test('sends the issueId as a variable', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.getIssue('xyz');
      final vars = (adapter.requests.single.data as Map)['variables'] as Map;
      expect(vars['id'], 'xyz');
    });

    test('returns null when issue is not a map', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      expect(await client.getIssue('x'), isNull);
    });

    test('surfaces GraphQL errors', () async {
      adapter.nextBody({
        'errors': [
          {'message': 'not found'},
        ],
      });
      await expectLater(client.getIssue('x'), throwsA(isA<NetworkException>()));
    });
  });

  group('createIssue', () {
    test('parses data.issueCreate.issue', () async {
      adapter.nextBody({
        'data': {
          'issueCreate': {'success': true, 'issue': issueNode()},
        },
      });
      final issue = await client.createIssue(
        title: 'T',
        description: 'D',
        teamId: 'team-1',
      );
      expect(issue!.teamName, 'Eng');
    });

    test('builds input with title/description/teamId', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.createIssue(title: 'T', description: 'D', teamId: 'team-1');
      final input =
          ((adapter.requests.single.data as Map)['variables'] as Map)['input']
              as Map;
      expect(input['title'], 'T');
      expect(input['description'], 'D');
      expect(input['teamId'], 'team-1');
      expect(input.containsKey('priority'), isFalse);
      expect(input.containsKey('assigneeId'), isFalse);
    });

    test('forwards optional priority and assigneeId', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.createIssue(
        title: 'T',
        description: 'D',
        teamId: 'team-1',
        priority: 1,
        assigneeId: 'u9',
      );
      final input =
          ((adapter.requests.single.data as Map)['variables'] as Map)['input']
              as Map;
      expect(input['priority'], 1);
      expect(input['assigneeId'], 'u9');
    });

    test('returns null when issue node is absent', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      expect(
        await client.createIssue(
          title: 'T',
          description: 'D',
          teamId: 'team-1',
        ),
        isNull,
      );
    });
  });

  group('updateIssue', () {
    test('only includes fields that are provided', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.updateIssue('abc', title: 'New');
      final vars = (adapter.requests.single.data as Map)['variables'] as Map;
      expect(vars['id'], 'abc');
      final input = vars['input'] as Map;
      expect(input['title'], 'New');
      expect(input.containsKey('description'), isFalse);
      expect(input.containsKey('priority'), isFalse);
    });

    test('includes description and priority when provided', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.updateIssue('abc', description: 'D2', priority: 3);
      final input =
          ((adapter.requests.single.data as Map)['variables'] as Map)['input']
              as Map;
      expect(input['description'], 'D2');
      expect(input['priority'], 3);
      expect(input.containsKey('title'), isFalse);
    });

    test('completes when no GraphQL errors are present', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.updateIssue('abc');
      expect(adapter.requests.single.path, '');
    });

    test('surfaces GraphQL errors', () async {
      adapter.nextBody({
        'errors': [
          {'message': 'denied'},
        ],
      });
      await expectLater(
        client.updateIssue('abc', title: 'x'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('assignIssue', () {
    test('sends assigneeId variable', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.assignIssue('abc', 'u1');
      final vars = (adapter.requests.single.data as Map)['variables'] as Map;
      expect(vars['id'], 'abc');
      expect(vars['assigneeId'], 'u1');
    });

    test('accepts null assigneeId (clears assignee)', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.assignIssue('abc', null);
      final vars = (adapter.requests.single.data as Map)['variables'] as Map;
      expect(vars['assigneeId'], isNull);
    });
  });

  group('getWorkflowStatesForIssue', () {
    test('flattens data.issue.team.states.nodes', () async {
      adapter.nextBody({
        'data': {
          'issue': {
            'team': {
              'states': {
                'nodes': [
                  {'id': 's1', 'name': 'Todo'},
                  {'id': 's2', 'name': 'Done'},
                  {'id': '', 'name': 'Empty'},
                  'not-a-map',
                ],
              },
            },
          },
        },
      });
      final states = await client.getWorkflowStatesForIssue('abc');
      expect(states.map((s) => s.name).toList(), ['Todo', 'Done']);
    });

    test('returns empty when states is missing', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      expect(await client.getWorkflowStatesForIssue('abc'), isEmpty);
    });

    test('surfaces GraphQL errors', () async {
      adapter.nextBody({
        'errors': [
          {'message': 'denied'},
        ],
      });
      await expectLater(
        client.getWorkflowStatesForIssue('abc'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('updateIssueState', () {
    test('sends id and stateId variables', () async {
      adapter.nextBody({'data': <String, dynamic>{}});
      await client.updateIssueState('abc', 's9');
      final vars = (adapter.requests.single.data as Map)['variables'] as Map;
      expect(vars['id'], 'abc');
      expect(vars['stateId'], 's9');
    });

    test('surfaces GraphQL errors', () async {
      adapter.nextBody({
        'errors': [
          {'message': 'denied'},
        ],
      });
      await expectLater(
        client.updateIssueState('abc', 's9'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rethrows a cancel DioException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.cancel,
      );
      await expectLater(
        client.updateIssueState('abc', 's9'),
        throwsA(isA<DioException>()),
      );
    });
  });
}

class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Object _nextBody = <String, dynamic>{};
  Object? _throwNext;

  void nextBody(Object body) => _nextBody = body;

  set throwNext(Object value) => _throwNext = value;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final err = _throwNext;
    if (err != null) {
      _throwNext = null;
      throw err;
    }
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
