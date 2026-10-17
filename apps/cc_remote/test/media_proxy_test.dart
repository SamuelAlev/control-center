import 'dart:convert';

import 'package:cc_remote/media_proxy.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const psk = 'phone-device-key';
  final endpoint = RemoteMediaEndpoint(
    httpBase: Uri.parse('https://app.example/phone/_cc_resource/capability/'),
    deviceId: 'phone-one',
    psk: psk,
  );

  test('logo, blob GET/POST and proxied images preserve virtual prefix', () {
    final urls = [
      endpoint.workspaceLogoUrl('workspace'),
      endpoint.blobUploadUrl(workspaceId: 'workspace'),
      endpoint.blobUrl(
        workspaceId: 'workspace',
        ref: 'blob:sha256:${List.filled(64, 'a').join()}',
      ),
      endpoint.resolve('https://news.example/image.png?token=a%2Fb'),
    ];
    for (final url in urls) {
      final uri = Uri.parse(url);
      expect(uri.path, startsWith('/phone/_cc_resource/capability/'));
      expect(uri.queryParameters['d'], 'phone-one');
      expect(uri.queryParameters['s'], isNotEmpty);
    }
    final proxied = Uri.parse(urls.last);
    final target = utf8.decode(base64Url.decode(proxied.queryParameters['u']!));
    expect(target, 'https://news.example/image.png?token=a%2Fb');
    expect(
      RemoteControlCrypto.verifyProxyTarget(
        target,
        psk,
        proxied.queryParameters['s']!,
      ),
      isTrue,
    );
  });

  test('desktop and phone refs share the signed resource target', () {
    final ref = 'blob:sha256:${'b' * 64}';
    final resource = endpoint.blobResourceUri(
      workspaceId: 'message-workspace',
      ref: ref,
    )!;
    final download = Uri.parse(
      endpoint.blobUrl(
        workspaceId: 'message-workspace',
        ref: ref,
        downloadName: 'screenshot.png',
      ),
    );
    expect(resource.path, '/blob');
    expect(download.queryParameters['download'], '1');
    expect(download.queryParameters['name'], 'screenshot.png');
    expect(resource.queryParameters['w'], 'message-workspace');
    expect(download.queryParameters['s'], resource.queryParameters['s']);
    expect(
      RemoteControlCrypto.verifyProxyTarget(
        'blob:message-workspace:${'b' * 64}',
        psk,
        resource.queryParameters['s']!,
      ),
      isTrue,
    );
    expect(
      endpoint.blobResourceUri(
        workspaceId: 'message-workspace',
        ref: '/Users/sender/screenshot.png',
      ),
      isNull,
    );
  });
}
