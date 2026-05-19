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
    void Function(ClaudeToolResult)? onToolResult,
    void Function(ClaudeUsage)? onUsage,
    void Function(String)? onError,
  }) => ClaudeStreamJsonParser(
    ClaudeStreamJsonCallbacks(
      onText: onText,
      onThinking: onThinking,
      onToolCall: onToolCall,
      onToolResult: onToolResult,
      onUsage: onUsage,
      onError: onError,
    ),
  );

  /// A `tool_use` block opened and closed in one go, so a result has something
  /// to pair against.
  void openTool(ClaudeStreamJsonParser p, String id, {String name = 'Bash'}) {
    p.process({
      'type': 'stream_event',
      'event': {
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'tool_use', 'id': id, 'name': name},
      },
    });
    p.process({
      'type': 'stream_event',
      'event': {'type': 'content_block_stop', 'index': 0},
    });
  }

  /// Wraps `tool_result` blocks the way `claude` replays them: a top-level
  /// `user` message, NOT a `stream_event`.
  Map<String, dynamic> userResult(List<Map<String, dynamic>> blocks) => {
    'type': 'user',
    'message': {'role': 'user', 'content': blocks},
  };

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

  group('tool_result pairing', () {
    test('a top-level user message closes the matching call', () {
      final results = <ClaudeToolResult>[];
      final p = build(onToolResult: results.add);
      openTool(p, 'tu_1');
      p.process(
        userResult([
          {
            'type': 'tool_result',
            'tool_use_id': 'tu_1',
            'content': 'hi',
            'is_error': false,
          },
        ]),
      );
      expect(results, hasLength(1));
      expect(results.single.id, 'tu_1');
      expect(results.single.outputs, 'hi');
      expect(results.single.isError, isFalse);
    });

    test('is_error is carried through', () {
      final results = <ClaudeToolResult>[];
      final p = build(onToolResult: results.add);
      openTool(p, 'tu_1', name: 'Read');
      p.process(
        userResult([
          {
            'type': 'tool_result',
            'tool_use_id': 'tu_1',
            'content': 'File does not exist.',
            'is_error': true,
          },
        ]),
      );
      expect(results.single.isError, isTrue);
    });

    test('block-list content is flattened, naming non-text parts', () {
      final results = <ClaudeToolResult>[];
      final p = build(onToolResult: results.add);
      openTool(p, 'tu_1');
      p.process(
        userResult([
          {
            'type': 'tool_result',
            'tool_use_id': 'tu_1',
            'content': [
              {'type': 'text', 'text': 'line one\n'},
              {'type': 'image', 'source': {}},
              {'type': 'text', 'text': 'line two'},
            ],
          },
        ]),
      );
      expect(results.single.outputs, 'line one\n[image]line two');
    });

    test('an unpaired id is dropped rather than closing another call', () {
      // A subagent's inner tool: its `tool_use` block never reaches this
      // stream, so pairing it would close the parent `Task` row instead.
      final results = <ClaudeToolResult>[];
      final p = build(onToolResult: results.add);
      openTool(p, 'tu_parent', name: 'Task');
      p.process(
        userResult([
          {
            'type': 'tool_result',
            'tool_use_id': 'tu_subagent_inner',
            'content': 'x',
          },
        ]),
      );
      expect(results, isEmpty);
    });

    test('a result is emitted once, even if replayed', () {
      final results = <ClaudeToolResult>[];
      final p = build(onToolResult: results.add);
      openTool(p, 'tu_1');
      final replay = userResult([
        {'type': 'tool_result', 'tool_use_id': 'tu_1', 'content': 'once'},
      ]);
      p.process(replay);
      p.process(replay);
      expect(results, hasLength(1));
    });

    test('non-tool_result user content is ignored', () {
      final results = <ClaudeToolResult>[];
      final p = build(onToolResult: results.add);
      openTool(p, 'tu_1');
      p.process(
        userResult([
          {'type': 'text', 'text': 'a follow-up prompt'},
        ]),
      );
      p.process({'type': 'user', 'message': 'not a map'});
      p.process({'type': 'user'});
      expect(results, isEmpty);
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

    group('usage', () {
      // The exact shape `claude -p --output-format stream-json` emits, trimmed
      // to the fields we read. Captured from a real invocation — the whole
      // point of this group is that a schema drift here fails loudly rather
      // than silently zeroing every run's token counts again.
      Map<String, dynamic> resultEvent({bool isError = false}) => {
        'type': 'result',
        'subtype': isError ? 'error_during_execution' : 'success',
        'is_error': isError,
        'duration_ms': 4210,
        'duration_api_ms': 3145,
        'ttft_ms': 2041,
        'total_cost_usd': 0.067079,
        'usage': {
          'input_tokens': 2,
          'cache_creation_input_tokens': 5844,
          'cache_read_input_tokens': 15894,
          'output_tokens': 4,
          'server_tool_use': {'web_search_requests': 0},
        },
      };

      test('a successful result reports the invocation total', () {
        final seen = <ClaudeUsage>[];
        final p = build(onUsage: seen.add);
        p.process(resultEvent());

        final usage = seen.single;
        expect(usage.inputTokens, 2);
        expect(usage.outputTokens, 4);
        expect(usage.cacheReadTokens, 15894);
        expect(usage.cacheWriteTokens, 5844);
        expect(usage.costUsd, closeTo(0.067079, 1e-9));
        expect(usage.costCents, 7);
        // `duration_ms` wins over `duration_api_ms`: the run log wants the
        // whole turn, not just the time on the wire.
        expect(usage.durationMs, 4210);
        expect(usage.timeToFirstTokenMs, 2041);
      });

      test('a FAILED result still reports what it spent', () {
        final seen = <ClaudeUsage>[];
        final errs = <String>[];
        final p = build(onUsage: seen.add, onError: errs.add);
        p.process(resultEvent(isError: true));

        // Both fire: the failure is surfaced AND the spend is counted. A turn
        // that burned 15k cached tokens before dying did not cost nothing.
        expect(seen.single.cacheReadTokens, 15894);
        expect(errs, hasLength(1));
      });

      test('falls back to duration_api_ms when duration_ms is absent', () {
        final seen = <ClaudeUsage>[];
        final p = build(onUsage: seen.add);
        p.process(resultEvent()..remove('duration_ms'));
        expect(seen.single.durationMs, 3145);
      });

      test('a result with no usage block reports nothing', () {
        final seen = <ClaudeUsage>[];
        final p = build(onUsage: seen.add);
        // An older CLI, or a failure that died before any accounting. Must not
        // synthesise a zero-token measurement — that would read as a run that
        // provably spent nothing.
        p.process({'type': 'result', 'is_error': true});
        expect(seen, isEmpty);
      });

      test('missing individual fields read as zero, not as a dropped event', () {
        final seen = <ClaudeUsage>[];
        final p = build(onUsage: seen.add);
        p.process({
          'type': 'result',
          'usage': {'output_tokens': 12},
        });
        final usage = seen.single;
        expect(usage.outputTokens, 12);
        expect(usage.inputTokens, 0);
        expect(usage.cacheReadTokens, 0);
        expect(usage.costUsd, 0.0);
        expect(usage.durationMs, isNull);
      });

      test('non-result events never report usage', () {
        final seen = <ClaudeUsage>[];
        final p = build(onUsage: seen.add);
        // `assistant` carries a per-turn `usage` snapshot that would
        // double-count against the cumulative `result` total.
        p.process({
          'type': 'assistant',
          'message': {
            'usage': {'input_tokens': 999, 'output_tokens': 999},
          },
        });
        p.process({'type': 'system', 'subtype': 'init'});
        p.process({'type': 'rate_limit_event'});
        expect(seen, isEmpty);
      });
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

  test('a real Bash call/result round-trip opens and closes one tool', () {
    // Verbatim shapes from `claude -p --output-format stream-json --verbose
    // --include-partial-messages`. The result arrives as a top-level `user`
    // message interleaved with the `stream_event` lane, which is why the
    // envelope type matters here.
    final tools = <ClaudeToolUse>[];
    final results = <ClaudeToolResult>[];
    final p = build(onToolCall: tools.add, onToolResult: results.add);
    for (final line in [
      '{"type":"stream_event","event":{"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_01Ru","name":"Bash","input":{}}}}',
      '{"type":"stream_event","event":{"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\\"command\\": \\"echo hi\\"}"}}}',
      '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_01Ru","name":"Bash","input":{"command":"echo hi"}}]}}',
      '{"type":"stream_event","event":{"type":"content_block_stop","index":1}}',
      '{"type":"stream_event","event":{"type":"message_stop"}}',
      '{"type":"user","message":{"role":"user","content":[{"tool_use_id":"toolu_01Ru","type":"tool_result","content":"hi","is_error":false}]}}',
    ]) {
      p.process(jsonDecode(line) as Map<String, dynamic>);
    }
    expect(tools.single.id, 'toolu_01Ru');
    expect(tools.single.input, {'command': 'echo hi'});
    expect(results.single.id, 'toolu_01Ru');
    expect(results.single.outputs, 'hi');
  });
}
