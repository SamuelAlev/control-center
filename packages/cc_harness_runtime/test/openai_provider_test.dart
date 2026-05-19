import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/openai_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

/// Replays canned chat-completions chunks; a `null` entry emits the `[DONE]`
/// sentinel.
class _FakeHttp extends ProviderHttp {
  _FakeHttp(this.chunks);

  final List<Map<String, dynamic>?> chunks;

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    for (final chunk in chunks) {
      yield SseMessage(
        event: null,
        data: chunk == null ? '[DONE]' : jsonEncode(chunk),
      );
    }
  }
}

void main() {
  group('OpenAiProvider', () {
    test('accumulates content + tool-call deltas across chunks', () async {
      final http = _FakeHttp([
        {
          'choices': [
            {
              'delta': {'content': 'Hi'},
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'function': {'name': 'read', 'arguments': '{"path":'},
                  },
                ],
              },
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'function': {'arguments': '"a.txt"}'},
                  },
                ],
              },
            },
          ],
        },
        {
          'choices': [
            {'finish_reason': 'tool_calls'},
          ],
        },
        {
          'usage': {'prompt_tokens': 7, 'completion_tokens': 3},
        },
        null,
      ]);
      final provider = OpenAiProvider(apiKey: 'k', http: http);

      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();

      expect(events.whereType<LlmTextDelta>().map((e) => e.text).join(), 'Hi');
      final toolUse = events.whereType<LlmToolUseDelta>().single;
      expect(toolUse.id, 'call_1');
      expect(toolUse.name, 'read');
      expect(toolUse.argumentsJson, '{"path":"a.txt"}');
      expect(
        events.whereType<LlmDone>().single.stopReason,
        LlmStopReason.toolUse,
      );
      expect(events.whereType<LlmUsage>().single.inputTokens, 7);
    });

    test(
      'extractThinkTags splits <think> content into thinking deltas',
      () async {
        final http = _FakeHttp([
          {
            'choices': [
              {
                'delta': {'content': '<think>reasoning</think>answer'},
              },
            ],
          },
          {
            'choices': [
              {'finish_reason': 'stop'},
            ],
          },
          null,
        ]);
        final provider = OpenAiProvider(
          apiKey: 'k',
          extractThinkTags: true,
          http: http,
        );
        final events = await provider
            .complete(messages: [HarnessMessage.user('hi')])
            .toList();
        expect(
          events.whereType<LlmThinkingDelta>().map((e) => e.thinking).join(),
          'reasoning',
        );
        expect(
          events.whereType<LlmTextDelta>().map((e) => e.text).join(),
          'answer',
        );
      },
    );
  });
}
