import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

/// Captures the request body and replays a scripted thinking + text stream that
/// includes a `signature_delta` on the thinking block.
class _ThinkingHttp extends ProviderHttp {
  Map<String, dynamic>? body;

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    this.body = body;
    SseMessage ev(Map<String, dynamic> m) =>
        SseMessage(event: m['type'] as String, data: jsonEncode(m));
    yield ev({
      'type': 'content_block_start',
      'index': 0,
      'content_block': {'type': 'thinking'},
    });
    yield ev({
      'type': 'content_block_delta',
      'index': 0,
      'delta': {'type': 'thinking_delta', 'thinking': 'Let me think.'},
    });
    yield ev({
      'type': 'content_block_delta',
      'index': 0,
      'delta': {'type': 'signature_delta', 'signature': 'SIG123'},
    });
    yield ev({'type': 'content_block_stop', 'index': 0});
    yield ev({
      'type': 'content_block_start',
      'index': 1,
      'content_block': {'type': 'text'},
    });
    yield ev({
      'type': 'content_block_delta',
      'index': 1,
      'delta': {'type': 'text_delta', 'text': 'Answer.'},
    });
    yield ev({'type': 'content_block_stop', 'index': 1});
    yield ev({'type': 'message_stop'});
  }
}

void main() {
  test(
    'captures signature_delta and emits it as a thinking signature',
    () async {
      final http = _ThinkingHttp();
      final provider = AnthropicProvider(apiKey: 'sk', http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      final sig = events
          .whereType<LlmThinkingDelta>()
          .firstWhere((e) => e.signature != null)
          .signature;
      expect(sig, 'SIG123');
    },
  );

  test('effort adds adaptive thinking + output_config.effort', () async {
    final http = _ThinkingHttp();
    final provider = AnthropicProvider(apiKey: 'sk', http: http);
    await provider
        .complete(
          messages: [HarnessMessage.user('hi')],
          config: const LlmCompleteConfig(effort: ReasoningEffort.high),
        )
        .toList();
    expect(http.body?['thinking'], {
      'type': 'adaptive',
      'display': 'summarized',
    });
    expect(http.body?['output_config'], {'effort': 'high'});
  });

  test('no effort omits thinking entirely', () async {
    final http = _ThinkingHttp();
    final provider = AnthropicProvider(apiKey: 'sk', http: http);
    await provider.complete(messages: [HarnessMessage.user('hi')]).toList();
    expect(http.body?.containsKey('thinking'), isFalse);
    expect(http.body?.containsKey('output_config'), isFalse);
  });

  test(
    'cache_control marks system, last tool and last message block',
    () async {
      final http = _ThinkingHttp();
      final provider = AnthropicProvider(apiKey: 'sk', http: http);
      await provider
          .complete(
            messages: [HarnessMessage.user('hi')],
            tools: const [
              LlmToolSchema(name: 'a', description: 'A', inputSchema: {}),
              LlmToolSchema(name: 'b', description: 'B', inputSchema: {}),
            ],
            config: const LlmCompleteConfig(systemPrompt: 'Sys'),
          )
          .toList();

      // The stable prefix (tools + system) rides the long TTL: it is constant
      // for the run and shared across runs, so it must survive a gap.
      const stable = {'type': 'ephemeral', 'ttl': '1h'};
      final system = http.body?['system'] as List;
      expect((system.last as Map)['cache_control'], stable);

      final tools = http.body?['tools'] as List;
      expect((tools.last as Map)['cache_control'], stable);
      expect((tools.first as Map).containsKey('cache_control'), isFalse);

      // The tail is rewritten every turn, so it stays on the short window.
      final messages = http.body?['messages'] as List;
      final lastContent = (messages.last as Map)['content'] as List;
      expect((lastContent.last as Map)['cache_control'], {'type': 'ephemeral'});
    },
  );

  test('the tools breakpoint sits on the last RESIDENT tool', () async {
    final http = _ThinkingHttp();
    final provider = AnthropicProvider(apiKey: 'sk', http: http);
    await provider
        .complete(
          messages: [HarnessMessage.user('hi')],
          tools: const [
            LlmToolSchema(name: 'a', description: 'A', inputSchema: {}),
            LlmToolSchema(name: 'b', description: 'B', inputSchema: {}),
            // Activated mid-run; appended AFTER the breakpoint so the cached
            // prefix stays byte-identical.
            LlmToolSchema(name: 'c', description: 'C', inputSchema: {}),
          ],
          config: const LlmCompleteConfig(
            systemPrompt: 'Sys',
            toolCacheBreakpointIndex: 1,
          ),
        )
        .toList();

    final tools = http.body?['tools'] as List;
    expect((tools[1] as Map)['cache_control'], {
      'type': 'ephemeral',
      'ttl': '1h',
    });
    expect((tools.last as Map).containsKey('cache_control'), isFalse);
  });

  test('an out-of-range breakpoint index clamps instead of throwing', () async {
    final http = _ThinkingHttp();
    final provider = AnthropicProvider(apiKey: 'sk', http: http);
    await provider
        .complete(
          messages: [HarnessMessage.user('hi')],
          tools: const [
            LlmToolSchema(name: 'a', description: 'A', inputSchema: {}),
          ],
          config: const LlmCompleteConfig(toolCacheBreakpointIndex: 99),
        )
        .toList();
    final tools = http.body?['tools'] as List;
    expect((tools.last as Map).containsKey('cache_control'), isTrue);
  });

  test('the rolling anchor marks the previous turn tail as well', () async {
    final http = _ThinkingHttp();
    final provider = AnthropicProvider(apiKey: 'sk', http: http);
    await provider
        .complete(
          messages: [
            HarnessMessage.user('one'),
            HarnessMessage.assistant('ok'),
            HarnessMessage.user('two'),
          ],
          // Where the previous request wrote. Two breakpoints in the message
          // lane give two independent lookback windows, which is what keeps a
          // wide parallel-tool turn from overrunning a single one.
          config: const LlmCompleteConfig(cacheAnchorIndex: 0),
        )
        .toList();

    final messages = http.body?['messages'] as List;
    final anchored = (messages[0] as Map)['content'] as List;
    expect((anchored.last as Map)['cache_control'], {'type': 'ephemeral'});
    final tail = (messages.last as Map)['content'] as List;
    expect((tail.last as Map)['cache_control'], {'type': 'ephemeral'});
    // Nothing in between: four breakpoints total is the hard ceiling.
    final middle = (messages[1] as Map)['content'] as List;
    expect((middle.last as Map).containsKey('cache_control'), isFalse);
  });

  test('a five-minute stable TTL sends no ttl field', () async {
    final http = _ThinkingHttp();
    final provider = AnthropicProvider(apiKey: 'sk', http: http);
    await provider
        .complete(
          messages: [HarnessMessage.user('hi')],
          tools: const [
            LlmToolSchema(name: 'a', description: 'A', inputSchema: {}),
          ],
          config: const LlmCompleteConfig(
            systemPrompt: 'Sys',
            stablePrefixTtl: LlmCacheTtl.fiveMinutes,
          ),
        )
        .toList();
    final tools = http.body?['tools'] as List;
    expect((tools.last as Map)['cache_control'], {'type': 'ephemeral'});
  });

  test(
    'cacheEnabled:false sends a plain string system and no breakpoints',
    () async {
      final http = _ThinkingHttp();
      final provider = AnthropicProvider(apiKey: 'sk', http: http);
      await provider
          .complete(
            messages: [HarnessMessage.user('hi')],
            config: const LlmCompleteConfig(
              systemPrompt: 'Sys',
              cacheEnabled: false,
            ),
          )
          .toList();
      expect(http.body?['system'], 'Sys');
    },
  );
}
