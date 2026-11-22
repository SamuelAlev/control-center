// A runner frame is weighed before the host decodes it: the scan counts what
// the text holds, string-aware, and JsonShape.weight bounds the heap the
// decoded value takes. Both are checked here against the decoder itself.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:test/test.dart';

import 'json_heap_probe.dart' show jsonHeapProbeShapes;

/// The counts of a decoded value, the way the scan counts its text.
(int, int, int, int) _count(Object? value) {
  var objects = 0;
  var arrays = 0;
  var members = 0;
  var scalars = 0;
  final stack = <Object?>[value];
  while (stack.isNotEmpty) {
    final v = stack.removeLast();
    if (v is Map) {
      objects++;
      members += v.length;
      stack.addAll(v.values);
    } else if (v is List) {
      arrays++;
      stack.addAll(v);
    } else {
      scalars++;
    }
  }
  return (objects, arrays, members, scalars);
}

int _depth(Object? value) => switch (value) {
  final Map<dynamic, dynamic> m =>
    1 + m.values.map(_depth).fold(0, (a, b) => a > b ? a : b),
  final List<dynamic> l => 1 + l.map(_depth).fold(0, (a, b) => a > b ? a : b),
  _ => 0,
};

(int, int, int, int) _counts(JsonShape s) =>
    (s.objects, s.arrays, s.members, s.scalars);

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  group('the scan', () {
    final samples = [
      r'{"a":[1,2.5e-3,-7,true,false,null,"x{[\"]},:"],"b":{"c":{},"d":[]},"é{":"é }","e":"x\\","f":[[[]],{"g":{"h":[0]}}]}',
      ' { "type" : "call" ,\n "id":1 ,\t"args" : { "k" : [ 1 , "}" ] } } ',
      '[1,{"a":2},[3,"]"]]',
      '"just a string with { and ["',
      '{}',
      '{"a":{}}',
      r'{"q":"\"","b":"\\\"{"}',
    ];
    for (final text in samples) {
      test('counts what the decoder builds: $text', () {
        final decoded = jsonDecode(text);
        final scan = scanJsonFrame(
          _bytes(text),
          keep: {
            'missing',
            if (decoded is Map<String, dynamic>) ...decoded.keys,
          },
        );
        expect(_counts(scan.shape), _count(decoded));
        expect(scan.depth, _depth(decoded));
        expect(scan.shape.bytes, utf8.encode(text).length);
        if (decoded is Map<String, dynamic>) {
          for (final MapEntry(:key, :value) in decoded.entries) {
            final member = scan.shapeOf(key)!;
            expect(_counts(member), _count(value), reason: key);
            expect(scan.valueOf(key), value, reason: key);
            // The member's text is its value's text, without spaces around.
            expect(
              member.bytes,
              lessThanOrEqualTo(utf8.encode(text).length),
              reason: key,
            );
          }
          expect(scan.shapeOf('missing'), isNull);
        }
      });
    }

    test('a repeated key counts every copy, though the decoder keeps the '
        'last: the count is never below what is built', () {
      const text = '{"dup":[1,2,3],"dup":{"x":[1,2]}}';
      final scan = scanJsonFrame(_bytes(text), keep: const {'dup'});
      expect(_counts(scan.shape), (2, 2, 3, 5));
      expect(_count(jsonDecode(text)), (2, 1, 2, 2));
      expect(scan.valueOf('dup'), {
        'x': [1, 2],
      });
    });

    test('a member replaced by an empty object decodes without it', () {
      const text = '{"type":"call","id":3,"args":{"pad":[{},{},{}]},"z":1}';
      final scan = scanJsonFrame(_bytes(text), keep: const {'args'});
      expect(scan.shapeOf('args')!.objects, 4);
      expect(utf8JsonDecoder.convert(scan.withEmptyObjectFor('args')), {
        'type': 'call',
        'id': 3,
        'args': <String, dynamic>{},
        'z': 1,
      });
      expect(scan.withEmptyObjectFor('none'), same(scan.bytes));
    });

    test('a 4 MiB string full of braces, brackets, commas and escaped '
        'quotes is one value', () {
      const chunk = '{}[],:"\\';
      final value = chunk * (4 * 1024 * 1024 ~/ chunk.length);
      final text = jsonEncode({
        'type': 'call',
        'args': {'s': value},
      });
      expect(text.length, greaterThan(4 * 1024 * 1024));
      final scan = scanJsonFrame(_bytes(text), keep: const {'type', 'args'});
      expect(_counts(scan.shapeOf('args')!), (1, 0, 1, 1));
      expect(scan.shape.items, 7);
      expect(scan.valueOf('type'), 'call');
      // Its weight is its text's, not its braces'.
      expect(scan.shape.weight, lessThan(text.length * 3));
    });

    test('only the members named are kept; a key written with an escape is '
        'read as the decoder reads it', () {
      const text = r'{"t\u0079pe":"call","other":1,"args":{"a":[1]}}';
      final scan = scanJsonFrame(_bytes(text), keep: const {'type'});
      expect(scan.valueOf('type'), 'call');
      expect(scan.shapeOf('args'), isNull);
      expect(scan.shapeOf('other'), isNull);
      expect(scanJsonFrame(_bytes(text)).shapeOf('type'), isNull);
    });

    test('a frame of 708,306 top-level keys keeps none of them: what the '
        'scan holds does not grow with the text (review 4, finding 7)', () {
      // The reviewer's frame: 8 MiB of distinct keys, weight about 117 MiB.
      final out = BytesBuilder(copy: false)..addByte(0x7b);
      for (var i = 0; i < 708306; i++) {
        if (i > 0) {
          out.addByte(0x2c);
        }
        out.add(utf8.encode('"${i.toRadixString(36).padLeft(6, '0')}":0'));
      }
      out.addByte(0x7d);
      final bytes = out.takeBytes();
      expect(bytes.length, lessThanOrEqualTo(8 * 1024 * 1024));
      final base = ProcessInfo.currentRss;
      final scan = scanJsonFrame(bytes, keep: const {'type', 'args', 'value'});
      final growth = ProcessInfo.currentRss - base;
      // ignore: avoid_print
      print('SCANMAP growth ${growth ~/ (1024 * 1024)} MiB');
      expect(scan.shape.members, 708306);
      expect(scan.shape.weight, greaterThan(100 * 1024 * 1024));
      expect(scan.shapeOf('000000'), isNull);
      // Held, the scan takes no more than a few MiB; it took about 100 MiB
      // when it kept every member.
      expect(growth, lessThan(16 * 1024 * 1024));
    });
  });

  group('a tool\'s text result', () {
    test('is decoded for the script when it is a JSON object or array of '
        'bounded size and structure', () {
      expect(scriptValueOfText(' {"a":[1,"}"]} '), {
        'a': [1, '}'],
      });
      expect(scriptValueOfText('[{}]'), [<String, dynamic>{}]);
      final big = jsonEncode({'s': 'x' * (3 * 1024 * 1024)});
      expect(scriptValueOfText(big), isA<Map<String, dynamic>>());
    });

    test('stays text when it is not JSON, holds more values than a script '
        'receives decoded, or is over twice the result cap', () {
      expect(scriptValueOfText('plain'), 'plain');
      expect(scriptValueOfText('{not json'), '{not json');
      expect(scriptValueOfText('"a string"'), '"a string"');
      final many = jsonEncode(
        List.generate(
          CodeModeLimits.maxNestedResultItems,
          (_) => <String, dynamic>{},
        ),
      );
      // The array itself is one more value than the cap.
      expect(scriptValueOfText(many), many);
      final under = jsonEncode(
        List.generate(
          CodeModeLimits.maxNestedResultItems - 1,
          (_) => <String, dynamic>{},
        ),
      );
      expect(scriptValueOfText(under), isA<List<dynamic>>());
      final long = '[${' ' * (2 * CodeModeLimits.maxNestedResultBytes)}]';
      expect(scriptValueOfText(long), long);
    });
  });

  group('the weight bounds the decoded heap', () {
    // Each shape is measured in a fresh process (json_heap_probe.dart): in
    // this one, memory freed by earlier tests would hide what a decode
    // takes.
    for (final shape in jsonHeapProbeShapes) {
      test(shape, () async {
        // Resident memory is what the probe reads, and on a loaded machine
        // the system may page the probe out or in while it measures: the
        // growth then reads below zero or above the decode, or low. So a
        // reading counts only when a second one agrees with it (within 15%;
        // alone, four runs of one shape agreed within 12%) and both are
        // within the weight. A weight that undercounts the heap fails
        // every reading, and a low misread would have to repeat itself to
        // pass.
        final valid = <int>[];
        var weight = 0;
        int? agreed;
        for (var attempt = 0; attempt < 4 && agreed == null; attempt++) {
          final probe = await Process.run(Platform.resolvedExecutable, [
            'test/code_mode/json_heap_probe.dart',
            shape,
          ]);
          expect(probe.exitCode, 0, reason: '${probe.stderr}');
          final [bytes, heap, w] = (probe.stdout as String)
              .trim()
              .split(' ')
              .map(int.parse)
              .toList();
          weight = w;
          // ignore: avoid_print
          print(
            'WEIGHT $shape: $bytes bytes, heap $heap, weight $weight '
            '(${(heap / weight * 100).toStringAsFixed(0)}%)',
          );
          if (heap <= 0 || heap > weight) {
            continue;
          }
          for (final earlier in valid) {
            final low = earlier < heap ? earlier : heap;
            final high = earlier < heap ? heap : earlier;
            if (high - low <= high * 0.15) {
              agreed = high;
            }
          }
          valid.add(heap);
        }
        expect(
          agreed,
          isNotNull,
          reason: 'no two readings within the weight $weight agreed: $valid',
        );
        expect(agreed, greaterThan(0));
        expect(agreed, lessThanOrEqualTo(weight));
      });
    }
  });
}
