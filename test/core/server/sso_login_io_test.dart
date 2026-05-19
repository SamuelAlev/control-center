@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/server/sso_login_io.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves one canned `/auth/providers` body over plaintext loopback.
Future<HttpServer> _serve({
  required int status,
  required String body,
  SecurityContext? tls,
}) async {
  final server = tls == null
      ? await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      : await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, tls);
  server.listen((request) async {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(body);
    await request.response.close();
  });
  return server;
}

String _origin(HttpServer server, {bool tls = false}) =>
    '${tls ? 'https' : 'http'}://${server.address.address}:${server.port}';

const _body =
    '{"providers":[{"id":"saml","kind":"saml","label":"SAML"},'
    '{"id":"oidc","kind":"oidc","label":"OpenID Connect"}],'
    '"pairingEnabled":false}';

/// Generates a throwaway self-signed localhost certificate. Returns null when
/// the host has no usable `openssl`, so the TLS group skips rather than fails
/// on a machine that cannot mint one.
Future<SecurityContext?> _selfSignedContext(Directory dir) async {
  final cert = '${dir.path}/cert.pem';
  final key = '${dir.path}/key.pem';
  try {
    final result = await Process.run('openssl', [
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-days',
      '1',
      '-subj',
      '/CN=127.0.0.1',
      '-keyout',
      key,
      '-out',
      cert,
    ]);
    if (result.exitCode != 0) {
      return null;
    }
  } on Object {
    return null;
  }
  return SecurityContext()
    ..useCertificateChain(cert)
    ..usePrivateKey(key);
}

void main() {
  group('probeAuthProviders', () {
    test('parses the providers and the pairing posture', () async {
      final server = await _serve(status: 200, body: _body);
      addTearDown(() => server.close(force: true));

      final snapshot = await probeAuthProvidersImpl(_origin(server));

      expect(snapshot, isNotNull);
      expect(snapshot!.providers.map((p) => p.id), ['saml', 'oidc']);
      expect(snapshot.providers.first.label, 'SAML');
      expect(snapshot.ofKind('oidc').single.label, 'OpenID Connect');
      // The whole point of the probe: a server that turned manual pairing off
      // must be able to say so, or the connect screens keep offering a form
      // whose credentials it will refuse.
      expect(snapshot.pairingEnabled, isFalse);
    });

    test('an unreachable server is "nothing offered", not a throw', () async {
      // Bind then immediately release the port, so the address is well-formed
      // and certainly refuses.
      final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final origin = _origin(probe);
      await probe.close(force: true);

      expect(await probeAuthProvidersImpl(origin), isNull);
    });

    test('a non-200 answer yields null', () async {
      final server = await _serve(status: 404, body: 'nope');
      addTearDown(() => server.close(force: true));

      expect(await probeAuthProvidersImpl(_origin(server)), isNull);
    });

    test('a malformed body yields null', () async {
      final server = await _serve(status: 200, body: 'not json');
      addTearDown(() => server.close(force: true));

      expect(await probeAuthProvidersImpl(_origin(server)), isNull);
    });

    test('a non-URL origin yields null without dialling', () async {
      expect(await probeAuthProvidersImpl('not an origin'), isNull);
      expect(await probeAuthProvidersImpl(''), isNull);
    });

    group('over TLS', () {
      late Directory dir;
      SecurityContext? tls;

      setUpAll(() async {
        dir = await Directory.systemTemp.createTemp('cc-sso-probe-');
        tls = await _selfSignedContext(dir);
      });

      tearDownAll(() => dir.delete(recursive: true));

      test('accepts the probed host self-signed certificate', () async {
        final context = tls;
        if (context == null) {
          markTestSkipped('no usable openssl to mint a test certificate');
          return;
        }
        // The regression this guards: a non-loopback cc_server serves TLS with
        // a self-signed certificate BY DESIGN. A strict HttpClient fails the
        // handshake, the probe returns nothing, every "Sign in with …" button
        // disappears and single sign-on looks like a desktop feature that does
        // not exist — while the same server shows it fine on the web client.
        final server = await _serve(status: 200, body: _body, tls: context);
        addTearDown(() => server.close(force: true));

        final snapshot = await probeAuthProvidersImpl(
          _origin(server, tls: true),
        );

        expect(snapshot, isNotNull);
        expect(snapshot!.providers, hasLength(2));
      });

      test('does not follow a redirect onto another authority', () async {
        final context = tls;
        if (context == null) {
          markTestSkipped('no usable openssl to mint a test certificate');
          return;
        }
        final elsewhere = await _serve(status: 200, body: _body, tls: context);
        addTearDown(() => elsewhere.close(force: true));
        final redirector = await HttpServer.bindSecure(
          InternetAddress.loopbackIPv4,
          0,
          context,
        );
        addTearDown(() => redirector.close(force: true));
        redirector.listen((request) async {
          request.response
            ..statusCode = HttpStatus.movedTemporarily
            ..headers.set(
              'Location',
              '${_origin(elsewhere, tls: true)}/auth/providers',
            );
          await request.response.close();
        });

        // The certificate relaxation is narrowed to the exact host:port under
        // probe, so a server that bounces the probe somewhere else does not
        // get its self-signed certificate waved through too. Not a blanket
        // "trust anything" — which is why this is a per-client callback and
        // never an `HttpOverrides.global`.
        final snapshot = await probeAuthProvidersImpl(
          _origin(redirector, tls: true),
        );

        expect(snapshot, isNull);
      });
    });
  });

  group('the /auth/providers request', () {
    test('is a plain GET at the documented path', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final seen = <String>[];
      server.listen((request) async {
        seen.add('${request.method} ${request.uri.path}');
        request.response
          ..statusCode = 200
          ..write(jsonEncode({'providers': [], 'pairingEnabled': true}));
        await request.response.close();
      });

      final snapshot = await probeAuthProvidersImpl(_origin(server));

      expect(seen, ['GET /auth/providers']);
      expect(snapshot?.providers, isEmpty);
      expect(snapshot?.pairingEnabled, isTrue);
    });
  });
}
