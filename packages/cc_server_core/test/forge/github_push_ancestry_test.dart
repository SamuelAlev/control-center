import 'package:cc_server_core/src/forge/github_push_ancestry.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:test/test.dart';

/// The push proxy asks GitHub's compare API whether a commit a push stands
/// on is already published below a base: reachable exactly when GitHub
/// answers 200 with `ahead_by` 0; not when it is ahead or unknown; unknown
/// (null) when GitHub could not be asked.
void main() {
  const tip = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const oid = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  late _GitHub github;

  setUp(() => github = _GitHub());

  Future<bool?> ask({
    String owner = 'acme',
    String name = 'api',
    String base = 'HEAD',
    String commit = oid,
  }) => githubPushAncestry(github)(
    owner: owner,
    name: name,
    base: base,
    oid: commit,
    token: 'ghs_write',
  );

  test('an ancestor or the tip itself is published', () async {
    github.answer = const GitHubRestResponse(200, {
      'status': 'behind',
      'ahead_by': 0,
      'behind_by': 3,
    });
    expect(await ask(), isTrue);
    github.answer = const GitHubRestResponse(200, {
      'status': 'identical',
      'ahead_by': 0,
      'behind_by': 0,
    });
    expect(await ask(base: tip), isTrue);
    expect(github.asked, [
      ('/repos/acme/api/compare/HEAD...$oid', 'per_page=1', 'ghs_write'),
      ('/repos/acme/api/compare/$tip...$oid', 'per_page=1', 'ghs_write'),
    ]);
  });

  test('a commit the base does not reach is not, a fork\'s included', () async {
    github.answer = const GitHubRestResponse(200, {
      'status': 'ahead',
      'ahead_by': 1,
      'behind_by': 0,
    });
    expect(await ask(), isFalse);
    github.answer = const GitHubRestResponse(200, {
      'status': 'diverged',
      'ahead_by': 2,
      'behind_by': 5,
    });
    expect(await ask(), isFalse);
  });

  test('an id the repository does not know is not', () async {
    github.answer = const GitHubRestResponse(404, {'message': 'Not Found'});
    expect(await ask(), isFalse);
  });

  test('GitHub that could not be asked is no answer', () async {
    for (final answer in const [
      GitHubRestResponse(0, null),
      GitHubRestResponse(502, null),
      GitHubRestResponse(429, null),
      GitHubRestResponse(
        403,
        {'message': 'API rate limit exceeded'},
        headers: {'x-ratelimit-remaining': '0'},
      ),
      GitHubRestResponse(200, {'status': 'ahead'}),
    ]) {
      github.answer = answer;
      expect(await ask(), isNull, reason: '${answer.status}');
    }
  });

  test('a refusal that is not a rate limit is not published', () async {
    github.answer = const GitHubRestResponse(403, {
      'message': 'Resource not accessible by integration',
    });
    expect(await ask(), isFalse);
  });

  test('a malformed argument is refused without asking', () async {
    for (final (owner, name, base, commit) in [
      ('acme/evil', 'api', 'HEAD', oid),
      ('acme', '..', 'HEAD', oid),
      ('acme', 'api?x=1', 'HEAD', oid),
      ('acme', 'api', 'main', oid),
      ('acme', 'api', 'HEAD', 'HEAD'),
      ('acme', 'api', 'HEAD', 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'),
      ('acme', 'api', 'HEAD', '$oid/../x'),
    ]) {
      expect(
        await ask(owner: owner, name: name, base: base, commit: commit),
        isFalse,
        reason: '$owner/$name $base...$commit',
      );
    }
    expect(github.asked, isEmpty);
  });
}

class _GitHub extends GitHubRest {
  GitHubRestResponse answer = const GitHubRestResponse(0, null);
  final asked = <(String, String, String?)>[];

  @override
  Future<GitHubRestResponse> send(
    String method,
    String path, {
    Map<String, String>? query,
    String? bearer,
    ({String clientId, String clientSecret})? basic,
    Object? body,
  }) async {
    expect(method, 'GET');
    asked.add((path, Uri(queryParameters: query).query, bearer));
    return answer;
  }
}
