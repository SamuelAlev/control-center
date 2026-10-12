import 'dart:convert';

import 'package:cc_infra/src/sandboxing/claude_native_session.dart'
    show ClaudeNativeSessionRecord;
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
    void Function()? onResult,
  }) => ClaudeStreamJsonParser(
    ClaudeStreamJsonCallbacks(
      onText: onText,
      onThinking: onThinking,
      onToolCall: onToolCall,
      onToolResult: onToolResult,
      onUsage: onUsage,
      onError: onError,
      onResult: onResult,
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

    test('onResult fires once per result, after the error is reported', () {
      final seen = <String>[];
      final p = build(
        onError: (e) => seen.add('error:$e'),
        onResult: () => seen.add('result'),
      );
      p.process({'type': 'result', 'is_error': false, 'result': 'ok'});
      p.process({'type': 'result', 'is_error': true, 'error': 'overloaded'});
      p.process({'type': 'system', 'subtype': 'init'});
      expect(seen, ['result', 'error:overloaded', 'result']);
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

      test(
        'missing individual fields read as zero, not as a dropped event',
        () {
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
        },
      );

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

  group('context occupancy', () {
    List<ClaudeCallUsage> readings(
      List<Map<String, dynamic>> events, {
      List<int?>? compactions,
    }) {
      final out = <ClaudeCallUsage>[];
      final p = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(
          onCallUsage: out.add,
          onCompactBoundary: compactions?.add,
        ),
      );
      events.forEach(p.process);
      return out;
    }

    Map<String, dynamic> start(Map<String, dynamic> usage, {String? parent}) =>
        {
          'type': 'stream_event',
          'parent_tool_use_id': parent,
          'event': {
            'type': 'message_start',
            'message': {'usage': usage},
          },
        };

    Map<String, dynamic> delta(int output, {String? parent}) => {
      'type': 'stream_event',
      'parent_tool_use_id': parent,
      'event': {
        'type': 'message_delta',
        'usage': {'output_tokens': output},
      },
    };

    test('a call reads uncached + cache read + cache write input', () {
      final out = readings([
        start({
          'input_tokens': 12,
          'cache_read_input_tokens': 150000,
          'cache_creation_input_tokens': 3000,
          'output_tokens': 1,
        }),
      ]);
      expect(out.single.promptTokens, 153012);
      expect(out.single.contextTokens, 153013);
    });

    test('message_delta adds the call output to the same prompt', () {
      final out = readings([
        start({'input_tokens': 10, 'cache_read_input_tokens': 90}),
        delta(40),
      ]);
      expect(out.last.promptTokens, 100);
      expect(out.last.contextTokens, 140);
    });

    test('the newest call replaces the previous one, not adds to it', () {
      final out = readings([
        start({'input_tokens': 100}),
        delta(10),
        start({'input_tokens': 5, 'cache_read_input_tokens': 110}),
      ]);
      expect(out.last.contextTokens, 115);
    });

    test('subagent calls run in their own window and are skipped', () {
      final out = readings([
        start({'input_tokens': 100}),
        start({'input_tokens': 9000}, parent: 'toolu_task'),
        delta(500, parent: 'toolu_task'),
      ]);
      expect(out, hasLength(1));
      expect(out.single.contextTokens, 100);
    });

    test('a delta with no call in flight reports nothing', () {
      expect(readings([delta(40)]), isEmpty);
    });

    test('compact_boundary is surfaced with its pre-compaction size', () {
      final compactions = <int?>[];
      readings([
        {
          'type': 'system',
          'subtype': 'compact_boundary',
          'compact_metadata': {'trigger': 'auto', 'pre_tokens': 187000},
        },
        {'type': 'system', 'subtype': 'compact_boundary'},
      ], compactions: compactions);
      expect(compactions, [187000, null]);
    });
  });

  /// The line shapes `claude -p` 2.1 emits for one `Agent` call, recorded from
  /// a real run: whole subagent messages tagged with `parent_tool_use_id`, and
  /// the final answer only as the spawn call's result on the parent's lane.
  group('subagents', () {
    const spawn = 'toolu_spawn';

    Map<String, dynamic> sub(String type, List<Map<String, dynamic>> blocks) =>
        {
          'type': type,
          'parent_tool_use_id': spawn,
          'message': {'role': type, 'content': blocks},
        };

    ({
      ClaudeStreamJsonParser parser,
      List<ClaudeSubagentEvent> events,
      List<String> text,
      List<ClaudeToolUse> calls,
      List<ClaudeToolResult> results,
    })
    harness() {
      final events = <ClaudeSubagentEvent>[];
      final text = <String>[];
      final calls = <ClaudeToolUse>[];
      final results = <ClaudeToolResult>[];
      final parser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(
          onText: text.add,
          onToolCall: calls.add,
          onToolResult: results.add,
          onSubagent: events.add,
        ),
      );
      return (
        parser: parser,
        events: events,
        text: text,
        calls: calls,
        results: results,
      );
    }

    test('task_started opens the subagent with its description', () {
      final h = harness();
      h.parser.process({
        'type': 'system',
        'subtype': 'task_started',
        'task_id': 'a1',
        'tool_use_id': spawn,
        'description': 'Run ls and report files',
        'subagent_type': 'general-purpose',
      });
      final started = h.events.single as ClaudeSubagentStarted;
      expect(started.spawnToolUseId, spawn);
      expect(started.description, 'Run ls and report files');
      expect(started.subagentType, 'general-purpose');
    });

    test('a background shell task is not a subagent', () {
      final h = harness();
      h.parser.process({
        'type': 'system',
        'subtype': 'task_started',
        'tool_use_id': 'toolu_bash',
        'description': 'npm run dev',
      });
      expect(h.events, isEmpty);
    });

    test('its work routes apart from the parent turn', () {
      final h = harness();
      openTool(h.parser, spawn, name: 'Agent');
      h.calls.clear();

      h.parser
        ..process(
          sub('user', [
            {'type': 'text', 'text': 'Run ls and report back.'},
          ]),
        )
        ..process(
          sub('assistant', [
            {'type': 'thinking', 'thinking': 'list it'},
            {
              'type': 'tool_use',
              'id': 'toolu_inner',
              'name': 'Bash',
              'input': {'command': 'ls'},
            },
          ]),
        )
        ..process(
          sub('user', [
            {
              'type': 'tool_result',
              'tool_use_id': 'toolu_inner',
              'content': 'a.txt',
            },
          ]),
        )
        ..process(
          sub('assistant', [
            {'type': 'text', 'text': 'One file: a.txt'},
          ]),
        );

      expect(h.text, isEmpty);
      expect(h.calls, isEmpty);
      expect(h.results, isEmpty);
      expect(h.events.map((e) => e.runtimeType), [
        ClaudeSubagentThinking,
        ClaudeSubagentToolCall,
        ClaudeSubagentToolResult,
        ClaudeSubagentText,
      ]);
      final call = (h.events[1] as ClaudeSubagentToolCall).call;
      expect(call.name, 'Bash');
      expect(call.input, {'command': 'ls'});
      expect((h.events[2] as ClaudeSubagentToolResult).result.outputs, 'a.txt');
      expect(h.events.every((e) => e.spawnToolUseId == spawn), isTrue);

      // The spawn call itself still closes on the parent's lane.
      h.parser.process(
        userResult([
          {
            'type': 'tool_result',
            'tool_use_id': spawn,
            'content': [
              {'type': 'text', 'text': 'One file: a.txt'},
            ],
          },
        ]),
      );
      expect(h.results.single.id, spawn);
    });

    test('partial deltas tagged to a subagent never reach the parent', () {
      final h = harness();
      h.parser
        ..process({
          'type': 'stream_event',
          'parent_tool_use_id': spawn,
          'event': {
            'type': 'content_block_start',
            'index': 0,
            'content_block': {'type': 'text'},
          },
        })
        ..process({
          'type': 'stream_event',
          'parent_tool_use_id': spawn,
          'event': {
            'type': 'content_block_delta',
            'index': 0,
            'delta': {'type': 'text_delta', 'text': 'inner'},
          },
        });
      expect(h.text, isEmpty);
    });
  });

  group('system/init metadata', () {
    Map<String, dynamic> initEvent({
      String? sessionId = 'sess-1',
      Object? tools,
      Object? servers,
      Object? errors,
      Object? capabilities,
    }) => {
      'type': 'system',
      'subtype': 'init',
      'session_id': ?sessionId,
      'model': 'claude-sonnet-4-5-20250929',
      'cwd': '/work',
      'permissionMode': 'plan',
      'apiKeySource': 'oauth',
      'claude_code_version': '2.1.293',
      'tools': tools ?? ['Bash', 'Read', 'mcp__cc__complete_ticket'],
      'mcp_servers':
          servers ??
          [
            {'name': 'cc', 'status': 'connected'},
          ],
      'mcp_server_errors': ?errors,
      'capabilities': ?capabilities,
    };

    test('parses the serving model, tools, MCP status and version', () {
      final inits = <ClaudeInitMetadata>[];
      final parser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(onInit: inits.add),
      );
      parser.process(initEvent());

      final init = inits.single;
      expect(init.sessionId, 'sess-1');
      expect(init.model, 'claude-sonnet-4-5-20250929');
      expect(init.tools, contains('mcp__cc__complete_ticket'));
      expect(init.hasControlCenterTools, isTrue);
      expect(init.mcpServers.single.name, 'cc');
      expect(init.mcpServers.single.isConnected, isTrue);
      expect(init.mcpHealthy, isTrue);
      expect(init.claudeCodeVersion, '2.1.293');
      expect(init.permissionMode, 'plan');
      expect(init.failedMcpServers, isEmpty);
    });

    test('surfaces --mcp-config entries skipped by validation', () {
      final inits = <ClaudeInitMetadata>[];
      final parser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(onInit: inits.add),
      );
      parser.process(
        initEvent(
          servers: [
            {'name': 'cc', 'status': 'connected'},
            {'name': 'broken', 'status': 'failed'},
          ],
          errors: [
            {'name': 'typo', 'type': 'url_missing_type', 'message': 'no type'},
          ],
        ),
      );

      final init = inits.single;
      expect(init.mcpHealthy, isFalse);
      expect(init.mcpServerErrors.single.name, 'typo');
      expect(init.mcpServerErrors.single.type, 'url_missing_type');
      expect(init.failedMcpServers.single.name, 'broken');
    });

    test('a pending MCP server is still healthy', () {
      final inits = <ClaudeInitMetadata>[];
      final parser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(onInit: inits.add),
      );
      parser.process(
        initEvent(
          servers: [
            {'name': 'cc', 'status': 'pending'},
          ],
        ),
      );
      expect(inits.single.mcpHealthy, isTrue);
      expect(inits.single.failedMcpServers, isEmpty);
    });

    test('reports capabilities when the CLI advertises them', () {
      final inits = <ClaudeInitMetadata>[];
      final parser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(onInit: inits.add),
      );
      parser.process(initEvent(capabilities: ['interrupt_receipt_v1']));
      expect(inits.single.capabilities, ['interrupt_receipt_v1']);
    });

    test(
      'no mcp__* tools means the control-center surface did not connect',
      () {
        final inits = <ClaudeInitMetadata>[];
        final parser = ClaudeStreamJsonParser(
          ClaudeStreamJsonCallbacks(onInit: inits.add),
        );
        parser.process(initEvent(tools: ['Bash', 'Read']));
        expect(inits.single.hasControlCenterTools, isFalse);
      },
    );

    test('a partial init never throws', () {
      final inits = <ClaudeInitMetadata>[];
      final parser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(onInit: inits.add),
      );
      parser.process({'type': 'system', 'subtype': 'init'});
      final init = inits.single;
      expect(init.sessionId, isNull);
      expect(init.model, isNull);
      expect(init.tools, isEmpty);
      expect(init.mcpServers, isEmpty);
    });
  });

  group('conversation reset and api retry', () {
    test('a conversation_reset resets the cumulative accounting', () {
      final resets = <String?>[];
      final parser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(onConversationReset: resets.add),
      );
      parser.process({
        'type': 'system',
        'subtype': 'conversation_reset',
        'session_id': 'sess-2',
      });
      expect(resets, ['sess-2']);
    });

    test('an api_retry carries attempt, status and delay', () {
      final retries = <ClaudeApiRetry>[];
      final parser = ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(onApiRetry: retries.add),
      );
      parser.process({
        'type': 'system',
        'subtype': 'api_retry',
        'attempt': 2,
        'max_retries': 5,
        'retry_delay_ms': 1500,
        'error_status': 429,
        'error': 'rate_limit',
      });
      final retry = retries.single;
      expect(retry.attempt, 2);
      expect(retry.maxRetries, 5);
      expect(retry.retryDelayMs, 1500);
      expect(retry.errorStatus, 429);
      expect(retry.error, 'rate_limit');
    });
  });

  group('ClaudeUsage.tryFromResult', () {
    Map<String, dynamic> result({
      int input = 10,
      int output = 5,
      int cacheRead = 2,
      int cacheWrite = 3,
      double cost = 1.0,
      String subtype = 'success',
      String? sessionId = 'sess-1',
      Object? modelUsage,
    }) => {
      'type': 'result',
      'subtype': subtype,
      'session_id': ?sessionId,
      'usage': {
        'input_tokens': input,
        'output_tokens': output,
        'cache_read_input_tokens': cacheRead,
        'cache_creation_input_tokens': cacheWrite,
      },
      'total_cost_usd': cost,
      'modelUsage': ?modelUsage,
    };

    test('reads the per-turn usage and the cumulative cost', () {
      final usage = ClaudeUsage.tryFromResult(result())!;
      expect(usage.inputTokens, 10);
      expect(usage.outputTokens, 5);
      expect(usage.cacheReadTokens, 2);
      expect(usage.cacheWriteTokens, 3);
      expect(usage.costUsd, 1.0);
      expect(usage.costCents, 100);
      expect(usage.costMicros, 1000000);
      expect(usage.subtype, 'success');
      expect(usage.sessionId, 'sess-1');
      expect(usage.isTokenless, isFalse);
    });

    test('parses modelUsage with camelCase keys', () {
      final usage = ClaudeUsage.tryFromResult(
        result(
          modelUsage: {
            'claude-opus-4-5': {
              'inputTokens': 100,
              'outputTokens': 20,
              'cacheReadInputTokens': 7,
              'cacheCreationInputTokens': 3,
              'costUSD': 0.5,
              'costBasis': 'list',
            },
          },
        ),
      )!;
      final model = usage.modelUsage['claude-opus-4-5']!;
      expect(model.inputTokens, 100);
      expect(model.outputTokens, 20);
      expect(model.cacheReadTokens, 7);
      expect(model.cacheWriteTokens, 3);
      expect(model.costUsd, 0.5);
      expect(model.costBasis, 'list');
      expect(usage.wholeTreeTotals.totalTokens, 130);
    });

    test('parses modelUsage with snake_case keys too', () {
      final usage = ClaudeUsage.tryFromResult(
        result(
          modelUsage: {
            'm': {
              'input_tokens': 4,
              'output_tokens': 1,
              'cache_read_input_tokens': 1,
              'cache_creation_input_tokens': 0,
            },
          },
        ),
      )!;
      expect(usage.modelUsage['m']!.inputTokens, 4);
      expect(usage.modelUsage['m']!.totalTokens, 6);
    });

    test('returns null when the result carries no usage block', () {
      expect(
        ClaudeUsage.tryFromResult({'type': 'result', 'is_error': true}),
        isNull,
      );
    });

    test('a monetary-only result retains its observed cost', () {
      final ledger = ClaudeAccountingLedger();
      ledger.record(
        ClaudeUsage.tryFromResult({'type': 'result', 'total_cost_usd': 0.2})!,
      );
      final next = ledger.record(
        ClaudeUsage.tryFromResult({
          'type': 'result',
          'total_cost_usd': 0.3,
          'modelUsage': {
            'main': {'inputTokens': 100},
          },
        })!,
      );
      expect(next.costDeltaMicros, 100000);
      expect(next.costUnavailable, isFalse);
      expect(next.tokenDelta.inputTokens, 100);
    });

    test('a zeroed crash is detected so a good baseline survives', () {
      final usage = ClaudeUsage.tryFromResult(
        result(
          input: 0,
          output: 0,
          cacheRead: 0,
          cacheWrite: 0,
          cost: 0,
          subtype: 'error_during_execution',
        ),
      )!;
      expect(usage.isTokenless, isTrue);
      expect(usage.isZeroedCrash, isTrue);
    });
  });

  group('ClaudeAccountingLedger', () {
    ClaudeUsage usage({
      int input = 0,
      int output = 0,
      double cost = 0,
      String subtype = 'success',
      Map<String, Object?> models = const {},
    }) => ClaudeUsage.tryFromResult({
      'type': 'result',
      'subtype': subtype,
      'usage': {
        'input_tokens': input,
        'output_tokens': output,
        'cache_read_input_tokens': 0,
        'cache_creation_input_tokens': 0,
      },
      'total_cost_usd': cost,
      'modelUsage': models,
    })!;

    test('two results from one session are delta\'d, not summed', () {
      // The research table: $1.00 then $1.50 cumulative is $1.50 spent, where
      // the old additive policy produced $2.50.
      final ledger = ClaudeAccountingLedger();
      final first = ledger.record(usage(input: 10, cost: 1.00));
      final second = ledger.record(usage(input: 4, cost: 1.50));

      expect(first.costDeltaUsd, closeTo(1.00, 1e-9));
      expect(second.costDeltaUsd, closeTo(0.50, 1e-9));
      expect(second.cumulativeCostUsd, closeTo(1.50, 1e-9));
      expect(second.cumulativeCostMicros, 1500000);
      // Per-turn tokens stay additive and are the main loop's, not the tree's.
      expect(first.inputTokens, 10);
      expect(second.inputTokens, 4);
      expect(ledger.turns, 2);
    });

    test('a repeated cumulative value adds nothing', () {
      final ledger = ClaudeAccountingLedger();
      ledger.record(usage(cost: 1.00));
      final repeat = ledger.record(usage(cost: 1.00));
      expect(repeat.costDeltaUsd, 0);
      expect(repeat.costReset, isFalse);
    });

    test(
      'a shrinking cumulative is a reset: the whole figure is folded in',
      () {
        final ledger = ClaudeAccountingLedger();
        ledger.record(usage(cost: 2.00));
        final after = ledger.record(usage(cost: 0.25));
        expect(after.costReset, isTrue);
        expect(after.costDeltaUsd, closeTo(0.25, 1e-9));
        expect(after.cumulativeCostUsd, closeTo(0.25, 1e-9));
      },
    );

    test('a zeroed crash leaves the good baseline untouched', () {
      final ledger = ClaudeAccountingLedger();
      ledger.record(usage(cost: 1.00));
      final crash = ledger.record(
        usage(subtype: 'error_during_execution', cost: 0),
      );
      expect(crash.costUnavailable, isTrue);
      expect(crash.costDeltaUsd, 0);
      expect(ledger.cumulativeCostUsd, closeTo(1.00, 1e-9));
    });

    test(
      'missing cost is unknown and never resets a good cumulative baseline',
      () {
        final ledger = ClaudeAccountingLedger();
        final totals = ClaudeDispatchTotals();
        totals.add(ledger.record(usage(input: 10, cost: 1)));
        final partial = ClaudeUsage.tryFromResult({
          'type': 'result',
          'subtype': 'success',
          'usage': {'input_tokens': 20, 'output_tokens': 3},
        })!;
        final accounted = ledger.record(partial);
        totals.add(accounted);
        expect(accounted.costUnavailable, isTrue);
        expect(accounted.costReset, isFalse);
        expect(ledger.cumulativeCostUsd, 1);
        expect(totals.inputTokens, 30);
        expect(totals.outputTokens, 3);
        expect(totals.costUnavailable, isTrue);
        final next = ledger.record(usage(input: 5, cost: 1.5));
        totals.add(next);
        expect(next.costDeltaMicros, 500000);
        expect(totals.costMicros, 1500000);
      },
    );

    test(
      'missing model counters retain main usage without replaying it later',
      () {
        final ledger = ClaudeAccountingLedger();
        final totals = ClaudeDispatchTotals();
        totals.add(
          ledger.record(
            usage(
              input: 10,
              cost: 1,
              models: {
                'main': {'inputTokens': 100},
              },
            ),
          ),
        );
        totals.add(ledger.record(usage(input: 12, cost: 1.2)));
        expect(totals.inputTokens, 112);
        expect(ledger.baseline.mainUsageSinceModels.inputTokens, 12);
        totals.add(
          ledger.record(
            usage(
              input: 9,
              cost: 1.5,
              models: {
                'main': {'inputTokens': 150},
              },
            ),
          ),
        );
        expect(totals.inputTokens, 150);
        expect(ledger.baseline.mainUsageSinceModels.totalTokens, 0);
      },
    );

    test('a restored baseline credits missing-model main usage only once', () {
      final ledger = ClaudeAccountingLedger();
      ledger.record(
        usage(
          input: 10,
          cost: 1,
          models: {
            'main': {'inputTokens': 100},
          },
        ),
      );
      ledger.record(usage(input: 12, cost: 1.2));
      final baseline = ledger.baseline;
      final persisted = ClaudeNativeSessionRecord.fromJson(
        ClaudeNativeSessionRecord(
          storageKey: 'workspace/account/conversation',
          sessionId: 'session',
          policyFingerprint: 'policy',
          conversationRevision: 'revision',
          createdAt: DateTime.utc(2026),
          lastUsedAt: DateTime.utc(2026),
          cumulativeCostUsd: baseline.cumulativeCostUsd,
          modelUsage: baseline.modelUsage,
          mainUsageSinceModels: baseline.mainUsageSinceModels,
        ).toJson(),
      )!;
      final restored = ClaudeAccountingLedger(
        baseline: ClaudeAccountingBaseline(
          cumulativeCostUsd: persisted.cumulativeCostUsd,
          modelUsage: persisted.modelUsage,
          mainUsageSinceModels: persisted.mainUsageSinceModels,
          restoredByCli: true,
        ),
      );
      final next = restored.record(
        usage(
          input: 9,
          cost: 1.5,
          models: {
            'main': {'inputTokens': 150},
          },
        ),
      );
      expect(next.tokenDelta.inputTokens, 38);
      expect(next.costDeltaMicros, 300000);
      restored.reset();
      final fresh = restored.record(
        usage(
          input: 5,
          cost: 0.1,
          models: {
            'main': {'inputTokens': 5},
          },
        ),
      );
      expect(fresh.tokenDelta.inputTokens, 5);
    });

    test('a resume baseline prevents re-counting restored spend', () {
      // Turn one cost $1.50 and was persisted as a CLI-RESTORABLE baseline. A
      // resumed call starts with its totals already at 1.50, so only the NEW
      // spend is a delta.
      final ledger = ClaudeAccountingLedger(
        baseline: const ClaudeAccountingBaseline(
          cumulativeCostUsd: 1.50,
          turns: 1,
          restoredByCli: true,
        ),
      );
      final turn = ledger.record(usage(cost: 2.00));
      expect(turn.costDeltaUsd, closeTo(0.50, 1e-9));
      expect(ledger.turns, 2);
    });

    test('a non-restorable baseline is ignored, not delta\'d against', () {
      // The CLI does not restore these totals (an older build, or a previous
      // run that never exited cleanly), so its figures describe THIS dispatch
      // and deltaing them against the old baseline would swallow spend.
      final ledger = ClaudeAccountingLedger(
        baseline: const ClaudeAccountingBaseline(cumulativeCostUsd: 1.50),
      );
      final turn = ledger.record(usage(cost: 2.00));
      expect(turn.costDeltaUsd, closeTo(2.00, 1e-9));
      expect(ledger.cumulativeCostUsd, closeTo(2.00, 1e-9));
    });

    test('a dispatch accumulator survives ledger resets', () {
      final totals = ClaudeDispatchTotals();
      final ledger = ClaudeAccountingLedger();
      totals.add(
        ledger.record(
          usage(
            cost: 1.00,
            input: 100,
            models: {
              'm': {'inputTokens': 100, 'costUSD': 1.0},
            },
          ),
        ),
      );
      // A `/clear` or an account switch resets the session's counters, not the
      // dispatch's attribution.
      ledger.reset();
      totals.add(ledger.record(usage(cost: 0.25, input: 10)));

      expect(totals.costMicros, 1250000);
      expect(totals.inputTokens, 110);
      expect(totals.snapshot.costUsd, closeTo(1.25, 1e-9));
    });

    test('a resume whose transcript was not saved reads as a new baseline', () {
      // The baseline WAS recorded as restorable, but this call's totals came
      // back smaller — no restore happened — so the whole figure is a new
      // baseline rather than a negative delta.
      final ledger = ClaudeAccountingLedger(
        baseline: const ClaudeAccountingBaseline(
          cumulativeCostUsd: 1.50,
          restoredByCli: true,
        ),
      );
      final turn = ledger.record(usage(cost: 0.30));
      expect(turn.costReset, isTrue);
      expect(turn.costDeltaUsd, closeTo(0.30, 1e-9));
    });

    test('modelUsage deltas are whole-tree and never double counted', () {
      final ledger = ClaudeAccountingLedger();
      final first = ledger.record(
        usage(
          input: 100,
          cost: 1.00,
          models: {
            'main': {
              'inputTokens': 100,
              'outputTokens': 10,
              'cacheReadInputTokens': 0,
              'cacheCreationInputTokens': 0,
              'costUSD': 0.9,
            },
            'haiku': {
              'inputTokens': 20,
              'outputTokens': 2,
              'cacheReadInputTokens': 0,
              'cacheCreationInputTokens': 0,
              'costUSD': 0.1,
            },
          },
        ),
      );
      expect(first.wholeTreeTotals.totalTokens, 132);
      // The per-turn main-loop tokens are the `usage` block only.
      expect(first.inputTokens, 100);

      final second = ledger.record(
        usage(
          input: 50,
          cost: 1.50,
          models: {
            'main': {
              'inputTokens': 150,
              'outputTokens': 20,
              'cacheReadInputTokens': 0,
              'cacheCreationInputTokens': 0,
              'costUSD': 1.4,
            },
            'haiku': {
              'inputTokens': 30,
              'outputTokens': 3,
              'cacheReadInputTokens': 0,
              'cacheCreationInputTokens': 0,
              'costUSD': 0.1,
            },
          },
        ),
      );
      // Deltas, not the cumulative values, so the tree is not counted twice.
      expect(second.modelUsageDeltas['main']!.inputTokens, 50);
      expect(second.modelUsageDeltas['haiku']!.inputTokens, 10);
      expect(second.wholeTreeTotals.inputTokens, 180);
      expect(second.cumulativeModelUsage['main']!.inputTokens, 150);
    });

    test('a reset restarts the model counters', () {
      final ledger = ClaudeAccountingLedger();
      ledger.record(
        usage(
          cost: 2.00,
          models: {
            'main': {'inputTokens': 500},
          },
        ),
      );
      final after = ledger.record(
        usage(
          cost: 0.10,
          models: {
            'main': {'inputTokens': 10},
          },
        ),
      );
      expect(after.costReset, isTrue);
      expect(after.modelUsageDeltas['main']!.inputTokens, 10);
      expect(after.cumulativeModelUsage['main']!.inputTokens, 10);
    });

    test('reset forgets both cumulative axes', () {
      final ledger = ClaudeAccountingLedger();
      ledger.record(
        usage(
          cost: 1.00,
          models: {
            'main': {'inputTokens': 5},
          },
        ),
      );
      ledger.reset();
      expect(ledger.cumulativeCostUsd, 0);
      expect(ledger.modelUsage, isEmpty);
      final next = ledger.record(usage(cost: 0.20));
      expect(next.costDeltaUsd, closeTo(0.20, 1e-9));
      expect(next.costReset, isFalse);
    });

    test('baseline round-trips through a persisted snapshot', () {
      final ledger = ClaudeAccountingLedger();
      ledger.record(
        usage(
          cost: 0.75,
          models: {
            'main': {'inputTokens': 40, 'costUSD': 0.75},
          },
        ),
      );
      // The session decides restorability from the CLI's exit + capability; a
      // restorable baseline seeds the next ledger.
      final restored = ClaudeAccountingLedger(
        baseline: ClaudeAccountingBaseline(
          cumulativeCostUsd: ledger.baseline.cumulativeCostUsd,
          modelUsage: ledger.baseline.modelUsage,
          turns: ledger.baseline.turns,
          restoredByCli: true,
        ),
      );
      expect(restored.cumulativeCostUsd, closeTo(0.75, 1e-9));
      expect(restored.modelUsage['main']!.inputTokens, 40);
      expect(restored.turns, 1);
    });
  });
}
