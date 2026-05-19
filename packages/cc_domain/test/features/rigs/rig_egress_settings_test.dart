import 'package:cc_domain/features/rigs/domain/value_objects/rig_egress_settings.dart';
import 'package:test/test.dart';

void main() {
  group('isValidRigEgressHost', () {
    test('admits exact hosts and subdomain wildcards', () {
      for (final host in [
        'example.com',
        'api.example.com',
        '*.example.com',
        'a.b.c.example.co.uk',
        'host-with-dashes.dev',
        'x.io',
      ]) {
        expect(isValidRigEgressHost(host), isTrue, reason: host);
      }
    });

    test('refuses anything that is not a bare host', () {
      for (final entry in [
        '',
        'https://example.com', // a scheme is a URL, not a host
        'example.com:8080', // no ports
        'example.com/path', // no paths
        'example .com', // no whitespace
        'EXAMPLE.COM', // stored lowercase; uppercase never reaches the gate
        '-example.com', // labels do not start with a dash
        'example..com', // no empty labels
        'exam ple.com',
        'example.com\nother.com', // one entry, never two
      ]) {
        expect(isValidRigEgressHost(entry), isFalse, reason: entry);
      }
    });

    test('bounds the entry length', () {
      // 253 chars is the DNS ceiling; 254 must not pass.
      final longest = '${'a' * 63}.com';
      expect(isValidRigEgressHost(longest), isTrue);
      final tooLong = List.filled(64, 'a').join();
      expect(isValidRigEgressHost('$tooLong.com'), isFalse);
      expect(isValidRigEgressHost('${'a' * 250}.com'), isFalse);
    });
  });

  group('parseRigEgressHostsSetting', () {
    test('blank, absent or corrupt collapses to the empty list', () {
      expect(parseRigEgressHostsSetting(null), isEmpty);
      expect(parseRigEgressHostsSetting(''), isEmpty);
      expect(parseRigEgressHostsSetting('   '), isEmpty);
      expect(parseRigEgressHostsSetting('not json'), isEmpty);
      expect(parseRigEgressHostsSetting('{"host":"x.com"}'), isEmpty);
      expect(parseRigEgressHostsSetting('"just a string"'), isEmpty);
    });

    test('drops invalid entries rather than failing the whole list', () {
      // The read side is the enforcement half of the contract: a hand-edited
      // or stale value must never reach the egress gate, and one bad entry
      // must not strip the good ones.
      expect(
        parseRigEgressHostsSetting(
          '["internal.example.com","https://evil.test",42,"*.corp.test"]',
        ),
        ['internal.example.com', '*.corp.test'],
      );
    });

    test('normalizes case and whitespace, dedupes', () {
      expect(
        parseRigEgressHostsSetting(
          '[" Example.COM ", "example.com", "*.Example.com"]',
        ),
        ['example.com', '*.example.com'],
      );
    });

    test('caps the list', () {
      final hosts = [
        for (var i = 0; i < kRigEgressHostsMax + 20; i++) 'host$i.example.com',
      ];
      final encoded = encodeRigEgressHostsSetting(hosts);
      expect(
        parseRigEgressHostsSetting(encoded).length,
        kRigEgressHostsMax,
      );
    });
  });

  group('encodeRigEgressHostsSetting', () {
    test('round-trips through parse', () {
      final hosts = ['api.example.com', '*.corp.test'];
      expect(
        parseRigEgressHostsSetting(encodeRigEgressHostsSetting(hosts)),
        hosts,
      );
    });

    test('normalizes, dedupes and skips blank lines', () {
      expect(
        parseRigEgressHostsSetting(
          encodeRigEgressHostsSetting([' API.Example.com ', '', 'api.example.com']),
        ),
        ['api.example.com'],
      );
    });

    test('names the invalid entry instead of dropping it silently', () {
      // The WRITE path is where a typo must be loud: the UI surfaces this
      // message verbatim.
      expect(
        () => encodeRigEgressHostsSetting(['ok.example.com', 'not a host']),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.invalidValue,
            'invalidValue',
            'not a host',
          ),
        ),
      );
    });
  });
}
