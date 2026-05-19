import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'fake_github_pr_client.dart';

/// Minimal manual mock for [GitHubApiClient] that returns a fake PR client.
class _FakeGitHubApiClient extends GitHubApiClient {
  _FakeGitHubApiClient(this._prClient) : super(_NullDio());

  final FakeGitHubPrClient _prClient;

  @override
  GitHubPrClient get pr => _prClient;
}

class _NullDio implements Dio {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Smoke test for the hand-written GitHub fakes.
///
/// (Formerly `test/test_mockito.dart` — a name left over from before mockito
/// was removed from the workspace, on a file that has never used it. It exists
/// to prove the manual-fake seam still composes: `GitHubApiClient.pr` is
/// overridable, which is what every PR-surface test depends on.)
void main() {
  test('a fake GitHubApiClient hands back the injected PR client', () {
    final fakePr = FakeGitHubPrClient();
    final apiClient = _FakeGitHubApiClient(fakePr);

    expect(apiClient.pr, same(fakePr));
  });
}
