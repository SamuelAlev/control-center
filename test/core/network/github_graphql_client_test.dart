import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:control_center/core/network/github_graphql_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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
  late GitHubGraphQLClient client;

  setUp(() {
    fakeDio = _FakeDio();
    client = GitHubGraphQLClient(fakeDio);
  });

  RequestOptions ro() => RequestOptions();

  group('markFileAsViewed', () {
    test('sends correct GraphQL mutation', () async {
      String? actualUrl;
      Map<String, dynamic>? actualBody;
      fakeDio.onPost =
          <T>(
            path, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            actualUrl = path;
            actualBody = data as Map<String, dynamic>?;
            return Response(requestOptions: ro(), data: {}) as Response<T>;
          };

      await client.markFileAsViewed(
        pullRequestId: 'PR_1',
        path: 'lib/main.dart',
      );

      expect(actualUrl, 'https://api.github.com/graphql');
      expect(actualBody?['query'], contains('markFileAsViewed'));
      expect(actualBody?['variables'], {
        'pullRequestId': 'PR_1',
        'path': 'lib/main.dart',
      });
    });

    test('completes without error', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async => Response(requestOptions: ro(), data: {}) as Response<T>;

      await expectLater(
        client.markFileAsViewed(pullRequestId: 'PR_1', path: 'src/foo.dart'),
        completes,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            received = cancelToken;
            return Response(requestOptions: ro(), data: {}) as Response<T>;
          };
      final ct = CancelToken();
      await client.markFileAsViewed(
        pullRequestId: 'PR_1',
        path: 'lib/main.dart',
        cancelToken: ct,
      );
      expect(received, same(ct));
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );

      await expectLater(
        client.markFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: '404',
          );

      await expectLater(
        client.markFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('wraps connection error DioExceptions', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: 'No connection',
          );

      await expectLater(
        client.markFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('unmarkFileAsViewed', () {
    test('sends correct GraphQL mutation', () async {
      String? actualUrl;
      Map<String, dynamic>? actualBody;
      fakeDio.onPost =
          <T>(
            path, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            actualUrl = path;
            actualBody = data as Map<String, dynamic>?;
            return Response(requestOptions: ro(), data: {}) as Response<T>;
          };

      await client.unmarkFileAsViewed(
        pullRequestId: 'PR_2',
        path: 'test/foo_test.dart',
      );

      expect(actualUrl, 'https://api.github.com/graphql');
      expect(actualBody?['query'], contains('unmarkFileAsViewed'));
      expect(actualBody?['variables'], {
        'pullRequestId': 'PR_2',
        'path': 'test/foo_test.dart',
      });
    });

    test('completes without error', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async => Response(requestOptions: ro(), data: {}) as Response<T>;

      await expectLater(
        client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'src/bar.dart'),
        completes,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            received = cancelToken;
            return Response(requestOptions: ro(), data: {}) as Response<T>;
          };
      final ct = CancelToken();
      await client.unmarkFileAsViewed(
        pullRequestId: 'PR_1',
        path: 'lib/main.dart',
        cancelToken: ct,
      );
      expect(received, same(ct));
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );

      await expectLater(
        client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: '500',
          );

      await expectLater(
        client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('wraps timeout DioExceptions', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),

            message: 'timeout',
          );

      await expectLater(
        client.unmarkFileAsViewed(pullRequestId: 'PR_1', path: 'lib/main.dart'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('searchReviewRequestedPullRequests', () {
    Response<T> ok<T>(Object nodes) => Response(
      requestOptions: ro(),
      data: {
        'data': {
          'search': {'nodes': nodes},
        },
      },
    ) as Response<T>;

    test('builds a review-requested search scoped to the repos', () async {
      final bodies = <Map<String, dynamic>>[];
      fakeDio.onPost =
          <T>(
            path, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            bodies.add(data as Map<String, dynamic>);
            return ok<T>([
              {
                'number': 7,
                'title': 'Fix the thing',
                'url': 'https://github.com/o/r/pull/7',
                'repository': {'nameWithOwner': 'o/r'},
              },
            ]);
          };

      final nodes = await client.searchReviewRequestedPullRequests(
        reviewerLogin: 'octocat',
        repos: [(owner: 'o', name: 'r')],
      );

      expect(bodies, hasLength(1));
      // The search string is a *variable*, not interpolated into the query.
      expect(bodies.first['query'] as String, contains(r'search(query: $q'));
      final q = (bodies.first['variables'] as Map)['q'] as String;
      expect(q, contains('is:pr is:open draft:false review-requested:octocat'));
      expect(q, contains('repo:o/r'));
      expect(nodes, hasLength(1));
      expect(nodes.first['number'], 7);
    });

    test('chunks repos into separate requests (5 per query)', () async {
      var posts = 0;
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            posts++;
            return ok<T>(const []);
          };

      await client.searchReviewRequestedPullRequests(
        reviewerLogin: 'me',
        repos: List.generate(6, (i) => (owner: 'o', name: 'r$i')),
      );

      expect(posts, 2);
    });

    test('returns empty without a request when there are no repos', () async {
      var posts = 0;
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            posts++;
            return ok<T>(const []);
          };

      final nodes = await client.searchReviewRequestedPullRequests(
        reviewerLogin: 'me',
        repos: const [],
      );

      expect(nodes, isEmpty);
      expect(posts, 0);
    });

    test('swallows cancellation and returns empty', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );

      final nodes = await client.searchReviewRequestedPullRequests(
        reviewerLogin: 'me',
        repos: [(owner: 'o', name: 'r')],
      );

      expect(nodes, isEmpty);
    });
  });

  group('searchReviewedByPullRequests', () {
    test('builds a reviewed-by search and returns (repo, number) pairs',
        () async {
      Map<String, dynamic>? body;
      fakeDio.onPost =
          <T>(
            path, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            body = data as Map<String, dynamic>;
            return Response(
              requestOptions: ro(),
              data: {
                'data': {
                  'search': {
                    'nodes': [
                      {
                        'number': 7,
                        'repository': {'nameWithOwner': 'o/r'},
                      },
                      // A non-PR hit deserializes empty — must be skipped.
                      <String, dynamic>{},
                    ],
                  },
                },
              },
            ) as Response<T>;
          };

      final pairs = await client.searchReviewedByPullRequests(
        reviewerLogin: 'octocat',
        repos: [(owner: 'o', name: 'r')],
      );

      final q = (body!['variables'] as Map)['q'] as String;
      expect(q, contains('is:pr is:open reviewed-by:octocat'));
      expect(q, contains('repo:o/r'));
      expect(pairs, hasLength(1));
      expect(pairs.first.repoFullName, 'o/r');
      expect(pairs.first.number, 7);
    });

    test('returns empty without a request when there are no repos', () async {
      var posts = 0;
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) async {
            posts++;
            return Response(requestOptions: ro(), data: {}) as Response<T>;
          };

      final pairs = await client.searchReviewedByPullRequests(
        reviewerLogin: 'me',
        repos: const [],
      );

      expect(pairs, isEmpty);
      expect(posts, 0);
    });
  });
}
