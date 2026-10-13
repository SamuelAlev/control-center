import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const psk = 'test-pre-shared-key';
  const deviceId = 'web-client-1';

  MediaProxyConfig config() => MediaProxyConfig(
    httpBase: Uri.parse('http://127.0.0.1:9030/_cc_resource/test-cap/'),
    deviceId: deviceId,
    psk: psk,
  );

  group('capability-preserving routes', () {
    test('all bulk routes retain the local capability prefix and signed query', () {
      final c = config();
      final routes = [
        c.workspaceLogoUrl(workspaceId: 'workspace'),
        c.meetingAudioUrl(workspaceId: 'workspace', meetingId: 'meeting'),
        c.blobUploadUrl(workspaceId: 'workspace'),
        c.backupWorkspaceUrl(workspaceId: 'workspace'),
        c.backupSnapshotUrl(name: 'snapshot'),
        c.backupRestoreUrl(workspaceId: 'workspace'),
        c.fontUrl(family: 'Inter', weight: 400, italic: false),
        c.rigStreamUrl(workspaceId: 'workspace', rigId: 'rig', width: 500, height: 300),
        c.rigFilesUrl(workspaceId: 'workspace', rigId: 'rig'),
        c.rigMicrophoneUrl(workspaceId: 'workspace', rigId: 'rig'),
        c.soundscapeStreamUrl(workspaceId: 'workspace', mood: 'calm'),
        c.soundscapePlaylistUrl(workspaceId: 'workspace', mood: 'calm'),
      ];
      for (final value in routes) {
        final uri = Uri.parse(value);
        expect(uri.path, startsWith('/_cc_resource/test-cap/'));
        expect(uri.host, '127.0.0.1');
        expect(uri.queryParameters['d'], deviceId);
        expect(uri.queryParameters['s'], isNotEmpty);
      }
    });
    test('blob originals use the same signed ref with attachment disposition', () {
      final c = config();
      final hash = 'a' * 64;
      final inline = Uri.parse(c.blobUrl(
        workspaceId: 'workspace',
        ref: 'blob:sha256:$hash',
      ));
      final downloaded = Uri.parse(c.blobUrl(
        workspaceId: 'workspace',
        ref: 'blob:sha256:$hash',
        downloadName: 'drawing.svg',
      ));
      expect(downloaded.path, inline.path);
      expect(downloaded.queryParameters['s'], inline.queryParameters['s']);
      expect(downloaded.queryParameters['download'], '1');
      expect(downloaded.queryParameters['name'], 'drawing.svg');
      expect(RemoteControlCrypto.verifyProxyTarget(
        'blob:workspace:$hash',
        psk,
        downloaded.queryParameters['s']!,
      ), isTrue);
      expect(c.blobUrl(
        workspaceId: 'workspace',
        ref: '/tmp/drawing.svg',
        downloadName: 'drawing.svg',
      ), isEmpty);
    });

  });

  group('MediaProxyConfig.resolve', () {
    test('passes through empty, data:, blob: and relative URLs', () {
      final c = config();
      expect(c.resolve(''), '');
      expect(
        c.resolve('data:image/png;base64,AAAA'),
        'data:image/png;base64,AAAA',
      );
      expect(c.resolve('blob:https://x/y'), 'blob:https://x/y');
      expect(c.resolve('/assets/logo.png'), '/assets/logo.png');
    });

    test('rewrites an http(s) URL to a signed /proxy/media on the server', () {
      const raw = 'https://news.example.org/a/cover.jpg?w=600&token=abc';
      final proxied = Uri.parse(config().resolve(raw));

      expect(proxied.scheme, 'http');
      expect(proxied.host, '127.0.0.1');
      expect(proxied.port, 9030);
      expect(proxied.path, '/_cc_resource/test-cap/proxy/media');
      expect(proxied.queryParameters['d'], deviceId);

      // The encoded target round-trips back to the exact original URL...
      final decoded = utf8.decode(
        base64Url.decode(proxied.queryParameters['u']!),
      );
      expect(decoded, raw);

      // ...and the signature is the one the server re-derives from the PSK,
      // so the endpoint accepts it (and only it).
      expect(
        RemoteControlCrypto.verifyProxyTarget(
          decoded,
          psk,
          proxied.queryParameters['s']!,
        ),
        isTrue,
      );
      // A signature minted for one URL must not validate a different target.
      expect(
        RemoteControlCrypto.verifyProxyTarget(
          'https://news.example.org/OTHER.jpg',
          psk,
          proxied.queryParameters['s']!,
        ),
        isFalse,
      );
    });

    test('proxies a private-user-images JWT attachment, JWT intact', () {
      // GitHub PR-body attachments are spliced to pre-signed
      // `private-user-images.*` URLs whose `?jwt=` query IS the auth. The proxy
      // must carry that query through verbatim — any re-encoding would yield a
      // 403 and the image would not render. (A web/remote thin client can only
      // load these through the proxy; dart:io is unavailable there.)
      const raw =
          'https://private-user-images.githubusercontent.com/47146443/'
          '612485089-0a1f8a49-c2bd-45d4-9788-2463672f5854.png'
          '?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.payload-segment.sig-segment';
      final proxied = Uri.parse(config().resolve(raw));

      expect(proxied.host, '127.0.0.1');
      expect(proxied.path, '/_cc_resource/test-cap/proxy/media');
      final decoded = utf8.decode(
        base64Url.decode(proxied.queryParameters['u']!),
      );
      expect(decoded, raw, reason: 'the JWT query must survive verbatim');
      expect(
        RemoteControlCrypto.verifyProxyTarget(
          decoded,
          psk,
          proxied.queryParameters['s']!,
        ),
        isTrue,
      );
    });

    test('omits the w param by default', () {
      final proxied = Uri.parse(config().resolve('https://x/y.jpg'));
      expect(proxied.queryParameters.containsKey('w'), isFalse);
    });

    test('adds an UNSIGNED w param without changing the signed target', () {
      const raw = 'https://x/y.jpg';
      final plain = Uri.parse(config().resolve(raw));
      final sized = Uri.parse(config().resolve(raw, maxWidth: 340));

      // Bucketed UP to the next ladder rung so nearby display sizes share one
      // (url, w) cache key on the server and in the client image cache.
      expect(sized.queryParameters['w'], '384');
      // The signature covers the raw URL only, so it is identical whether or not
      // a downscale is requested — w is a post-process hint, not part of `u`.
      expect(sized.queryParameters['u'], plain.queryParameters['u']);
      expect(sized.queryParameters['s'], plain.queryParameters['s']);
    });
  });

  group('rig media URLs', () {
    test('requests 60 fps by default and signs the rig target', () {
      final uri = Uri.parse(
        config().rigStreamUrl(
          workspaceId: 'ws-1',
          rigId: 'rig-1',
          width: 1280,
          height: 800,
        ),
      );

      expect(uri.queryParameters['fps'], '60');
      expect(
        RemoteControlCrypto.verifyProxyTarget(
          'rig:ws-1/rig-1',
          psk,
          uri.queryParameters['s']!,
        ),
        isTrue,
      );
    });

    test('microphone chunks and session end share one signed target', () {
      final c = config();
      final chunk = Uri.parse(
        c.rigMicrophoneUrl(workspaceId: 'ws-1', rigId: 'rig-1'),
      );
      final end = Uri.parse(
        c.rigMicrophoneUrl(workspaceId: 'ws-1', rigId: 'rig-1', end: true),
      );

      expect(chunk.path, '/_cc_resource/test-cap/rig/stream/rig-1');
      expect(chunk.queryParameters['lane'], 'microphone');
      expect(chunk.queryParameters['rate'], '16000');
      expect(chunk.queryParameters['channels'], '1');
      expect(chunk.queryParameters.containsKey('end'), isFalse);
      expect(end.queryParameters['end'], '1');
      expect(end.queryParameters['s'], chunk.queryParameters['s']);
    });
  });

  group('MediaProxyScope.urlOf', () {
    testWidgets(
      'does not load remote HTTP media without a live facade',
      (tester) async {
        late String resolved;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              resolved = MediaProxyScope.urlOf(context, 'https://x/y.png');
              return const SizedBox();
            },
          ),
        );
        expect(resolved, isEmpty);
      },
    );

    testWidgets('routes through the nearest scope when present (connected)', (
      tester,
    ) async {
      late String resolved;
      await tester.pumpWidget(
        MediaProxyScope(
          config: config(),
          child: Builder(
            builder: (context) {
              resolved = MediaProxyScope.urlOf(context, 'https://x/y.png');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved, startsWith('http://127.0.0.1:9030/_cc_resource/test-cap/proxy/media?'));
    });
  });
}
