import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_content_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Exercises [GitHubContentClient] — file-content, commit, blob, user, and
/// collaborator operations over the GitHub REST API. Pure response handling
/// over an injectable [Dio]; pins the request paths/params and the
/// error-mapping matrix (cancel rethrows, 404 → empty on org members, other
/// DioException → NetworkException).
void main() {
  late FakeAdapter adapter;
  late GitHubContentClient client;

  setUp(() {
    adapter = FakeAdapter();
    client = GitHubContentClient(Dio()..httpClientAdapter = adapter);
  });

  group('getFileContent', () {
    test('GETs the contents endpoint with the raw accept header', () async {
      adapter.nextBody('the file body', isString: true);
      final content = await client.getFileContent(
        'o',
        'r',
        'lib/x.dart',
        'main',
      );
      expect(content, 'the file body');
      final req = adapter.requests.single;
      expect(req.path, 'https://api.github.com/repos/o/r/contents/lib/x.dart');
      expect(req.queryParameters['ref'], 'main');
      expect(req.responseType, ResponseType.plain);
      expect((req.headers['Accept'] as String?)?.contains('raw'), isTrue);
    });

    test('rethrows a cancel DioException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.cancel,
      );
      await expectLater(
        client.getFileContent('o', 'r', 'p', 'ref'),
        throwsA(isA<DioException>()),
      );
    });

    test('maps a non-cancel DioException to NetworkException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      );
      await expectLater(
        client.getFileContent('o', 'r', 'p', 'ref'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rejects empty owner/repo', () async {
      expect(
        () => client.getFileContent('', 'r', 'p', 'ref'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('getLatestCommitSha', () {
    test('returns the first commit SHA when a list is returned', () async {
      adapter.nextBody([
        {'sha': 'abc123'},
        {'sha': 'older'},
      ]);
      final sha = await client.getLatestCommitSha('o', 'r', 'lib/x.dart');
      expect(sha, 'abc123');
      final qp = adapter.requests.single.queryParameters;
      expect(qp['path'], 'lib/x.dart');
      expect(qp['per_page'], 1);
    });

    test('forwards a non-empty branch as sha=', () async {
      adapter.nextBody(const []);
      await client.getLatestCommitSha('o', 'r', 'p', branch: 'develop');
      expect(adapter.requests.single.queryParameters['sha'], 'develop');
    });

    test('omits sha when branch is empty', () async {
      adapter.nextBody(const []);
      await client.getLatestCommitSha('o', 'r', 'p', branch: '');
      expect(
        adapter.requests.single.queryParameters.containsKey('sha'),
        isFalse,
      );
    });

    test('returns null for an empty list', () async {
      adapter.nextBody(const []);
      expect(await client.getLatestCommitSha('o', 'r', 'p'), isNull);
    });

    test('returns null when the first entry is not a map', () async {
      adapter.nextBody(['not-a-map']);
      expect(await client.getLatestCommitSha('o', 'r', 'p'), isNull);
    });

    test('returns null when data is not a list', () async {
      adapter.nextBody(<String, dynamic>{'oops': 1});
      expect(await client.getLatestCommitSha('o', 'r', 'p'), isNull);
    });
  });

  group('createBlob', () {
    test('POSTs and returns the sha', () async {
      adapter.nextBody({'sha': 'blob-sha'});
      final sha = await client.createBlob('o', 'r', 'base64==');
      expect(sha, 'blob-sha');
      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.path, 'https://api.github.com/repos/o/r/git/blobs');
      expect(req.data, {'content': 'base64==', 'encoding': 'base64'});
    });
  });

  group('createFileContent', () {
    test('PUTs and returns the download_url', () async {
      adapter.nextBody({
        'content': {'download_url': 'https://raw.githubusercontent.com/x'},
      });
      final url = await client.createFileContent('o', 'r', 'p', 'b64', 'msg');
      expect(url, 'https://raw.githubusercontent.com/x');
      final req = adapter.requests.single;
      expect(req.method, 'PUT');
      expect(req.data, {'message': 'msg', 'content': 'b64'});
    });

    test('throws NetworkException when download_url is missing', () async {
      adapter.nextBody({'content': <String, dynamic>{}});
      await expectLater(
        client.createFileContent('o', 'r', 'p', 'b64', 'msg'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws NetworkException when download_url is empty', () async {
      adapter.nextBody({
        'content': {'download_url': ''},
      });
      await expectLater(
        client.createFileContent('o', 'r', 'p', 'b64', 'msg'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('getAuthenticatedUser', () {
    test('parses the user profile from a map response', () async {
      adapter.nextBody({'login': 'sam', 'avatar_url': 'a', 'name': 'Sam'});
      final u = await client.getAuthenticatedUser();
      expect(u, isNotNull);
      expect(u!.login, 'sam');
      expect(u.name, 'Sam');
    });

    test('returns null for a non-map response', () async {
      adapter.nextBody(<dynamic>[]);
      expect(await client.getAuthenticatedUser(), isNull);
    });
  });

  group('getUserByLogin', () {
    test('parses the user profile', () async {
      adapter.nextBody({'login': 'sam', 'avatar_url': 'a'});
      final u = await client.getUserByLogin('sam');
      expect(u!.login, 'sam');
    });

    test('returns null for a non-map response', () async {
      adapter.nextBody('x');
      expect(await client.getUserByLogin('sam'), isNull);
    });
  });

  group('getCollaboratorPermission', () {
    test('returns the permission string', () async {
      adapter.nextBody({'permission': 'write'});
      expect(await client.getCollaboratorPermission('o', 'r', 'sam'), 'write');
      expect(
        adapter.requests.single.path,
        'https://api.github.com/repos/o/r/collaborators/sam/permission',
      );
    });

    test('defaults to none when permission is missing', () async {
      adapter.nextBody(<String, dynamic>{});
      expect(await client.getCollaboratorPermission('o', 'r', 'sam'), 'none');
    });

    test('returns none for a non-map response', () async {
      adapter.nextBody(<dynamic>[]);
      expect(await client.getCollaboratorPermission('o', 'r', 'sam'), 'none');
    });
  });

  group('getOrganizationMembers', () {
    test('returns the parsed members', () async {
      adapter.nextBody([
        {'login': 'a', 'avatar_url': 'x'},
        {'login': 'b', 'avatar_url': 'y'},
        'not-a-map',
      ]);
      final members = await client.getOrganizationMembers('acme');
      expect(members.map((m) => m.login).toList(), ['a', 'b']);
      expect(adapter.requests.single.queryParameters['per_page'], 100);
    });

    test('returns empty for a non-list response', () async {
      adapter.nextBody(<String, dynamic>{});
      expect(await client.getOrganizationMembers('acme'), isEmpty);
    });

    test('returns empty on a 404 (not an org)', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 404),
      );
      expect(await client.getOrganizationMembers('acme'), isEmpty);
    });

    test('maps a non-404 DioException to NetworkException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        response: Response(requestOptions: RequestOptions(), statusCode: 500),
      );
      await expectLater(
        client.getOrganizationMembers('acme'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rethrows a cancel DioException', () async {
      adapter.throwNext = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.cancel,
      );
      await expectLater(
        client.getOrganizationMembers('acme'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('owner/repo validation', () {
    test('rejects empty owner/repo on every repo-scoped method', () {
      expect(
        () => client.getLatestCommitSha('', 'r', 'p'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => client.createBlob('o', '', 'b'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => client.createFileContent('o', '', 'p', 'b', 'm'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => client.getCollaboratorPermission('', 'r', 'u'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

class FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  Object _nextBody = <String, dynamic>{};
  Object? _throwNext;
  // Whether the canned body is already a Dart String (vs JSON-encodable).
  bool _bodyIsString = false;

  void nextBody(Object body, {bool isString = false}) {
    _nextBody = body;
    _bodyIsString = isString;
  }

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
    // getFileContent uses ResponseType.plain — return the raw string body.
    if (_bodyIsString) {
      return ResponseBody.fromString(
        _nextBody as String,
        200,
        headers: const {
          Headers.contentTypeHeader: ['text/plain'],
        },
      );
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
