import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_check_run.dart';
import 'package:cc_infra/src/network/models/github_review.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDio implements Dio {
  _FakeDio();

  Future<Response<T>> Function<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  })?
  onGet;

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

  Future<Response<T>> Function<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  })?
  onDelete;

  Future<Response<T>> Function<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  })?
  onPatch;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    final cb = onGet;
    if (cb == null) {
      throw UnimplementedError('onGet not set');
    }
    return cb<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

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
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    final cb = onDelete;
    if (cb == null) {
      throw UnimplementedError('onDelete not set');
    }
    return cb<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final cb = onPatch;
    if (cb == null) {
      throw UnimplementedError('onPatch not set');
    }
    return cb<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeDio fakeDio;
  late GitHubPrClient client;

  setUp(() {
    fakeDio = _FakeDio();
    client = GitHubPrClient(fakeDio);
  });

  RequestOptions ro() => RequestOptions();

  group('listOpenPullRequests', () {
    test('returns list of open PRs', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {'number': 1, 'html_url': 'u'},
                        {'number': 2, 'html_url': 'u'},
                      ]
                      as T?,
            ),
          );

      final result = await client.listOpenPullRequestsPage('owner', 'repo');
      expect(result.items.length, 2);
      expect(result.items[0].number, 1);
    });

    test('returns empty list for null data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) =>
              Future.value(Response<T>(requestOptions: ro(), data: null as T?));

      final result = await client.listOpenPullRequestsPage('owner', 'repo');
      expect(result.items, isEmpty);
    });

    test('returns empty list for non-list data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'not a list' as T?),
          );

      final result = await client.listOpenPullRequestsPage('owner', 'repo');
      expect(result.items, isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listOpenPullRequestsPage('', 'repo'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for empty repo', () {
      expect(
        () => client.listOpenPullRequestsPage('owner', ''),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) {
            received = cancelToken;
            return Future.value(
              Response<T>(requestOptions: ro(), data: [] as T?),
            );
          };
      final ct = CancelToken();
      await client.listOpenPullRequestsPage('owner', 'repo', cancelToken: ct);
      expect(received, same(ct));
    });

    test('rethrows DioExceptions of type cancel', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.listOpenPullRequestsPage('owner', 'repo'),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: 'timeout',
          );
      await expectLater(
        client.listOpenPullRequestsPage('owner', 'repo'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('calls correct URL with query parameters', () async {
      String? actualUrl;
      Map<String, dynamic>? actualParams;
      fakeDio.onGet =
          <T>(
            path, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) {
            actualUrl = path;
            actualParams = queryParameters;
            return Future.value(
              Response<T>(requestOptions: ro(), data: [] as T?),
            );
          };
      await client.listOpenPullRequestsPage('owner', 'repo');
      expect(actualUrl, 'https://api.github.com/repos/owner/repo/pulls');
      expect(actualParams, containsPair('state', 'open'));
    });
  });

  group('listRequestedReviews', () {
    test('returns PRs from search items', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  {
                        'items': [
                          {'number': 10, 'html_url': 'u'},
                        ],
                      }
                      as T?,
            ),
          );
      final result = await client.listRequestedReviews('owner', 'repo');
      expect(result.length, 1);
      expect(result[0].number, 10);
    });

    test('returns empty list when items is null', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(Response<T>(requestOptions: ro(), data: <String, dynamic>{} as T?));
      expect(await client.listRequestedReviews('owner', 'repo'), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listRequestedReviews('', 'repo'),
        throwsArgumentError,
      );
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.listRequestedReviews('owner', 'repo'),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: 'not found',
          );
      await expectLater(
        client.listRequestedReviews('owner', 'repo'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getPullRequest', () {
    test('returns a PR when data is map', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data: {'number': 42, 'html_url': 'u'} as T?,
            ),
          );
      final result = await client.getPullRequest('owner', 'repo', 42);
      expect(result!.number, 42);
    });

    test('returns null when data is not a map', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'not a map' as T?),
          );
      expect(await client.getPullRequest('owner', 'repo', 42), isNull);
    });

    test('returns null for null data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) =>
              Future.value(Response<T>(requestOptions: ro(), data: null as T?));
      expect(await client.getPullRequest('owner', 'repo', 42), isNull);
    });

    test('throws ArgumentError for empty owner', () {
      expect(() => client.getPullRequest('', 'repo', 42), throwsArgumentError);
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) {
            received = cancelToken;
            return Future.value(
              Response<T>(requestOptions: ro(), data: {'number': 1} as T?),
            );
          };
      final ct = CancelToken();
      await client.getPullRequest('owner', 'repo', 1, cancelToken: ct);
      expect(received, same(ct));
    });

    test('wraps DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: 'error',
          );
      await expectLater(
        client.getPullRequest('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getPullRequestDiff', () {
    test('returns diff text', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'diff --git' as T?),
          );
      expect(
        await client.getPullRequestDiff('owner', 'repo', 42),
        'diff --git',
      );
    });

    test('returns empty string for null data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) =>
              Future.value(Response<T>(requestOptions: ro(), data: null as T?));
      expect(await client.getPullRequestDiff('owner', 'repo', 42), '');
    });

    test('sends Accept diff header', () async {
      Options? receivedOptions;
      fakeDio.onGet =
          <T>(
            path, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) {
            receivedOptions = options;
            return Future.value(
              Response<T>(requestOptions: ro(), data: 'diff' as T?),
            );
          };
      await client.getPullRequestDiff('owner', 'repo', 1);
      expect(
        receivedOptions?.headers?['Accept'],
        'application/vnd.github.diff',
      );
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.getPullRequestDiff('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.getPullRequestDiff('owner', 'repo', 1),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: 'timeout',
          );
      await expectLater(
        client.getPullRequestDiff('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('listPullRequestFiles', () {
    test('returns list of files', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {
                          'filename': 'lib/main.dart',
                          'status': 'modified',
                          'additions': 5,
                          'deletions': 2,
                          'changes': 7,
                        },
                        {
                          'filename': 'lib/foo.dart',
                          'status': 'added',
                          'additions': 10,
                          'deletions': 0,
                          'changes': 10,
                        },
                      ]
                      as T?,
            ),
          );
      final result = await client.listPullRequestFiles('owner', 'repo', 42);
      expect(result.length, 2);
      expect(result[0].filename, 'lib/main.dart');
    });

    test('returns empty list for null data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) =>
              Future.value(Response<T>(requestOptions: ro(), data: null as T?));
      expect(await client.listPullRequestFiles('owner', 'repo', 42), isEmpty);
    });

    test('sends per_page query parameter', () async {
      Map<String, dynamic>? actualParams;
      fakeDio.onGet =
          <T>(
            path, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) {
            actualParams = queryParameters;
            return Future.value(
              Response<T>(requestOptions: ro(), data: [] as T?),
            );
          };
      await client.listPullRequestFiles('owner', 'repo', 1);
      expect(actualParams, containsPair('per_page', 100));
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listPullRequestFiles('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) {
            received = cancelToken;
            return Future.value(
              Response<T>(requestOptions: ro(), data: [] as T?),
            );
          };
      final ct = CancelToken();
      await client.listPullRequestFiles('owner', 'repo', 1, cancelToken: ct);
      expect(received, same(ct));
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.listPullRequestFiles('owner', 'repo', 1),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: '404',
          );
      await expectLater(
        client.listPullRequestFiles('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });

    test('filters out non-map items', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {
                          'filename': 'a.dart',
                          'status': 'modified',
                          'additions': 1,
                          'deletions': 0,
                          'changes': 1,
                        },
                        'not a map',
                        42,
                      ]
                      as T?,
            ),
          );
      final result = await client.listPullRequestFiles('owner', 'repo', 1);
      expect(result.length, 1);
      expect(result[0].filename, 'a.dart');
    });
  });

  group('listPullRequestCommits', () {
    test('returns list of commits', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {
                          'sha': 'abc123',
                          'commit': {
                            'message': 'fix bug',
                            'author': {
                              'name': 'dev',
                              'email': 'dev@test.com',
                              'date': '2024-01-01T00:00:00Z',
                            },
                          },
                        },
                      ]
                      as T?,
            ),
          );
      final result = await client.listPullRequestCommits('owner', 'repo', 42);
      expect(result.length, 1);
      expect(result[0].sha, 'abc123');
    });

    test('returns empty list for null data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) =>
              Future.value(Response<T>(requestOptions: ro(), data: null as T?));
      expect(await client.listPullRequestCommits('owner', 'repo', 42), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listPullRequestCommits('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('wraps DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: 'timeout',
          );
      await expectLater(
        client.listPullRequestCommits('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getCommitFiles', () {
    test('returns files from commit', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  {
                        'files': [
                          {
                            'filename': 'src/app.ts',
                            'status': 'modified',
                            'additions': 3,
                            'deletions': 1,
                            'changes': 4,
                          },
                        ],
                      }
                      as T?,
            ),
          );
      final result = await client.getCommitFiles('owner', 'repo', 'abc123');
      expect(result.length, 1);
      expect(result[0].filename, 'src/app.ts');
    });

    test('returns empty list for empty sha', () async {
      expect(await client.getCommitFiles('owner', 'repo', ''), isEmpty);
    });

    test('returns empty list when data is not map', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'not a map' as T?),
          );
      expect(await client.getCommitFiles('owner', 'repo', 'abc123'), isEmpty);
    });

    test('returns empty list when files is null', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(Response<T>(requestOptions: ro(), data: {} as T?));
      expect(await client.getCommitFiles('owner', 'repo', 'abc123'), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.getCommitFiles('', 'repo', 'abc123'),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) {
            received = cancelToken;
            return Future.value(
              Response<T>(requestOptions: ro(), data: {'files': []} as T?),
            );
          };
      final ct = CancelToken();
      await client.getCommitFiles('owner', 'repo', 'sha', cancelToken: ct);
      expect(received, same(ct));
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.getCommitFiles('owner', 'repo', 'sha'),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: '404',
          );
      await expectLater(
        client.getCommitFiles('owner', 'repo', 'sha'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('listPullRequestReviews', () {
    test('returns list of reviews', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {'id': 1, 'state': 'APPROVED', 'body': 'LGTM'},
                        {
                          'id': 2,
                          'state': 'CHANGES_REQUESTED',
                          'body': 'Needs work',
                        },
                      ]
                      as T?,
            ),
          );
      final result = await client.listPullRequestReviews('owner', 'repo', 42);
      expect(result.length, 2);
      expect(result[0].state, GitHubReviewState.approved);
    });

    test('returns empty list for null data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) =>
              Future.value(Response<T>(requestOptions: ro(), data: null as T?));
      expect(await client.listPullRequestReviews('owner', 'repo', 42), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listPullRequestReviews('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('wraps DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: 'reset',
          );
      await expectLater(
        client.listPullRequestReviews('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('listPullRequestReviewComments', () {
    test('returns list of review comments', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {
                          'id': 1,
                          'body': 'Please fix',
                          'path': 'src/main.dart',
                          'diff_hunk': '@@...',
                        },
                      ]
                      as T?,
            ),
          );
      final result = await client.listPullRequestReviewComments(
        'owner',
        'repo',
        42,
      );
      expect(result.length, 1);
      expect(result[0].id, 1);
    });

    test('returns empty list for null data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) =>
              Future.value(Response<T>(requestOptions: ro(), data: null as T?));
      expect(
        await client.listPullRequestReviewComments('owner', 'repo', 42),
        isEmpty,
      );
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listPullRequestReviewComments('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.listPullRequestReviewComments('owner', 'repo', 1),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('listIssueComments', () {
    test('returns list of issue comments', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {'id': 1, 'body': 'Working'},
                        {'id': 2, 'body': 'Done'},
                      ]
                      as T?,
            ),
          );
      final result = await client.listIssueComments('owner', 'repo', 42);
      expect(result.length, 2);
      expect(result[0].id, 1);
    });

    test('returns empty list for null data', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) =>
              Future.value(Response<T>(requestOptions: ro(), data: null as T?));
      expect(await client.listIssueComments('owner', 'repo', 42), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listIssueComments('', 'repo', 1),
        throwsArgumentError,
      );
    });

    test('wraps DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: 'timeout',
          );
      await expectLater(
        client.listIssueComments('owner', 'repo', 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('listCheckRuns', () {
    test('returns check runs', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  {
                        'check_runs': [
                          {
                            'id': 1,
                            'name': 'build',
                            'status': 'completed',
                            'conclusion': 'success',
                            'app': {'name': 'GitHub Actions'},
                            'html_url': 'https://e.com',
                          },
                        ],
                      }
                      as T?,
            ),
          );
      final result = await client.listCheckRuns('owner', 'repo', 'abc123');
      expect(result.length, 1);
      expect(result[0].name, 'build');
      expect(result[0].status, GitHubCheckStatus.completed);
    });

    test('returns empty list for empty ref', () async {
      expect(await client.listCheckRuns('owner', 'repo', ''), isEmpty);
    });

    test('returns empty list when data is not map', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'not a map' as T?),
          );
      expect(await client.listCheckRuns('owner', 'repo', 'abc123'), isEmpty);
    });

    test('returns empty list when check_runs is null', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(Response<T>(requestOptions: ro(), data: {} as T?));
      expect(await client.listCheckRuns('owner', 'repo', 'abc123'), isEmpty);
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.listCheckRuns('', 'repo', 'ref'),
        throwsArgumentError,
      );
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.listCheckRuns('owner', 'repo', 'ref'),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            message: '404',
          );
      await expectLater(
        client.listCheckRuns('owner', 'repo', 'ref'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('createPullRequest', () {
    test('returns created PR data', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: {'number': 99} as T?),
          );
      final result = await client.createPullRequest(
        'owner',
        'repo',
        title: 'New',
        body: 'Desc',
        head: 'f',
        base: 'm',
      );
      expect(result['number'], 99);
    });

    test('returns empty map for non-map response', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'not a map' as T?),
          );
      final result = await client.createPullRequest(
        'owner',
        'repo',
        title: 'New',
        body: 'Desc',
        head: 'f',
        base: 'm',
      );
      expect(result, isEmpty);
    });

    test('sends correct POST body', () async {
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
          }) {
            actualUrl = path;
            actualBody = data as Map<String, dynamic>?;
            return Future.value(
              Response<T>(requestOptions: ro(), data: {} as T?),
            );
          };
      await client.createPullRequest(
        'owner',
        'repo',
        title: 'Title',
        body: 'Body',
        head: 'head',
        base: 'base',
      );
      expect(actualUrl, 'https://api.github.com/repos/owner/repo/pulls');
      expect(actualBody, {
        'title': 'Title',
        'body': 'Body',
        'head': 'head',
        'base': 'base',
        'draft': false,
      });
    });

    test('throws ArgumentError for empty owner', () async {
      await expectLater(
        client.createPullRequest(
          '',
          'repo',
          title: 't',
          body: 'b',
          head: 'h',
          base: 'b',
        ),
        throwsArgumentError,
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
          }) {
            received = cancelToken;
            return Future.value(
              Response<T>(requestOptions: ro(), data: {} as T?),
            );
          };
      final ct = CancelToken();
      await client.createPullRequest(
        'owner',
        'repo',
        title: 't',
        body: 'b',
        head: 'h',
        base: 'b',
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
        client.createPullRequest(
          'owner',
          'repo',
          title: 't',
          body: 'b',
          head: 'h',
          base: 'b',
        ),
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
  
            message: '422',
          );
      await expectLater(
        client.createPullRequest(
          'owner',
          'repo',
          title: 't',
          body: 'b',
          head: 'h',
          base: 'b',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('fromJson round-trip', () {
    test('PR includes nodeId and headRef', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  {
                        'number': 1,
                        'node_id': 'PR_nodeId',
                        'head': {'sha': 'abc', 'ref': 'feature/x'},
                        'user': {'login': 'dev', 'avatar_url': 'a'},
                      }
                      as T?,
            ),
          );
      final result = await client.getPullRequest('owner', 'repo', 1);
      expect(result!.nodeId, 'PR_nodeId');
      expect(result.headRef, 'feature/x');
    });

    test('PR file includes previousFilename for renames', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {
                          'filename': 'new.dart',
                          'status': 'renamed',
                          'additions': 0,
                          'deletions': 0,
                          'changes': 0,
                          'previous_filename': 'old.dart',
                        },
                      ]
                      as T?,
            ),
          );
      final result = await client.listPullRequestFiles('owner', 'repo', 1);
      expect(result[0].previousFilename, 'old.dart');
    });

    test('review comment includes line and diffHunk', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {
                          'id': 5,
                          'body': 'N',
                          'path': 'f.dart',
                          'diff_hunk': '@@',
                          'line': 42,
                          'original_line': 40,
                          'start_line': 38,
                        },
                      ]
                      as T?,
            ),
          );
      final result = await client.listPullRequestReviewComments(
        'owner',
        'repo',
        1,
      );
      expect(result[0].line, 42);
      expect(result[0].originalLine, 40);
    });

    test('commit includes author and committedAt', () async {
      fakeDio.onGet =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data:
                  [
                        {
                          'sha': 'def456',
                          'commit': {
                            'message': 'feat',
                            'author': {
                              'name': 'Alice',
                              'email': 'a@t.com',
                              'date': '2024-06-15T12:00:00Z',
                            },
                          },
                          'author': {'login': 'alice', 'avatar_url': 'a'},
                        },
                      ]
                      as T?,
            ),
          );
      final result = await client.listPullRequestCommits('owner', 'repo', 1);
      expect(result[0].authorName, 'Alice');
      expect(result[0].committedAt, DateTime.utc(2024, 6, 15, 12, 0, 0));
    });
  });

  group('postReviewComment', () {
    test('returns created review comment', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data: {
                'id': 777,
                'body': 'New comment',
                'path': 'lib/main.dart',
                'diff_hunk': '@@...',
              } as T?,
            ),
          );
      final result = await client.postReviewComment(
        'owner',
        'repo',
        prNumber: 42,
        commitSha: 'abc123',
        path: 'lib/main.dart',
        line: 10,
        side: 'RIGHT',
        body: 'New comment',
      );
      expect(result.id, 777);
      expect(result.body, 'New comment');
    });

    test('includes startLine and startSide for multi-line comments', () async {
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
          }) {
            actualBody = data as Map<String, dynamic>?;
            return Future.value(
              Response<T>(
                requestOptions: ro(),
                data: {'id': 1, 'body': 'm'} as T?,
              ),
            );
          };
      await client.postReviewComment(
        'owner',
        'repo',
        prNumber: 1,
        commitSha: 'sha',
        path: 'f.dart',
        line: 20,
        side: 'RIGHT',
        body: 'Multi-line',
        startLine: 15,
        startSide: 'RIGHT',
      );
      expect(actualBody?['start_line'], 15);
      expect(actualBody?['start_side'], 'RIGHT');
    });

    test('omits startLine when equal to line', () async {
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
          }) {
            actualBody = data as Map<String, dynamic>?;
            return Future.value(
              Response<T>(
                requestOptions: ro(),
                data: {'id': 1, 'body': 'm'} as T?,
              ),
            );
          };
      await client.postReviewComment(
        'owner',
        'repo',
        prNumber: 1,
        commitSha: 'sha',
        path: 'f.dart',
        line: 10,
        side: 'RIGHT',
        body: 'Single line',
        startLine: 10,
      );
      expect(actualBody?.containsKey('start_line'), isFalse);
    });

    test('posts to correct URL', () async {
      String? actualUrl;
      fakeDio.onPost =
          <T>(
            path, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) {
            actualUrl = path;
            return Future.value(
              Response<T>(
                requestOptions: ro(),
                data: {'id': 1, 'body': 'm'} as T?,
              ),
            );
          };
      await client.postReviewComment(
        'owner',
        'repo',
        prNumber: 42,
        commitSha: 'sha',
        path: 'f.dart',
        line: 1,
        side: 'RIGHT',
        body: 'Test',
      );
      expect(
        actualUrl,
        'https://api.github.com/repos/owner/repo/pulls/42/comments',
      );
    });

    test('throws for non-map response', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'not a map' as T?),
          );
      await expectLater(
        client.postReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          commitSha: 'sha',
          path: 'f.dart',
          line: 1,
          side: 'RIGHT',
          body: 'Test',
        ),
        throwsFormatException,
      );
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.postReviewComment(
          '',
          'repo',
          prNumber: 1,
          commitSha: 'sha',
          path: 'f.dart',
          line: 1,
          side: 'RIGHT',
          body: 'Test',
        ),
        throwsArgumentError,
      );
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
        client.postReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          commitSha: 'sha',
          path: 'f.dart',
          line: 1,
          side: 'RIGHT',
          body: 'Test',
        ),
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
  
            response: Response(
              requestOptions: ro(),
              statusCode: 422,
            ),
            message: 'Unprocessable Entity',
          );
      await expectLater(
        client.postReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          commitSha: 'sha',
          path: 'f.dart',
          line: 1,
          side: 'RIGHT',
          body: 'Test',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('replyToReviewComment', () {
    test('returns comment from reply', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data: {
                'id': 888,
                'body': 'Good point',
                'path': 'lib/main.dart',
                'diff_hunk': '@@...',
              } as T?,
            ),
          );
      final result = await client.replyToReviewComment(
        'owner',
        'repo',
        prNumber: 42,
        parentCommentId: 777,
        body: 'Good point',
      );
      expect(result.id, 888);
      expect(result.body, 'Good point');
    });

    test('posts to correct reply URL', () async {
      String? actualUrl;
      fakeDio.onPost =
          <T>(
            path, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) {
            actualUrl = path;
            return Future.value(
              Response<T>(
                requestOptions: ro(),
                data: {'id': 1, 'body': 'm'} as T?,
              ),
            );
          };
      await client.replyToReviewComment(
        'owner',
        'repo',
        prNumber: 42,
        parentCommentId: 100,
        body: 'Reply',
      );
      expect(
        actualUrl,
        'https://api.github.com/repos/owner/repo/pulls/42/comments/100/replies',
      );
    });

    test('throws for non-map response', () async {
      fakeDio.onPost =
          <T>(
            _, {
            data,
            queryParameters,
            cancelToken,
            options,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'not a map' as T?),
          );
      await expectLater(
        client.replyToReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          parentCommentId: 1,
          body: 'Reply',
        ),
        throwsFormatException,
      );
    });

    test('wraps DioExceptions', () async {
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
  
            response: Response(requestOptions: ro(), statusCode: 404),
            message: 'Not Found',
          );
      await expectLater(
        client.replyToReviewComment(
          'owner',
          'repo',
          prNumber: 1,
          parentCommentId: 1,
          body: 'Reply',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('deleteReviewComment', () {
    test('completes without error', () async {
      fakeDio.onDelete =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: {} as T?),
          );
      await expectLater(
        client.deleteReviewComment('owner', 'repo', commentId: 777),
        completes,
      );
    });

    test('calls DELETE on correct URL', () async {
      String? actualUrl;
      fakeDio.onDelete =
          <T>(
            path, {
            data,
            queryParameters,
            options,
            cancelToken,
          }) {
            actualUrl = path;
            return Future.value(
              Response<T>(requestOptions: ro(), data: {} as T?),
            );
          };
      await client.deleteReviewComment('owner', 'repo', commentId: 42);
      expect(
        actualUrl,
        'https://api.github.com/repos/owner/repo/pulls/comments/42',
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onDelete =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
          }) {
            received = cancelToken;
            return Future.value(
              Response<T>(requestOptions: ro(), data: {} as T?),
            );
          };
      final ct = CancelToken();
      await client.deleteReviewComment(
        'owner',
        'repo',
        commentId: 1,
        cancelToken: ct,
      );
      expect(received, same(ct));
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onDelete =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.deleteReviewComment('owner', 'repo', commentId: 1),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onDelete =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
          }) => throw DioException(
            requestOptions: ro(),
  
            response: Response(requestOptions: ro(), statusCode: 403),
            message: 'Forbidden',
          );
      await expectLater(
        client.deleteReviewComment('owner', 'repo', commentId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('editReviewComment', () {
    test('returns edited review comment', () async {
      fakeDio.onPatch =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(
              requestOptions: ro(),
              data: {
                'id': 999,
                'body': 'Updated comment',
                'path': 'lib/main.dart',
                'diff_hunk': '@@...',
              } as T?,
            ),
          );
      final result = await client.editReviewComment(
        'owner',
        'repo',
        commentId: 999,
        body: 'Updated comment',
      );
      expect(result.id, 999);
      expect(result.body, 'Updated comment');
    });

    test('sends PATCH to correct URL with body', () async {
      String? actualUrl;
      Map<String, dynamic>? actualBody;
      fakeDio.onPatch =
          <T>(
            path, {
            data,
            queryParameters,
            options,
            cancelToken,
            onSendProgress,
            onReceiveProgress,
          }) {
            actualUrl = path;
            actualBody = data as Map<String, dynamic>?;
            return Future.value(
              Response<T>(
                requestOptions: ro(),
                data: {'id': 1, 'body': 'm'} as T?,
              ),
            );
          };
      await client.editReviewComment(
        'owner',
        'repo',
        commentId: 42,
        body: 'Edited',
      );
      expect(
        actualUrl,
        'https://api.github.com/repos/owner/repo/pulls/comments/42',
      );
      expect(actualBody, {'body': 'Edited'});
    });

    test('throws for non-map response', () async {
      fakeDio.onPatch =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: 'not a map' as T?),
          );
      await expectLater(
        client.editReviewComment(
          'owner',
          'repo',
          commentId: 1,
          body: 'Edited',
        ),
        throwsFormatException,
      );
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.editReviewComment('', 'repo', commentId: 1, body: 'Edit'),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onPatch =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onSendProgress,
            onReceiveProgress,
          }) {
            received = cancelToken;
            return Future.value(
              Response<T>(
                requestOptions: ro(),
                data: {'id': 1, 'body': 'm'} as T?,
              ),
            );
          };
      final ct = CancelToken();
      await client.editReviewComment(
        'owner',
        'repo',
        commentId: 1,
        body: 'Edited',
        cancelToken: ct,
      );
      expect(received, same(ct));
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onPatch =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
            type: DioExceptionType.cancel,
          );
      await expectLater(
        client.editReviewComment(
          'owner',
          'repo',
          commentId: 1,
          body: 'Edited',
        ),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onPatch =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onSendProgress,
            onReceiveProgress,
          }) => throw DioException(
            requestOptions: ro(),
  
            response: Response(requestOptions: ro(), statusCode: 403),
            message: 'Forbidden',
          );
      await expectLater(
        client.editReviewComment(
          'owner',
          'repo',
          commentId: 1,
          body: 'Edited',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
