import 'dart:async';

import 'package:control_center/features/dispatch/data/datasources/agent_process_data_source.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentProcessDataSource', () {
    late AgentProcessDataSource dataSource;

    setUp(() {
      dataSource = AgentProcessDataSource();
    });

    group('handlePiEvent', () {
      late StreamController<AgentProcessEvent> controller;
      late List<AgentProcessEvent> events;

      setUp(() {
        controller = StreamController<AgentProcessEvent>.broadcast();
        events = [];
        controller.stream.listen(events.add);
      addTearDown(() => controller.close());
        // Inject a test controller via the @visibleForTesting method.
        // We reuse the broadcast controller so we can listen.
        dataSource.initTestController();
        // Override the internal controller with our own.
        // Since initTestController creates a broadcast controller,
        // we need to use the one it created.
      });

      test('handles "event" type with thinking eventType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'thinking',
          'content': 'I am thinking...',
        });

        // Thinking is buffered — flush manually
        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<ThinkingEvent>());
        expect((events.first as ThinkingEvent).content, 'I am thinking...');
      });

      test('handles "event" type with text eventType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'Hello world',
        });

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<TextEvent>());
        expect((events.first as TextEvent).content, 'Hello world');
      });

      test('handles "event" type with error eventType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'error',
          'content': 'Something failed',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<ErrorEvent>());
        expect((events.first as ErrorEvent).content, 'Something failed');
      });

      test('handles "event" type with done eventType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'done',
          'content': '',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<DoneEvent>());
      });

      test('handles "event" type with tool_call eventType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'tool_call',
          'content': 'read_file',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<ToolCallEvent>());
        expect((events.first as ToolCallEvent).toolName, 'read_file');
      });

      test('handles "event" type with tool_result eventType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'tool_result',
          'content': 'file contents here',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<ToolResultEvent>());
        expect((events.first as ToolResultEvent).outputs, 'file contents here');
      });

      test('handles "event" type with sandbox_violation eventType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'sandbox_violation',
          'content': 'Access denied',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<SandboxViolationEvent>());
        expect((events.first as SandboxViolationEvent).content, 'Access denied');
      });

      test('handles "message_update" with text_delta', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'message_update',
          'assistantMessageEvent': {
            'type': 'text_delta',
            'delta': 'Hello ',
          },
        });

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<TextEvent>());
        expect((events.first as TextEvent).content, 'Hello ');
      });

      test('handles "message_update" with thinking_delta', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'message_update',
          'assistantMessageEvent': {
            'type': 'thinking_delta',
            'delta': 'reasoning...',
          },
        });

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<ThinkingEvent>());
        expect((events.first as ThinkingEvent).content, 'reasoning...');
      });

      test('handles "message_update" with empty delta — no event', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'message_update',
          'assistantMessageEvent': {
            'type': 'text_delta',
            'delta': '',
          },
        });

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('handles "message_update" with null assistantMessageEvent — no event', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'message_update',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('handles "tool_execution_start"', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_start',
          'toolName': 'write_file',
          'toolCallId': 'call-123',
          'args': {'path': '/tmp/test.txt'},
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<ToolCallEvent>());
        final event = events.first as ToolCallEvent;
        expect(event.toolName, 'write_file');
        expect(event.toolCallId, 'call-123');
        expect(event.inputs, isNotNull);
      });

      test('handles "tool_execution_end"', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_end',
          'toolCallId': 'call-456',
          'toolName': 'read_file',
          'result': {'content': 'file data'},
          'isError': false,
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<ToolResultEvent>());
        final event = events.first as ToolResultEvent;
        expect(event.toolCallId, 'call-456');
        expect(event.toolName, 'read_file');
        expect(event.isError, isFalse);
      });

      test('handles "tool_execution_end" with error', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_end',
          'toolCallId': 'call-789',
          'toolName': 'bash',
          'isError': true,
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        final event = events.first as ToolResultEvent;
        expect(event.isError, isTrue);
      });

      test('handles "agent_end" as DoneEvent', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'agent_end',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<DoneEvent>());
      });

      test('ignores "start" type', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'start',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('ignores "end" type', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'end',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('ignores "session" type', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'session',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('handles unknown event type gracefully', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'unknown_event_type',
          'content': 'test',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Unknown event types are silently ignored
        expect(events, isEmpty);
      });

      test('handles missing type key — no event', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({'content': 'test'});

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('handles "event" with missing eventType — no event', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'content': 'some content',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('handles "message_update" with unknown subtype — no event', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'message_update',
          'assistantMessageEvent': {
            'type': 'tool_use',
            'delta': 'some args',
          },
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('handles "message_update" with empty assistantMessageEvent map — no event',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'message_update',
          'assistantMessageEvent': <String, dynamic>{},
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('handles "tool_execution_end" with null result — empty outputs',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_end',
          'toolCallId': 'call-null-result',
          'toolName': 'read_file',
          'result': null,
          'isError': false,
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        final event = events.first as ToolResultEvent;
        expect(event.outputs, '');
      });

      test('handles "tool_execution_update" with non-map partialResult — no event',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_update',
          'toolCallId': 'call-5',
          'partialResult': 'not a map',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('handles "tool_execution_update" with non-list content — no event',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_update',
          'toolCallId': 'call-6',
          'partialResult': {
            'content': 'not a list',
          },
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('flushes buffered text before emitting non-buffered error event',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        // Buffer a text event
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'pending text',
        });

        // Emit a non-buffered event — _emitEvent flushes buffer first
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'error',
          'content': 'error message',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(2));
        expect(events[0], isA<TextEvent>());
        expect((events[0] as TextEvent).content, 'pending text');
        expect(events[1], isA<ErrorEvent>());
        expect((events[1] as ErrorEvent).content, 'error message');
      });

      test('handlePiEvent does not crash when no controller set',
          timeout: const Timeout.factor(2), () {
        // Don't call initTestController — _controller stays null
        final fresh = AgentProcessDataSource();
        expect(
          () => fresh.handlePiEvent({'type': 'agent_end'}),
          returnsNormally,
        );
      });
    });

    group('event coalescing', () {
      test('coalesces consecutive text events', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        // Send two text events in quick succession
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'Hello ',
        });
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'World',
        });

        // Flush the coalesced buffer
        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Should be coalesced into a single event
        expect(events, hasLength(1));
        expect((events.first as TextEvent).content, 'Hello World');
      });

      test('flushes buffered event when type changes', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'text content',
        });

        // Changing type to thinking flushes the text buffer
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'thinking',
          'content': 'thinking content',
        });

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(2));
        expect((events[0] as TextEvent).content, 'text content');
        expect((events[1] as ThinkingEvent).content, 'thinking content');
      });

      test('coalesceWindow is 50ms', timeout: const Timeout.factor(2), () {
        expect(AgentProcessDataSource.coalesceWindow, const Duration(milliseconds: 50));
      });

      test('empty content is not buffered', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': '',
        });

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('coalesces three or more events of same type', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'thinking',
          'content': 'A',
        });
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'thinking',
          'content': 'B',
        });
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'thinking',
          'content': 'C',
        });

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect((events.first as ThinkingEvent).content, 'ABC');
      });

      test('flushBufferedEvent when nothing buffered — no events',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('empty content does not set bufferedType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        // Empty content — buffer type should remain null
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': '',
        });

        // Then valid content — should buffer normally
        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'valid',
        });

        dataSource.flushBufferedEvent();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Only the valid content should produce an event
        expect(events, hasLength(1));
        expect((events.first as TextEvent).content, 'valid');
      });
    });

    group('tool_execution_update', () {
      test('handles partial result with text content', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_update',
          'toolCallId': 'call-update-1',
          'toolName': 'bash',
          'partialResult': {
            'content': [
              {'type': 'text', 'text': 'partial output'},
            ],
          },
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        final event = events.first as ToolResultEvent;
        expect(event.outputs, 'partial output');
        expect(event.toolCallId, 'call-update-1');
        expect(event.isPartial, isTrue);
      });

      test('ignores partial result with no text blocks', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_update',
          'toolCallId': 'call-update-2',
          'partialResult': {
            'content': [
              {'type': 'image', 'url': 'http://example.com/img.png'},
            ],
          },
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('ignores partial result with empty text', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_update',
          'toolCallId': 'call-update-3',
          'partialResult': {
            'content': [
              {'type': 'text', 'text': ''},
            ],
          },
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('ignores tool_execution_update with no partialResult',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'tool_execution_update',
          'toolCallId': 'call-update-4',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });
    });

    group('debug event', () {
      test('handles "event" type with debug eventType', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'debug',
          'content': 'launching pi',
        });

        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, hasLength(1));
        expect(events.first, isA<DebugEvent>());
        expect((events.first as DebugEvent).content, 'launching pi');
      });
    });

    group('initTestController', () {
      test('returns a broadcast stream', timeout: const Timeout.factor(2), () {
        final stream = dataSource.initTestController();
        expect(stream, isA<Stream<AgentProcessEvent>>());
        expect(stream.isBroadcast, isTrue);
      });

      test('multiple calls replace the controller', timeout: const Timeout.factor(2), () {
        final stream1 = dataSource.initTestController();
        final stream2 = dataSource.initTestController();
        // Streams are distinct
        expect(identical(stream1, stream2), isFalse);
      });
    });

    group('smoke test', () {
      test('can be instantiated without arguments', timeout: const Timeout.factor(2), () {
        expect(AgentProcessDataSource.new, returnsNormally);
      });

      test('can be instantiated with an event bus', timeout: const Timeout.factor(2), () {
        expect(() => AgentProcessDataSource(eventBus: null), returnsNormally);
      });
    });

    group('controller lifecycle', () {
      test('stop() closes controller — new events not emitted',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        await dataSource.stop();

        dataSource.handlePiEvent({
          'type': 'agent_end',
        });
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('stop() flushes buffered events before closing',
          timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        dataSource.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'pending',
        });
        // Buffer has content, not yet flushed

        await dataSource.stop();

        // Stop should flush the buffer first
        expect(events, hasLength(1));
        expect((events.first as TextEvent).content, 'pending');
      });

      test('stopDispatch() closes controller', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        await dataSource.stopDispatch('test-dispatch-id');

        dataSource.handlePiEvent({
          'type': 'agent_end',
        });
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('stopAllForAgent() closes controller', timeout: const Timeout.factor(2), () async {
        final stream = dataSource.initTestController();
        final events = <AgentProcessEvent>[];
        stream.listen(events.add);

        await dataSource.stopAllForAgent('agent-42');

        dataSource.handlePiEvent({
          'type': 'agent_end',
        });
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(events, isEmpty);
      });

      test('multiple stop calls do not throw', timeout: const Timeout.factor(2), () async {
        dataSource.initTestController();

        await dataSource.stop();
        // Second stop should be a no-op — already stopped
        await dataSource.stop();
        // Third via stopDispatch
        await dataSource.stopDispatch('any');
      });
    });
  });
}
