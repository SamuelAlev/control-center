import 'dart:convert';

import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

void main() {
  group('parseSse', () {
    test('parses event + data pairs split across byte chunks', () async {
      const raw =
          'event: message_start\n'
          'data: {"a":1}\n'
          '\n'
          'event: ping\n'
          ': keep-alive comment\n'
          'data: {"b":2}\n'
          '\n';
      // Split mid-line to exercise the line buffering.
      final chunks = <List<int>>[
        utf8.encode(raw.substring(0, 10)),
        utf8.encode(raw.substring(10, 30)),
        utf8.encode(raw.substring(30)),
      ];
      final events = await parseSse(Stream.fromIterable(chunks)).toList();
      expect(events.length, 2);
      expect(events[0].event, 'message_start');
      expect(events[0].data, '{"a":1}');
      expect(events[1].event, 'ping');
      expect(events[1].data, '{"b":2}');
    });

    test('joins multi-line data payloads with newlines', () async {
      const raw = 'data: line1\ndata: line2\n\n';
      final events = await parseSse(Stream.value(utf8.encode(raw))).toList();
      expect(events.single.data, 'line1\nline2');
    });

    test('flushes a trailing event with no final blank line', () async {
      const raw = 'data: {"done":true}';
      final events = await parseSse(Stream.value(utf8.encode(raw))).toList();
      expect(events.single.data, '{"done":true}');
    });
  });
}
