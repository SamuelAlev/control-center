import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_content_client.dart';
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
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  })?
  onPut;

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
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    final cb = onPut;
    if (cb == null) {
      throw UnimplementedError('onPut not set');
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
  late GitHubContentClient client;

  setUp(() {
    fakeDio = _FakeDio();
    client = GitHubContentClient(fakeDio);
  });

  RequestOptions ro() => RequestOptions();

  group('getFileContent', () {
    test('returns file content as string', () async {
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
                  'import "package:flutter/material.dart";\n\nvoid main() {}'
                      as T?,
            ),
          );
      final result = await client.getFileContent(
        'owner',
        'repo',
        'lib/main.dart',
        'main',
      );
      expect(result, contains('package:flutter/material.dart'));
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
      expect(
        await client.getFileContent('owner', 'repo', 'path.dart', 'main'),
        '',
      );
    });

    test('sends raw accept header and plain response type', () async {
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
              Response<T>(requestOptions: ro(), data: 'content' as T?),
            );
          };
      await client.getFileContent('owner', 'repo', 'path.dart', 'main');
      expect(
        receivedOptions?.headers?['Accept'],
        'application/vnd.github.raw',
      );
      expect(receivedOptions?.responseType, ResponseType.plain);
    });

    test('sends ref query parameter', () async {
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
              Response<T>(requestOptions: ro(), data: 'content' as T?),
            );
          };
      await client.getFileContent('owner', 'repo', 'path.dart', 'develop');
      expect(
        actualUrl,
        'https://api.github.com/repos/owner/repo/contents/path.dart',
      );
      expect(actualParams, {'ref': 'develop'});
    });

    test('throws ArgumentError for empty owner', () {
      expect(
        () => client.getFileContent('', 'repo', 'path.dart', 'main'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for empty repo', () {
      expect(
        () => client.getFileContent('owner', '', 'path.dart', 'main'),
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
              Response<T>(requestOptions: ro(), data: 'content' as T?),
            );
          };
      final ct = CancelToken();
      await client.getFileContent(
        'owner',
        'repo',
        'path.dart',
        'main',
        cancelToken: ct,
      );
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
        client.getFileContent('owner', 'repo', 'path.dart', 'main'),
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
        client.getFileContent('owner', 'repo', 'path.dart', 'main'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('createBlob', () {
    test('returns blob SHA', () async {
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
              data: {'sha': 'abc123def456'} as T?,
            ),
          );
      expect(
        await client.createBlob('owner', 'repo', 'aGVsbG8='),
        'abc123def456',
      );
    });

    test('sends base64 content with encoding', () async {
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
              Response<T>(requestOptions: ro(), data: {'sha': 'sha123'} as T?),
            );
          };
      await client.createBlob('owner', 'repo', 'base64content');
      expect(actualUrl, 'https://api.github.com/repos/owner/repo/git/blobs');
      expect(actualBody, {'content': 'base64content', 'encoding': 'base64'});
    });

    test('throws ArgumentError for empty owner', () async {
      await expectLater(
        client.createBlob('', 'repo', 'content'),
        throwsArgumentError,
      );
    });
    test('throws ArgumentError for empty repo', () async {
      await expectLater(
        client.createBlob('owner', '', 'content'),
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
              Response<T>(requestOptions: ro(), data: {'sha': 'sha123'} as T?),
            );
          };
      final ct = CancelToken();
      await client.createBlob('owner', 'repo', 'content', cancelToken: ct);
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
        client.createBlob('owner', 'repo', 'content'),
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
        client.createBlob('owner', 'repo', 'content'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('createFileContent', () {
    test('returns download URL', () async {
      fakeDio.onPut =
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
              data:
                  {
                        'content': {
                          'download_url':
                              'https://raw.githubusercontent.com/owner/repo/main/img.png',
                        },
                      }
                      as T?,
            ),
          );
      final url = await client.createFileContent(
        'owner',
        'repo',
        'img.png',
        'b64',
        'Add photo',
      );
      expect(url, 'https://raw.githubusercontent.com/owner/repo/main/img.png');
    });

    test('throws when download_url is null', () async {
      fakeDio.onPut =
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
              data: <String, dynamic>{'content': <String, dynamic>{}} as T?,
            ),
          );
      await expectLater(
        client.createFileContent(
          'owner',
          'repo',
          'file.txt',
          'content',
          'Add file',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('GitHub did not return a download_url'),
          ),
        ),
      );
    });

    test('throws when download_url is empty', () async {
      fakeDio.onPut =
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
              data:
                  {
                        'content': {'download_url': ''},
                      }
                      as T?,
            ),
          );
      await expectLater(
        client.createFileContent(
          'owner',
          'repo',
          'file.txt',
          'content',
          'Add file',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('GitHub did not return a download_url'),
          ),
        ),
      );
    });

    test('throws when content is null', () async {
      fakeDio.onPut =
          <T>(
            _, {
            data,
            queryParameters,
            options,
            cancelToken,
            onSendProgress,
            onReceiveProgress,
          }) => Future.value(
            Response<T>(requestOptions: ro(), data: <String, dynamic>{} as T?),
          );
      await expectLater(
        client.createFileContent(
          'owner',
          'repo',
          'file.txt',
          'content',
          'Add file',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('GitHub did not return a download_url'),
          ),
        ),
      );
    });

    test('sends correct PUT body', () async {
      String? actualUrl;
      Map<String, dynamic>? actualBody;
      fakeDio.onPut =
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
                data:
                    {
                          'content': {'download_url': 'https://e.com/img.png'},
                        }
                        as T?,
              ),
            );
          };
      await client.createFileContent(
        'owner',
        'repo',
        'images/photo.png',
        'base64data',
        'Upload photo',
      );
      expect(
        actualUrl,
        'https://api.github.com/repos/owner/repo/contents/images/photo.png',
      );
      expect(actualBody, {'message': 'Upload photo', 'content': 'base64data'});
    });

    test('throws ArgumentError for empty owner', () async {
      await expectLater(
        client.createFileContent('', 'repo', 'path', 'content', 'msg'),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fakeDio.onPut =
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
                data:
                    {
                          'content': {'download_url': 'https://e.com/img.png'},
                        }
                        as T?,
              ),
            );
          };
      final ct = CancelToken();
      await client.createFileContent(
        'owner',
        'repo',
        'file.txt',
        'content',
        'msg',
        cancelToken: ct,
      );
      expect(received, same(ct));
    });

    test('rethrows cancel DioExceptions', () async {
      fakeDio.onPut =
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
        client.createFileContent('owner', 'repo', 'file.txt', 'content', 'msg'),
        throwsA(isA<DioException>()),
      );
    });

    test('wraps other DioExceptions', () async {
      fakeDio.onPut =
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

            message: '409 conflict',
          );
      await expectLater(
        client.createFileContent('owner', 'repo', 'file.txt', 'content', 'msg'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getAuthenticatedUser', () {
    test('returns GitHubUser', () async {
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
                        'login': 'octocat',
                        'avatar_url': 'https://avatars/octocat.png',
                      }
                      as T?,
            ),
          );
      final user = await client.getAuthenticatedUser();
      expect(user!.login, 'octocat');
    });

    test('returns null for non-map data', () async {
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
      expect(await client.getAuthenticatedUser(), isNull);
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
      expect(await client.getAuthenticatedUser(), isNull);
    });

    test('calls correct endpoint', () async {
      String? actualUrl;
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
            return Future.value(
              Response<T>(
                requestOptions: ro(),
                data: {'login': 'u', 'avatar_url': 'a'} as T?,
              ),
            );
          };
      await client.getAuthenticatedUser();
      expect(actualUrl, 'https://api.github.com/user');
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
              Response<T>(
                requestOptions: ro(),
                data: {'login': 'u', 'avatar_url': 'a'} as T?,
              ),
            );
          };
      final ct = CancelToken();
      await client.getAuthenticatedUser(cancelToken: ct);
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
        client.getAuthenticatedUser(),
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

            message: 'no connection',
          );
      await expectLater(
        client.getAuthenticatedUser(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
