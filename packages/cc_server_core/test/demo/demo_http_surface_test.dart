import 'dart:convert';
import 'dart:io';

import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import '../helpers/best_effort_delete.dart';
import '../helpers/native_staging.dart';

/// The demo's HTTP surface, asserted from outside.
///
/// Layer 1 of the lockdown works by passing `null` for a port, which makes both
/// the RPC ops AND the byte routes disappear. `demo_op_lockdown_ratchet_test`
/// covers the ops; this covers the routes — including the media proxy, which
/// was the last way a locked-down host could still make an outbound request.
///
/// It also pins the `/invites/redeem` CORS fix, which is not demo-specific: the
/// web client sends `Content-Type: application/json`, so a browser preflights
/// the redeem POST, and that preflight used to hit a bare 405 with no CORS
/// headers — making cross-origin pairing by invite impossible for anyone.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for demo server boot',
      () => fail('run scripts/natives/build_natives.sh'),
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  late Directory tmp;
  late CcServer server;
  late HttpClient http;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('cc_demo_http');
    await stageServerNatives(tmp.path);
    server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0', '--code-index', 'off'],
      demoBuilder: buildDemoWiring,
    );
    http = HttpClient();
  });

  tearDownAll(() async {
    http.close(force: true);
    await server.shutdown();
    await deleteDirBestEffort(tmp);
  });

  Future<HttpClientResponse> get(String path) async {
    final req = await http.getUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}$path'),
    );
    return req.close();
  }

  /// Redeems the public code, optionally forging an `X-Forwarded-For`.
  Future<int> redeemStatus({String? forwardedFor}) async {
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    if (forwardedFor != null) {
      req.headers.set('x-forwarded-for', forwardedFor);
    }
    req.write(jsonEncode({'code': 'demo'}));
    final resp = await req.close();
    await resp.drain<void>();
    return resp.statusCode;
  }

  test('a forged X-Forwarded-For cannot buy a fresh per-IP budget', () async {
    // `trustProxy` is on for a demo because the documented topology puts a
    // TLS-terminating edge in front, and without it every visitor shares the
    // proxy's address so the per-IP cap bounds the whole deployment.
    //
    // The header is APPENDED to by each hop, so only the RIGHTMOST entry was
    // written by a proxy — everything left of it is whatever the client sent.
    // Reading the leftmost entry made the cap one header away from useless: a
    // visitor could be a brand-new address on every request. Here each call
    // forges a different left hop behind one common right hop, which is
    // exactly the shape an edge produces, and the cap must still bite.
    var refused = false;
    for (var i = 0; i < 12; i++) {
      final status = await redeemStatus(forwardedFor: 'far.$i.0.1, 8.8.8.8');
      if (status == HttpStatus.tooManyRequests ||
          status == HttpStatus.serviceUnavailable ||
          status == HttpStatus.forbidden) {
        refused = true;
        break;
      }
    }
    expect(
      refused,
      isTrue,
      reason:
          'every request forged a different LEFT hop behind one right hop; if '
          'the cap never bit, the address is being read from the client half '
          'of the header',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('every execution and identity route is absent', () async {
    // Each of these is a byte route whose port the demo passes as null. A 404
    // here is the same answer a host that never had the capability gives —
    // the route is not merely refusing, it has nothing behind it.
    const absent = <String>[
      '/proxy/vscode/session/index.html',
      '/rig/stream/rig-1/frame',
      '/rig/clipboard/rig-1',
      // The backup byte lane. A demo's databases are shared public fixtures,
      // and `/backup/workspace` would hand one of them to whoever asked.
      '/backup/workspace',
      '/backup/snapshot',
      '/backup/restore',
      '/oauth/github/callback',
      '/oidc/login',
      '/oidc/callback',
      '/saml/login',
      '/scim/v2/Users',
      '/webhooks/github',
      '/api/webhooks/tickets/linear',
      '/mcp',
      '/sse',
      '/proxy/font?u=https%3A%2F%2Fexample.invalid%2Ff.woff2',
    ];
    for (final path in absent) {
      // Per-request timeout: a route that HANGS is as much a failure as one
      // that answers, and without this the whole suite just times out with no
      // indication which path never closed its response.
      final resp = await get(path).timeout(
        const Duration(seconds: 10),
        onTimeout: () => fail('$path did not answer — it must not stream'),
      );
      await resp
          .drain<void>()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => fail('$path never closed its response'),
          );
      expect(
        resp.statusCode,
        anyOf(
          HttpStatus.notFound,
          HttpStatus.unauthorized,
          // The rig byte routes verify their signed URL BEFORE consulting the
          // port, so an unsigned probe is rejected at the signature.
          HttpStatus.badRequest,
          // A POST-only route (the MCP lanes) answers a GET probe at the
          // method check. Either way nothing behind the route is reachable:
          // the port is null, so a well-formed request 404s too.
          HttpStatus.methodNotAllowed,
        ),
        reason: '$path must not be served by a demo host',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('the media proxy answers but refuses anything unsigned', () async {
    // Unlike the routes above, `/proxy/media` IS served on a demo host: the
    // newsfeed reads real feeds and a feed without images is the one surface
    // nobody wants a screenshot of. What makes that safe is not absence but
    // the checks it already had — so pin them, because "enabled" is otherwise
    // indistinguishable from "open relay".
    for (final path in <String>[
      // No signature at all.
      '/proxy/media?u=https%3A%2F%2Fexample.com%2Fi.png',
      // A signature that cannot verify against any device PSK.
      '/proxy/media?u=https%3A%2F%2Fexample.com%2Fi.png&d=nope&s=nope',
      // The SSRF shapes, which must lose before the fetch either way.
      '/proxy/media?u=http%3A%2F%2F169.254.169.254%2Flatest%2Fmeta-data%2F&d=nope&s=nope',
      '/proxy/media?u=http%3A%2F%2F127.0.0.1%3A9%2Fx.png&d=nope&s=nope',
      '/proxy/media?u=file%3A%2F%2F%2Fetc%2Fpasswd&d=nope&s=nope',
    ]) {
      final resp = await get(path).timeout(
        const Duration(seconds: 10),
        onTimeout: () => fail('$path did not answer'),
      );
      await resp.drain<void>();
      expect(
        resp.statusCode,
        anyOf(
          HttpStatus.badRequest,
          HttpStatus.forbidden,
          HttpStatus.notFound,
        ),
        reason: '$path must never be fetched on behalf of a visitor',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('/healthz still answers, unauthenticated and CORS-open', () async {
    final resp = await get('/healthz');
    expect(resp.statusCode, 200);
    expect(resp.headers.value('access-control-allow-origin'), '*');
    final body = jsonDecode(await resp.transform(utf8.decoder).join());
    expect((body as Map)['status'], 'ok');
    expect(
      body['demo'],
      isTrue,
      reason:
          'the client probes /healthz before connecting and needs to know it '
          'is talking to a demo so the shell can say so',
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('OPTIONS /invites/redeem answers the browser preflight', () async {
    final req = await http.openUrl(
      'OPTIONS',
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers
      ..set('Origin', 'https://app.usectrl.dev')
      ..set('Access-Control-Request-Method', 'POST')
      ..set('Access-Control-Request-Headers', 'content-type');
    final resp = await req.close();
    await resp.drain<void>();

    expect(
      resp.statusCode,
      HttpStatus.noContent,
      reason: 'a 405 here made cross-origin invite pairing impossible',
    );
    expect(resp.headers.value('access-control-allow-origin'), '*');
    expect(resp.headers.value('access-control-allow-methods'), contains('POST'));
    expect(
      resp.headers.value('access-control-allow-headers')?.toLowerCase(),
      contains('content-type'),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('POST /invites/redeem carries CORS on the real response too', () async {
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'code': 'demo'}));
    final resp = await req.close();
    await resp.drain<void>();
    expect(resp.statusCode, 200);
    expect(resp.headers.value('access-control-allow-origin'), '*');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
