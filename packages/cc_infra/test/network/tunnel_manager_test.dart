import 'dart:io';

import 'package:cc_infra/src/network/tunnel_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_tunnel_manager_test');
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {
      // Best-effort cleanup.
    }
  });

  group('cloudflared supervision', () {
    test(
      'parses the quick-tunnel URL, goes up, and stop() terminates it',
      () async {
        const url = 'https://lorem-ipsum-dolor-sit.trycloudflare.com';
        final fake = _writeFakeExe(tmp, 'fake_cloudflared', '''
#!/bin/sh
echo "2026-07-10T12:00:00Z INF Thank you for trying Cloudflare Tunnel."
echo "2026-07-10T12:00:00Z INF |  $url  |"
exec sleep 30
''');
        final addresses = <TunnelAddress?>[];
        final manager = TunnelManager(
          provider: TunnelProvider.cloudflared,
          localPort: 8080,
          binaryPath: fake.path,
          baseBackoff: const Duration(milliseconds: 50),
          onAddress: addresses.add,
          log: (_) {},
        );
        addTearDown(manager.stop);

        final up = manager.statusStream.firstWhere(
          (s) => s.state == TunnelState.up,
        );
        await manager.start();
        final status = await up.timeout(const Duration(seconds: 10));

        expect(status.publicUrl, url);
        expect(status.error, isNull);
        expect(status.restarts, 0);
        expect(addresses, [const TunnelAddress(publicUrl: url)]);

        await manager.stop();
        expect(manager.status.state, TunnelState.off);
        // The tunnel going down reports a null address.
        expect(addresses.last, isNull);
      },
    );

    test('a matching checksum spawns (case-insensitive hex compare)', () async {
      const url = 'https://sha-pinned-tunnel-ok.trycloudflare.com';
      final fake = _writeFakeExe(tmp, 'fake_cloudflared_pinned', '''
#!/bin/sh
echo "INF |  $url  |"
exec sleep 30
''');
      final digest = sha256
          .convert(fake.readAsBytesSync())
          .toString()
          .toUpperCase();
      final manager = TunnelManager(
        provider: TunnelProvider.cloudflared,
        localPort: 8080,
        binaryPath: fake.path,
        expectedSha256: digest,
        baseBackoff: const Duration(milliseconds: 50),
        log: (_) {},
      );
      addTearDown(manager.stop);

      final up = manager.statusStream.firstWhere(
        (s) => s.state == TunnelState.up,
      );
      await manager.start();
      final status = await up.timeout(const Duration(seconds: 10));
      expect(status.publicUrl, url);
      await manager.stop();
    });

    test('checksum mismatch refuses to spawn with a loud error', () async {
      final marker = '${tmp.path}/spawned.marker';
      final fake = _writeFakeExe(tmp, 'fake_cloudflared_evil', '''
#!/bin/sh
touch $marker
exec sleep 30
''');
      final manager = TunnelManager(
        provider: TunnelProvider.cloudflared,
        localPort: 8080,
        binaryPath: fake.path,
        expectedSha256: 'a' * 64,
        baseBackoff: const Duration(milliseconds: 50),
        log: (_) {},
      );
      addTearDown(manager.stop);

      final err = manager.statusStream.firstWhere(
        (s) => s.state == TunnelState.error,
      );
      await manager.start();
      final status = await err.timeout(const Duration(seconds: 10));

      expect(status.error, contains('checksum mismatch'));
      expect(status.error, contains('a' * 64));
      // Give a (buggy) spawn a beat to land, then assert none ever happened.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        File(marker).existsSync(),
        isFalse,
        reason: 'the binary must never be spawned on checksum mismatch',
      );
      await manager.stop();
    });

    test(
      'restarts with backoff after immediate exit; stop() ends the loop',
      () async {
        final fake = _writeFakeExe(tmp, 'fake_crash', '''
#!/bin/sh
echo "boom" >&2
exit 7
''');
        final manager = TunnelManager(
          provider: TunnelProvider.cloudflared,
          localPort: 8080,
          binaryPath: fake.path,
          baseBackoff: const Duration(milliseconds: 20),
          log: (_) {},
        );
        addTearDown(manager.stop);

        final restarted = manager.statusStream.firstWhere(
          (s) => s.restarts >= 2,
        );
        await manager.start();
        final status = await restarted.timeout(const Duration(seconds: 15));

        expect(status.state, TunnelState.error);
        expect(status.error, contains('code 7'));
        expect(
          status.error,
          contains('boom'),
          reason: 'the exit error carries the output tail',
        );

        await manager.stop();
        expect(manager.status.state, TunnelState.off);
        final frozen = manager.status.restarts;
        // No restart after stop: the counter and state must stay frozen.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(manager.status.restarts, frozen);
        expect(manager.status.state, TunnelState.off);
      },
    );
  });

  group('ngrok supervision', () {
    test('parses the JSON started-tunnel log line', () async {
      const url = 'https://84c5df474.ngrok-free.dev';
      final fake = _writeFakeExe(tmp, 'fake_ngrok', '''
#!/bin/sh
echo '{"t":"2026-07-10T12:00:00+0000","lvl":"info","msg":"started tunnel","obj":"tunnels","name":"command_line","addr":"http://localhost:8080","url":"$url"}'
exec sleep 30
''');
      final addresses = <TunnelAddress?>[];
      final manager = TunnelManager(
        provider: TunnelProvider.ngrok,
        localPort: 8080,
        binaryPath: fake.path,
        baseBackoff: const Duration(milliseconds: 50),
        onAddress: addresses.add,
        log: (_) {},
      );
      addTearDown(manager.stop);

      final up = manager.statusStream.firstWhere(
        (s) => s.state == TunnelState.up,
      );
      await manager.start();
      final status = await up.timeout(const Duration(seconds: 10));

      expect(status.publicUrl, url);
      expect(addresses.first?.publicUrl, url);
      await manager.stop();
      expect(manager.status.state, TunnelState.off);
    });
  });

  group('tailscale detection', () {
    test('reports the MagicDNS host as a tailnet:// address', () async {
      final fake = _writeFakeExe(tmp, 'fake_tailscale', '''
#!/bin/sh
echo '{"BackendState":"Running","Self":{"DNSName":"myhost.tail1234.ts.net.","Online":true}}'
''');
      final addresses = <TunnelAddress?>[];
      final manager = TunnelManager(
        provider: TunnelProvider.tailscale,
        localPort: 9443,
        binaryPath: fake.path,
        onAddress: addresses.add,
        log: (_) {},
      );
      addTearDown(manager.stop);

      await manager.start();
      expect(manager.status.state, TunnelState.up);
      expect(manager.status.publicUrl, 'tailnet://myhost.tail1234.ts.net:9443');
      expect(
        addresses.single?.publicUrl,
        'tailnet://myhost.tail1234.ts.net:9443',
      );

      await manager.stop();
      expect(manager.status.state, TunnelState.off);
      expect(addresses.last, isNull);
    });

    test('an offline node is a clear error, not a silent up', () async {
      final fake = _writeFakeExe(tmp, 'fake_tailscale_offline', '''
#!/bin/sh
echo '{"BackendState":"Stopped","Self":{"DNSName":"myhost.tail1234.ts.net.","Online":false}}'
''');
      final manager = TunnelManager(
        provider: TunnelProvider.tailscale,
        localPort: 9443,
        binaryPath: fake.path,
        log: (_) {},
      );
      addTearDown(manager.stop);

      await manager.start();
      expect(manager.status.state, TunnelState.error);
      expect(manager.status.error, contains('offline'));
      await manager.stop();
    });

    test('a missing binary is a clear error', () async {
      final manager = TunnelManager(
        provider: TunnelProvider.tailscale,
        localPort: 9443,
        binaryPath: '${tmp.path}/does-not-exist',
        log: (_) {},
      );
      addTearDown(manager.stop);

      await manager.start();
      expect(manager.status.state, TunnelState.error);
      expect(manager.status.error, contains('not found'));
      await manager.stop();
    });
  });

  group('URL parsing (pure)', () {
    test('cloudflared: extracts the trycloudflare URL from the banner box', () {
      expect(
        TunnelManager.parseCloudflaredUrl(
          '2026-07-10T12:00:00Z INF |  https://abc-def-123.trycloudflare.com  |',
        ),
        'https://abc-def-123.trycloudflare.com',
      );
      expect(
        TunnelManager.parseCloudflaredUrl(
          'Visit it at: https://quick-brown-fox.trycloudflare.com',
        ),
        'https://quick-brown-fox.trycloudflare.com',
      );
      expect(
        TunnelManager.parseCloudflaredUrl(
          '2026-07-10T12:00:00Z INF Registered tunnel connection',
        ),
        isNull,
      );
      expect(
        TunnelManager.parseCloudflaredUrl('https://example.com is not it'),
        isNull,
      );
    });

    test('ngrok: parses the JSON log line', () {
      expect(
        TunnelManager.parseNgrokUrl(
          '{"lvl":"info","msg":"started tunnel","obj":"tunnels",'
          '"addr":"http://localhost:8080","url":"https://x9y.ngrok-free.app"}',
        ),
        'https://x9y.ngrok-free.app',
      );
      // A JSON line without a URL (e.g. the session event) is not a match —
      // notably the http:// `addr` field must not be mistaken for the URL.
      expect(
        TunnelManager.parseNgrokUrl(
          '{"lvl":"info","msg":"client session established",'
          '"addr":"http://localhost:8080"}',
        ),
        isNull,
      );
    });

    test('ngrok: falls back to the url=… text format', () {
      expect(
        TunnelManager.parseNgrokUrl(
          't=2026-07-10T12:00:00+0000 lvl=info msg="started tunnel" '
          'obj=tunnels name=command_line addr=http://localhost:8080 '
          'url=https://legacy.ngrok-free.app',
        ),
        'https://legacy.ngrok-free.app',
      );
      expect(
        TunnelManager.parseNgrokUrl('not json "url":"https://frag.ngrok.app"'),
        'https://frag.ngrok.app',
      );
      expect(TunnelManager.parseNgrokUrl('lvl=info msg="no url here"'), isNull);
    });

    test('tailscale: parses Self.DNSName (trailing dot stripped) + Online', () {
      final online = TunnelManager.parseTailscaleStatus(
        '{"BackendState":"Running","Self":'
        '{"DNSName":"host.tail1234.ts.net.","Online":true}}',
      );
      expect(online, isNotNull);
      expect(online!.dnsName, 'host.tail1234.ts.net');
      expect(online.online, isTrue);

      final offline = TunnelManager.parseTailscaleStatus(
        '{"Self":{"DNSName":"host.tail1234.ts.net","Online":false}}',
      );
      expect(offline!.dnsName, 'host.tail1234.ts.net');
      expect(offline.online, isFalse);

      expect(
        TunnelManager.parseTailscaleStatus('{"BackendState":"Running"}'),
        isNull,
      );
      expect(TunnelManager.parseTailscaleStatus('not json at all'), isNull);
      expect(
        TunnelManager.parseTailscaleStatus('{"Self":{"DNSName":""}}'),
        isNull,
      );
    });
  });

  group('TunnelStatus', () {
    test('toWire round-trips the fields', () {
      final since = DateTime.utc(2026, 7, 10, 12);
      final status = TunnelStatus(
        provider: TunnelProvider.ngrok,
        state: TunnelState.up,
        publicUrl: 'https://x.ngrok-free.app',
        restarts: 2,
        since: since,
      );
      expect(status.toWire(), {
        'provider': 'ngrok',
        'state': 'up',
        'publicUrl': 'https://x.ngrok-free.app',
        'error': null,
        'restarts': 2,
        'since': since.toIso8601String(),
      });
    });

    test('constructor validation rejects a malformed sha256 pin', () {
      expect(
        () => TunnelManager(
          provider: TunnelProvider.ngrok,
          localPort: 8080,
          expectedSha256: 'not-a-digest',
        ),
        throwsArgumentError,
      );
      expect(
        () => TunnelManager(provider: TunnelProvider.ngrok, localPort: 0),
        throwsArgumentError,
      );
    });
  });
}

/// Writes a `#!/bin/sh` fake executable (chmod 755) into [dir] so the tests
/// need no real tunnel binaries.
File _writeFakeExe(Directory dir, String name, String script) {
  final file = File('${dir.path}/$name')..writeAsStringSync(script);
  final chmod = Process.runSync('chmod', ['755', file.path]);
  if (chmod.exitCode != 0) {
    throw StateError('chmod failed: ${chmod.stderr}');
  }
  return file;
}
