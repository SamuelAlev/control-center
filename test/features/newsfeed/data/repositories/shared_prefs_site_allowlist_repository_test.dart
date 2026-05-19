import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/newsfeed/data/repositories/shared_prefs_site_allowlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SharedPrefsSiteAllowlistRepository repo;

  setUp(() async {
    final prefs = AppPreferences.inMemory(<String, Object>{});
    repo = SharedPrefsSiteAllowlistRepository(prefs);
  });

  group('normalizeDomain', () {
    test('lowercases and trims', () {
      expect(repo.normalizeDomain('  EXAMPLE.com  '), 'example.com');
    });

    test('strips scheme + path + query + fragment', () {
      expect(
        repo.normalizeDomain('https://example.com/some/path?q=1#frag'),
        'example.com',
      );
    });

    test('strips port', () {
      expect(repo.normalizeDomain('example.com:8080'), 'example.com');
    });

    test('strips leading www.', () {
      expect(repo.normalizeDomain('www.example.com'), 'example.com');
    });

    test('preserves deeper subdomains', () {
      expect(repo.normalizeDomain('sub.example.com'), 'sub.example.com');
    });

    test('returns empty for input without a dot', () {
      expect(repo.normalizeDomain('localhost'), '');
    });

    test('returns empty for input with invalid characters', () {
      expect(repo.normalizeDomain('not a domain'), '');
      expect(repo.normalizeDomain('Bad!@#.com'), '');
    });

    test('returns empty for empty input', () {
      expect(repo.normalizeDomain(''), '');
      expect(repo.normalizeDomain('   '), '');
    });
  });

  group('isAllowedUrl', () {
    test('returns false for empty allowlist', () {
      expect(repo.isAllowedUrl('https://example.com', const <String>{}), false);
    });

    test('matches exact host', () {
      expect(
        repo.isAllowedUrl('https://example.com/x', {'example.com'}),
        true,
      );
    });

    test('matches subdomain via suffix', () {
      expect(
        repo.isAllowedUrl('https://www.example.com', {'example.com'}),
        true,
      );
      expect(
        repo.isAllowedUrl('https://news.sub.example.com', {'example.com'}),
        true,
      );
    });

    test('does not match unrelated host with shared suffix', () {
      expect(
        repo.isAllowedUrl('https://notexample.com', {'example.com'}),
        false,
      );
      expect(
        repo.isAllowedUrl('https://otherexample.com', {'example.com'}),
        false,
      );
    });

    test('returns false for unparseable url', () {
      expect(repo.isAllowedUrl('::::', {'example.com'}), false);
    });
  });

  group('add / remove / read / watch', () {
    test('add persists across instances', () async {
      await repo.add('example.com');
      final freshPrefs = AppPreferences.inMemory();
      final fresh = SharedPrefsSiteAllowlistRepository(freshPrefs);
      expect(await fresh.read(), {'example.com'});
    });

    test('add deduplicates after normalisation', () async {
      await repo.add('https://www.example.com/');
      await repo.add('EXAMPLE.com');
      expect(await repo.read(), {'example.com'});
    });

    test('remove drops the entry', () async {
      await repo.add('example.com');
      await repo.add('foo.org');
      await repo.remove('example.com');
      expect(await repo.read(), {'foo.org'});
    });

    test('remove is a no-op for missing entries', () async {
      await repo.add('example.com');
      await repo.remove('absent.com');
      expect(await repo.read(), {'example.com'});
    });

    test('watch emits initial state and updates', () async {
      await repo.add('a.com');
      final emissions = <Set<String>>[];
      final sub = repo.watch().listen(emissions.add);
      // Initial.
      await Future<void>.delayed(Duration.zero);
      expect(emissions.first, {'a.com'});
      // Mutation.
      await repo.add('b.com');
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, {'a.com', 'b.com'});
      await sub.cancel();
    });
  });
}
