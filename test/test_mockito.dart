import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'fakes/fake_github_pr_client.dart';

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

void main() {
  test('github api client returns fake pr client', () {
    final fakePr = FakeGitHubPrClient();
    final apiClient = _FakeGitHubApiClient(fakePr);

    expect(apiClient.pr, same(fakePr));
    // ignore: avoid_print
    print('OK');
  });
}
