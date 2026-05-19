import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

/// A [ProviderHttp] that replays canned SSE events instead of making a request.
class _FakeHttp extends ProviderHttp {
  _FakeHttp(this.events);

  final List<Map<String, dynamic>> events;

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    for (final event in events) {
      yield SseMessage(
        event: event['type'] as String?,
        data: jsonEncode(event),
      );
    }
  }
}

void main() {
  group('AnthropicProvider', () {
    test('streams text + tool-use + usage + done from the SSE flow', () async {
      final http = _FakeHttp([
        {
          'type': 'message_start',
          'message': {
            'usage': {'input_tokens': 10},
          },
        },
        {
          'type': 'content_block_start',
          'index': 0,
          'content_block': {'type': 'text', 'text': ''},
        },
        {
          'type': 'content_block_delta',
          'index': 0,
          'delta': {'type': 'text_delta', 'text': 'Hello'},
        },
        {'type': 'content_block_stop', 'index': 0},
        {
          'type': 'content_block_start',
          'index': 1,
          'content_block': {'type': 'tool_use', 'id': 't1', 'name': 'read'},
        },
        {
          'type': 'content_block_delta',
          'index': 1,
          'delta': {'type': 'input_json_delta', 'partial_json': '{"path":'},
        },
        {
          'type': 'content_block_delta',
          'index': 1,
          'delta': {'type': 'input_json_delta', 'partial_json': '"a.txt"}'},
        },
        {'type': 'content_block_stop', 'index': 1},
        {
          'type': 'message_delta',
          'delta': {'stop_reason': 'tool_use'},
          'usage': {'output_tokens': 5},
        },
        {'type': 'message_stop'},
      ]);
      final provider = AnthropicProvider(apiKey: 'k', http: http);

      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();

      final text = events.whereType<LlmTextDelta>().map((e) => e.text).join();
      expect(text, 'Hello');

      final toolUse = events.whereType<LlmToolUseDelta>().single;
      expect(toolUse.id, 't1');
      expect(toolUse.name, 'read');
      expect(toolUse.argumentsJson, '{"path":"a.txt"}');

      final done = events.whereType<LlmDone>().single;
      expect(done.stopReason, LlmStopReason.toolUse);
      expect(done.usage?.inputTokens, 10);
      expect(done.usage?.outputTokens, 5);
    });

    test('maps a stream error event to LlmError', () async {
      final http = _FakeHttp([
        {
          'type': 'error',
          'error': {'type': 'overloaded_error', 'message': 'slow down'},
        },
      ]);
      final provider = AnthropicProvider(apiKey: 'k', http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      final error = events.whereType<LlmError>().single;
      expect(error.code, 'overloaded_error');
      expect(error.retryable, isTrue);
      expect(events.whereType<LlmDone>(), isNotEmpty);
    });
  });
}
