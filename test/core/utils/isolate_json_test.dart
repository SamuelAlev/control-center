import 'dart:convert';

import 'package:control_center/core/utils/isolate_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A payload comfortably above the 50 KB threshold so the isolate path is
  // exercised, alongside small payloads that stay on the calling isolate.
  String largeJsonList() {
    final items = List.generate(
      4000,
      (i) => {'filename': 'lib/file_$i.dart', 'patch': '@@ -$i +$i @@\n+x' * 4},
    );
    final encoded = jsonEncode(items);
    expect(encoded.length, greaterThan(kJsonIsolateThresholdBytes));
    return encoded;
  }

  group('decodeJsonMapInIsolate', () {
    test('decodes a small JSON object inline', () async {
      final result = await decodeJsonMapInIsolate('{"a": 1, "b": "two"}');
      expect(result, {'a': 1, 'b': 'two'});
    });

    test('returns null for non-object payloads', () async {
      expect(await decodeJsonMapInIsolate('[1, 2, 3]'), isNull);
      expect(await decodeJsonMapInIsolate('42'), isNull);
    });

    test('decodes a large object on a background isolate', () async {
      final source = jsonEncode({
        'nodes': List.generate(5000, (i) => {'i': i, 'name': 'item_$i'}),
      });
      expect(source.length, greaterThan(kJsonIsolateThresholdBytes));

      final result = await decodeJsonMapInIsolate(source);
      expect(result!['nodes'] as List, hasLength(5000));
    });
  });

  group('decodeJsonListInIsolate', () {
    test('decodes a small JSON array of objects inline', () async {
      final result = await decodeJsonListInIsolate('[{"a": 1}, {"b": 2}]');
      expect(result, [
        {'a': 1},
        {'b': 2},
      ]);
    });

    test('drops non-object entries', () async {
      final result = await decodeJsonListInIsolate('[{"a": 1}, 2, "x", null]');
      expect(result, [
        {'a': 1},
      ]);
    });

    test('returns an empty list for non-array payloads', () async {
      expect(await decodeJsonListInIsolate('{"a": 1}'), isEmpty);
    });

    test('decodes a large array on a background isolate', () async {
      final result = await decodeJsonListInIsolate(largeJsonList());
      expect(result, hasLength(4000));
      expect(result.first['filename'], 'lib/file_0.dart');
    });
  });

  group('encodeJsonInIsolate', () {
    test('encodes inline by default', () async {
      final result = await encodeJsonInIsolate({'a': 1, 'b': true});
      expect(result, '{"a":1,"b":true}');
    });

    test('large:true produces identical output to inline encoding', () async {
      final value = {
        'files': List.generate(3000, (i) => {'name': 'f_$i', 'add': i}),
      };
      final offloaded = await encodeJsonInIsolate(value, large: true);
      expect(offloaded, jsonEncode(value));
    });

    test('round-trips through decode', () async {
      final value = [
        {'x': 1},
        {'y': 'two'},
      ];
      final encoded = await encodeJsonInIsolate(value, large: true);
      expect(await decodeJsonListInIsolate(encoded), value);
    });
  });
}
