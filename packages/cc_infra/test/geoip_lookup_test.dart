import 'package:cc_infra/src/geoip/geoip_lookup.dart';
import 'package:test/test.dart';

/// `GeoIpLookup` against the REAL embedded table (regenerated from the five
/// RIR delegation stats by `tool/gen_geoip_country.dart`): well-known public
/// resolvers resolve to their delegated country, and private / loopback /
/// reserved / unparseable input resolves to null — the audit trail stores
/// null for those rather than a guess.
void main() {
  late GeoIpLookup lookup;

  setUp(() => lookup = GeoIpLookup());

  group('public IPv4 resolvers resolve to their delegated country', () {
    test('8.8.8.8 (Google DNS) is US', () {
      expect(lookup.countryCodeFor('8.8.8.8'), 'US');
    });

    test('1.1.1.1 (Cloudflare/APNIC) is AU', () {
      expect(lookup.countryCodeFor('1.1.1.1'), 'AU');
    });

    test('9.9.9.9 (Quad9) is US', () {
      expect(lookup.countryCodeFor('9.9.9.9'), 'US');
    });
  });

  group('non-public input resolves to null', () {
    test('192.168.1.1 (RFC 1918)', () {
      expect(lookup.countryCodeFor('192.168.1.1'), isNull);
    });

    test('10.0.0.1 (RFC 1918)', () {
      expect(lookup.countryCodeFor('10.0.0.1'), isNull);
    });

    test('127.0.0.1 (loopback)', () {
      expect(lookup.countryCodeFor('127.0.0.1'), isNull);
    });

    test('::1 (IPv6 loopback)', () {
      expect(lookup.countryCodeFor('::1'), isNull);
    });

    test('a garbage string is a parse failure, not a crash', () {
      expect(lookup.countryCodeFor('not-an-ip-address'), isNull);
      expect(lookup.countryCodeFor('999.999.999.999'), isNull);
      expect(lookup.countryCodeFor(''), isNull);
    });
  });
}
