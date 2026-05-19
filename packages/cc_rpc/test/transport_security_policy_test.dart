import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  group('TransportSecurityPolicy', () {
    test('wss and https are always allowed', () {
      expect(
        TransportSecurityPolicy.allows(Uri.parse('wss://a.example/rpc')),
        isTrue,
      );
      expect(
        TransportSecurityPolicy.allows(Uri.parse('https://a.example')),
        isTrue,
      );
    });

    test('plaintext to loopback is allowed', () {
      for (final host in ['localhost', '127.0.0.1', '[::1]', '127.1.2.3']) {
        expect(
          TransportSecurityPolicy.allows(Uri.parse('ws://$host:9030/rpc')),
          isTrue,
          reason: host,
        );
        expect(
          TransportSecurityPolicy.allows(Uri.parse('http://$host:9030')),
          isTrue,
          reason: host,
        );
      }
    });

    test(
      'plaintext off-loopback is refused — the TLS-or-loopback invariant',
      () {
        expect(
          TransportSecurityPolicy.allows(
            Uri.parse('ws://192.168.1.20:9030/rpc'),
          ),
          isFalse,
        );
        expect(
          TransportSecurityPolicy.allows(Uri.parse('http://server.lan:9030')),
          isFalse,
        );
        expect(
          () => TransportSecurityPolicy.enforce(
            Uri.parse('ws://192.168.1.20:9030/rpc'),
          ),
          throwsA(isA<InsecureTransportException>()),
        );
      },
    );

    test('--insecure is the only override and must be explicit', () {
      expect(
        TransportSecurityPolicy.allows(
          Uri.parse('ws://192.168.1.20:9030/rpc'),
          insecureAllowed: true,
        ),
        isTrue,
      );
      expect(
        () => TransportSecurityPolicy.enforce(
          Uri.parse('http://server.lan:9030'),
          insecureAllowed: true,
        ),
        returnsNormally,
      );
    });

    test('unknown schemes are refused even with the override', () {
      expect(
        TransportSecurityPolicy.allows(
          Uri.parse('ftp://server.lan'),
          insecureAllowed: true,
        ),
        isFalse,
      );
    });

    test('isLoopbackHost recognizes ::1 and is case-insensitive', () {
      expect(TransportSecurityPolicy.isLoopbackHost('::1'), isTrue);
      expect(TransportSecurityPolicy.isLoopbackHost('LOCALHOST'), isTrue);
      expect(TransportSecurityPolicy.isLoopbackHost('::2'), isFalse);
      expect(TransportSecurityPolicy.isLoopbackHost('example.com'), isFalse);
    });

    test('isTailnetHost matches the 100.64.0.0/10 CGNAT range', () {
      expect(TransportSecurityPolicy.isTailnetHost('100.64.0.1'), isTrue);
      expect(TransportSecurityPolicy.isTailnetHost('100.127.255.255'), isTrue);
      // Just outside the range on both sides and a look-alike prefix.
      expect(TransportSecurityPolicy.isTailnetHost('100.63.255.255'), isFalse);
      expect(TransportSecurityPolicy.isTailnetHost('100.128.0.1'), isFalse);
      expect(TransportSecurityPolicy.isTailnetHost('100.5.5.5'), isFalse);
    });

    test('isTailnetHost matches MagicDNS names, not impostors', () {
      expect(
        TransportSecurityPolicy.isTailnetHost('devbox.tail1234.ts.net'),
        isTrue,
      );
      // Case-insensitive.
      expect(
        TransportSecurityPolicy.isTailnetHost('Devbox.Tail1234.TS.NET'),
        isTrue,
      );
      // A suffix look-alike is not a MagicDNS name.
      expect(
        TransportSecurityPolicy.isTailnetHost('myserver.ts.net.evil.com'),
        isFalse,
      );
      // Not an IPv4 literal at all.
      expect(TransportSecurityPolicy.isTailnetHost('100.64.0.1.5'), isFalse);
    });

    test(
      'InsecureTransportException carries the refused uri in its message',
      () {
        final uri = Uri.parse('ws://192.168.1.20:9030/rpc');
        final exc = InsecureTransportException(uri);
        expect(exc.uri, uri);
        expect(exc.toString(), contains('ws://192.168.1.20:9030/rpc'));
        expect(exc.toString(), contains('--insecure'));
      },
    );
  });
}
