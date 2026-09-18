import 'package:cc_data/src/repositories/key_value_site_allowlist_repository.dart';
import 'package:cc_domain/core/domain/ports/key_value_store.dart';
import 'package:test/test.dart';

class _MemStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  String? getString(String key) => _data[key];

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  int? getInt(String key) {
    final raw = _data[key];
    return raw == null ? null : int.tryParse(raw);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = '$value';
    return true;
  }
}

void main() {
  late KeyValueSiteAllowlistRepository repo;

  setUp(() {
    repo = KeyValueSiteAllowlistRepository(_MemStore());
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
      expect(repo.isAllowedUrl('https://example.com/x', {'example.com'}), true);
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
      final store = _MemStore();
      final writer = KeyValueSiteAllowlistRepository(store);
      await writer.add('example.com');
      final fresh = KeyValueSiteAllowlistRepository(store);
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
      await Future<void>.delayed(Duration.zero);
      expect(emissions.first, {'a.com'});
      await repo.add('b.com');
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, {'a.com', 'b.com'});
      await sub.cancel();
    });
  });
}
