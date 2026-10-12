import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/demo/demo_repo_stats.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Serves one canned JSON body, counts fetches, and can be flipped to fail —
/// enough behaviour to exercise the whole cache policy without a network.
class _ScriptedGitHub {
  _ScriptedGitHub(this.body);

  final String body;
  int fetches = 0;
  bool fail = false;

  late final TestHttpClient client = TestHttpClient(
    handler: (HttpRequest request) {
      fetches++;
      if (fail) {
        throw StateError('network down');
      }
      return httpTextResponse(request, body);
    },
  );
}

DemoRepoStats _stats(
  _ScriptedGitHub github, {
  Duration ttl = const Duration(minutes: 30),
  Duration failureCooldown = const Duration(minutes: 5),
}) => DemoRepoStats(
  httpClient: github.client,
  ttl: ttl,
  failureCooldown: failureCooldown,
);

void main() {
  test('parses stargazers_count', () async {
    final github = _ScriptedGitHub('{"stargazers_count": 1287}');
    final stats = _stats(github);

    expect(await stats.current(), 1287);
    expect(github.fetches, 1);
  });

  test('a fresh cache serves without a second fetch', () async {
    final github = _ScriptedGitHub('{"stargazers_count": 1287}');
    final stats = _stats(github);

    await stats.current();
    expect(await stats.current(), 1287);
    expect(github.fetches, 1);
  });

  test('an expired cache refetches', () async {
    final github = _ScriptedGitHub('{"stargazers_count": 1287}');
    final stats = _stats(github, ttl: const Duration(milliseconds: 1));

    expect(await stats.current(), 1287);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(await stats.current(), 1287);
    expect(github.fetches, 2);
  });

  test('a failed refresh keeps the last known count', () async {
    final github = _ScriptedGitHub('{"stargazers_count": 1287}');
    final stats = _stats(github, ttl: const Duration(milliseconds: 1));

    expect(await stats.current(), 1287);
    github.fail = true;
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // The count does not flash away just because GitHub hiccuped.
    expect(await stats.current(), 1287);
  });

  test('a failed fetch starts a cooldown, not a retry storm', () async {
    final github = _ScriptedGitHub('{"stargazers_count": 1287}')..fail = true;
    final stats = _stats(github, ttl: const Duration(milliseconds: 1));

    expect(await stats.current(), isNull);
    expect(await stats.current(), isNull);
    // Failed requests count against GitHub's unauthenticated rate limit
    // exactly like successful ones — one attempt per cooldown, not per caller.
    expect(github.fetches, 1);
  });

  test('a malformed body is a failure, not a bogus count', () async {
    final github = _ScriptedGitHub('{"message": "rate limited"}');
    final stats = _stats(github);

    expect(await stats.current(), isNull);
  });
}
