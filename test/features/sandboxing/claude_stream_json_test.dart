import 'dart:convert';

import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ClaudeStreamJsonParser makeParser({
    List<String>? text,
    List<String>? thinking,
    List<Map<String, dynamic>>? toolCalls,
    List<String>? errors,
  }) {
    return ClaudeStreamJsonParser(
      ClaudeStreamJsonCallbacks(
        onText: (d) => text?.add(d),
        onThinking: (d) => thinking?.add(d),
        onToolCall: (tu) =>
            toolCalls?.add({'id': tu.id, 'name': tu.name, 'input': tu.input}),
        onError: (m) => errors?.add(m),
      ),
    );
  }

  Map<String, dynamic> wrapStream(Map<String, dynamic> event) => {
    'type': 'stream_event',
    'event': event,
  };

  group('ClaudeStreamJsonParser', () {
    test('accumulates text deltas', () {
      final text = <String>[];
      final parser = makeParser(text: text);

      parser.process(
        wrapStream({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'text', 'id': 'b1'},
        }),
      );
      parser.process(
        wrapStream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': 'Hello'},
        }),
      );
      parser.process(
        wrapStream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': ', world'},
        }),
      );
      parser.process(wrapStream({'type': 'content_block_stop', 'index': 0}));

      expect(text, ['Hello', ', world']);
    });

    test('routes thinking_delta to onThinking', () {
      final thinking = <String>[];
      final parser = makeParser(thinking: thinking);

      parser.process(
        wrapStream({
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'thinking_delta', 'thinking': 'reasoning'},
        }),
      );

      expect(thinking, ['reasoning']);
    });

    test('reassembles tool_use input from input_json_delta fragments', () {
      final toolCalls = <Map<String, dynamic>>[];
      final parser = makeParser(toolCalls: toolCalls);

      parser.process(
        wrapStream({
          'type': 'content_block_start',
          'index': 1,
          'content_block': {
            'type': 'tool_use',
            'id': 'tool_123',
            'name': 'Bash',
          },
        }),
      );
      parser.process(
        wrapStream({
          'type': 'content_block_delta',
          'index': 1,
          'delta': {'type': 'input_json_delta', 'partial_json': '{"command"'},
        }),
      );
      parser.process(
        wrapStream({
          'type': 'content_block_delta',
          'index': 1,
          'delta': {'type': 'input_json_delta', 'partial_json': ':"ls -la"}'},
        }),
      );
      parser.process(wrapStream({'type': 'content_block_stop', 'index': 1}));

      expect(toolCalls, [
        {
          'id': 'tool_123',
          'name': 'Bash',
          'input': {'command': 'ls -la'},
        },
      ]);
    });

    test('ignores system + successful result lines', () {
      final text = <String>[];
      final errors = <String>[];
      final parser = makeParser(text: text, errors: errors);

      parser.process({'type': 'system', 'subtype': 'init', 'session_id': 's'});
      parser.process({
        'type': 'result',
        'subtype': 'success',
        'is_error': false,
      });

      expect(text, isEmpty);
      expect(errors, isEmpty);
    });

    test('surfaces a failed result as onError with the http status', () {
      final errors = <String>[];
      final parser = makeParser(errors: errors);

      parser.process({
        'type': 'result',
        'subtype': 'success',
        'is_error': true,
        'result': "There's an issue with the selected model (gpt-4o).",
        'api_error_status': 404,
      });

      expect(errors, [
        "There's an issue with the selected model (gpt-4o). (HTTP 404)",
      ]);
    });

    test('failed result without text falls back to the error field', () {
      final errors = <String>[];
      final parser = makeParser(errors: errors);

      parser.process({
        'type': 'result',
        'is_error': true,
        'error': 'model_not_found',
      });

      expect(errors, ['model_not_found']);
    });

    test('parses a full NDJSON line end-to-end', () {
      final text = <String>[];
      final parser = makeParser(text: text);

      parser.process(
        jsonDecode(
              '{"type":"stream_event","event":{"type":"content_block_delta",'
              '"index":0,"delta":{"type":"text_delta","text":"hi"}}}',
            )
            as Map<String, dynamic>,
      );

      expect(text, ['hi']);
    });

    test('emits no tool call for a non-tool block on stop', () {
      final toolCalls = <Map<String, dynamic>>[];
      final parser = makeParser(toolCalls: toolCalls);

      parser.process(
        wrapStream({
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'text', 'id': 'b1'},
        }),
      );
      parser.process(wrapStream({'type': 'content_block_stop', 'index': 0}));

      expect(toolCalls, isEmpty);
    });
  });
}
