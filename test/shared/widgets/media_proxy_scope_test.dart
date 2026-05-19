import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const psk = 'test-pre-shared-key';
  const deviceId = 'web-client-1';

  MediaProxyConfig config({String server = 'wss://cc.example.com:9030/rpc'}) =>
      MediaProxyConfig.fromConnection(
        serverUri: Uri.parse(server),
        deviceId: deviceId,
        psk: psk,
      )!;

  group('MediaProxyConfig.fromConnection', () {
    test('maps wss → https and ws → http, preserving host:port', () {
      expect(config().httpBase.toString(), 'https://cc.example.com:9030');
      expect(
        config(server: 'ws://localhost:9030/rpc').httpBase.toString(),
        'http://localhost:9030',
      );
    });

    test('returns null for non-ws schemes or blank creds', () {
      expect(
        MediaProxyConfig.fromConnection(
          serverUri: Uri.parse('https://cc.example.com/rpc'),
          deviceId: deviceId,
          psk: psk,
        ),
        isNull,
      );
      expect(
        MediaProxyConfig.fromConnection(
          serverUri: Uri.parse('wss://cc.example.com/rpc'),
          deviceId: '',
          psk: psk,
        ),
        isNull,
      );
    });
  });

  group('MediaProxyConfig.resolve', () {
    test('passes through empty, data:, blob:, and relative URLs', () {
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

      expect(proxied.scheme, 'https');
      expect(proxied.host, 'cc.example.com');
      expect(proxied.port, 9030);
      expect(proxied.path, '/proxy/media');
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

      expect(proxied.host, 'cc.example.com');
      expect(proxied.path, '/proxy/media');
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

      expect(sized.queryParameters['w'], '340');
      // The signature covers the raw URL only, so it is identical whether or not
      // a downscale is requested — w is a post-process hint, not part of `u`.
      expect(sized.queryParameters['u'], plain.queryParameters['u']);
      expect(sized.queryParameters['s'], plain.queryParameters['s']);
    });
  });

  group('MediaProxyScope.urlOf', () {
    testWidgets(
      'returns the raw URL when no scope is present (not connected)',
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
        expect(resolved, 'https://x/y.png');
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
      expect(resolved, startsWith('https://cc.example.com:9030/proxy/media?'));
    });
  });
}
