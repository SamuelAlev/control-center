import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/tickets/linear/linear_graphql_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake Dio for testing [LinearGraphQlClient] without a real HTTP
/// stack.  Injects responses via [onPost] callback and captures the sent
/// payload so query/variable assertions stay pure-logic.
class _FakeDio implements Dio {
  _FakeDio();

  Future<Response<T>> Function<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  })?
  onPost;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final cb = onPost;
    if (cb == null) {
      throw UnimplementedError('onPost not set');
    }
    return cb<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeDio fakeDio;
  late LinearGraphQlClient client;

  setUp(() {
    fakeDio = _FakeDio();
    client = LinearGraphQlClient(fakeDio);
  });

  RequestOptions ro() => RequestOptions();

  /// Builds a success [Response] wrapping [graphqlData] inside
  /// `{'data': graphqlData}` — the shape the client expects.
  Response<T> ok<T>(Map<String, dynamic> graphqlData) => Response(
    requestOptions: ro(),
    data: {'data': graphqlData},
  ) as Response<T>;

  /// Builds a [Response] whose body contains GraphQL-level errors.
  Response<T> error<T>(List<Map<String, dynamic>> errors) => Response(
    requestOptions: ro(),
    data: {'errors': errors},
  ) as Response<T>;


  // -----------------------------------------------------------------------
  // Helper: a minimal valid issue JSON node used across parsing tests.
  // -----------------------------------------------------------------------
  Map<String, dynamic> issueJson({
    String id = 'abc-123',
    String identifier = 'LIN-1',
    String title = 'Fix login crash',
    String description = 'It crashes on null email.',
    String stateName = 'In Progress',
    int priority = 2,
    String teamName = 'Core',
    String? url = 'https://linear.app/issue/LIN-1',
    String? assigneeId = 'user-42',
    List<String> labels = const ['bug', 'p1'],
  }) {
    return {
      'id': id,
      'identifier': identifier,
      'title': title,
      'description': description,
      'state': {'name': stateName},
      'priority': priority,
      'team': {'name': teamName},
      'url': ?url,
      if (assigneeId != null) 'assignee': {'id': assigneeId},
      'labels': {
        'nodes': labels.map((n) => {'name': n}).toList(),
      },
    };
  }

  // =====================================================================
  // getAssignedIssues
  // =====================================================================
  group('getAssignedIssues', () {
    test('sends the correct GraphQL query with no variables', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({'issues': {'nodes': <Map<String, dynamic>>[]}});
          };

      await client.getAssignedIssues();

      final query = body!['query'] as String;
      expect(
        query,
        contains('issues(filter: { assignee: { isMe: { eq: true } } })'),
      );
      expect(body, isNot(contains('variables')));
    });

    test('parses an issue list into LinearIssueDto objects', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({
            'issues': {
              'nodes': [
                issueJson(id: 'i1', identifier: 'LIN-1', title: 'Fix a'),
                issueJson(id: 'i2', identifier: 'LIN-2', title: 'Fix b'),
              ],
            },
          });

      final issues = await client.getAssignedIssues();

      expect(issues, hasLength(2));
      expect(issues[0].id, 'i1');
      expect(issues[0].identifier, 'LIN-1');
      expect(issues[0].title, 'Fix a');
      expect(issues[0].stateName, 'In Progress');
      expect(issues[0].priority, 2);
      expect(issues[0].teamName, 'Core');
      expect(issues[0].url, 'https://linear.app/issue/LIN-1');
      expect(issues[0].assigneeId, 'user-42');
      expect(issues[0].labels, ['bug', 'p1']);
      expect(issues[1].id, 'i2');
    });

    test('skips non-map entries in the nodes list', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({
            'issues': {
              'nodes': [
                'not-a-map',
                42,
                true,
                issueJson(id: 'good'),
              ],
            },
          });

      final issues = await client.getAssignedIssues();

      expect(issues, hasLength(1));
      expect(issues.first.id, 'good');
    });

    test('returns empty list when nodes is not a List', () async {
      for (final nodes in <dynamic>[null, 'str', 5, {'a': 'b'}]) {
        fakeDio.onPost =
            <T>(
              String path, {
              Object? data,
              Map<String, dynamic>? queryParameters,
              CancelToken? cancelToken,
              Options? options,
              ProgressCallback? onSendProgress,
              ProgressCallback? onReceiveProgress,
            }) async => ok<T>({'issues': {'nodes': nodes}});

        final issues = await client.getAssignedIssues();
        expect(issues, isEmpty, reason: 'nodes=$nodes');
      }
    });

    test('returns empty list when response data is null', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async =>
              Response<Map<String, dynamic>>(requestOptions: ro(), data: null) as Response<T>;

      final issues = await client.getAssignedIssues();
      expect(issues, isEmpty);
    });

    test('returns empty list when response data has no issues key', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({});

      final issues = await client.getAssignedIssues();
      expect(issues, isEmpty);
    });

    test('throws NetworkException on GraphQL errors', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => error<T>([{'message': 'Authentication required'}]);

      await expectLater(
        client.getAssignedIssues(),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.code,
            'code',
            'graphql_error',
          ),
        ),
      );
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );

      await expectLater(
        client.getAssignedIssues(),
        throwsA(isA<DioException>()),
      );
    });

    test('maps non-cancel DioExceptions to NetworkException', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            message: 'Connection refused',
          );

      await expectLater(
        client.getAssignedIssues(),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // =====================================================================
  // getIssue
  // =====================================================================
  group('getIssue', () {
    test('sends query with id variable', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({'issue': issueJson()});
          };

      await client.getIssue('ISSUE-42');

      expect(body!['query'], contains(r'query GetIssue($id: String!)'));
      expect((body!['variables'] as Map)['id'], 'ISSUE-42');
    });

    test('parses an issue into LinearIssueDto', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({'issue': issueJson(id: 'iss-1', title: 'One')});

      final issue = await client.getIssue('iss-1');

      expect(issue, isNotNull);
      expect(issue!.id, 'iss-1');
      expect(issue.title, 'One');
    });

    test('returns null when issue is missing from response', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({});

      final issue = await client.getIssue('any');
      expect(issue, isNull);
    });

    test('returns null when issue is not a map', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({'issue': 'invalid'});

      final issue = await client.getIssue('any');
      expect(issue, isNull);
    });

    test('returns null when data is null', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async =>
              Response<Map<String, dynamic>>(requestOptions: ro(), data: null) as Response<T>;

      final issue = await client.getIssue('any');
      expect(issue, isNull);
    });

    test('throws NetworkException on GraphQL errors', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => error<T>([{'message': 'Not found'}]);

      await expectLater(
        client.getIssue('any'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.code,
            'code',
            'graphql_error',
          ),
        ),
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            received = cancelToken;
            return ok<T>({'issue': issueJson()});
          };

      final ct = CancelToken();
      await client.getIssue('iss', cancelToken: ct);
      expect(received, same(ct));
    });
  });

  // =====================================================================
  // createIssue
  // =====================================================================
  group('createIssue', () {
    test('sends mutation with required input fields', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({
              'issueCreate': {
                'success': true,
                'issue': issueJson(),
              },
            });
          };

      await client.createIssue(
        title: 'New bug',
        description: 'Details here',
        teamId: 'TEAM-1',
      );

      final query = body!['query'] as String;
      expect(query, contains('mutation CreateIssue'));
      // Ensure $input is literal, not Dart interpolation.
      expect(query, contains(r'$input'));
      expect(query, contains('IssueCreateInput!'));
      final vars = body!['variables'] as Map;
      final input = vars['input'] as Map;
      expect(input['title'], 'New bug');
      expect(input['description'], 'Details here');
      expect(input['teamId'], 'TEAM-1');
    });

    test('includes optional priority and assigneeId in input', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({
              'issueCreate': {
                'success': true,
                'issue': issueJson(),
              },
            });
          };

      await client.createIssue(
        title: 't',
        description: 'd',
        teamId: 'T1',
        priority: 1,
        assigneeId: 'U-1',
      );

      final input = (body!['variables'] as Map)['input'] as Map;
      expect(input['priority'], 1);
      expect(input['assigneeId'], 'U-1');
    });

    test('parses the created issue from issueCreate.issue', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({
            'issueCreate': {
              'success': true,
              'issue': issueJson(id: 'new-1', title: 'Created'),
            },
          });

      final issue = await client.createIssue(
        title: 't',
        description: 'd',
        teamId: 'T1',
      );

      expect(issue, isNotNull);
      expect(issue!.id, 'new-1');
      expect(issue.title, 'Created');
    });

    test('returns null when issueCreate is missing', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({});

      final issue = await client.createIssue(
        title: 't',
        description: 'd',
        teamId: 'T1',
      );

      expect(issue, isNull);
    });

    test('returns null when issueCreate.issue is not a map', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({
            'issueCreate': {'success': true, 'issue': null},
          });

      final issue = await client.createIssue(
        title: 't',
        description: 'd',
        teamId: 'T1',
      );

      expect(issue, isNull);
    });
  });

  // =====================================================================
  // updateIssue
  // =====================================================================
  group('updateIssue', () {
    test('sends mutation with id and input variables', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({});
          };

      await client.updateIssue('ISS-1', title: 'New title');

      expect(body!['query'], contains('mutation UpdateIssue'));
      final vars = body!['variables'] as Map;
      expect(vars['id'], 'ISS-1');
      final input = vars['input'] as Map;
      expect(input['title'], 'New title');
      expect(input, isNot(contains('description')));
    });

    test('includes only supplied optional fields in input', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({});
          };

      await client.updateIssue('ISS-1', description: 'Updated desc');

      final input = (body!['variables'] as Map)['input'] as Map;
      expect(input['description'], 'Updated desc');
      expect(input, isNot(contains('title')));
    });

    test('includes priority when supplied', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({});
          };

      await client.updateIssue('ISS-1', priority: 3);

      final input = (body!['variables'] as Map)['input'] as Map;
      expect(input['priority'], 3);
    });

    test('completes without error on success response', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({});

      await expectLater(
        client.updateIssue('ISS-1', title: 't'),
        completes,
      );
    });

    test('throws on GraphQL errors', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => error<T>([{'message': 'Permission denied'}]);

      await expectLater(
        client.updateIssue('ISS-1'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.code,
            'code',
            'graphql_error',
          ),
        ),
      );
    });
  });

  // =====================================================================
  // assignIssue
  // =====================================================================
  group('assignIssue', () {
    test('sends mutation with id and assigneeId', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({});
          };

      await client.assignIssue('ISS-1', 'U-99');

      final vars = body!['variables'] as Map;
      expect(vars['id'], 'ISS-1');
      expect(vars['assigneeId'], 'U-99');
    });

    test('sends null assigneeId to clear assignee', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({});
          };

      await client.assignIssue('ISS-1', null);

      final vars = body!['variables'] as Map;
      expect(vars['assigneeId'], isNull);
    });

    test('completes without error on success', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({});

      await expectLater(
        client.assignIssue('ISS-1', 'U-1'),
        completes,
      );
    });
  });

  // =====================================================================
  // getWorkflowStatesForIssue
  // =====================================================================
  group('getWorkflowStatesForIssue', () {
    test('sends query with issue id variable', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({
              'issue': {
                'team': {
                  'states': {
                    'nodes': [
                      {'id': 's1', 'name': 'Todo'},
                    ],
                  },
                },
              },
            });
          };

      await client.getWorkflowStatesForIssue('ISS-1');

      expect(body!['query'], contains(r'query States($id: String!)'));
      expect((body!['variables'] as Map)['id'], 'ISS-1');
    });

    test('parses state nodes into id/name records', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({
            'issue': {
              'team': {
                'states': {
                  'nodes': [
                    {'id': 'backlog', 'name': 'Backlog'},
                    {'id': 'done', 'name': 'Done'},
                  ],
                },
              },
            },
          });

      final states = await client.getWorkflowStatesForIssue('ISS-1');

      expect(states, hasLength(2));
      expect(states[0].id, 'backlog');
      expect(states[0].name, 'Backlog');
      expect(states[1].id, 'done');
      expect(states[1].name, 'Done');
    });

    test('filters out entries with empty id', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({
            'issue': {
              'team': {
                'states': {
                  'nodes': [
                    {'id': '', 'name': 'Empty'},
                    {'id': 'valid', 'name': 'Valid'},
                    {'id': null, 'name': 'Null id'},
                  ],
                },
              },
            },
          });

      final states = await client.getWorkflowStatesForIssue('ISS-1');

      expect(states, hasLength(1));
      expect(states.first.id, 'valid');
    });

    test('returns empty list when states path is missing', () async {
      final testCases = <Map<String, dynamic>>[
        <String, dynamic>{},
        <String, dynamic>{'issue': <String, dynamic>{}},
        <String, dynamic>{'issue': <String, dynamic>{'team': <String, dynamic>{}}},
        <String, dynamic>{'issue': <String, dynamic>{'team': <String, dynamic>{'states': null}}},
      ];
      for (final tc in testCases) {
        fakeDio.onPost =
            <T>(
              String path, {
              Object? data,
              Map<String, dynamic>? queryParameters,
              CancelToken? cancelToken,
              Options? options,
              ProgressCallback? onSendProgress,
              ProgressCallback? onReceiveProgress,
            }) async => ok<T>(tc);

        final states = await client.getWorkflowStatesForIssue('ISS-1');
        expect(states, isEmpty, reason: 'tc=$tc');
      }
    });

    test('handles missing name gracefully', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({
            'issue': {
              'team': {
                'states': {
                  'nodes': [
                    {'id': 's1'},
                  ],
                },
              },
            },
          });

      final states = await client.getWorkflowStatesForIssue('ISS-1');

      expect(states, hasLength(1));
      expect(states.first.id, 's1');
      expect(states.first.name, '');
    });
  });

  // =====================================================================
  // updateIssueState
  // =====================================================================
  group('updateIssueState', () {
    test('sends mutation with id and stateId variables', () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>?;
            return ok<T>({});
          };

      await client.updateIssueState('ISS-1', 'state-done');

      final vars = body!['variables'] as Map;
      expect(vars['id'], 'ISS-1');
      expect(vars['stateId'], 'state-done');
    });

    test('completes on success', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({});

      await expectLater(
        client.updateIssueState('ISS-1', 's1'),
        completes,
      );
    });
  });

  // =====================================================================
  // GraphQL error handling (_checkGraphQLErrors)
  // =====================================================================
  group('GraphQL error handling', () {
    test('extracts messages from multiple errors and joins with "; "', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => error<T>([
            {'message': 'First error'},
            {'message': 'Second error'},
          ]);

      await expectLater(
        client.getIssue('x'),
        throwsA(
          isA<NetworkException>()
              .having(
                (e) => e.message,
                'message',
                'First error; Second error',
              )
              .having((e) => e.code, 'code', 'graphql_error'),
        ),
      );
    });

    test('includes raw response body in the exception', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => error<T>([{'message': 'boom'}]);

      await expectLater(
        client.getIssue('x'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.responseBody,
            'responseBody',
            contains('boom'),
          ),
        ),
      );
    });

    test('handles error objects without a message key', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => error<T>([{'other': 'stuff'}]);

      await expectLater(
        client.getIssue('x'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.code,
            'code',
            'graphql_error',
          ),
        ),
      );
    });

    test('does not throw when errors list is empty', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async =>
              Response(
                requestOptions: ro(),
                data: {'errors': <dynamic>[]},
              ) as Response<T>;

      // Should not throw: getIssue returns null when issue is missing.
      final issue = await client.getIssue('x');
      expect(issue, isNull);
    });

    test('does not throw when errors key is absent', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) async => ok<T>({});

      // getIssue returns null when issue is missing — but no graphql error.
      final issue = await client.getIssue('x');
      expect(issue, isNull);
    });
  });

  // =====================================================================
  // DioException mapping (covers all methods via getIssue as proxy)
  // =====================================================================
  group('DioException mapping', () {
    test('rethrows cancel-type DioExceptions unchanged', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );

      await expectLater(
        client.getIssue('x'),
        throwsA(isA<DioException>()),
      );
    });

    test('maps 401 DioExceptions to NetworkException', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            response: Response(requestOptions: ro(), statusCode: 401),
          );

      await expectLater(
        client.getIssue('x'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('maps 404 DioExceptions to NetworkException', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            response: Response(requestOptions: ro(), statusCode: 404),
          );

      await expectLater(
        client.getIssue('x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('maps connection-timeout DioExceptions to NetworkException', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.connectionTimeout,
          );

      await expectLater(
        client.getIssue('x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('maps connection-error DioExceptions to NetworkException', () async {
      fakeDio.onPost =
          <T>(
            String path, {
            Object? data,
            Map<String, dynamic>? queryParameters,
            CancelToken? cancelToken,
            Options? options,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.connectionError,
          );

      await expectLater(
        client.getIssue('x'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
