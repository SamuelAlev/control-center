import 'dart:typed_data';

import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/gitlab/gitlab_api_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Captures the resolved URI without sending anything.
class _CaptureAdapter implements HttpClientAdapter {
  final List<Uri> uris = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    uris.add(options.uri);
    return ResponseBody.fromString('[]', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// GitLab addresses a project by its URL-encoded `namespace/project` path, so a
/// nested namespace becomes `group%2Fsub%2Fproject` inside ONE path segment.
///
/// This is the single likeliest source of silent 404s in the adapter: encode it
/// twice and every nested-namespace project is unreachable; encode it not at
/// all and the slashes split into extra path segments and hit a different
/// endpoint. Both failures look like "GitLab says the project does not exist".
void main() {
  group('GitLabApiClient.encodeProjectPath', () {
    test('encodes a flat namespace', () {
      expect(GitLabApiClient.encodeProjectPath('acme/web'), 'acme%2Fweb');
    });

    test('encodes every separator of a nested namespace', () {
      expect(
        GitLabApiClient.encodeProjectPath('group/sub/project'),
        'group%2Fsub%2Fproject',
      );
    });

    test('tolerates surrounding slashes', () {
      expect(GitLabApiClient.encodeProjectPath('/acme/web/'), 'acme%2Fweb');
    });

    test('rejects an empty path rather than building /projects//…', () {
      expect(
        () => GitLabApiClient.encodeProjectPath('  '),
        throwsArgumentError,
      );
    });
  });

  group('dio preserves the encoding', () {
    test('a nested project path survives as one segment on the wire', () async {
      // The encoding is only correct if dio does not re-encode the `%` — a
      // double encode (`%252F`) reaches a URL that cannot resolve.
      final adapter = _CaptureAdapter();
      final dio = createDio(baseUrl: 'https://gitlab.com/api/v4')
        ..httpClientAdapter = adapter;

      final encoded = GitLabApiClient.encodeProjectPath('group/sub/project');
      await dio.get<dynamic>('/projects/$encoded/merge_requests');

      final uri = adapter.uris.single.toString();
      expect(
        uri,
        'https://gitlab.com/api/v4/projects/group%2Fsub%2Fproject/merge_requests',
      );
      expect(uri, isNot(contains('%252F')));
    });
  });
}
