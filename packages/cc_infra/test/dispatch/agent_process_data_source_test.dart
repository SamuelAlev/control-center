import 'dart:async';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/dispatch/agent_process_data_source.dart';
import 'package:test/test.dart';

/// Collects every event and error emitted on the controller stream until it
/// closes. Returns a record of `(events, errors)`.
Future<(List<AgentProcessEvent>, List<Object>)> drainWithErrors(
  Stream<AgentProcessEvent> stream,
) async {
  final events = <AgentProcessEvent>[];
  final errors = <Object>[];
  final done = Completer<void>();
  final sub = stream.listen(
    events.add,
    onError: errors.add,
    onDone: done.complete,
  );
  await done.future;
  await sub.cancel();
  return (events, errors);
}

void main() {
  group('coalesceWindow', () {
    test('is a short fixed duration used for event coalescing', () {
      expect(
        AgentProcessDataSource.coalesceWindow,
        const Duration(milliseconds: 50),
      );
    });

    test('auto-flushes the buffer after the coalesce window elapses', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'event',
        'eventType': 'text',
        'content': 'buffered',
      });
      // Do NOT call flushBufferedEvent; wait for the internal Timer to fire.
      await Future<void>.delayed(
        AgentProcessDataSource.coalesceWindow * 2 +
            const Duration(milliseconds: 20),
      );
      await ds.stop();

      final (events, _) = await future;
      expect(events.whereType<TextEvent>().single.content, 'buffered');
    });
  });

  group('handlePiEvent (event envelope)', () {
    test(
      'thinking and text are buffered then flushed on type change',
      () async {
        final ds = AgentProcessDataSource();
        final stream = ds.initTestController();
        final future = drainWithErrors(stream);

        // Two consecutive text deltas coalesce; switching to thinking flushes
        // the text buffer first, then the thinking delta is buffered.
        ds.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'hello ',
        });
        ds.handlePiEvent({
          'type': 'event',
          'eventType': 'text',
          'content': 'world',
        });
        ds.handlePiEvent({
          'type': 'event',
          'eventType': 'thinking',
          'content': 'hmm',
        });
        // Flush the remaining thinking buffer before closing.
        ds.flushBufferedEvent();
        await ds.stop();

        final (events, _) = await future;
        // Expect: one coalesced TextEvent ('hello world'), one ThinkingEvent.
        final texts = events.whereType<TextEvent>().toList();
        final thoughts = events.whereType<ThinkingEvent>().toList();
        expect(texts, hasLength(1));
        expect(texts.single.content, 'hello world');
        expect(thoughts, hasLength(1));
        expect(thoughts.single.content, 'hmm');
      },
    );

    test(
      'buffered events with empty content are dropped, not emitted',
      () async {
        final ds = AgentProcessDataSource();
        final stream = ds.initTestController();
        final future = drainWithErrors(stream);

        ds.handlePiEvent({'type': 'event', 'eventType': 'text', 'content': ''});
        ds.flushBufferedEvent();
        await ds.stop();

        final (events, _) = await future;
        expect(events.whereType<TextEvent>(), isEmpty);
      },
    );

    test('debug event is emitted immediately', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'event',
        'eventType': 'debug',
        'content': 'launching pi',
      });
      await ds.stop();

      final (events, _) = await future;
      final debug = events.whereType<DebugEvent>().toList();
      expect(debug, hasLength(1));
      expect(debug.single.content, 'launching pi');
    });

    test(
      'error event carries code from "code" then falls back to "errorType"',
      () async {
        final ds1 = AgentProcessDataSource();
        final stream1 = ds1.initTestController();
        final future1 = drainWithErrors(stream1);

        ds1.handlePiEvent({
          'type': 'event',
          'eventType': 'error',
          'content': 'rate limited',
          'code': 'rate_limit_error',
        });
        await ds1.stop();
        var (events, _) = await future1;
        var errs = events.whereType<ErrorEvent>().toList();
        expect(errs, hasLength(1));
        expect(errs.single.content, 'rate limited');
        expect(errs.single.code, 'rate_limit_error');
        expect(errs.single.source, 'pi');

        // Fall back to errorType when code is absent.
        final ds2 = AgentProcessDataSource();
        final stream2 = ds2.initTestController();
        final future2 = drainWithErrors(stream2);
        ds2.handlePiEvent({
          'type': 'event',
          'eventType': 'error',
          'content': 'overloaded',
          'errorType': 'overloaded_error',
        });
        await ds2.stop();
        (events, _) = await future2;
        errs = events.whereType<ErrorEvent>().toList();
        expect(errs.single.code, 'overloaded_error');
      },
    );

    test(
      'tool_call and tool_result are emitted as structured events',
      () async {
        final ds = AgentProcessDataSource();
        final stream = ds.initTestController();
        final future = drainWithErrors(stream);

        ds.handlePiEvent({
          'type': 'event',
          'eventType': 'tool_call',
          'content': 'bash',
        });
        ds.handlePiEvent({
          'type': 'event',
          'eventType': 'tool_result',
          'content': 'done',
        });
        await ds.stop();

        final (events, _) = await future;
        final call = events.whereType<ToolCallEvent>().single;
        expect(call.toolName, 'bash');
        expect(call.toolCallId, '');
        final result = events.whereType<ToolResultEvent>().single;
        expect(result.outputs, 'done');
      },
    );

    test('sandbox_violation and done are emitted', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'event',
        'eventType': 'sandbox_violation',
        'content': 'denied network',
      });
      ds.handlePiEvent({'type': 'event', 'eventType': 'done'});
      await ds.stop();

      final (events, _) = await future;
      expect(
        events.whereType<SandboxViolationEvent>().single.content,
        'denied network',
      );
      expect(events.whereType<DoneEvent>(), hasLength(1));
    });

    test('an unknown eventType surfaces a debug marker', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'event',
        'eventType': 'mystery',
        'content': '',
      });
      await ds.stop();

      final (events, _) = await future;
      final debug = events.whereType<DebugEvent>().single;
      expect(debug.content, contains('unknown pi eventType'));
      expect(debug.content, contains('mystery'));
    });
  });

  group('handlePiEvent (message_update)', () {
    test(
      'text_delta buffers text and thinking_delta buffers thinking',
      () async {
        final ds = AgentProcessDataSource();
        final stream = ds.initTestController();
        final future = drainWithErrors(stream);

        ds.handlePiEvent({
          'type': 'message_update',
          'assistantMessageEvent': {'type': 'text_delta', 'delta': 'a '},
        });
        ds.handlePiEvent({
          'type': 'message_update',
          'assistantMessageEvent': {'type': 'text_delta', 'delta': 'b'},
        });
        ds.handlePiEvent({
          'type': 'message_update',
          'assistantMessageEvent': {
            'type': 'thinking_delta',
            'delta': 'ponder',
          },
        });
        ds.flushBufferedEvent();
        await ds.stop();

        final (events, _) = await future;
        expect(events.whereType<TextEvent>().single.content, 'a b');
        expect(events.whereType<ThinkingEvent>().single.content, 'ponder');
      },
    );

    test('returns early when assistantMessageEvent is missing', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({'type': 'message_update'});
      ds.flushBufferedEvent();
      await ds.stop();

      final (events, _) = await future;
      expect(events, isEmpty);
    });

    test('returns early when delta is empty', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'message_update',
        'assistantMessageEvent': {'type': 'text_delta', 'delta': ''},
      });
      ds.flushBufferedEvent();
      await ds.stop();

      final (events, _) = await future;
      expect(events, isEmpty);
    });

    test('unrecognised subType does not emit', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'message_update',
        'assistantMessageEvent': {'type': 'image_delta', 'delta': 'x'},
      });
      ds.flushBufferedEvent();
      await ds.stop();

      final (events, _) = await future;
      expect(events, isEmpty);
    });
  });

  group('handlePiEvent (tool lifecycle)', () {
    test('tool_execution_start carries name, id, and args', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'tool_execution_start',
        'toolName': 'edit',
        'toolCallId': 'tc1',
        'args': {'file': 'a.dart'},
      });
      await ds.stop();

      final (events, _) = await future;
      final call = events.whereType<ToolCallEvent>().single;
      expect(call.toolName, 'edit');
      expect(call.toolCallId, 'tc1');
      expect(call.inputs, {'file': 'a.dart'});
    });

    test('tool_execution_update emits a partial text result', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'tool_execution_update',
        'toolCallId': 'tc1',
        'toolName': 'bash',
        'partialResult': {
          'content': [
            {'type': 'text', 'text': 'streaming '},
            {'type': 'image', 'text': 'ignored'},
            {'type': 'text', 'text': 'output'},
          ],
        },
      });
      await ds.stop();

      final (events, _) = await future;
      final result = events.whereType<ToolResultEvent>().single;
      expect(result.outputs, 'streaming output');
      expect(result.toolName, 'bash');
      expect(result.isPartial, isTrue);
    });

    test('tool_execution_update without text content emits nothing', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({
        'type': 'tool_execution_update',
        'partialResult': {
          'content': [
            {'type': 'image', 'text': 'x'},
          ],
        },
      });
      await ds.stop();

      final (events, _) = await future;
      expect(events.whereType<ToolResultEvent>(), isEmpty);
    });

    test('tool_execution_update without partialResult emits nothing', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({'type': 'tool_execution_update'});
      await ds.stop();

      final (events, _) = await future;
      expect(events, isEmpty);
    });

    test(
      'tool_execution_end emits the final result, flagging errors',
      () async {
        final ds = AgentProcessDataSource();
        final stream = ds.initTestController();
        final future = drainWithErrors(stream);

        ds.handlePiEvent({
          'type': 'tool_execution_end',
          'toolCallId': 'tc1',
          'toolName': 'bash',
          'result': {'exit': 1},
          'isError': true,
        });
        await ds.stop();

        final (events, _) = await future;
        final result = events.whereType<ToolResultEvent>().single;
        expect(result.toolCallId, 'tc1');
        expect(result.toolName, 'bash');
        expect(result.isError, isTrue);
        expect(result.outputs, contains('"exit":1'));
      },
    );

    test('tool_execution_end with no result emits empty outputs', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({'type': 'tool_execution_end', 'toolCallId': 'tc2'});
      await ds.stop();

      final (events, _) = await future;
      expect(events.whereType<ToolResultEvent>().single.outputs, '');
    });
  });

  group('handlePiEvent (top-level envelope)', () {
    test('agent_end emits a DoneEvent', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({'type': 'agent_end'});
      await ds.stop();

      final (events, _) = await future;
      expect(events.whereType<DoneEvent>(), hasLength(1));
    });

    test('start / end / session are ignored without emitting', () async {
      for (final type in const ['start', 'end', 'session']) {
        final ds = AgentProcessDataSource();
        final stream = ds.initTestController();
        final future = drainWithErrors(stream);
        ds.handlePiEvent({'type': type});
        await ds.stop();
        final (events, _) = await future;
        expect(events, isEmpty, reason: type);
      }
    });

    test('an unknown top-level type surfaces a debug marker', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent({'type': 'alien'});
      await ds.stop();

      final (events, _) = await future;
      final debug = events.whereType<DebugEvent>().single;
      expect(debug.content, contains('unknown pi event type'));
      expect(debug.content, contains('alien'));
    });

    test('a missing type field is treated as unknown', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      final future = drainWithErrors(stream);

      ds.handlePiEvent(<String, dynamic>{});
      await ds.stop();

      final (events, _) = await future;
      expect(events.whereType<DebugEvent>(), hasLength(1));
    });
  });

  group('lifecycle', () {
    test('stop closes the controller stream', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      var closed = false;
      stream.listen((_) {}, onDone: () => closed = true);

      await ds.stop();
      expect(closed, isTrue);
    });

    test('stopDispatch closes the controller stream', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      var closed = false;
      stream.listen((_) {}, onDone: () => closed = true);

      await ds.stopDispatch('whatever');
      expect(closed, isTrue);
    });

    test('stopAllForAgent delegates to stop', () async {
      final ds = AgentProcessDataSource();
      final stream = ds.initTestController();
      var closed = false;
      stream.listen((_) {}, onDone: () => closed = true);

      await ds.stopAllForAgent('a1');
      expect(closed, isTrue);
    });

    test(
      'steer / pause / resume return false (unsupported for external CLI)',
      () async {
        final ds = AgentProcessDataSource();
        expect(await ds.steerDispatch('d', 'm'), isFalse);
        expect(await ds.steerDispatch('d', 'm', followUp: true), isFalse);
        expect(await ds.pauseDispatch('d'), isFalse);
        expect(await ds.resumeDispatch('d'), isFalse);
      },
    );
  });
}
