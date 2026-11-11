import 'package:cc_server_core/src/forge/forge_client_cache.dart';
import 'package:test/test.dart';

final class _Client {
  _Client(this.name);

  final String name;
}

void main() {
  late List<String> disposed;
  late ForgeClientCache<String, _Client> cache;

  setUp(() {
    disposed = [];
    cache = ForgeClientCache(
      dispose: (client) => disposed.add(client.name),
      maxEntries: 2,
      grace: const Duration(milliseconds: 20),
    );
  });

  Future<void> afterGrace() =>
      Future<void>.delayed(const Duration(milliseconds: 40));

  test('a client is built once and reused', () {
    var built = 0;
    _Client build() => _Client('a${built++}');
    expect(identical(cache.get('a', build), cache.get('a', build)), isTrue);
    expect(built, 1);
  });

  test('past the bound the least recently used client is retired, after '
      'the grace', () async {
    cache
      ..get('a', () => _Client('a'))
      ..get('b', () => _Client('b'))
      // `a` was used last, so `b` goes.
      ..get('a', () => _Client('a again'))
      ..get('c', () => _Client('c'));
    expect(cache.length, 2);
    expect(disposed, isEmpty, reason: 'still in its grace');
    await afterGrace();
    expect(disposed, ['b']);
  });

  test(
    'forgotten clients are retired; close disposes the rest at once',
    () async {
      cache
        ..get('ws1:alice', () => _Client('alice'))
        ..get('ws1:bob', () => _Client('bob'))
        ..retireWhere((key) => key.endsWith('alice'));
      expect(cache.length, 1);
      var rebuilt = false;
      cache.get('ws1:alice', () {
        rebuilt = true;
        return _Client('alice 2');
      });
      expect(rebuilt, isTrue);
      cache.close();
      expect(disposed, unorderedEquals(['bob', 'alice 2']));
      await afterGrace();
      expect(disposed, unorderedEquals(['bob', 'alice 2', 'alice']));
    },
  );
}
