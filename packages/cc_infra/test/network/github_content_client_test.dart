import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/github_content_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Exercises [GitHubContentClient] — file-content, commit, blob, user and
/// collaborator operations over the GitHub REST API. Pure response handling
/// over an injectable [RhttpClient]; pins the request paths/params and the
/// error-mapping matrix (cancel rethrows, 404 → empty on org members, other
/// statuses → NetworkException).
void main() {
  late FakeTransport transport;
  late GitHubContentClient client;

  setUp(() {
    transport = FakeTransport();
    client = GitHubContentClient(transport.client);
  });

  group('getFileContent', () {
    test('GETs the contents endpoint with the raw accept header', () async {
      transport.nextBody('the file body');
      final content = await client.getFileContent(
        'o',
        'r',
        'lib/x.dart',
        'main',
      );
      expect(content, 'the file body');
      final req = transport.requests.single;
      expect(req.url, '/repos/o/r/contents/lib/x.dart');
      expect(req.query!['ref'], 'main');
      expect((req.headers! as HttpHeaderRawMap).map['Accept'], contains('raw'));
    });

    test('rethrows a cancel RhttpException', () async {
      transport.cancelNext();
      await expectLater(
        client.getFileContent('o', 'r', 'p', 'ref'),
        throwsA(isA<RhttpCancelException>()),
      );
    });

    test('maps a non-cancel status error to NetworkException', () async {
      transport.nextBody(const {'message': 'Not Found'}, status: 404);
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

  group('getFileBytes', () {
    test('GETs the contents endpoint as raw bytes', () async {
      transport.nextBody([0x89, 0x50, 0x4e, 0x47]);
      final bytes = await client.getFileBytes('o', 'r', 'shot.png', 'abc123');
      expect(bytes, [0x89, 0x50, 0x4e, 0x47]);
      final req = transport.requests.single;
      expect(req.url, '/repos/o/r/contents/shot.png');
      expect(req.query!['ref'], 'abc123');
      expect((req.headers! as HttpHeaderRawMap).map['Accept'], contains('raw'));
    });

    test('rejects empty owner/repo', () {
      expect(
        () => client.getFileBytes('', 'r', 'p', 'ref'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('getLatestCommitSha', () {
    test('returns the first commit SHA when a list is returned', () async {
      transport.nextBody([
        {'sha': 'abc123'},
        {'sha': 'older'},
      ]);
      final sha = await client.getLatestCommitSha('o', 'r', 'lib/x.dart');
      expect(sha, 'abc123');
      final qp = transport.requests.single.query!;
      expect(qp['path'], 'lib/x.dart');
      expect(qp['per_page'], '1');
    });

    test('forwards a non-empty branch as sha=', () async {
      transport.nextBody(const []);
      await client.getLatestCommitSha('o', 'r', 'p', branch: 'develop');
      expect(transport.requests.single.query!['sha'], 'develop');
    });

    test('omits sha when branch is empty', () async {
      transport.nextBody(const []);
      await client.getLatestCommitSha('o', 'r', 'p', branch: '');
      expect(transport.requests.single.query!.containsKey('sha'), isFalse);
    });

    test('returns null for an empty list', () async {
      transport.nextBody(const []);
      expect(await client.getLatestCommitSha('o', 'r', 'p'), isNull);
    });

    test('returns null when the first entry is not a map', () async {
      transport.nextBody(['not-a-map']);
      expect(await client.getLatestCommitSha('o', 'r', 'p'), isNull);
    });

    test('returns null when data is not a list', () async {
      transport.nextBody(<String, dynamic>{'oops': 1});
      expect(await client.getLatestCommitSha('o', 'r', 'p'), isNull);
    });
  });

  group('getRepoSummary', () {
    test('maps a 404 to a repo_not_found NetworkException', () async {
      transport.nextBody(const {'message': 'Not Found'}, status: 404);
      await expectLater(
        client.getRepoSummary('o', 'missing'),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.code,
            'code',
            'repo_not_found',
          ),
        ),
      );
    });

    test('maps description, default branch and stars', () async {
      transport.nextBody({
        'description': 'Widgets',
        'default_branch': 'trunk',
        'stargazers_count': 12,
      });
      final summary = await client.getRepoSummary('o', 'r');
      expect(summary.description, 'Widgets');
      expect(summary.defaultBranch, 'trunk');
      expect(summary.starCount, 12);
      expect(transport.requests.single.url, '/repos/o/r');
    });
  });

  group('createBlob', () {
    test('POSTs and returns the sha', () async {
      transport.nextBody({'sha': 'blob-sha'});
      final sha = await client.createBlob('o', 'r', 'base64==');
      expect(sha, 'blob-sha');
      final req = transport.requests.single;
      expect(req.method.value, 'POST');
      expect(req.url, '/repos/o/r/git/blobs');
      expect((req.body! as HttpBodyJson).json, {
        'content': 'base64==',
        'encoding': 'base64',
      });
    });
  });

  group('createFileContent', () {
    test('PUTs and returns the download_url', () async {
      transport.nextBody({
        'content': {'download_url': 'https://raw.githubusercontent.com/x'},
      });
      final url = await client.createFileContent('o', 'r', 'p', 'b64', 'msg');
      expect(url, 'https://raw.githubusercontent.com/x');
      final req = transport.requests.single;
      expect(req.method.value, 'PUT');
      expect((req.body! as HttpBodyJson).json, {
        'message': 'msg',
        'content': 'b64',
      });
    });

    test('throws NetworkException when download_url is missing', () async {
      transport.nextBody({'content': <String, dynamic>{}});
      await expectLater(
        client.createFileContent('o', 'r', 'p', 'b64', 'msg'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws NetworkException when download_url is empty', () async {
      transport.nextBody({
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
      transport.nextBody({'login': 'sam', 'avatar_url': 'a', 'name': 'Sam'});
      final u = await client.getAuthenticatedUser();
      expect(u, isNotNull);
      expect(u!.login, 'sam');
      expect(u.name, 'Sam');
    });

    test('returns null for a non-map response', () async {
      transport.nextBody(<dynamic>[]);
      expect(await client.getAuthenticatedUser(), isNull);
    });
  });

  group('getUserByLogin', () {
    test('parses the user profile', () async {
      transport.nextBody({'login': 'sam', 'avatar_url': 'a'});
      final u = await client.getUserByLogin('sam');
      expect(u!.login, 'sam');
    });

    test('returns null for a non-map response', () async {
      transport.nextBody(5);
      expect(await client.getUserByLogin('sam'), isNull);
    });
  });

  group('getAuthenticatedRepoPermission', () {
    test('maps admin/push/pull from the repo payload', () async {
      transport.nextBody({
        'permissions': {'admin': true, 'push': true, 'pull': true},
      });
      expect(await client.getAuthenticatedRepoPermission('o', 'r'), 'admin');
      expect(transport.requests.single.url, '/repos/o/r');
    });

    test('maps push without admin as write', () async {
      transport.nextBody({
        'permissions': {'admin': false, 'push': true, 'pull': true},
      });
      expect(await client.getAuthenticatedRepoPermission('o', 'r'), 'write');
    });

    test('maps maintain as write', () async {
      transport.nextBody({
        'permissions': {'admin': false, 'maintain': true, 'pull': true},
      });
      expect(await client.getAuthenticatedRepoPermission('o', 'r'), 'write');
    });

    test('maps pull-only as read', () async {
      transport.nextBody({
        'permissions': {'admin': false, 'push': false, 'pull': true},
      });
      expect(await client.getAuthenticatedRepoPermission('o', 'r'), 'read');
    });

    test('falls back to role_name when permissions is absent', () async {
      transport.nextBody({'role_name': 'write'});
      expect(await client.getAuthenticatedRepoPermission('o', 'r'), 'write');
    });

    test(
      'returns none when neither permissions nor role_name is present',
      () async {
        transport.nextBody(<String, dynamic>{});
        expect(await client.getAuthenticatedRepoPermission('o', 'r'), 'none');
      },
    );
  });

  group('getCollaboratorPermission', () {
    test('returns the permission string', () async {
      transport.nextBody({'permission': 'write'});
      expect(await client.getCollaboratorPermission('o', 'r', 'sam'), 'write');
      expect(
        transport.requests.single.url,
        '/repos/o/r/collaborators/sam/permission',
      );
    });

    test('defaults to none when permission is missing', () async {
      transport.nextBody(<String, dynamic>{});
      expect(await client.getCollaboratorPermission('o', 'r', 'sam'), 'none');
    });

    test('returns none for a non-map response', () async {
      transport.nextBody(<dynamic>[]);
      expect(await client.getCollaboratorPermission('o', 'r', 'sam'), 'none');
    });
  });

  group('getOrganizationMembers', () {
    test('returns the parsed members', () async {
      transport.nextBody([
        {'login': 'a', 'avatar_url': 'x'},
        {'login': 'b', 'avatar_url': 'y'},
        'not-a-map',
      ]);
      final members = await client.getOrganizationMembers('acme');
      expect(members.map((m) => m.login).toList(), ['a', 'b']);
      expect(transport.requests.single.query!['per_page'], '100');
    });

    test('returns empty for a non-list response', () async {
      transport.nextBody(<String, dynamic>{});
      expect(await client.getOrganizationMembers('acme'), isEmpty);
    });

    test('returns empty on a 404 (not an org)', () async {
      transport.nextBody(const {'message': 'Not Found'}, status: 404);
      expect(await client.getOrganizationMembers('acme'), isEmpty);
    });

    test('maps a non-404 status error to NetworkException', () async {
      transport.nextBody(const {'message': 'boom'}, status: 500);
      await expectLater(
        client.getOrganizationMembers('acme'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rethrows a cancel RhttpException', () async {
      transport.cancelNext();
      await expectLater(
        client.getOrganizationMembers('acme'),
        throwsA(isA<RhttpCancelException>()),
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

/// Canned transport for [GitHubContentClient]: one response is armed per call
/// and every request is recorded.
class FakeTransport {
  FakeTransport() {
    client = TestHttpClient(handler: _handle);
  }

  /// The transport the client under test talks to.
  late final TestHttpClient client;

  /// Requests served so far, oldest first.
  List<HttpRequest> get requests => client.requests;

  Object? _body = const <String, dynamic>{};
  int _status = 200;
  bool _cancelNext = false;

  /// Arms [body] as the next response: a [String] is sent verbatim, anything
  /// else is JSON-encoded. [status] ≥ 400 makes the transport throw the same
  /// [RhttpStatusCodeException] a real client would.
  void nextBody(Object body, {int status = 200}) {
    _body = body;
    _status = status;
  }

  /// Arms a cancellation as the next response.
  void cancelNext() => _cancelNext = true;

  HttpResponse _handle(HttpRequest request) {
    if (_cancelNext) {
      _cancelNext = false;
      throw RhttpCancelException(request);
    }
    if (request.expectBody == HttpExpectBody.bytes) {
      return httpBytesResponse(
        request,
        _body as List<int>,
        statusCode: _status,
      );
    }
    return httpTextResponse(request, _body, statusCode: _status);
  }
}
