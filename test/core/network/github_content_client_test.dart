import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_content_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhttp/rhttp.dart';

void main() {
  late TestHttpClient fake;
  late GitHubContentClient client;

  setUp(() {
    fake = TestHttpClient(handler: (_) => throw StateError('handler not set'));
    client = GitHubContentClient(fake);
  });

  group('getFileContent', () {
    test('returns file content as string', () async {
      const content =
          'import "package:flutter/material.dart";\n\nvoid main() {}';
      fake.handler = (request) => httpTextResponse(request, content);
      final result = await client.getFileContent(
        'owner',
        'repo',
        'lib/main.dart',
        'main',
      );
      expect(result, contains('package:flutter/material.dart'));
    });

    test('returns empty string for an empty body', () async {
      fake.handler = (request) => httpTextResponse(request, '');
      expect(
        await client.getFileContent('owner', 'repo', 'path.dart', 'main'),
        '',
      );
    });

    test('sends raw accept header', () async {
      fake.handler = (request) => httpTextResponse(request, 'content');
      await client.getFileContent('owner', 'repo', 'path.dart', 'main');
      final request = fake.requests.single;
      final headers = (request.headers as HttpHeaderRawMap).map;
      expect(headers['Accept'], 'application/vnd.github.raw');
    });

    test('sends ref query parameter', () async {
      fake.handler = (request) => httpTextResponse(request, 'content');
      await client.getFileContent('owner', 'repo', 'path.dart', 'develop');
      final request = fake.requests.single;
      expect(request.url, '/repos/owner/repo/contents/path.dart');
      expect(request.query, {'ref': 'develop'});
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
      fake.handler = (request) {
        received = request.cancelToken;
        return httpTextResponse(request, 'content');
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

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.getFileContent('owner', 'repo', 'path.dart', 'main'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other exceptions', () async {
      fake.handler = (request) => throw RhttpTimeoutException(request);
      await expectLater(
        client.getFileContent('owner', 'repo', 'path.dart', 'main'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('wraps a failed status code', () async {
      fake.handler = (request) =>
          httpTextResponse(request, 'not found', statusCode: 404);
      await expectLater(
        client.getFileContent('owner', 'repo', 'path.dart', 'main'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('createBlob', () {
    test('returns blob SHA', () async {
      fake.handler = (request) =>
          httpTextResponse(request, {'sha': 'abc123def456'});
      expect(
        await client.createBlob('owner', 'repo', 'aGVsbG8='),
        'abc123def456',
      );
    });

    test('sends base64 content with encoding', () async {
      fake.handler = (request) => httpTextResponse(request, {'sha': 'sha123'});
      await client.createBlob('owner', 'repo', 'base64content');
      final request = fake.requests.single;
      expect(request.url, '/repos/owner/repo/git/blobs');
      expect(request.method.value, 'POST');
      expect((request.body as HttpBodyJson).json, {
        'content': 'base64content',
        'encoding': 'base64',
      });
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
      fake.handler = (request) {
        received = request.cancelToken;
        return httpTextResponse(request, {'sha': 'sha123'});
      };
      final ct = CancelToken();
      await client.createBlob('owner', 'repo', 'content', cancelToken: ct);
      expect(received, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.createBlob('owner', 'repo', 'content'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other exceptions', () async {
      fake.handler = (request) =>
          httpTextResponse(request, 'unprocessable', statusCode: 422);
      await expectLater(
        client.createBlob('owner', 'repo', 'content'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('createFileContent', () {
    test('returns download URL', () async {
      fake.handler = (request) => httpTextResponse(request, {
        'content': {
          'download_url':
              'https://raw.githubusercontent.com/owner/repo/main/img.png',
        },
      });
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
      fake.handler = (request) =>
          httpTextResponse(request, {'content': <String, dynamic>{}});
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
      fake.handler = (request) => httpTextResponse(request, {
        'content': {'download_url': ''},
      });
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
      fake.handler = (request) =>
          httpTextResponse(request, <String, dynamic>{});
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
      fake.handler = (request) => httpTextResponse(request, {
        'content': {'download_url': 'https://e.com/img.png'},
      });
      await client.createFileContent(
        'owner',
        'repo',
        'images/photo.png',
        'base64data',
        'Upload photo',
      );
      final request = fake.requests.single;
      expect(request.url, '/repos/owner/repo/contents/images/photo.png');
      expect(request.method.value, 'PUT');
      expect((request.body as HttpBodyJson).json, {
        'message': 'Upload photo',
        'content': 'base64data',
      });
    });

    test('throws ArgumentError for empty owner', () async {
      await expectLater(
        client.createFileContent('', 'repo', 'path', 'content', 'msg'),
        throwsArgumentError,
      );
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fake.handler = (request) {
        received = request.cancelToken;
        return httpTextResponse(request, {
          'content': {'download_url': 'https://e.com/img.png'},
        });
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

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.createFileContent('owner', 'repo', 'file.txt', 'content', 'msg'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other exceptions', () async {
      fake.handler = (request) =>
          httpTextResponse(request, 'conflict', statusCode: 409);
      await expectLater(
        client.createFileContent('owner', 'repo', 'file.txt', 'content', 'msg'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getAuthenticatedUser', () {
    test('returns GitHubUser', () async {
      fake.handler = (request) => httpTextResponse(request, {
        'login': 'octocat',
        'avatar_url': 'https://avatars/octocat.png',
      });
      final user = await client.getAuthenticatedUser();
      expect(user!.login, 'octocat');
    });

    test('returns null for non-map data', () async {
      fake.handler = (request) => httpTextResponse(request, <dynamic>[1, 2, 3]);
      expect(await client.getAuthenticatedUser(), isNull);
    });

    test('returns null for an empty body', () async {
      fake.handler = (request) => httpTextResponse(request, '');
      expect(await client.getAuthenticatedUser(), isNull);
    });

    test('calls correct endpoint', () async {
      fake.handler = (request) =>
          httpTextResponse(request, {'login': 'u', 'avatar_url': 'a'});
      await client.getAuthenticatedUser();
      expect(fake.requests.single.url, '/user');
    });

    test('propagates cancel token', () async {
      CancelToken? received;
      fake.handler = (request) {
        received = request.cancelToken;
        return httpTextResponse(request, {'login': 'u', 'avatar_url': 'a'});
      };
      final ct = CancelToken();
      await client.getAuthenticatedUser(cancelToken: ct);
      expect(received, same(ct));
    });

    test('rethrows cancel exceptions', () async {
      fake.handler = (request) => throw RhttpCancelException(request);
      await expectLater(
        client.getAuthenticatedUser(),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('wraps other exceptions', () async {
      fake.handler = (request) =>
          throw RhttpConnectionException(request, 'no connection');
      await expectLater(
        client.getAuthenticatedUser(),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
