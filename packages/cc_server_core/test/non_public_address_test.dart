import 'dart:io';

import 'package:cc_harness/tools.dart' show HarnessToolContext;
import 'package:cc_harness_runtime/cc_harness_runtime.dart'
    show isNonPublicAddress;
import 'package:cc_harness_runtime/src/tools/web_fetch_tool.dart';
import 'package:cc_server_core/src/media_proxy_guard.dart';
import 'package:test/test.dart';

/// One rule decides which addresses a server-side fetch of a URL somebody
/// else chose may reach: the media and font proxy, agent web fetch and web
/// push all ask [isNonPublicAddress], so they agree on every address.
void main() {
  const nonPublic = [
    // IPv4 special-purpose ranges.
    '0.0.0.0',
    '0.1.2.3',
    '10.0.0.1',
    '100.64.0.1',
    '100.127.255.254',
    '127.0.0.1',
    '169.254.169.254',
    '172.16.0.1',
    '172.31.255.255',
    '192.0.0.1',
    '192.0.2.1',
    '192.88.99.1',
    '192.168.1.1',
    '198.18.0.1',
    '198.19.255.255',
    '198.51.100.2',
    '203.0.113.1',
    '224.0.0.1',
    '240.0.0.1',
    '255.255.255.255',
    // IPv6 special-purpose ranges.
    '::',
    '::1',
    'fc00::1',
    'fd12:3456::1',
    'fe80::1',
    'fec0::1',
    'ff02::1',
    '100::1',
    '2001::1',
    '2001:db8::1',
    '3fff::1',
    '64:ff9b:1::a00:1',
    // IPv6 forms carrying a non-public IPv4 address.
    '::ffff:127.0.0.1',
    '::ffff:10.0.0.1',
    '::ffff:100.64.0.1',
    '::127.0.0.1',
    '::10.0.0.1',
    '64:ff9b::a9fe:a9fe',
    '64:ff9b::7f00:1',
    '2002:a00:1::1',
    '2002:c0a8:101::1',
    '2002:a9fe:a9fe::1',
  ];
  const public = [
    '1.1.1.1',
    '8.8.8.8',
    '93.184.215.14',
    '100.63.255.255',
    '100.128.0.1',
    '172.15.0.1',
    '172.32.0.1',
    '192.0.1.1',
    '198.17.0.1',
    '198.20.0.1',
    '223.255.255.254',
    '2606:4700:4700::1111',
    '2a00:1450:4001::1',
    '2607:f8b0:4000::1',
    '::ffff:8.8.8.8',
    '64:ff9b::808:808',
    '2002:808:808::1',
  ];

  group('isNonPublicAddress', () {
    for (final address in nonPublic) {
      test('refuses $address', () {
        expect(isNonPublicAddress(InternetAddress(address)), isTrue);
      });
    }
    for (final address in public) {
      test('passes $address', () {
        expect(isNonPublicAddress(InternetAddress(address)), isFalse);
      });
    }
  });

  group('every caller agrees on the whole table', () {
    for (final address in [...nonPublic, ...public]) {
      test(address, () async {
        final ip = InternetAddress(address);
        final expected = isNonPublicAddress(ip);

        // The media and font proxy, on the literal.
        expect(
          isBlockedProxyTarget(Uri(scheme: 'https', host: address)),
          expected,
          reason: 'media proxy',
        );

        // Agent web fetch, on a name that resolves to it: it dials only an
        // address it permits.
        final dialed = <InternetAddress>[];
        final result =
            await WebFetchTool(
              resolveHost: (_) async => [ip],
              connect: (address, _) async {
                dialed.add(address);
                throw const SocketException('stopped before network I/O');
              },
            ).execute(const {
              'url': 'https://probe.test/',
            }, const HarnessToolContext(workingDirectory: '/tmp'));
        expect(result.isError, isTrue);
        expect(dialed.isEmpty, expected, reason: 'web fetch');
      });
    }
  });
}
