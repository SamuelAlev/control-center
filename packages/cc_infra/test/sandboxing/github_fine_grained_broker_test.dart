import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_infra/src/network/github/github_app_client.dart';
import 'package:cc_infra/src/sandboxing/github_fine_grained_broker.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

// The same throwaway test key used by the minter test.
const _privatePem = '''
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDzy3mpCyNtGV9o
MiUaB8uN1EFevaXVTdvmH9/jKpNsijCsqYyY4Z4XVOK4xJMaXLzbh5rEdNjBDaxj
/3Lz2eGFCSVfzfOYQxncwF4CmUFojZkeKDH6dufBfY48z+bxqItvy5ge2zUe+Ab8
A3Gncm6G6VG554u2dE1ro4iHRnDf2ZE8vZIlV7i0MkL2D85iYLG1vG/Dj6hW2wAQ
HmvuMJ72eB/gL7pEUPKWVlLm88SHfrV1g6LhFc4xnPUaL5TfSsvJiO+rdKzraMb3
SyFXf4zMJvhs+7+FtYNuzG4rK4K02dLAuRbSWlzPFGpA+0ffFmydbHsS85N+Fj+D
qIfb7stPAgMBAAECggEAA58SpBGvyYeWdLhF99CE1AsCm5MqmvQIn676hufTf8m/
tljgZ0b2r7cJlSAKZVpaTdKCWIe5zohS9rtNLFUgtfawUO+AvlLE2BQdcWFwaMqt
qxaCw4svnx6r1bhq4E0WISd/j3nHHLondGfisM+Q170wgxfu6dtpaP9pYEUKGTEd
PHal+ZFoXfpyFrkJJ651oKP1SuH5pr60Yuf6DtnvcXCbuEbZRwjnVPpCENuynf/4
IBz6qEeAM7Qke/YfCzAnU76KWa4eEjzEY20v4Edubik8ii1vAs/W+FTORcjU4zdh
JHrr1j6h89uU9ejh3GtmF+t0yPDu7tPMJeSEwVBcsQKBgQD9e4DNOlEe8RCddGif
/2pKq/OAaR0yN+bnK7iEW6aA7XtQJEzbu4Mk1+GTqzuTIXDKFmm3Oq8ssnxwRU3e
Q/pk1k1/jWlw3RBpCs2vX8ms0ErSxBIRNBi6zjLhgVMiA2z5TbDvC8VRf+enasuk
RpK7o1DZXWNk7mU7e+aKcuak8QKBgQD2N1c2ugNUoab0OKWBCHifSYhDJpJnNI4H
5sz/apHt0Cw8PR4F4Pt2u4oq42yYj9f6VspNJLc8VNR4tSqN5Y0DLiwHh4C3Kd4v
U9EfAor0u+opwiowr8ti8eqEOYe7iUCTiV4QEJ2rl1nGyI2UQ6OB0mL5TgcTq4Fs
xfjHrV90PwKBgBxumPDsJKM62OlAYGfp50s+5E43/B1g5dZyMf0upot5l8ZSfAh9
jOU6DcRZhZIoQxV31B3ISFPUJV8WdviCWXisDP9MplIRicCuhImyTdXDe1EOyxQA
6vExJcXjkqaTCcsg6sK1aEmO9jXyJatkexru46et8PMmRlaYvDA1WSeRAoGBALBL
4+jNvEDHFtJcFTWVKTl031qlrcK0QNarjjF8z0ym+GWRpYO0GppjooUfHs0GgjFA
H86o8YMDgreDkRrVOOkEEIa7oZCFLBBbRaucmH6wZvTLkIYX+du5OKDAyM2hc1mw
zGdYXm1VC/Vn+OgmnlcAm9nC4xJUhXGrN31SSLzlAoGBANs4bDYJsaQH0di80bnf
Fs337XsAyGsU2UF7DvbaBbjANbZNGo3rzeXICepSMPnSoney3S/RI6udOiWxpKMc
AIcwfcfbR1AuAuzyI6F4znw/QSNcBTr/UimdRdq8pQy+swEVZfLqYp8u9tEObAqz
j5nS7DACgETgsbZygZ/tDqmx
-----END PRIVATE KEY-----''';

class _FakeCreds implements CredentialsRepository {
  @override
  Future<ApiCredentials> loadCredentials() async =>
      const ApiCredentials(githubToken: 'pat_raw', ticketingApiKey: 'tk_raw');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    requests.add(o);
    return handler(o);
  }

  @override
  void close({bool force = false}) {}
}

/// The server's GitHub App, answering `/app/installations` with ONE
/// installation on `o` — so a mint for `o/r` resolves to id 9 the way it does
/// in production, instead of being told an id up front.
Future<GitHubAppClient?> Function() _app(_FakeAdapter fake) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
    ..httpClientAdapter = fake;
  final client = GitHubAppClient(
    appId: '1',
    privateKeyPem: _privatePem,
    dio: dio,
  );
  return () async => client;
}

/// The installations document the fake serves for `/app/installations`.
const _installations = [
  {
    'id': 9,
    'account': {'login': 'o'},
    'repository_selection': 'all',
  },
];

/// Routes the two calls a scoped mint makes: list installations, then mint.
ResponseBody Function(RequestOptions) _route(
  ResponseBody Function(RequestOptions) mint,
) => (options) => options.path == '/app/installations'
    ? _ok(_installations)
    : mint(options);

ResponseBody _ok(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  const ghCaps = AgentCapabilities(canCallGitHubApi: true);
  const pushCaps = AgentCapabilities(
    canPushToRepo: true,
    canCallGitHubApi: true,
  );

  test('no app → falls back to the raw PAT', () async {
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds());
    final creds = await broker.mint(
      conversationId: 'c1',
      capabilities: ghCaps,
      repoOwner: 'o',
      repoName: 'r',
    );
    expect(creds.environment['GH_TOKEN'], 'pat_raw');
    expect(creds.notes.join(' '), contains('no GitHub App'));
  });

  test(
    'with an app → mints a scoped token (write perms when pushing)',
    () async {
      final fake = _FakeAdapter(
        _route(
          (_) => _ok({
            'token': 'ghs_scoped',
            'expires_at': '2026-07-06T13:00:00Z',
          }),
        ),
      );
      final broker = GitHubFineGrainedTokenBroker(
        _FakeCreds(),
        app: _app(fake),
      );

      final creds = await broker.mint(
        conversationId: 'c1',
        capabilities: pushCaps,
        repoOwner: 'o',
        repoName: 'r',
      );

      expect(creds.environment['GH_TOKEN'], 'ghs_scoped');
      expect(creds.environment['GITHUB_TOKEN'], 'ghs_scoped');
      // The installation was RESOLVED from the owner, not configured.
      expect(fake.requests.first.path, '/app/installations');
      final mintReq = fake.requests.last;
      expect(mintReq.path, '/app/installations/9/access_tokens');
      final perms = (mintReq.data as Map)['permissions'] as Map;
      expect(perms['contents'], 'write'); // pushing → write
      expect((mintReq.data as Map)['repositories'], ['r']);
      expect(creds.notes.join(' '), contains('installation token'));
    },
  );

  test('read-only capability mints contents:read', () async {
    final fake = _FakeAdapter(_route((_) => _ok({'token': 'ghs_ro'})));
    final broker = GitHubFineGrainedTokenBroker(
      _FakeCreds(),
      app: _app(fake),
    );
    await broker.mint(
      conversationId: 'c1',
      capabilities: ghCaps, // no push
      repoOwner: 'o',
      repoName: 'r',
    );
    final perms = (fake.requests.last.data as Map)['permissions'] as Map;
    expect(perms['contents'], 'read');
    expect(perms.containsKey('pull_requests'), isFalse);
  });

  test('mint failure → falls back to the raw PAT (fail-safe)', () async {
    final fake = _FakeAdapter(
      _route((_) => _ok({'message': 'Bad creds'}, status: 401)),
    );
    final broker = GitHubFineGrainedTokenBroker(
      _FakeCreds(),
      app: _app(fake),
    );
    final creds = await broker.mint(
      conversationId: 'c1',
      capabilities: pushCaps,
      repoOwner: 'o',
      repoName: 'r',
    );
    expect(creds.environment['GH_TOKEN'], 'pat_raw');
    expect(creds.notes.join(' '), contains('Fallback'));
  });

  test('revoke DELETEs the minted installation token', () async {
    final calls = <RequestOptions>[];
    final fake = _FakeAdapter(
      _route((o) {
        calls.add(o);
        return _ok({'token': 'ghs_scoped'});
      }),
    );
    final broker = GitHubFineGrainedTokenBroker(
      _FakeCreds(),
      app: _app(fake),
    );
    final creds = await broker.mint(
      conversationId: 'c1',
      capabilities: pushCaps,
      repoOwner: 'o',
      repoName: 'r',
    );
    await broker.revoke(creds.handle);

    final del = calls.where((o) => o.method == 'DELETE').toList();
    expect(del, hasLength(1));
    expect(del.single.path, '/installation/token');
    expect(del.single.headers['Authorization'], 'Bearer ghs_scoped');
  });

  test('an owner the app is not installed on falls back to the PAT', () async {
    // The app exists but covers another account — exactly the case a single
    // server-wide installation id could not express.
    final fake = _FakeAdapter(
      (o) => o.path == '/app/installations'
          ? _ok(const [
              {
                'id': 9,
                'account': {'login': 'someone-else'},
              },
            ])
          : _ok({'token': 'ghs_should_not_be_used'}),
    );
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds(), app: _app(fake));

    final creds = await broker.mint(
      conversationId: 'c1',
      capabilities: pushCaps,
      repoOwner: 'o',
      repoName: 'r',
    );

    expect(creds.environment['GH_TOKEN'], 'pat_raw');
    expect(
      fake.requests.any((o) => o.path.contains('access_tokens')),
      isFalse,
      reason: 'nothing should be minted for an installation we do not have',
    );
  });

  test('no repo owner falls back — the installation cannot be resolved', () async {
    final fake = _FakeAdapter(_route((_) => _ok({'token': 'ghs_x'})));
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds(), app: _app(fake));

    final creds = await broker.mint(
      conversationId: 'c1',
      capabilities: pushCaps,
      repoName: 'r',
    );

    expect(creds.environment['GH_TOKEN'], 'pat_raw');
  });

  test('ticketing key is still passed through', () async {
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds());
    final creds = await broker.mint(
      conversationId: 'c1',
      capabilities: const AgentCapabilities(canCallTicketing: true),
    );
    expect(creds.environment['TICKETING_API_KEY'], 'tk_raw');
  });

  group('the server PAT is not a shared credential', () {
    // The raw PAT is the SERVER's token. Handing it to a run acting for a
    // member would give that member the server's whole GitHub reach — the
    // escalation the per-member proof exists to prevent, arriving through the
    // back door whenever they simply have not connected GitHub.
    test('is withheld from a run acting for another member', () async {
      final broker = GitHubFineGrainedTokenBroker(
        _FakeCreds(),
        serverOwnerUserId: () async => 'user-owner',
      );
      final creds = await broker.mint(
        conversationId: 'c1',
        capabilities: pushCaps,
        repoOwner: 'o',
        repoName: 'r',
        actingUserId: 'user-someone-else',
      );

      expect(creds.environment.containsKey('GH_TOKEN'), isFalse);
      expect(creds.environment.containsKey('GITHUB_TOKEN'), isFalse);
      expect(creds.notes.join(' '), contains('has not connected GitHub'));
    });

    test('is still used when the operator runs their own server', () async {
      final broker = GitHubFineGrainedTokenBroker(
        _FakeCreds(),
        serverOwnerUserId: () async => 'user-owner',
      );
      final creds = await broker.mint(
        conversationId: 'c1',
        capabilities: pushCaps,
        repoOwner: 'o',
        repoName: 'r',
        actingUserId: 'user-owner',
      );
      expect(creds.environment['GH_TOKEN'], 'pat_raw');
    });

    test('is still used when no human asked', () async {
      // A webhook or a reconciler IS the server acting as itself.
      final broker = GitHubFineGrainedTokenBroker(
        _FakeCreds(),
        serverOwnerUserId: () async => 'user-owner',
      );
      final creds = await broker.mint(
        conversationId: 'c1',
        capabilities: pushCaps,
        repoOwner: 'o',
        repoName: 'r',
      );
      expect(creds.environment['GH_TOKEN'], 'pat_raw');
    });
  });
}
