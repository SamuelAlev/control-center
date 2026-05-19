import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// SSRF block-list coverage for the media proxy target validator
/// ([isBlockedProxyTarget]). The proxy fetches remote URLs on behalf of a
/// paired (authenticated-but-untrusted) client, so it must refuse loopback,
/// link-local, cloud-metadata and RFC-1918 / IPv6 unique-local ranges — and
/// it re-runs this check on every redirect hop (see `_serveMediaProxy`).
void main() {
  group('isBlockedProxyTarget — must BLOCK', () {
    const blocked = <String>[
      // Loopback.
      'http://127.0.0.1/x',
      'http://127.5.6.7/x',
      'https://[::1]/x',
      // Named localhost variants.
      'http://localhost/x',
      'http://LOCALHOST/x',
      'http://app.localhost/x',
      // Cloud metadata endpoints.
      'http://169.254.169.254/latest/meta-data/',
      'http://metadata.google.internal/computeMetadata/v1/',
      // Link-local.
      'http://169.254.10.20/x',
      // RFC-1918 private ranges.
      'http://10.0.0.1/x',
      'http://10.255.255.255/x',
      'http://172.16.0.1/x',
      'http://172.31.255.1/x',
      'http://192.168.1.1/x',
      // 0.0.0.0/8 and unspecified.
      'http://0.0.0.0/x',
      // IPv6 unique-local (fc00::/7).
      'http://[fc00::1]/x',
      'http://[fd12:3456::1]/x',
      // IPv4-mapped IPv6 smuggling a private literal.
      'http://[::ffff:10.0.0.1]/x',
      'http://[::ffff:169.254.169.254]/x',
      'http://[::ffff:192.168.0.1]/x',
      // Empty host.
      'http:///x',
    ];
    for (final url in blocked) {
      test('blocks $url', () {
        expect(
          isBlockedProxyTarget(Uri.parse(url)),
          isTrue,
          reason: '$url must be refused by the SSRF guard',
        );
      });
    }
  });

  group('isBlockedProxyTarget — must ALLOW', () {
    const allowed = <String>[
      // Ordinary public hosts (resolved at connect time; PSK is the boundary).
      'https://example.com/image.png',
      'https://cdn.jsdelivr.net/favicon.ico',
      'https://8.8.8.8/x', // public IP literal
      'https://[2606:4700:4700::1111]/x', // public IPv6 (Cloudflare)
      // 172.x outside the private 16–31 second-octet window.
      'https://172.15.0.1/x',
      'https://172.32.0.1/x',
      // 192.x that is not 192.168.
      'https://192.167.0.1/x',
      'https://192.169.0.1/x',
    ];
    for (final url in allowed) {
      test('allows $url', () {
        expect(
          isBlockedProxyTarget(Uri.parse(url)),
          isFalse,
          reason: '$url is a public target and must be permitted',
        );
      });
    }
  });

  group('resolvesToBlockedAddress — DNS rebinding', () {
    test('an IP literal is not re-resolved (already judged)', () async {
      expect(
        await resolvesToBlockedAddress(Uri.parse('https://8.8.8.8/x')),
        isFalse,
      );
      expect(
        await resolvesToBlockedAddress(Uri.parse('https://10.0.0.5/x')),
        isFalse,
        reason: 'literals are the SYNC check\'s job, not this one\'s',
      );
    });

    test('a hostname resolving to loopback is blocked', () async {
      // `localhost` is the one name guaranteed to resolve internally on every
      // machine — the stand-in for `evil.example.com A 127.0.0.1`, which is
      // exactly what the literal-IP blocks alone could not see.
      expect(
        await resolvesToBlockedAddress(Uri.parse('https://localhost/x')),
        isTrue,
      );
    });

    test('an unresolvable host is blocked, not fetched', () async {
      expect(
        await resolvesToBlockedAddress(
          Uri.parse('https://this-host-does-not-exist.invalid/x'),
        ),
        isTrue,
      );
    });
  });
}
