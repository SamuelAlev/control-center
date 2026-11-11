import 'dart:convert';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

void main() {
  late ConnectInstallIdentity a;
  late ConnectInstallIdentity b;
  late ConnectInstallIdentity stranger;

  setUpAll(() async {
    a = await ConnectInstallIdentity.derive(
      masterSeed: seed(1),
      connectUrl: testPublicUrl,
    );
    b = await ConnectInstallIdentity.derive(
      masterSeed: seed(2),
      connectUrl: testPublicUrl,
    );
    stranger = await ConnectInstallIdentity.derive(
      masterSeed: seed(3),
      connectUrl: testPublicUrl,
    );
  });

  group('unauthenticated routes', () {
    late Harness harness;
    setUp(() async => harness = await Harness.start(allowed: [a]));
    tearDown(() => harness.close());

    test('/healthz', () async {
      final response = await harness.raw('GET', '/healthz');
      expect(response.status, 200);
      expect(response.json, {'ok': true});
      expect(response.header('cache-control'), 'no-store');
      expect(response.header('x-content-type-options'), 'nosniff');
      expect(response.header('access-control-allow-origin'), isNull);
      expect(response.header('server'), isNull);
    });

    test('/v1/version', () async {
      final response = await harness.raw('GET', '/v1/version');
      expect(response.json, {
        'protocol': connectProtocolVersion,
        'version': connectServiceVersion,
      });
    });

    test('no CORS, even for a preflight', () async {
      final response = await harness.raw(
        'OPTIONS',
        '/v1/config',
        headers: {
          'origin': 'https://evil.example',
          'access-control-request-method': 'POST',
        },
      );
      expect(response.status, 405);
      expect(response.header('access-control-allow-origin'), isNull);
      expect(response.header('access-control-allow-methods'), isNull);
    });

    test('unknown routes and methods', () async {
      final missing = await harness.raw('GET', '/v1/nope');
      expect(missing.status, 404);
      expect(missing.json, {'error': 'invalid_request'});
      final method = await harness.raw('POST', '/healthz');
      expect(method.status, 405);
      final signedMethod = await harness.call(a, 'GET', '/v1/github/refresh');
      expect(signedMethod.status, 405);
    });
  });

  group('signatures', () {
    late Harness harness;
    setUp(
      () async => harness = await Harness.start(
        allowed: [a, b],
        env: {'CONNECT_DENY_INSTALLS': b.installId},
      ),
    );
    tearDown(() => harness.close());

    test('unsigned calls are refused', () async {
      final response = await harness.raw('GET', '/v1/config');
      expect(response.status, 403);
      expect(response.json, {'error': 'access_denied'});
    });

    test('a signed call is served', () async {
      final response = await harness.call(a, 'GET', '/v1/config');
      expect(response.status, 200);
    });

    test('a replayed nonce is refused', () async {
      final nonce = b64url(randomBytes(16));
      final first = await harness.call(a, 'GET', '/v1/config', nonce: nonce);
      expect(first.status, 200);
      final replay = await harness.call(a, 'GET', '/v1/config', nonce: nonce);
      expect(replay.status, 400);
      expect(replay.json, {'error': 'stale_request'});
    });

    test('an old signature is stale', () async {
      final response = await harness.call(
        a,
        'GET',
        '/v1/config',
        signedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      expect(response.json, {'error': 'stale_request'});
    });

    test('a signature for another Connect is refused', () async {
      final response = await harness.call(
        a,
        'GET',
        '/v1/config',
        signedUrl: 'https://evil.example/v1/config',
      );
      expect(response.json, {'error': 'access_denied'});
    });

    test('the Host and X-Forwarded headers are never trusted', () async {
      final response = await harness.call(
        a,
        'GET',
        '/v1/config',
        extraHeaders: {
          'x-forwarded-host': 'evil.example',
          'x-forwarded-proto': 'http',
        },
      );
      expect(response.status, 200);
    });

    test('an edited body is refused', () async {
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: {'seal': 'v1.a.b', 'workspace_id': 'ws1'},
        sentBody: utf8.encode('{"seal":"v1.a.c","workspace_id":"ws1"}'),
      );
      expect(response.json, {'error': 'access_denied'});
    });

    test('an install not on the allow list is blocked', () async {
      final response = await harness.call(stranger, 'GET', '/v1/config');
      expect(response.status, 403);
      expect(response.json, {'error': 'install_blocked'});
    });

    test('the deny list wins over the allow list', () async {
      final response = await harness.call(b, 'GET', '/v1/config');
      expect(response.json, {'error': 'install_blocked'});
      final log = harness.logs.firstWhere((l) => l.contains('auth.refused'));
      expect(log, contains('"reason":"blocked"'));
      expect(log, isNot(contains(b.installId)));
    });

    test('bodies over 16 KB are refused before verification', () async {
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: {'seal': 'x' * (connectMaxRequestBytes + 1)},
      );
      expect(response.status, 400);
      expect(response.json, {'error': 'invalid_request'});
    });

    test('malformed JSON is invalid_request', () async {
      final response = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: ['not', 'an', 'object'],
      );
      expect(response.json, {'error': 'invalid_request'});
    });

    test('there is no chat action route', () async {
      final response = await harness.call(
        a,
        'POST',
        '/v1/chat/slack/act',
        body: {'workspace_id': 'ws1'},
      );
      expect(response.status, 404);
    });

    test('logs never carry install ids, seals or bodies', () async {
      await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: {'seal': 'v1.secret-looking.seal', 'workspace_id': 'ws1'},
      );
      final all = harness.logs.join('\n');
      expect(all, isNot(contains(a.installId)));
      expect(all, isNot(contains('secret-looking')));
      expect(all, contains('"route":"/v1/github/refresh"'));
    });
  });

  group('/v1/config (self-hosted)', () {
    test('is generated from the complete lanes, without a signature', () async {
      final harness = await Harness.start(allowed: [a]);
      addTearDown(harness.close);
      final response = await harness.call(a, 'GET', '/v1/config');
      final config = ConnectConfig.fromJson(response.json);
      expect(config.signature, isEmpty);
      expect(config.epoch, 1);
      expect(config.github!.appId, 4242);
      expect(config.github!.clientId, 'Iv23test');
      expect(config.github!.appSlug, 'cc-test');
      expect(config.google!.clientId, 'g-client.apps.googleusercontent.com');
      expect(config.linear!.clientId, 'lin_client');
      expect(config.slack!.appId, 'A0TEST');
      expect(config.klipy!.mode, KlipyLaneMode.proxy);
      expect(response.body, isNot(contains('klipy-key-123')));
      expect(response.body, isNot(contains('secret')));
    });

    test('a partial lane is not served', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {'CONNECT_GITHUB_CLIENT_SECRET': ''},
      );
      addTearDown(harness.close);
      final response = await harness.call(a, 'GET', '/v1/config');
      expect(ConnectConfig.fromJson(response.json).github, isNull);
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: PkcePair.generate().challenge,
        ).toJson(),
      );
      expect(start.json, {'error': 'provider_unavailable'});
    });

    test('a lane that stops accepting new authorizations', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {'CONNECT_GITHUB_ACCEPTS_NEW': 'false'},
      );
      addTearDown(harness.close);
      final config = ConnectConfig.fromJson(
        (await harness.call(a, 'GET', '/v1/config')).json,
      );
      expect(config.github!.acceptsNewAuthorizations, isFalse);
      final start = await harness.call(
        a,
        'POST',
        '/v1/oauth/github/start',
        body: OAuthStartRequest(
          workspaceId: 'ws1',
          codeChallenge: PkcePair.generate().challenge,
        ).toJson(),
      );
      expect(start.json, {'error': 'provider_unavailable'});
    });
  });

  group('mounted under a path prefix', () {
    test('routes, signs and redirects under /connect', () async {
      const mountedUrl = '$testPublicUrl/connect';
      final mounted = await ConnectInstallIdentity.derive(
        masterSeed: seed(1),
        connectUrl: mountedUrl,
      );
      final harness = await Harness.start(
        allowed: [mounted],
        env: {'CONNECT_PUBLIC_URL': '$mountedUrl/'},
      );
      addTearDown(harness.close);
      expect(harness.mount, '/connect');
      expect(harness.service.ownsPath('/connect/v1/config'), isTrue);
      expect(harness.service.ownsPath('/connect'), isTrue);
      expect(harness.service.ownsPath('/connectx/v1/config'), isFalse);
      expect(harness.service.ownsPath('/api/rpc'), isFalse);

      final config = await harness.call(mounted, 'GET', '/v1/config');
      expect(config.status, 200);
      final health = await harness.raw('GET', '/connect/healthz');
      expect(health.status, 200);

      FakeGitHub(harness.upstream);
      final flow = await browserFlow(harness, mounted, ConnectOAuthLane.github);
      expect(flow.done.status, 200);
      final exchange = harness.upstream.callsTo(
        'POST',
        'https://github.com/login/oauth/access_token',
      );
      expect(exchange, isEmpty, reason: 'the code is exchanged at claim');
      final claim = await harness.call(
        mounted,
        'POST',
        '/v1/oauth/github/claim',
        body: OAuthClaimRequest(
          loginId: flow.loginId,
          confirmCode: flow.confirmCode,
          codeVerifier: flow.pkce.verifier,
          workspaceId: 'ws1',
        ).toJson(),
      );
      expect(claim.status, 200);
      expect(
        harness.upstream
            .callsTo('POST', 'https://github.com/login/oauth/access_token')
            .single
            .form['redirect_uri'],
        'https://connect.test/connect/oauth/github/callback',
      );
    });
  });

  group('rate limits', () {
    test('per install', () async {
      final harness = await Harness.start(
        allowed: [a, b],
        env: {'CONNECT_RATE_INSTALL_PER_MINUTE': '2'},
      );
      addTearDown(harness.close);
      expect((await harness.call(a, 'GET', '/v1/config')).status, 200);
      expect((await harness.call(a, 'GET', '/v1/config')).status, 200);
      final limited = await harness.call(a, 'GET', '/v1/config');
      expect(limited.status, 429);
      expect(limited.json, {'error': 'rate_limited'});
      expect((await harness.call(b, 'GET', '/v1/config')).status, 200);
    });

    test('per IP, keyed by the trusted proxy hop only', () async {
      final direct = await Harness.start(
        allowed: [a],
        env: {'CONNECT_RATE_IP_PER_MINUTE': '1'},
      );
      addTearDown(direct.close);
      expect((await direct.call(a, 'GET', '/v1/config')).status, 200);
      final spoofed = await direct.call(
        a,
        'GET',
        '/v1/config',
        extraHeaders: {'x-forwarded-for': '203.0.113.9'},
      );
      expect(spoofed.status, 429, reason: 'XFF is ignored without a proxy');

      final proxied = await Harness.start(
        allowed: [a],
        env: {'CONNECT_RATE_IP_PER_MINUTE': '1', 'CONNECT_TRUST_PROXY': '1'},
      );
      addTearDown(proxied.close);
      for (final ip in ['203.0.113.1', '203.0.113.2']) {
        final response = await proxied.call(
          a,
          'GET',
          '/v1/config',
          extraHeaders: {'x-forwarded-for': 'forged, $ip'},
        );
        expect(response.status, 200);
      }
      final again = await proxied.call(
        a,
        'GET',
        '/v1/config',
        extraHeaders: {'x-forwarded-for': 'other, 203.0.113.1'},
      );
      expect(again.status, 429);
    });

    test('Slack hooks are exempt from the IP budget', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {'CONNECT_RATE_IP_PER_MINUTE': '1'},
      );
      addTearDown(harness.close);
      for (var i = 0; i < 3; i++) {
        final response = await harness.raw(
          'POST',
          '/v1/hooks/slack/events',
          body: utf8.encode('{}'),
        );
        expect(response.status, isNot(429));
      }
    });
  });
}
