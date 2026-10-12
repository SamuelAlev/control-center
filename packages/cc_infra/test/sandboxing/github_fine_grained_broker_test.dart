import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';
import 'package:cc_infra/src/network/github/github_app_client.dart';
import 'package:cc_infra/src/sandboxing/github_fine_grained_broker.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:rhttp/rhttp.dart';
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

/// The server's GitHub App, answering `/app/installations` with ONE
/// installation on `o` — so a mint for `o/r` resolves to id 9 the way it does
/// in production, instead of being told an id up front.
Future<GitHubAppClient?> Function({String? workspaceId}) _app(
  TestHttpClient fake,
) {
  final client = GitHubAppClient(
    appId: '1',
    privateKeyPem: _privatePem,
    httpClient: fake,
  );
  return ({workspaceId}) async => client;
}

/// The installations document the fake serves for `/app/installations`.
const _installations = [
  {
    'id': 9,
    'account': {'login': 'o'},
    'repository_selection': 'all',
  },
];

/// Whether [request] asks for the app's installation list.
bool _isInstallations(HttpRequest request) =>
    _path(request) == '/app/installations';

/// The path of a captured request.
String _path(HttpRequest request) => httpRequestUri(request).path;

/// The decoded JSON body of a captured request.
Map<String, dynamic> _jsonBody(HttpRequest request) =>
    (request.body! as HttpBodyJson).json as Map<String, dynamic>;

/// The `Authorization` header of a captured request.
String? _authHeader(HttpRequest request) =>
    (request.headers! as HttpHeaderRawMap).map['Authorization'];

/// Routes the two calls a scoped mint makes: list installations, then mint.
HttpResponse Function(HttpRequest) _route(
  HttpResponse Function(HttpRequest) mint,
) =>
    (request) => _isInstallations(request)
    ? httpTextResponse(request, _installations)
    : mint(request);

void main() {
  test('no app → falls back to the raw PAT', () async {
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds());
    final creds = await broker.mint(
      conversationId: 'c1',
      scope: ForgeTokenScope.read,
      repoOwner: 'o',
      repoName: 'r',
    );
    expect(creds.environment['GH_TOKEN'], 'pat_raw');
    expect(creds.notes.join(' '), contains('no GitHub App'));
  });

  test(
    'with an app → mints a scoped token (write perms for a write scope)',
    () async {
      final fake = TestHttpClient(
        handler: _route(
          (request) => httpTextResponse(request, {
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
        scope: ForgeTokenScope.write,
        repoOwner: 'o',
        repoName: 'r',
      );

      expect(creds.environment['GH_TOKEN'], 'ghs_scoped');
      expect(creds.environment['GITHUB_TOKEN'], 'ghs_scoped');
      // The installation was RESOLVED from the owner, not configured.
      expect(_path(fake.requests.first), '/app/installations');
      final mintReq = fake.requests.last;
      expect(_path(mintReq), '/app/installations/9/access_tokens');
      final perms = _jsonBody(mintReq)['permissions'] as Map;
      expect(perms['contents'], 'write');
      // The gateway's push token only needs to push.
      expect(perms.containsKey('pull_requests'), isFalse);
      expect(_jsonBody(mintReq)['repositories'], ['r']);
      expect(creds.notes.join(' '), contains('installation token'));
    },
  );

  test('read scope mints contents:read + pull_requests:write', () async {
    final fake = TestHttpClient(
      handler: _route(
        (request) => httpTextResponse(request, {'token': 'ghs_ro'}),
      ),
    );
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds(), app: _app(fake));
    await broker.mint(
      conversationId: 'c1',
      scope: ForgeTokenScope.read,
      repoOwner: 'o',
      repoName: 'r',
    );
    final perms = _jsonBody(fake.requests.last)['permissions'] as Map;
    expect(perms['contents'], 'read');
    // Opening a PR is the policy's call, not the token's.
    expect(perms['pull_requests'], 'write');
  });

  test('mint failure → falls back to the raw PAT (fail-safe)', () async {
    final fake = TestHttpClient(
      handler: _route(
        (request) => httpTextResponse(request, const {
          'message': 'Bad creds',
        }, statusCode: 401),
      ),
    );
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds(), app: _app(fake));
    final creds = await broker.mint(
      conversationId: 'c1',
      scope: ForgeTokenScope.write,
      repoOwner: 'o',
      repoName: 'r',
    );
    expect(creds.environment['GH_TOKEN'], 'pat_raw');
    expect(creds.notes.join(' '), contains('Fallback'));
  });

  test('revoke DELETEs the minted installation token', () async {
    final calls = <HttpRequest>[];
    final fake = TestHttpClient(
      handler: _route((request) {
        calls.add(request);
        return httpTextResponse(request, {'token': 'ghs_scoped'});
      }),
    );
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds(), app: _app(fake));
    final creds = await broker.mint(
      conversationId: 'c1',
      scope: ForgeTokenScope.write,
      repoOwner: 'o',
      repoName: 'r',
    );
    await broker.revoke(creds.handle);

    final del = calls.where((r) => r.method.value == 'DELETE').toList();
    expect(del, hasLength(1));
    expect(_path(del.single), '/installation/token');
    expect(_authHeader(del.single), 'Bearer ghs_scoped');
  });

  test('an owner the app is not installed on falls back to the PAT', () async {
    // The app exists but covers another account — exactly the case a single
    // server-wide installation id could not express.
    final fake = TestHttpClient(
      handler: (request) => _isInstallations(request)
          ? httpTextResponse(request, const [
              {
                'id': 9,
                'account': {'login': 'someone-else'},
              },
            ])
          : httpTextResponse(request, {'token': 'ghs_should_not_be_used'}),
    );
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds(), app: _app(fake));

    final creds = await broker.mint(
      conversationId: 'c1',
      scope: ForgeTokenScope.write,
      repoOwner: 'o',
      repoName: 'r',
    );

    expect(creds.environment['GH_TOKEN'], 'pat_raw');
    expect(
      fake.requests.any((r) => _path(r).contains('access_tokens')),
      isFalse,
      reason: 'nothing should be minted for an installation we do not have',
    );
  });

  test(
    'no repo owner falls back — the installation cannot be resolved',
    () async {
      final fake = TestHttpClient(
        handler: _route(
          (request) => httpTextResponse(request, {'token': 'ghs_x'}),
        ),
      );
      final broker = GitHubFineGrainedTokenBroker(
        _FakeCreds(),
        app: _app(fake),
      );

      final creds = await broker.mint(
        conversationId: 'c1',
        scope: ForgeTokenScope.write,
        repoName: 'r',
      );

      expect(creds.environment['GH_TOKEN'], 'pat_raw');
    },
  );

  test('the ticketing key is never placed in a sandbox', () async {
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds());
    final creds = await broker.mint(
      conversationId: 'c1',
      scope: ForgeTokenScope.read,
    );
    expect(creds.environment.containsKey('TICKETING_API_KEY'), isFalse);
  });

  test('a PAT fallback says the push rule is advisory', () async {
    final broker = GitHubFineGrainedTokenBroker(_FakeCreds());
    final creds = await broker.mint(
      conversationId: 'c1',
      scope: ForgeTokenScope.read,
      repoOwner: 'o',
      repoName: 'r',
    );
    expect(creds.notes.join(' '), contains('advisory'));
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
        scope: ForgeTokenScope.write,
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
        scope: ForgeTokenScope.write,
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
        scope: ForgeTokenScope.write,
        repoOwner: 'o',
        repoName: 'r',
      );
      expect(creds.environment['GH_TOKEN'], 'pat_raw');
    });

    test(
      'a workspace background PAT is the fallback for a member run',
      () async {
        final broker = GitHubFineGrainedTokenBroker(
          _FakeCreds(),
          serverOwnerUserId: () async => 'user-owner',
          workspacePat: (workspaceId) async =>
              workspaceId == 'ws-a' ? 'gho_workspace' : null,
        );
        final creds = await broker.mint(
          conversationId: 'c1',
          scope: ForgeTokenScope.write,
          repoOwner: 'o',
          repoName: 'r',
          actingUserId: 'user-someone-else',
          workspaceId: 'ws-a',
        );
        expect(creds.environment['GH_TOKEN'], 'gho_workspace');
      },
    );
  });
}
