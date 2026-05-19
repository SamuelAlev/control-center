import 'package:cc_infra/src/sandboxing/sse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractSseEvents', () {
    test('parses a single complete event', () {
      final result = extractSseEvents(
        'event: message_start\n'
        'data: {"type":"message_start"}\n\n',
      );
      expect(result.complete, hasLength(1));
      expect(result.complete.first.event, 'message_start');
      expect(result.remainder, isEmpty);
      final parsed = result.complete.first.parsed;
      expect(parsed, isA<Map<String, dynamic>>());
      expect((parsed! as Map)['type'], 'message_start');
    });

    test('carries the trailing partial block as remainder', () {
      final result = extractSseEvents(
        'data: {"type":"a"}\n\n'
        'data: {"type":"b"}',
      );
      expect(result.complete, hasLength(1));
      expect((result.complete.first.parsed! as Map)['type'], 'a');
      expect(result.remainder, 'data: {"type":"b"}');
    });

    test('reassembles an event across two chunks', () {
      final first = extractSseEvents('data: {"ty');
      expect(first.complete, isEmpty);
      expect(first.remainder, 'data: {"ty');

      final second = extractSseEvents('${first.remainder}pe":"ping"}\n\n');
      expect(second.complete, hasLength(1));
      expect((second.complete.first.parsed! as Map)['type'], 'ping');
    });

    test('handles multiple events in one buffer', () {
      final result = extractSseEvents(
        'data: {"type":"a"}\n\n'
        'data: {"type":"b"}\n\n'
        'data: {"type":"c"}\n\n',
      );
      expect(result.complete, hasLength(3));
      expect(
        result.complete.map((e) => (e.parsed! as Map)['type']),
        ['a', 'b', 'c'],
      );
    });

    test('leaves parsed null for non-JSON data', () {
      final result = extractSseEvents('data: not json\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.first.data, 'not json');
      expect(result.complete.first.parsed, isNull);
    });

    test('joins multiple data lines in one block', () {
      final result = extractSseEvents('data: line1\ndata: line2\n\n');
      expect(result.complete, hasLength(1));
      expect(result.complete.first.data, 'line1\nline2');
    });
  });
}
