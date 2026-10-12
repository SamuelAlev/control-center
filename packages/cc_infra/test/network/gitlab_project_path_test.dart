import 'package:cc_infra/src/network/gitlab/gitlab_api_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:test/test.dart';

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

  group('project paths reach the wire intact', () {
    test('a nested project path survives as one segment', () async {
      // The encoding is only correct if the client forwards the `%` as-is — a
      // double encode (`%252F`) reaches a URL that cannot resolve.
      final client = TestHttpClient(
        handler: (request) async =>
            httpTextResponse(request, const <Object?>[]),
      );
      final api = GitLabApiClient(client);

      await api.listMergeRequests(
        GitLabApiClient.encodeProjectPath('group/sub/project'),
        state: 'opened',
      );

      final url = client.requests.single.url;
      expect(url, '/projects/group%2Fsub%2Fproject/merge_requests');
      expect(url, isNot(contains('%252F')));
    });
  });
}
