import 'dart:convert';

import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:test/test.dart';

/// Exercises [ClaudeStreamJsonParser] by feeding it decoded `stream-json`
/// event maps. The parser reconstructs streamed text/thinking deltas and
/// reassembles `tool_use` input from incremental `input_json_delta` fragments,
/// and surfaces terminal `result` errors — covering the live-transcription
/// path used to drive Claude Code as a structured CLI.
void main() {
  ClaudeStreamJsonParser build({
    void Function(String)? onText,
    void Function(String)? onThinking,
    void Function(ClaudeToolUse)? onToolCall,
    void Function(String)? onError,
  }) => ClaudeStreamJsonParser(
    ClaudeStreamJsonCallbacks(
      onText: onText,
      onThinking: onThinking,
      onToolCall: onToolCall,
      onError: onError,
    ),
  );

  /// Wraps a content-block event as a `stream_event` envelope.
  Map<String, dynamic> stream(Map<String, dynamic> event) => {
    'type': 'stream_event',
    'event': event,
  };

  group('text deltas', () {
    test('concatenates text_delta events into onText callbacks', () {
      final out = <String>[];
      final p = build(onText: out.add);
      p.process(
        stream({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'text', 'id': 'b0'},
        }),
      );
      p.process(
        stream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': 'Hello'},
        }),
      );
      p.process(
        stream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': ', world'},
        }),
      );
      p.process(stream({'type': 'content_block_stop', 'index': 0}));
      expect(out, ['Hello', ', world']);
    });

    test('an empty text_delta is dropped (no callback)', () {
      final out = <String>[];
      final p = build(onText: out.add);
      p.process(
        stream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': ''},
        }),
      );
      expect(out, isEmpty);
    });

    test('a delta with no prior block start still emits onText', () {
      // A text_delta with an unknown index resolves to block == null, so it is
      // treated as ordinary text (not thinking).
      final out = <String>[];
      final p = build(onText: out.add);
      p.process(
        stream({
          'type': 'content_block_delta',
          'index': 9,
          'delta': {'type': 'text_delta', 'text': 'late'},
        }),
      );
      expect(out, ['late']);
    });
  });

  group('thinking deltas', () {
    test('routes a text_delta on a thinking block to onThinking', () {
      final text = <String>[];
      final think = <String>[];
      final p = build(onText: text.add, onThinking: think.add);
      p.process(
        stream({
          'type': 'content_block_start',
          'index': 1,
          'content_block': {'type': 'thinking'},
        }),
      );
      p.process(
        stream({
          'type': 'content_block_delta',
          'index': 1,
          'delta': {'type': 'text_delta', 'text': 'hmm'},
        }),
      );
      expect(text, isEmpty);
      expect(think, ['hmm']);
    });

    test('routes thinking_delta events to onThinking', () {
      final think = <String>[];
      final p = build(onThinking: think.add);
      p.process(
        stream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'thinking_delta', 'thinking': 'pondering'},
        }),
      );
      expect(think, ['pondering']);
    });

    test('an empty thinking_delta is dropped', () {
      final think = <String>[];
      final p = build(onThinking: think.add);
      p.process(
        stream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'thinking_delta', 'thinking': ''},
        }),
      );
      expect(think, isEmpty);
    });
  });

  group('tool_use reassembly', () {
    test(
      'joins input_json_delta fragments and emits on content_block_stop',
      () {
        final calls = <ClaudeToolUse>[];
        final p = build(onToolCall: calls.add);
        p.process(
          stream({
            'type': 'content_block_start',
            'index': 2,
            'content_block': {'type': 'tool_use', 'id': 'tu_1', 'name': 'Bash'},
          }),
        );
        p.process(
          stream({
            'type': 'content_block_delta',
            'index': 2,
            'delta': {
              'type': 'input_json_delta',
              'partial_json': '{"cmd": "rm ',
            },
          }),
        );
        p.process(
          stream({
            'type': 'content_block_delta',
            'index': 2,
            'delta': {'type': 'input_json_delta', 'partial_json': '-rf /"}'},
          }),
        );
        p.process(stream({'type': 'content_block_stop', 'index': 2}));
        expect(calls, hasLength(1));
        expect(calls.single.id, 'tu_1');
        expect(calls.single.name, 'Bash');
        expect(calls.single.input, {'cmd': 'rm -rf /'});
      },
    );

    test('a non-JSON partial buffer is surfaced as a raw string', () {
      final calls = <ClaudeToolUse>[];
      final p = build(onToolCall: calls.add);
      p.process(
        stream({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'id': 'x', 'name': 'T'},
        }),
      );
      p.process(
        stream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'input_json_delta', 'partial_json': 'not-json'},
        }),
      );
      p.process(stream({'type': 'content_block_stop', 'index': 0}));
      expect(calls.single.input, 'not-json');
    });

    test('an empty buffer yields a null input', () {
      final calls = <ClaudeToolUse>[];
      final p = build(onToolCall: calls.add);
      p.process(
        stream({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'tool_use', 'id': null, 'name': null},
        }),
      );
      p.process(stream({'type': 'content_block_stop', 'index': 0}));
      expect(calls.single.id, '');
      expect(calls.single.name, '');
      expect(calls.single.input, isNull);
    });

    test('a text-block stop does NOT emit a tool call', () {
      final calls = <ClaudeToolUse>[];
      final p = build(onToolCall: calls.add);
      p.process(
        stream({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'text'},
        }),
      );
      p.process(stream({'type': 'content_block_stop', 'index': 0}));
      expect(calls, isEmpty);
    });
  });

  group('malformed events are ignored', () {
    test('stream_event with a non-map event is dropped', () {
      final out = <String>[];
      final p = build(onText: out.add);
      p.process({'type': 'stream_event', 'event': 'oops'});
      p.process({'type': 'stream_event'});
      expect(out, isEmpty);
    });

    test(
      'content_block_start with missing index / non-map block is dropped',
      () {
        final out = <String>[];
        final p = build(onText: out.add);
        p.process(
          stream({
            'type': 'content_block_start',
            'content_block': {'type': 'text'},
          }),
        );
        p.process(
          stream({
            'type': 'content_block_start',
            'index': 0,
            'content_block': 'nope',
          }),
        );
        // Defaults to a 'text' kind block when type missing.
        p.process(
          stream({
            'type': 'content_block_delta',
            'index': 0,
            'delta': {'type': 'text_delta', 'text': 'x'},
          }),
        );
        expect(out, ['x']);
      },
    );

    test(
      'content_block_delta with missing index / non-map delta is dropped',
      () {
        final out = <String>[];
        final p = build(onText: out.add);
        p.process(
          stream({
            'type': 'content_block_delta',
            'delta': {'type': 'text_delta', 'text': 'x'},
          }),
        );
        p.process(
          stream({'type': 'content_block_delta', 'index': 0, 'delta': 'nope'}),
        );
        expect(out, isEmpty);
      },
    );

    test('unknown event types are dropped', () {
      final out = <String>[];
      final p = build(onText: out.add);
      p.process(stream({'type': 'something_else'}));
      p.process({'type': 'system'});
      p.process({'type': 'assistant'});
      expect(out, isEmpty);
    });
  });

  group('terminal result error', () {
    test('surfaces is_error result via onError, preferring result text', () {
      final errs = <String>[];
      final p = build(onError: errs.add);
      p.process({
        'type': 'result',
        'is_error': true,
        'result': 'model not found',
        'api_error_status': 404,
      });
      expect(errs.single, 'model not found (HTTP 404)');
    });

    test('falls back to error then default, with no status', () {
      final errs = <String>[];
      final p = build(onError: errs.add);
      p.process({'type': 'result', 'is_error': true, 'error': 'overloaded'});
      expect(errs.single, 'overloaded');

      final errs2 = <String>[];
      final p2 = build(onError: errs2.add);
      p2.process({'type': 'result', 'is_error': true});
      expect(errs2.single, 'claude reported an error');
    });

    test('a non-error result is dropped (not surfaced)', () {
      final errs = <String>[];
      final p = build(onError: errs.add);
      p.process({'type': 'result', 'is_error': false, 'result': 'ok'});
      expect(errs, isEmpty);
    });

    test('whitespace-only result/error fall through to the next source', () {
      final errs = <String>[];
      final p = build(onError: errs.add);
      p.process({
        'type': 'result',
        'is_error': true,
        'result': '   ',
        'error': '',
      });
      expect(errs.single, 'claude reported an error');
    });
  });

  test('real-shaped two-turn stream example round-trips', () {
    // A compact realistic sequence: thinking then text then a tool call.
    final text = <String>[];
    final think = <String>[];
    final tools = <ClaudeToolUse>[];
    final p = build(
      onText: text.add,
      onThinking: think.add,
      onToolCall: tools.add,
    );
    for (final line in [
      '{"type":"stream_event","event":{"type":"content_block_start","index":0,"content_block":{"type":"thinking","id":"t"}}}',
      '{"type":"stream_event","event":{"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"plan"}}}',
      '{"type":"stream_event","event":{"type":"content_block_stop","index":0}}',
      '{"type":"stream_event","event":{"type":"content_block_start","index":1,"content_block":{"type":"text","id":"b"}}}',
      '{"type":"stream_event","event":{"type":"content_block_delta","index":1,"delta":{"type":"text_delta","text":"hi"}}}',
      '{"type":"stream_event","event":{"type":"content_block_stop","index":1}}',
    ]) {
      p.process(jsonDecode(line) as Map<String, dynamic>);
    }
    expect(think, ['plan']);
    expect(text, ['hi']);
    expect(tools, isEmpty);
  });
}
