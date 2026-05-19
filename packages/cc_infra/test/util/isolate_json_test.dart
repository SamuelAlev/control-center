import 'dart:convert';

import 'package:cc_infra/src/util/isolate_json.dart';
import 'package:test/test.dart';

void main() {
  group('decodeJsonMapInIsolate', () {
    test('decodes a small object inline', () async {
      final m = await decodeJsonMapInIsolate('{"a":1,"b":"x"}');
      expect(m, {'a': 1, 'b': 'x'});
    });

    test('returns null for a non-object payload', () async {
      final m = await decodeJsonMapInIsolate('[1,2,3]');
      expect(m, isNull);
    });

    test('throws on invalid JSON', () async {
      expect(
        () => decodeJsonMapInIsolate('not json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('decodes a large object on a background isolate', () async {
      // Build a payload above the isolate threshold.
      final big = {'data': List.filled(10000, 'x' * 10)};
      final source = jsonEncode(big);
      expect(source.length, greaterThanOrEqualTo(kJsonIsolateThresholdBytes));
      final m = await decodeJsonMapInIsolate(source);
      expect(m, isNotNull);
      expect(m!['data'], isA<List>());
    });
  });

  group('decodeJsonListInIsolate', () {
    test('decodes a small array of objects inline', () async {
      final l = await decodeJsonListInIsolate('[{"a":1},{"b":2}]');
      expect(l, [
        {'a': 1},
        {'b': 2},
      ]);
    });

    test('drops non-object entries', () async {
      final l = await decodeJsonListInIsolate('[{"a":1},42,"x",{"b":2}]');
      expect(l, [
        {'a': 1},
        {'b': 2},
      ]);
    });

    test('non-array payload yields an empty list', () async {
      final l = await decodeJsonListInIsolate('{"a":1}');
      expect(l, isEmpty);
    });

    test('invalid JSON throws', () async {
      expect(() => decodeJsonListInIsolate('not json'), throwsA(isA<Object>()));
    });

    test('decodes a large array on a background isolate', () async {
      final big = List.filled(6000, {'k': 'v'});
      final source = jsonEncode(big);
      expect(source.length, greaterThanOrEqualTo(kJsonIsolateThresholdBytes));
      final l = await decodeJsonListInIsolate(source);
      expect(l, hasLength(6000));
    });
  });

  group('encodeJsonInIsolate', () {
    test('encodes inline by default', () async {
      final s = await encodeJsonInIsolate({'a': 1});
      expect(s, '{"a":1}');
    });

    test('encodes on a background isolate when large: true', () async {
      final value = {
        'data': List.filled(1000, {'k': 'vvvv'}),
      };
      final s = await encodeJsonInIsolate(value, large: true);
      // Round-trips to the same value.
      expect(jsonDecode(s), jsonDecode(jsonEncode(value)));
    });

    test('handles null', () async {
      final s = await encodeJsonInIsolate(null);
      expect(s, 'null');
    });

    test('handles primitives', () async {
      expect(await encodeJsonInIsolate(42), '42');
      expect(await encodeJsonInIsolate('hi'), '"hi"');
      expect(await encodeJsonInIsolate(true), 'true');
    });
  });
}
