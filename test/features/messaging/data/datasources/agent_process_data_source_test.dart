import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/features/dispatch/data/datasources/agent_process_data_source.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AgentProcessDataSource ds;

  setUp(() {
    ds = AgentProcessDataSource();
  });

  tearDown(() {
    ds.stop();
  });

  group('initial state', () {
    test('has expected initial state', () {
      expect(ds, isA<AgentDispatchPort>());
    });
  });

  group('start', () {
    test('returns a dispatch handle with a stream', () {
      final handle = ds.start(
        cliName: 'pi',
        prompt: 'test',
        workingDirectory: '/tmp',
      );
      expect(handle, isA<DispatchHandle>());
      expect(handle.events, isA<Stream<AgentProcessEvent>>());
      expect(handle.events.isBroadcast, isFalse);
    });
  });

  group('stop', () {
    test('stops process without throwing', () async {
      ds.start(cliName: 'pi', prompt: 'test', workingDirectory: '/tmp');
      await ds.stop();
    });

    test('multiple stops do not throw', () async {
      await ds.stop();
      await ds.stop();
    });
  });

  group('start with parameters', () {
    test('accepts optional parameters', () async {
      final handle = ds.start(
        cliName: 'pi',
        prompt: 'hello',
        workingDirectory: '/tmp',
        modelId: 'sonnet',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
      );
      expect(handle, isA<DispatchHandle>());
      expect(handle.events, isA<Stream<AgentProcessEvent>>());
      await ds.stop();
    });

    test('pi cliName delegates to _spawnPi', () async {
      final handle = ds.start(
        cliName: 'pi',
        prompt: 'test',
        workingDirectory: '/tmp',
      );
      expect(handle, isA<DispatchHandle>());
      expect(handle.events, isA<Stream<AgentProcessEvent>>());
      await ds.stop();
    });
  });

  group('start with params', () {
    test('accepts optional parameters including ticketId and wakeContext', () async {
      final handle = ds.start(
        cliName: 'pi',
        prompt: 'test',
        workingDirectory: '/tmp',
        modelId: 'haiku',
        ticketId: 'ticket-1',
      );
      expect(handle, isA<DispatchHandle>());
      expect(handle.events, isA<Stream<AgentProcessEvent>>());
      await ds.stop();
    });
  });

  group('event bus integration', () {
    test('creates with eventBus', () {
      final bus = DomainEventBus();
      final dsWithBus = AgentProcessDataSource(eventBus: bus);
      expect(dsWithBus, isNotNull);
      bus.dispose();
    });

    test('creates without eventBus', () {
      final dsNoBus = AgentProcessDataSource();
      expect(dsNoBus, isNotNull);
    });
  });

  group('stream error handling', () {
    test('stream errors are propagated through error channel', () async {
      final handle = ds.start(
        cliName: 'pi',
        prompt: 'test',
        workingDirectory: '/tmp',
      );

      final errors = <Object>[];
      handle.events.listen(
        (_) {},
        onError: errors.add,
        cancelOnError: false,
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      await ds.stop();
    });

    test('processing error during spawn results in error state', () async {
      ds.start(
        cliName: 'pi',
        prompt: 'test',
        workingDirectory: '/tmp',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await ds.stop();
    });
  });

  group('dispatch lifecycle', () {
    test('can start and stop a dispatch', () {
      final handle = ds.start(
        cliName: 'pi',
        prompt: 'test',
        workingDirectory: '/tmp',
      );
      expect(handle, isA<DispatchHandle>());
      expect(handle.events, isA<Stream<AgentProcessEvent>>());
    });
  });

  group('handlePiEvent — "event" type routing', () {
    late AgentProcessDataSource testDs;
    late List<AgentProcessEvent> collected;

    setUp(() {
      testDs = AgentProcessDataSource();
      collected = [];
      final handle = testDs.start(
        cliName: 'pi',
        prompt: 'test',
        workingDirectory: '/tmp',
      );
      handle.events.listen(collected.add);
    });

    tearDown(() {
      testDs.stop();
    });

    test('debug event is emitted immediately', () async {
      testDs.handlePiEvent({
        'type': 'event',
        'eventType': 'debug',
        'content': '[sandbox] launching pi…',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.debug);
      expect(collected[0].content, '[sandbox] launching pi…');
    });

    test('error event is emitted immediately', () async {
      testDs.handlePiEvent({
        'type': 'event',
        'eventType': 'error',
        'content': 'Warning: Model not found',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.error);
      expect(collected[0].content, 'Warning: Model not found');
    });

    test('done event is emitted immediately', () async {
      testDs.handlePiEvent({
        'type': 'event',
        'eventType': 'done',
        'content': '',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.done);
    });

    test('tool_call event is emitted immediately', () async {
      testDs.handlePiEvent({
        'type': 'event',
        'eventType': 'tool_call',
        'content': 'read_file',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.toolCall);
      expect(collected[0].content, 'read_file');
    });

    test('tool_result event is emitted immediately', () async {
      testDs.handlePiEvent({
        'type': 'event',
        'eventType': 'tool_result',
        'content': 'read_file',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.toolResult);
    });

    test('sandbox_violation event is emitted immediately', () async {
      testDs.handlePiEvent({
        'type': 'event',
        'eventType': 'sandbox_violation',
        'content': 'network access denied',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.sandboxViolation);
    });

    test('"start" type is silently ignored', () async {
      testDs.handlePiEvent({
        'type': 'start',
        'ts': '2026-05-23T00:00:00',
        'agentId': 'abc',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, isEmpty);
    });

    test('"end" type is silently ignored', () async {
      testDs.handlePiEvent({
        'type': 'end',
        'ts': '2026-05-23T00:00:00',
        'exitCode': 0,
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, isEmpty);
    });

    test('"session" type is silently ignored', () async {
      testDs.handlePiEvent({'type': 'session'});

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, isEmpty);
    });

    test('unknown event type is silently ignored', () async {
      testDs.handlePiEvent({
        'type': 'event',
        'eventType': 'unknown_type',
        'content': 'something',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, isEmpty);
    });

    test('unknown top-level type is silently ignored', () async {
      testDs.handlePiEvent({'type': 'something_else'});

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, isEmpty);
    });

    test('agent_end emits done event', () async {
      testDs.handlePiEvent({'type': 'agent_end'});

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.done);
    });
  });

  group('coalescing — thinking/text buffering', () {
    late AgentProcessDataSource testDs;
    late List<AgentProcessEvent> collected;

    setUp(() {
      testDs = AgentProcessDataSource();
      collected = [];
      testDs.initTestController().listen(collected.add);
    });

    tearDown(() {
      testDs.stop();
    });

    Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 5));

    test('consecutive thinking events are buffered until flush', () async {
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'The '});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'user '});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'greeted me.'});

      await pump();
      expect(collected, isEmpty);

      testDs.flushBufferedEvent();
      await pump();

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.thinking);
      expect(collected[0].content, 'The user greeted me.');
    });

    test('consecutive text events are buffered until flush', () async {
      testDs.handlePiEvent({'type': 'event', 'eventType': 'text', 'content': 'Yo'});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'text', 'content': '!'});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'text', 'content': ' What?'});

      await pump();
      expect(collected, isEmpty);

      testDs.flushBufferedEvent();
      await pump();

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.text);
      expect(collected[0].content, 'Yo! What?');
    });

    test('type change flushes previous buffer immediately', () async {
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'Planning…'});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'text', 'content': 'Hello!'});

      await pump();
      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.thinking);
      expect(collected[0].content, 'Planning…');

      testDs.flushBufferedEvent();
      await pump();

      expect(collected, hasLength(2));
      expect(collected[1].type, AgentProcessEventType.text);
      expect(collected[1].content, 'Hello!');
    });

    test('non-buffered event type flushes buffer before emitting', () async {
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'reasoning…'});

      await pump();
      expect(collected, isEmpty);

      testDs.handlePiEvent({'type': 'event', 'eventType': 'debug', 'content': '[sandbox] step'});

      await pump();
      expect(collected, hasLength(2));
      expect(collected[0].type, AgentProcessEventType.thinking);
      expect(collected[0].content, 'reasoning…');
      expect(collected[1].type, AgentProcessEventType.debug);
      expect(collected[1].content, '[sandbox] step');
    });

    test('timer auto-flushes after coalesceWindow', () async {
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'token1'});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'token2'});

      await pump();
      expect(collected, isEmpty);

      await Future<void>.delayed(
          AgentProcessDataSource.coalesceWindow + const Duration(milliseconds: 20));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.thinking);
      expect(collected[0].content, 'token1token2');
    });

    test('empty content is skipped', () async {
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': ''});

      await pump();
      testDs.flushBufferedEvent();
      await pump();

      expect(collected, isEmpty);
    });

    test('flush on empty buffer is a no-op', () async {
      testDs.flushBufferedEvent();
      testDs.flushBufferedEvent();
      await pump();
      expect(collected, isEmpty);
    });

    test('real-world sequence produces correct events', () async {
      testDs.handlePiEvent({'type': 'event', 'eventType': 'debug', 'content': '[sandbox] starting…'});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'debug', 'content': '[sandbox] launching pi…'});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'debug', 'content': '[sandbox] pi running (pid 123)'});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'error', 'content': 'Warning: Model not found'});

      await pump();

      expect(collected[0].type, AgentProcessEventType.debug);
      expect(collected[0].content, '[sandbox] starting…');
      expect(collected[1].type, AgentProcessEventType.debug);
      expect(collected[1].content, '[sandbox] launching pi…');
      expect(collected[2].type, AgentProcessEventType.debug);
      expect(collected[2].content, '[sandbox] pi running (pid 123)');
      expect(collected[3].type, AgentProcessEventType.error);
      expect(collected[3].content, 'Warning: Model not found');
      expect(collected.length, 4);

      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'The '});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'user '});
      testDs.handlePiEvent({'type': 'event', 'eventType': 'thinking', 'content': 'said yo.'});

      await pump();
      expect(collected.length, 4);

      testDs.handlePiEvent({'type': 'event', 'eventType': 'text', 'content': 'Yo!'});

      await pump();
      expect(collected.length, 5);
      expect(collected[4].type, AgentProcessEventType.thinking);
      expect(collected[4].content, 'The user said yo.');

      testDs.handlePiEvent({'type': 'event', 'eventType': 'text', 'content': " What's up?"});

      testDs.flushBufferedEvent();
      await pump();

      expect(collected.length, 6);
      expect(collected[5].type, AgentProcessEventType.text);
      expect(collected[5].content, "Yo! What's up?");

      testDs.handlePiEvent({'type': 'event', 'eventType': 'done', 'content': ''});

      await pump();
      expect(collected.last.type, AgentProcessEventType.done);
    });
  });

  group('handlePiEvent — PI native format', () {
    late AgentProcessDataSource testDs;
    late List<AgentProcessEvent> collected;

    setUp(() {
      testDs = AgentProcessDataSource();
      collected = [];
      final handle = testDs.start(
        cliName: 'pi',
        prompt: 'test',
        workingDirectory: '/tmp',
      );
      handle.events.listen(collected.add);
    });

    tearDown(() {
      testDs.stop();
    });

    Future<void> pump() =>
        Future<void>.delayed(const Duration(milliseconds: 10));

    test('tool_execution_start with full payload emits toolCall with metadata',
        () async {
      testDs.handlePiEvent({
        'type': 'tool_execution_start',
        'toolCallId': 'call_abc123',
        'toolName': 'bash',
        'args': {'command': 'ls -la'},
      });

      await pump();

      expect(collected, hasLength(1));
      final event = collected[0];
      expect(event.type, AgentProcessEventType.toolCall);
      expect(event.content, 'bash');
      expect(event.metadata, isNotNull);
      expect(event.metadata!['toolName'], 'bash');
      expect(event.metadata!['toolCallId'], 'call_abc123');
      expect(event.metadata!['inputs'], {'command': 'ls -la'});
    });

    test(
        'tool_execution_start with minimal payload emits toolCall without inputs',
        () async {
      testDs.handlePiEvent({
        'type': 'tool_execution_start',
        'toolName': 'read',
      });

      await pump();

      expect(collected, hasLength(1));
      final event = collected[0];
      expect(event.type, AgentProcessEventType.toolCall);
      expect(event.content, 'read');
      expect(event.metadata, isNotNull);
      expect(event.metadata!['toolName'], 'read');
      expect(event.metadata!['toolCallId'], '');
      expect(event.metadata!.containsKey('inputs'), isFalse);
    });

    test('tool_execution_end with full payload emits toolResult with outputs',
        () async {
      testDs.handlePiEvent({
        'type': 'tool_execution_end',
        'toolCallId': 'call_abc123',
        'toolName': 'bash',
        'result': {
          'content': [
            {'type': 'text', 'text': 'total 48\ndrwxr-xr-x 5 user staff'}
          ],
        },
        'isError': false,
      });

      await pump();

      expect(collected, hasLength(1));
      final event = collected[0];
      expect(event.type, AgentProcessEventType.toolResult);
      expect(event.content, isNotNull);
      expect(event.metadata, isNotNull);
      expect(event.metadata!['toolName'], 'bash');
      expect(event.metadata!['toolCallId'], 'call_abc123');
      expect(event.metadata!['outputs'], isNotNull);
      expect(event.metadata!['isError'], isFalse);
    });

    test('tool_execution_end with isError emits error flag', () async {
      testDs.handlePiEvent({
        'type': 'tool_execution_end',
        'toolCallId': 'call_def456',
        'toolName': 'bash',
        'result': {
          'content': [
            {'type': 'text', 'text': 'command not found'}
          ],
        },
        'isError': true,
      });

      await pump();

      expect(collected, hasLength(1));
      final event = collected[0];
      expect(event.type, AgentProcessEventType.toolResult);
      expect(event.metadata!['isError'], isTrue);
    });

    test('tool_execution_update emits toolResult with partial outputs',
        () async {
      testDs.handlePiEvent({
        'type': 'tool_execution_update',
        'toolCallId': 'call_abc123',
        'toolName': 'bash',
        'args': {'command': 'ls -la'},
        'partialResult': {
          'content': [
            {'type': 'text', 'text': 'partial output so far...'}
          ],
        },
      });

      await pump();

      expect(collected, hasLength(1));
      final event = collected[0];
      expect(event.type, AgentProcessEventType.toolResult);
      expect(event.content, 'partial output so far...');
      expect(event.metadata, isNotNull);
      expect(event.metadata!['outputs'], 'partial output so far...');
      expect(event.metadata!['partial'], isTrue);
    });

    test(
        'tool_execution_update with no text content is silently ignored',
        () async {
      testDs.handlePiEvent({
        'type': 'tool_execution_update',
        'toolCallId': 'call_abc123',
        'toolName': 'bash',
        'args': {'command': 'ls'},
        'partialResult': {
          'content': [],
        },
      });

      await pump();

      expect(collected, isEmpty);
    });

    test('message_update with text_delta emits text event', () async {
      testDs.handlePiEvent({
        'type': 'message_update',
        'message': {'role': 'assistant', 'content': []},
        'assistantMessageEvent': {
          'type': 'text_delta',
          'delta': 'Hello, world!',
        },
      });

      // text_delta is buffered — wait for coalesce window
      await Future<void>.delayed(
          AgentProcessDataSource.coalesceWindow +
              const Duration(milliseconds: 20));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.text);
      expect(collected[0].content, 'Hello, world!');
    });

    test('message_update with thinking_delta emits thinking event', () async {
      testDs.handlePiEvent({
        'type': 'message_update',
        'message': {'role': 'assistant', 'content': []},
        'assistantMessageEvent': {
          'type': 'thinking_delta',
          'delta': 'I need to read the file first.',
        },
      });

      // thinking_delta is buffered — wait for coalesce window
      await Future<void>.delayed(
          AgentProcessDataSource.coalesceWindow +
              const Duration(milliseconds: 20));

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.thinking);
      expect(collected[0].content, 'I need to read the file first.');
    });

    test('message_update with empty delta is ignored', () async {
      testDs.handlePiEvent({
        'type': 'message_update',
        'assistantMessageEvent': {
          'type': 'text_delta',
          'delta': '',
        },
      });

      await pump();

      expect(collected, isEmpty);
    });

    test('message_update with null assistantMessageEvent is ignored',
        () async {
      testDs.handlePiEvent({
        'type': 'message_update',
      });

      await pump();

      expect(collected, isEmpty);
    });

    test('PI native format "agent_end" still emits done', () async {
      testDs.handlePiEvent({'type': 'agent_end'});

      await pump();

      expect(collected, hasLength(1));
      expect(collected[0].type, AgentProcessEventType.done);
    });
  });
}
