import 'package:control_center/core/domain/value_objects/thinking_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThinkingEventKind', () {
    test('has all 5 values', () {
      expect(ThinkingEventKind.values, hasLength(5));
      expect(ThinkingEventKind.values, containsAllInOrder([
        ThinkingEventKind.reasoning,
        ThinkingEventKind.toolCall,
        ThinkingEventKind.toolResult,
        ThinkingEventKind.error,
        ThinkingEventKind.sandboxViolation,
      ]));
    });
  });

  group('ThinkingEvent', () {
    final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    test('default content is empty string', () {
      final event = ThinkingEvent(
        kind: ThinkingEventKind.reasoning,
        timestamp: ts,
      );
      expect(event.content, '');
    });

    test('construction with all fields', () {
      final event = ThinkingEvent(
        kind: ThinkingEventKind.toolCall,
        timestamp: ts,
        content: 'calling tool',
        duration: const Duration(milliseconds: 500),
        toolName: 'read_file',
        inputs: {'path': '/foo/bar.dart'},
        outputs: null,
      );
      expect(event.kind, ThinkingEventKind.toolCall);
      expect(event.timestamp, ts);
      expect(event.content, 'calling tool');
      expect(event.duration, const Duration(milliseconds: 500));
      expect(event.toolName, 'read_file');
      expect(event.inputs, {'path': '/foo/bar.dart'});
      expect(event.outputs, isNull);
    });

    group('fromJson/toJson round-trip', () {
      test('reasoning event round-trips', () {
        final event = ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          timestamp: ts,
          content: 'Let me think...',
          duration: const Duration(milliseconds: 100),
        );
        final json = event.toJson();
        final roundTripped = ThinkingEvent.fromJson(json);
        expect(roundTripped, event);
      });

      test('toolCall with toolName and inputs round-trips', () {
        final event = ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          timestamp: ts,
          content: 'calling tool',
          toolName: 'read_file',
          inputs: {'path': '/foo.dart', 'offset': 10},
        );
        final roundTripped = ThinkingEvent.fromJson(event.toJson());
        expect(roundTripped, event);
      });

      test('toolResult with outputs round-trips', () {
        final event = ThinkingEvent(
          kind: ThinkingEventKind.toolResult,
          timestamp: ts,
          content: '',
          outputs: 'file contents here',
        );
        final roundTripped = ThinkingEvent.fromJson(event.toJson());
        expect(roundTripped, event);
        expect(roundTripped.outputs, 'file contents here');
      });

      test('error event round-trips', () {
        final event = ThinkingEvent(
          kind: ThinkingEventKind.error,
          timestamp: ts,
          content: 'Something went wrong',
        );
        final roundTripped = ThinkingEvent.fromJson(event.toJson());
        expect(roundTripped, event);
      });

      test('sandboxViolation event round-trips', () {
        final event = ThinkingEvent(
          kind: ThinkingEventKind.sandboxViolation,
          timestamp: ts,
          content: 'Blocked network access',
        );
        final roundTripped = ThinkingEvent.fromJson(event.toJson());
        expect(roundTripped, event);
      });

      test('fromJson defaults kind to reasoning for unknown kind string', () {
        final json = {'kind': 'unknown_type', 'timestamp': ts.millisecondsSinceEpoch};
        final event = ThinkingEvent.fromJson(json);
        expect(event.kind, ThinkingEventKind.reasoning);
      });

      test('fromJson defaults timestamp to epoch when null', () {
        final json = <String, dynamic>{'kind': 'reasoning'};
        final event = ThinkingEvent.fromJson(json);
        expect(event.timestamp, DateTime.fromMillisecondsSinceEpoch(0));
      });

      test('toJson omits empty content', () {
        final event = ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          timestamp: ts,
          content: '',
        );
        final json = event.toJson();
        expect(json.containsKey('content'), isFalse);
      });

      test('toJson omits null optional fields', () {
        final event = ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          timestamp: ts,
          content: 'hello',
        );
        final json = event.toJson();
        expect(json.containsKey('durationMs'), isFalse);
        expect(json.containsKey('toolName'), isFalse);
        expect(json.containsKey('inputs'), isFalse);
        expect(json.containsKey('outputs'), isFalse);
      });
    });

    group('copyWith', () {
      test('overrides specified fields', () {
        final original = ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          timestamp: ts,
          content: 'original',
          duration: const Duration(milliseconds: 200),
        );
        final copy = original.copyWith(
          content: 'updated',
          kind: ThinkingEventKind.error,
        );
        expect(copy.kind, ThinkingEventKind.error);
        expect(copy.content, 'updated');
        expect(copy.timestamp, ts);
        expect(copy.duration, const Duration(milliseconds: 200));
      });

      test('with clearDuration=true clears duration', () {
        final original = ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          timestamp: ts,
          content: 'thinking',
          duration: const Duration(milliseconds: 300),
        );
        final copy = original.copyWith(clearDuration: true);
        expect(copy.duration, isNull);
        // other fields preserved
        expect(copy.kind, ThinkingEventKind.reasoning);
        expect(copy.content, 'thinking');
      });
    });

    group('== and hashCode', () {
      test('equal events match', () {
        final a = ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          timestamp: ts,
          content: 'call',
          toolName: 'bash',
          inputs: {'cmd': 'ls'},
        );
        final b = ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          timestamp: ts,
          content: 'call',
          toolName: 'bash',
          inputs: {'cmd': 'ls'},
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different fields do not match', () {
        final a = ThinkingEvent(
          kind: ThinkingEventKind.reasoning,
          timestamp: ts,
          content: 'a',
        );
        final b = ThinkingEvent(
          kind: ThinkingEventKind.error,
          timestamp: ts,
          content: 'b',
        );
        expect(a, isNot(equals(b)));
      });

      test('inputs map equality works', () {
        final a = ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          timestamp: ts,
          inputs: {'a': 1, 'b': [2, 3]},
        );
        final b = ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          timestamp: ts,
          inputs: {'a': 1, 'b': [2, 3]},
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));

        final c = ThinkingEvent(
          kind: ThinkingEventKind.toolCall,
          timestamp: ts,
          inputs: {'a': 1, 'b': [3, 2]},
        );
        expect(a, isNot(equals(c)));
      });
    });
  });

  group('ThinkingEventRow', () {
    final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    test('construction with primary only', () {
      final event = ThinkingEvent(kind: ThinkingEventKind.reasoning, timestamp: ts);
      final row = ThinkingEventRow(primary: event);
      expect(row.primary, event);
      expect(row.result, isNull);
    });

    test('construction with primary and result', () {
      final call = ThinkingEvent(kind: ThinkingEventKind.toolCall, timestamp: ts);
      final result = ThinkingEvent(kind: ThinkingEventKind.toolResult, timestamp: ts);
      final row = ThinkingEventRow(primary: call, result: result);
      expect(row.primary, call);
      expect(row.result, result);
    });
  });

  group('groupThinkingEvents', () {
    final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    test('empty list returns empty', () {
      expect(groupThinkingEvents([]), isEmpty);
    });

    test('single reasoning event creates one row', () {
      final event = ThinkingEvent(kind: ThinkingEventKind.reasoning, timestamp: ts);
      final rows = groupThinkingEvents([event]);
      expect(rows, hasLength(1));
      expect(rows.first.primary, event);
      expect(rows.first.result, isNull);
    });

    test('toolCall followed by toolResult creates one row with result', () {
      final call = ThinkingEvent(
        kind: ThinkingEventKind.toolCall,
        timestamp: ts,
        toolName: 'read',
      );
      final result = ThinkingEvent(
        kind: ThinkingEventKind.toolResult,
        timestamp: ts,
        outputs: 'data',
      );
      final rows = groupThinkingEvents([call, result]);
      expect(rows, hasLength(1));
      expect(rows.first.primary, call);
      expect(rows.first.result, result);
    });

    test('toolCall without following toolResult creates row with null result', () {
      final call = ThinkingEvent(kind: ThinkingEventKind.toolCall, timestamp: ts);
      final rows = groupThinkingEvents([call]);
      expect(rows, hasLength(1));
      expect(rows.first.primary, call);
      expect(rows.first.result, isNull);
    });

    test('orphan toolResult creates its own row', () {
      final orphan = ThinkingEvent(kind: ThinkingEventKind.toolResult, timestamp: ts);
      final rows = groupThinkingEvents([orphan]);
      expect(rows, hasLength(1));
      expect(rows.first.primary, orphan);
      expect(rows.first.result, isNull);
    });

    test('multiple events group correctly', () {
      final reasoning = ThinkingEvent(kind: ThinkingEventKind.reasoning, timestamp: ts, content: 'thinking');
      final call = ThinkingEvent(kind: ThinkingEventKind.toolCall, timestamp: ts, toolName: 'bash');
      final result = ThinkingEvent(kind: ThinkingEventKind.toolResult, timestamp: ts, outputs: 'ok');
      final error = ThinkingEvent(kind: ThinkingEventKind.error, timestamp: ts, content: 'oops');
      final call2 = ThinkingEvent(kind: ThinkingEventKind.toolCall, timestamp: ts, toolName: 'grep');
      final orphanResult = ThinkingEvent(kind: ThinkingEventKind.toolResult, timestamp: ts, outputs: 'stray');

      final rows = groupThinkingEvents([reasoning, call, result, error, call2, orphanResult]);

      expect(rows, hasLength(4));
      // Row 0: reasoning
      expect(rows[0].primary.kind, ThinkingEventKind.reasoning);
      expect(rows[0].result, isNull);
      // Row 1: toolCall + toolResult
      expect(rows[1].primary.kind, ThinkingEventKind.toolCall);
      expect(rows[1].primary.toolName, 'bash');
      expect(rows[1].result?.kind, ThinkingEventKind.toolResult);
      // Row 2: error
      expect(rows[2].primary.kind, ThinkingEventKind.error);
      expect(rows[2].result, isNull);
      // Row 3: call2 + orphanResult
      expect(rows[3].primary.kind, ThinkingEventKind.toolCall);
      expect(rows[3].primary.toolName, 'grep');
      expect(rows[3].result?.kind, ThinkingEventKind.toolResult);
    });
  });
}
