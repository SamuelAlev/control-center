import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_infra/src/sandboxing/github_app_token_minter.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

// A throwaway 2048-bit RSA keypair generated solely for this test — NOT a
// credential. Used to prove the minter builds a valid RS256 JWT and to verify
// its signature locally (no live GitHub needed).
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

const _publicPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA88t5qQsjbRlfaDIlGgfL
jdRBXr2l1U3b5h/f4yqTbIowrKmMmOGeF1TiuMSTGly824eaxHTYwQ2sY/9y89nh
hQklX83zmEMZ3MBeAplBaI2ZHigx+nbnwX2OPM/m8aiLb8uYHts1HvgG/ANxp3Ju
hulRueeLtnRNa6OIh0Zw39mRPL2SJVe4tDJC9g/OYmCxtbxvw4+oVtsAEB5r7jCe
9ngf4C+6RFDyllZS5vPEh361dYOi4RXOMZz1Gi+U30rLyYjvq3Ss62jG90shV3+M
zCb4bPu/hbWDbsxuKyuCtNnSwLkW0lpczxRqQPtH3xZsnWx7EvOTfhY/g6iH2+7L
TwIDAQAB
-----END PUBLIC KEY-----''';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  const config = GitHubAppConfig(
    appId: '12345',
    privateKeyPem: _privatePem,
    installationId: '99',
  );

  ({GitHubAppTokenMinter minter, _FakeAdapter fake}) build(
    ResponseBody Function(RequestOptions) handler,
  ) {
    final fake = _FakeAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
      ..httpClientAdapter = fake;
    return (minter: GitHubAppTokenMinter(dio: dio, config: config), fake: fake);
  }

  group('GitHubAppTokenMinter', () {
    test('buildAppJwt signs a verifiable RS256 JWT with the right claims', () {
      final b = build((_) => _json(const {}));
      final jwt = b.minter.buildAppJwt();

      // Verifiable with the matching public key → the signature is valid RS256.
      final verified = JWT.verify(jwt, RSAPublicKey(_publicPem));
      final payload = verified.payload as Map<String, dynamic>;
      expect(payload['iss'], '12345');
      // exp = iat + 9 min, well under GitHub's 10-minute (600s) ceiling.
      final iat = payload['iat'] as int;
      final exp = payload['exp'] as int;
      expect(exp - iat, 540);
      expect(exp - iat, lessThanOrEqualTo(600));
    });

    test(
      'mint POSTs the installation-token endpoint with repos + perms',
      () async {
        final b = build(
          (_) => _json({
            'token': 'ghs_scoped123',
            'expires_at': '2026-07-06T13:00:00Z',
          }),
        );
        final minted = await b.minter.mint(
          repositories: ['my-repo'],
          permissions: {'contents': 'write', 'metadata': 'read'},
        );

        final req = b.fake.requests.single;
        expect(req.method, 'POST');
        expect(req.path, '/app/installations/99/access_tokens');
        expect('${req.headers['Authorization']}', startsWith('Bearer '));
        final body = req.data as Map<String, dynamic>;
        expect(body['repositories'], ['my-repo']);
        expect((body['permissions'] as Map)['contents'], 'write');
        expect(minted.token, 'ghs_scoped123');
        expect(minted.expiresAt, DateTime.utc(2026, 7, 6, 13));
      },
    );

    test('mint throws when the response carries no token', () async {
      final b = build(
        (_) => _json(const {'message': 'Bad credentials'}, status: 401),
      );
      await expectLater(
        b.minter.mint(repositories: ['r']),
        throwsA(isA<Object>()),
      );
    });

    test('revoke DELETEs /installation/token authed with the token', () async {
      final b = build((_) => _json(const {}, status: 204));
      await b.minter.revoke('ghs_scoped123');
      final req = b.fake.requests.single;
      expect(req.method, 'DELETE');
      expect(req.path, '/installation/token');
      expect(req.headers['Authorization'], 'Bearer ghs_scoped123');
    });
  });
}
