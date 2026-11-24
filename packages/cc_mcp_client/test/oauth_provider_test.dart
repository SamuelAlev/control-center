import 'dart:convert';
import 'dart:io';

import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late String base;
  late List<String> hits;
  late List<Map<String, Object?>> registrations;
  late List<({Map<String, String> form, String? authorization})> tokenCalls;
  late Map<String, Object?> metadataExtra;
  late Map<String, Object?> registrationAnswer;
  late int registrationStatus;
  late InMemoryOAuthTokenStore store;

  McpOAuthProvider provider() =>
      McpOAuthProvider(serverUrl: '$base/mcp', tokenStore: store);

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    hits = [];
    registrations = [];
    tokenCalls = [];
    metadataExtra = {};
    registrationAnswer = {'client_id': 'client-1'};
    registrationStatus = 200;
    store = InMemoryOAuthTokenStore();
    server.listen((request) async {
      final res = request.response;
      void json(Object body) => res
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      hits.add(request.uri.path);
      switch (request.uri.path) {
        case '/.well-known/oauth-protected-resource/mcp':
          json({
            'authorization_servers': ['$base/tenant'],
          });
        case '/.well-known/oauth-authorization-server/tenant':
          json({
            'issuer': '$base/tenant',
            'authorization_endpoint': '$base/tenant/authorize?audience=x',
            'token_endpoint': '$base/tenant/token',
            'registration_endpoint': '$base/tenant/register',
            'scopes_supported': ['mcp:connect'],
            ...metadataExtra,
          });
        case '/tenant/register':
          registrations.add(
            (jsonDecode(await utf8.decoder.bind(request).join()) as Map)
                .cast<String, Object?>(),
          );
          res.statusCode = registrationStatus;
          json(registrationAnswer);
        case '/tenant/token':
          tokenCalls.add((
            form: Uri.splitQueryString(await utf8.decoder.bind(request).join()),
            authorization: request.headers.value('authorization'),
          ));
          json({
            'access_token': 'at-${tokenCalls.length}',
            'refresh_token': 'rt',
            'expires_in': 0,
          });
        default:
          res.statusCode = HttpStatus.notFound;
      }
      await res.close();
    });
  });
  tearDown(() => server.close(force: true));

  test('begin finds the resource\'s own authorization server, registers a '
      'public client for the redirect and stores nothing', () async {
    final pending = await provider().begin(
      redirectUri: 'https://cc.example.com/oauth/mcp/callback',
      state: 'st',
    );
    final query = pending.authorizationUrl.queryParameters;
    expect(pending.authorizationUrl.path, '/tenant/authorize');
    expect(query['audience'], 'x', reason: 'the endpoint\'s own query stays');
    expect(query['state'], 'st');
    expect(query['client_id'], 'client-1');
    expect(query['scope'], 'mcp:connect');
    expect(query['resource'], '$base/mcp');
    expect(query['code_challenge'], isNotEmpty);
    expect(registrations.single['redirect_uris'], [
      'https://cc.example.com/oauth/mcp/callback',
    ]);
    expect(registrations.single['application_type'], 'web');
    expect(registrations.single['token_endpoint_auth_method'], 'none');
    expect(await store.read(base), isNull);
    expect(await provider().authHeaders(), isEmpty);
  });

  test('complete exchanges with the verifier and the same redirect, then '
      'the token is refreshed and its registration reused only for that '
      'redirect', () async {
    const redirect = 'https://cc.example.com/oauth/mcp/callback';
    final p = provider();
    final pending = await p.begin(redirectUri: redirect, state: 'st');
    await p.complete(pending, 'code-1');
    expect(tokenCalls.single.form['grant_type'], 'authorization_code');
    expect(tokenCalls.single.form['code'], 'code-1');
    expect(tokenCalls.single.form['redirect_uri'], redirect);
    expect(tokenCalls.single.form['code_verifier'], hasLength(43));

    // `expires_in: 0`: the next read refreshes.
    expect(await provider().authHeaders(), {'Authorization': 'Bearer at-2'});
    expect(tokenCalls.last.form['grant_type'], 'refresh_token');
    expect(tokenCalls.last.form['refresh_token'], 'rt');

    await provider().begin(redirectUri: redirect, state: 's2');
    expect(registrations, hasLength(1), reason: 'same redirect, same client');
    await provider().begin(
      redirectUri: 'https://moved.example.com/oauth/mcp/callback',
      state: 's3',
    );
    expect(registrations, hasLength(2));

    await provider().signOut();
    expect(await provider().authHeaders(), isEmpty);
  });

  test('a server that takes no public client gets a secret, sent the way '
      'the registration says', () async {
    metadataExtra = {
      'token_endpoint_auth_methods_supported': [
        'client_secret_basic',
        'client_secret_post',
      ],
    };
    registrationAnswer = {
      'client_id': 'client-1',
      'client_secret': 's3cret',
      'token_endpoint_auth_method': 'client_secret_basic',
    };
    final p = provider();
    final pending = await p.begin(
      redirectUri: 'http://127.0.0.1:9030/oauth/mcp/callback',
      state: 'st',
    );
    expect(
      registrations.single['token_endpoint_auth_method'],
      'client_secret_post',
    );
    expect(registrations.single['application_type'], 'native');
    await p.complete(pending, 'code-1');
    expect(
      tokenCalls.single.authorization,
      'Basic ${base64.encode(utf8.encode('client-1:s3cret'))}',
    );
    expect(tokenCalls.single.form.containsKey('client_secret'), isFalse);

    await provider().authHeaders();
    expect(tokenCalls.last.form['grant_type'], 'refresh_token');
    expect(tokenCalls.last.authorization, startsWith('Basic '));
  });

  test('a server that offers no registration cannot be signed in to', () async {
    metadataExtra = {'registration_endpoint': null};
    await expectLater(
      provider().begin(redirectUri: 'https://cc.example.com/cb', state: 's'),
      throwsA(isA<OAuthException>()),
    );
  });

  test('a refused registration says what the server answered, as plain '
      'bounded text', () async {
    registrationStatus = 403;
    registrationAnswer = {
      'error': 'invalid_client_metadata',
      'error_description': 'Client not\u001b[31m allowed ${'x' * 300}',
    };
    await expectLater(
      provider().begin(redirectUri: 'https://cc.example.com/cb', state: 's'),
      throwsA(
        isA<OAuthException>().having(
          (e) => e.message,
          'message',
          allOf(
            startsWith(
              'the server refused to register this client: HTTP 403, '
              'Client not [31m allowed x',
            ),
            hasLength(lessThan(200)),
          ),
        ),
      ),
    );
  });
}
