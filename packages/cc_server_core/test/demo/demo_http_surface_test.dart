import 'dart:convert';
import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import '../helpers/best_effort_delete.dart';
import '../helpers/native_staging.dart';

/// The demo's public HTTP and authenticated resource surfaces.
///
/// Sensitive bytes require the Noise resource tunnel, even on the demo.
/// Inside that tunnel, execution and backup ports remain unavailable while
/// signed media requests still obey their own authorization and SSRF checks.
///
/// This also pins `/invites/redeem` CORS: browser pairing preflights the
/// JSON POST, and a bare 405 used to make cross-origin pairing impossible.
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
  late RemoteRpcClient remote;
  late String deviceId;
  late String psk;
  late String workspaceId;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('cc_demo_http');
    await stageServerNatives(tmp.path);
    server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0', '--code-index', 'off'],
      demoBuilder: buildDemoWiring,
    );
    http = HttpClient();
    final recipient = await CredentialSeal.newRecipient();
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'code': 'demo', 'handoff_key': recipient.publicKey}));
    final resp = await req.close();
    final wire = await resp.transform(utf8.decoder).join();
    expect(resp.statusCode, HttpStatus.ok, reason: wire);
    final body = jsonDecode(wire) as Map<String, dynamic>;
    final credential = await CredentialSeal.open(
      recipientPrivateKey: recipient.privateKey,
      envelope: (body['box'] as Map).cast<String, dynamic>(),
      context: 'cc-public-demo-v1',
    );
    deviceId = credential['device_id'] as String;
    psk = credential['psk'] as String;
    workspaceId = credential['workspace_id'] as String;
    remote = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: deviceId,
      psk: psk,
    );
  });

  tearDownAll(() async {
    await remote.close();
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

  Future<int> resourceStatus(Uri uri, {String method = 'GET'}) async {
    final response = await remote.resources
        .request(method, uri)
        .timeout(const Duration(seconds: 10));
    await response.body.drain<void>().timeout(const Duration(seconds: 10));
    return response.statusCode;
  }

  Uri signedResource(
    String path,
    String target, [
    Map<String, String>? query,
  ]) => Uri(
    path: path,
    queryParameters: {
      ...?query,
      'd': deviceId,
      's': RemoteControlCrypto.signProxyTarget(target, psk),
    },
  );

  /// Redeems the public code to a fresh client-held recipient, optionally
  /// forging an `X-Forwarded-For`.
  Future<int> redeemStatus({String? forwardedFor}) async {
    final recipient = await CredentialSeal.newRecipient();
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    if (forwardedFor != null) {
      req.headers.set('x-forwarded-for', forwardedFor);
    }
    req.write(jsonEncode({'code': 'demo', 'handoff_key': recipient.publicKey}));
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

  test('public byte routes require the encrypted resource channel', () async {
    for (final path in <String>[
      '/proxy/vscode/session/index.html',
      '/rig/stream/rig-1/frame',
      '/rig/clipboard/rig-1',
      '/rig/files/rig-1',
      '/backup/workspace',
      '/backup/snapshot',
      '/backup/restore',
      '/meeting/audio',
      '/workspace/logo',
      '/blob',
      '/soundscape/stream',
      '/proxy/font',
      signedResource('/proxy/media', 'http://127.0.0.1:9/image.png', {
        'u': base64Url.encode(utf8.encode('http://127.0.0.1:9/image.png')),
      }).toString(),
    ]) {
      final resp = await get(path).timeout(const Duration(seconds: 10));
      await resp.drain<void>().timeout(const Duration(seconds: 10));
      expect(
        resp.statusCode,
        HttpStatus.upgradeRequired,
        reason: '$path must not expose bytes over public HTTP, even if signed',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('demo execution and backup bytes stay unavailable over Noise', () async {
    final rig = signedResource(
      '/rig/stream/rig-1/frame',
      'rig:$workspaceId/rig-1',
      {'w': workspaceId},
    );
    final rigTransfer = LocalRpcServer.rigTransferTarget(workspaceId, 'rig-1');
    final clipboard = signedResource('/rig/clipboard/rig-1', rigTransfer, {
      'w': workspaceId,
    });
    final files = signedResource('/rig/files/rig-1', rigTransfer, {
      'w': workspaceId,
    });
    final backup = signedResource(
      '/backup/workspace',
      'backup-workspace:$workspaceId',
      {'w': workspaceId},
    );
    final snapshot = signedResource(
      '/backup/snapshot',
      'backup-snapshot:demo-snapshot',
      {'n': 'demo-snapshot'},
    );
    final restore = signedResource(
      '/backup/restore',
      'backup-restore:$workspaceId',
      {'w': workspaceId},
    );

    expect(
      await resourceStatus(Uri.parse('/proxy/vscode/session/index.html')),
      HttpStatus.forbidden,
      reason: 'an unknown editor capability cannot open a demo proxy',
    );
    for (final uri in [rig, clipboard, files, backup]) {
      expect(
        await resourceStatus(uri),
        HttpStatus.notFound,
        reason: '${uri.path} has no executable or export port on a demo',
      );
    }
    expect(
      await resourceStatus(snapshot),
      HttpStatus.forbidden,
      reason: 'a visitor cannot retrieve install-wide snapshots',
    );
    expect(
      await resourceStatus(restore, method: 'POST'),
      HttpStatus.forbidden,
      reason: 'a visitor cannot restore a demo workspace',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test(
    'unpaired public identity and integration routes still refuse',
    () async {
      for (final path in <String>[
        '/oauth/github/callback',
        '/oidc/login',
        '/oidc/callback',
        '/saml/login',
        '/scim/v2/Users',
        '/webhooks/github',
        '/api/webhooks/tickets/linear',
        '/mcp',
        '/sse',
      ]) {
        final resp = await get(path).timeout(const Duration(seconds: 10));
        await resp.drain<void>().timeout(const Duration(seconds: 10));
        expect(
          resp.statusCode,
          anyOf(
            HttpStatus.notFound,
            HttpStatus.unauthorized,
            HttpStatus.forbidden,
            HttpStatus.badRequest,
            HttpStatus.methodNotAllowed,
          ),
          reason: '$path must not give an anonymous demo visitor access',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('sealed media refuses unsigned, forged and SSRF targets', () async {
    Uri image(String url, {String? signature}) => Uri(
      path: '/proxy/media',
      queryParameters: {
        'u': base64Url.encode(utf8.encode(url)),
        'd': deviceId,
        's': ?signature,
      },
    );

    const safe = 'https://example.com/i.png';
    expect(await resourceStatus(image(safe)), HttpStatus.badRequest);
    expect(
      await resourceStatus(image(safe, signature: 'invalid')),
      HttpStatus.forbidden,
    );
    for (final target in <String>[
      'http://169.254.169.254/latest/meta-data/',
      'http://127.0.0.1:9/x.png',
      'http://[fd00::1]/x.png',
    ]) {
      final status = await resourceStatus(
        image(
          target,
          signature: RemoteControlCrypto.signProxyTarget(target, psk),
        ),
      );
      expect(
        status,
        HttpStatus.forbidden,
        reason: '$target must not be fetched',
      );
    }
    const fileUrl = 'file:///etc/passwd';
    expect(
      await resourceStatus(
        image(
          fileUrl,
          signature: RemoteControlCrypto.signProxyTarget(fileUrl, psk),
        ),
      ),
      HttpStatus.badRequest,
    );
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
    expect(
      resp.headers.value('access-control-allow-methods'),
      contains('POST'),
    );
    expect(
      resp.headers.value('access-control-allow-headers')?.toLowerCase(),
      contains('content-type'),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('POST /invites/redeem seals the PSK and preserves CORS', () async {
    final recipient = await CredentialSeal.newRecipient();
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'code': 'demo', 'handoff_key': recipient.publicKey}));
    final resp = await req.close();
    final wire = await resp.transform(utf8.decoder).join();
    expect(resp.statusCode, 200);
    expect(resp.headers.value('access-control-allow-origin'), '*');
    expect(wire, isNot(contains('"psk"')));
    final body = jsonDecode(wire) as Map<String, dynamic>;
    final credential = await CredentialSeal.open(
      recipientPrivateKey: recipient.privateKey,
      envelope: (body['box'] as Map).cast<String, dynamic>(),
      context: 'cc-public-demo-v1',
    );
    expect(credential['psk'], isA<String>());
    expect(credential['device_id'], isA<String>());
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('demo refuses a missing client-held recipient', () async {
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'code': 'demo'}));
    final resp = await req.close();
    await resp.drain<void>();
    expect(resp.statusCode, HttpStatus.forbidden);
  });
}
