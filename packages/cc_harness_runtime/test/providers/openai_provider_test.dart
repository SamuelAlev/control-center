import 'dart:async';
import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/openai_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

/// Exercises [OpenAiProvider] via a stubbed [ProviderHttp]. Covers: text
/// streaming, usage parsing (incl. cached/reasoning split), reasoning_content
/// surfacing, think-tag extraction, tool-call assembly (incl. missing ids),
/// stop-reason resolution, listModels catalog parsing with pricing, and error
/// handling (HTTP error → LlmError with retryable flag).
void main() {
  group('OpenAiProvider.complete — text streaming', () {
    test(
      'emits LlmTextDelta + LlmDone(endTurn) for a plain completion',
      () async {
        final http = _ScriptedHttp(
          sse: [
            _delta(content: 'Hello'),
            _delta(content: ', world'),
            _delta(finishReason: 'stop'),
          ],
        );
        final provider = OpenAiProvider(http: http);
        final events = await provider
            .complete(messages: [HarnessMessage.user('hi')])
            .toList();

        final texts = events
            .whereType<LlmTextDelta>()
            .map((e) => e.text)
            .join();
        expect(texts, 'Hello, world');
        final done = events.whereType<LlmDone>().single;
        expect(done.stopReason, LlmStopReason.endTurn);
      },
    );

    test('stops at [DONE] sentinel', () async {
      final http = _ScriptedHttp(
        sse: [
          _delta(content: 'a'),
          const SseMessage(event: null, data: '[DONE]'),
          _delta(content: 'should-not-emit'),
        ],
      );
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events.whereType<LlmTextDelta>().map((e) => e.text).join(), 'a');
    });

    test('skips malformed JSON payloads', () async {
      final http = _ScriptedHttp(
        sse: [
          const SseMessage(event: null, data: 'not json'),
          _delta(content: 'ok', finishReason: 'stop'),
        ],
      );
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events.whereType<LlmTextDelta>().map((e) => e.text).join(), 'ok');
    });
  });

  group('OpenAiProvider.complete — usage', () {
    test('parses usage incl. cached and reasoning splits', () async {
      final http = _ScriptedHttp(
        sse: [
          SseMessage(
            event: null,
            data: jsonEncode({
              'usage': {
                'prompt_tokens': 100,
                'completion_tokens': 30,
                'prompt_tokens_details': {'cached_tokens': 25},
                'completion_tokens_details': {'reasoning_tokens': 10},
              },
            }),
          ),
          _delta(finishReason: 'stop'),
        ],
      );
      final provider = OpenAiProvider(http: http);
      final usage =
          (await provider
                  .complete(messages: [HarnessMessage.user('hi')])
                  .toList())
              .whereType<LlmUsage>()
              .single;
      expect(usage.inputTokens, 75); // 100 - 25 cached
      expect(usage.outputTokens, 30);
      expect(usage.cacheReadTokens, 25);
      expect(usage.thoughtTokens, 10);
    });

    test('omits usage block when absent', () async {
      final http = _ScriptedHttp(
        sse: [_delta(content: 'x', finishReason: 'stop')],
      );
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events.whereType<LlmUsage>(), isEmpty);
    });
  });

  group('OpenAiProvider.complete — reasoning', () {
    test('surfaces reasoning_content as LlmThinkingDelta', () async {
      final http = _ScriptedHttp(
        sse: [
          _delta(reasoning: 'pondering'),
          _delta(content: 'answer', finishReason: 'stop'),
        ],
      );
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      final thinking = events
          .whereType<LlmThinkingDelta>()
          .map((e) => e.thinking)
          .join();
      expect(thinking, 'pondering');
    });
  });

  group('OpenAiProvider.complete — think tags', () {
    test('splits <think>…</think> into thinking + text', () async {
      final http = _ScriptedHttp(
        sse: [
          _delta(content: '<think>secret'),
          _delta(content: '</think>visible'),
          _delta(finishReason: 'stop'),
        ],
      );
      final provider = OpenAiProvider(http: http, extractThinkTags: true);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      final thinking = events
          .whereType<LlmThinkingDelta>()
          .map((e) => e.thinking)
          .join();
      final text = events.whereType<LlmTextDelta>().map((e) => e.text).join();
      expect(thinking, 'secret');
      expect(text, 'visible');
    });

    test('holds a partial <think> tag split across chunks', () async {
      final http = _ScriptedHttp(
        sse: [
          _delta(content: 'a<thi'),
          _delta(content: 'nk>x</think>b', finishReason: 'stop'),
        ],
      );
      final provider = OpenAiProvider(http: http, extractThinkTags: true);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      final text = events.whereType<LlmTextDelta>().map((e) => e.text).join();
      final thinking = events
          .whereType<LlmThinkingDelta>()
          .map((e) => e.thinking)
          .join();
      expect(text, 'ab');
      expect(thinking, 'x');
    });
  });

  group('OpenAiProvider.complete — tool calls', () {
    test('assembles streamed tool-call deltas', () async {
      final http = _ScriptedHttp(
        sse: [
          SseMessage(
            event: null,
            data: jsonEncode({
              'choices': [
                {
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'id': 'call_1',
                        'function': {
                          'name': 'get_weather',
                          'arguments': '{"city"',
                        },
                      },
                    ],
                  },
                },
              ],
            }),
          ),
          SseMessage(
            event: null,
            data: jsonEncode({
              'choices': [
                {
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'function': {'arguments': ': "SF"}'},
                      },
                    ],
                  },
                },
              ],
            }),
          ),
          _delta(finishReason: 'tool_calls'),
        ],
      );
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      final tool = events.whereType<LlmToolUseDelta>().single;
      expect(tool.id, 'call_1');
      expect(tool.name, 'get_weather');
      expect(tool.argumentsJson, '{"city": "SF"}');
      final done = events.whereType<LlmDone>().single;
      expect(done.stopReason, LlmStopReason.toolUse);
    });

    test(
      'synthesizes call_\$index id when missing and infers toolUse stop',
      () async {
        final http = _ScriptedHttp(
          sse: [
            SseMessage(
              event: null,
              data: jsonEncode({
                'choices': [
                  {
                    'delta': {
                      'tool_calls': [
                        {
                          'index': 0,
                          'function': {'name': 'noop', 'arguments': '{}'},
                        },
                      ],
                    },
                  },
                ],
              }),
            ),
          ],
        );
        final provider = OpenAiProvider(http: http);
        final events = await provider
            .complete(messages: [HarnessMessage.user('hi')])
            .toList();
        final tool = events.whereType<LlmToolUseDelta>().single;
        expect(tool.id, 'call_0');
        // No explicit finish_reason: stopReason is inferred as toolUse.
        expect(
          events.whereType<LlmDone>().single.stopReason,
          LlmStopReason.toolUse,
        );
      },
    );

    test('uses {} when arguments delta is empty', () async {
      final http = _ScriptedHttp(
        sse: [
          SseMessage(
            event: null,
            data: jsonEncode({
              'choices': [
                {
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'id': 'c0',
                        'function': {'name': 'ping'},
                      },
                    ],
                  },
                  'finish_reason': 'tool_calls',
                },
              ],
            }),
          ),
        ],
      );
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      final tool = events.whereType<LlmToolUseDelta>().single;
      expect(tool.argumentsJson, '{}');
    });

    test('drops a tool call with no name', () async {
      final http = _ScriptedHttp(
        sse: [
          SseMessage(
            event: null,
            data: jsonEncode({
              'choices': [
                {
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'function': {'arguments': '{}'},
                      },
                    ],
                  },
                  'finish_reason': 'tool_calls',
                },
              ],
            }),
          ),
        ],
      );
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events.whereType<LlmToolUseDelta>(), isEmpty);
    });
  });

  group('OpenAiProvider.complete — request building', () {
    test(
      'includes system prompt, model, max_tokens, and cache key when supported',
      () async {
        final http = _ScriptedHttp(sse: [_delta(finishReason: 'stop')]);
        final provider = OpenAiProvider(
          http: http,
          supportsPromptCacheKey: true,
        );
        await provider
            .complete(
              messages: [HarnessMessage.user('hi')],
              config: const LlmCompleteConfig(
                systemPrompt: 'be nice',
                model: 'gpt-4o-mini',
                maxTokens: 128,
                cacheEnabled: true,
                cacheKey: 'k1',
              ),
            )
            .toList();
        final body = http.lastBody!;
        expect(body['model'], 'gpt-4o-mini');
        expect(body['max_tokens'], 128);
        expect(body['stream'], isTrue);
        expect(body['prompt_cache_key'], 'k1');
        expect((body['messages'] as List).first, {
          'role': 'system',
          'content': 'be nice',
        });
      },
    );

    test('omits prompt_cache_key when not supported', () async {
      final http = _ScriptedHttp(sse: [_delta(finishReason: 'stop')]);
      final provider = OpenAiProvider(http: http);
      await provider
          .complete(
            messages: [HarnessMessage.user('hi')],
            config: const LlmCompleteConfig(cacheEnabled: true, cacheKey: 'k1'),
          )
          .toList();
      expect(http.lastBody!.containsKey('prompt_cache_key'), isFalse);
    });

    test('serializes assistant tool_calls back into the request', () async {
      final http = _ScriptedHttp(sse: [_delta(finishReason: 'stop')]);
      final provider = OpenAiProvider(http: http);
      await provider
          .complete(
            messages: [
              HarnessMessage.user('hi'),
              const HarnessMessage(
                role: HarnessRole.assistant,
                content: [
                  HarnessToolUseBlock(
                    id: 't1',
                    name: 'get_weather',
                    input: {'a': 1},
                  ),
                ],
              ),
            ],
          )
          .toList();
      final messages = http.lastBody!['messages'] as List;
      final assistant = messages.last as Map<String, dynamic>;
      expect(assistant['role'], 'assistant');
      final calls = assistant['tool_calls'] as List;
      final function = (calls.single as Map)['function'] as Map;
      expect(function['arguments'], '{"a":1}');
    });

    test('includes tools when provided', () async {
      final http = _ScriptedHttp(sse: [_delta(finishReason: 'stop')]);
      final provider = OpenAiProvider(http: http);
      await provider
          .complete(
            messages: [HarnessMessage.user('hi')],
            tools: const [
              LlmToolSchema(
                name: 'get_weather',
                description: 'Weather lookup',
                inputSchema: {'type': 'object'},
              ),
            ],
          )
          .toList();
      final tools = http.lastBody!['tools'] as List;
      expect(((tools.single as Map)['function'] as Map)['name'], 'get_weather');
    });
  });

  group('OpenAiProvider.complete — errors', () {
    test('HTTP 429 → retryable LlmError + LlmDone', () async {
      final http = _ScriptedHttp.throws(
        ProviderHttpException(
          429,
          'rate limited',
          retryAfter: const Duration(seconds: 2),
        ),
      );
      final provider = OpenAiProvider(http: http, providerName: 'TestProvider');
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      final err = events.whereType<LlmError>().single;
      expect(err.retryable, isTrue);
      expect(err.retryAfterMs, 2000);
      expect(err.code, 'http_429');
      expect(err.message, contains('TestProvider API error 429'));
      expect(events.whereType<LlmDone>(), hasLength(1));
    });

    test('HTTP 401 → non-retryable LlmError', () async {
      final http = _ScriptedHttp.throws(ProviderHttpException(401, 'no key'));
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events.whereType<LlmError>().single.retryable, isFalse);
    });

    test('HTTP 503 → retryable LlmError', () async {
      final http = _ScriptedHttp.throws(ProviderHttpException(503, 'down'));
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events.whereType<LlmError>().single.retryable, isTrue);
    });

    test('non-HTTP exception → retryable LlmError', () async {
      final http = _ScriptedHttp.throws(StateError('socket died'));
      final provider = OpenAiProvider(http: http);
      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();
      expect(events.whereType<LlmError>().single.retryable, isTrue);
    });
  });

  group('OpenAiProvider.complete — expiring OAuth bearers', () {
    test('resolves the bearer per request, not once at build time', () async {
      // A Kimi Code token lives ~15 minutes, so the token that was current when
      // the provider was built is not the token the next turn must send.
      final http = _AuthScriptedHttp(sse: [_delta(finishReason: 'stop')]);
      final tokens = _TokenScript();
      final provider = OpenAiProvider(
        http: http,
        apiKey: 'built-at-start',
        tokenResolver: tokens.resolve,
      );

      await provider.complete(messages: [HarnessMessage.user('hi')]).toList();
      await provider
          .complete(messages: [HarnessMessage.user('again')])
          .toList();

      expect(http.bearers, ['Bearer t1', 'Bearer t2']);
      expect(tokens.forced, [false, false]);
    });

    test('a 401 re-mints the bearer and retries once', () async {
      final http = _AuthScriptedHttp(
        unauthorizedCalls: 1,
        sse: [
          _delta(content: 'ok'),
          _delta(finishReason: 'stop'),
        ],
      );
      final tokens = _TokenScript();
      final provider = OpenAiProvider(
        http: http,
        tokenResolver: tokens.resolve,
      );

      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();

      // The rejected token was re-minted (force), and the run continued.
      expect(tokens.forced, [false, true]);
      expect(http.bearers, ['Bearer t1', 'Bearer t2']);
      expect(events.whereType<LlmError>(), isEmpty);
      expect(events.whereType<LlmTextDelta>().map((e) => e.text).join(), 'ok');
    });

    test('a 401 that survives the retry reports how to fix it', () async {
      final http = _AuthScriptedHttp(unauthorizedCalls: 2);
      final tokens = _TokenScript();
      final provider = OpenAiProvider(
        http: http,
        providerName: 'Kimi Code',
        tokenResolver: tokens.resolve,
      );

      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();

      // Exactly one retry — a dead account must not spin.
      expect(http.bearers, hasLength(2));
      final err = events.whereType<LlmError>().single;
      expect(err.retryable, isFalse);
      expect(err.message, contains('Kimi Code API error 401'));
      expect(err.message, contains('Reconnect the account'));
    });

    test('an API key never retries — the key did not change', () async {
      final http = _AuthScriptedHttp(unauthorizedCalls: 2);
      final provider = OpenAiProvider(http: http, apiKey: 'k');

      final events = await provider
          .complete(messages: [HarnessMessage.user('hi')])
          .toList();

      expect(http.bearers, ['Bearer k']);
      expect(
        events.whereType<LlmError>().single.message,
        isNot(contains('Reconnect')),
      );
    });

    test(
      'a resolver that comes up empty falls back to the static key',
      () async {
        final http = _AuthScriptedHttp(sse: [_delta(finishReason: 'stop')]);
        final provider = OpenAiProvider(
          http: http,
          apiKey: 'fallback-key',
          tokenResolver: ({bool force = false}) async => null,
        );

        await provider.complete(messages: [HarnessMessage.user('hi')]).toList();
        expect(http.bearers, ['Bearer fallback-key']);
      },
    );
  });

  group('OpenAiProvider.listModels', () {
    test('parses the OpenAI catalog', () async {
      final http = _FakeCatalogHttp(
        body: jsonEncode({
          'data': [
            {'id': 'gpt-4o'},
            {'id': 'gpt-4o-mini', 'context_length': 128000},
            'not-a-map',
          ],
        }),
      );
      final provider = OpenAiProvider(http: http);
      final models = await provider.listModels();
      expect(models.map((m) => m.id).toList(), ['gpt-4o', 'gpt-4o-mini']);
      expect(models.last.contextWindow, 128000);
    });

    test('parses OpenRouter pricing into per-1M costs', () async {
      final http = _FakeCatalogHttp(
        body: jsonEncode({
          'data': [
            {
              'id': 'llama-3',
              'pricing': {'prompt': '0.000001', 'completion': '0.000002'},
            },
          ],
        }),
      );
      final provider = OpenAiProvider(http: http);
      final models = await provider.listModels();
      expect(models.single.inputCostPerMTokens, 1.0);
      expect(models.single.outputCostPerMTokens, 2.0);
    });

    test('returns empty on HTTP error', () async {
      final http = _CatalogThrowingHttp();
      final provider = OpenAiProvider(http: http);
      expect(await provider.listModels(), isEmpty);
    });

    test('exposes displayName and defaultModel', () {
      final provider = OpenAiProvider(
        http: _FakeCatalogHttp(body: '{}'),
        defaultModel: 'gpt-4o',
        providerName: 'OpenAI',
      );
      expect(provider.displayName, 'OpenAI');
      expect(provider.defaultModel, 'gpt-4o');
    });
  });
}

/// Builds a chat-completion SSE delta message.
SseMessage _delta({String? content, String? reasoning, String? finishReason}) {
  final delta = <String, dynamic>{};
  if (content != null) {
    delta['content'] = content;
  }
  if (reasoning != null) {
    delta['reasoning_content'] = reasoning;
  }
  return SseMessage(
    event: null,
    data: jsonEncode({
      'choices': [
        {'delta': delta, 'finish_reason': ?finishReason},
      ],
    }),
  );
}

/// A [ProviderHttp] that replays a canned list of SSE messages for `postSse`
/// and records the request body. Throws for `getJson` by default.
class _ScriptedHttp implements ProviderHttp {
  _ScriptedHttp({required this.sse}) : _throw = null;
  _ScriptedHttp.throws(this._throw) : sse = const [];

  final List<SseMessage> sse;
  final Object? _throw;
  Map<String, dynamic>? lastBody;

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    lastBody = body;
    if (_throw != null) {
      throw _throw;
    }
    for (final m in sse) {
      yield m;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

/// A [ProviderHttp] that 401s its first [unauthorizedCalls] attempts and then
/// replays [sse], recording the bearer each attempt carried.
class _AuthScriptedHttp implements ProviderHttp {
  _AuthScriptedHttp({this.unauthorizedCalls = 0, this.sse = const []});

  final int unauthorizedCalls;
  final List<SseMessage> sse;

  /// One entry per attempt, in order.
  final List<String?> bearers = [];

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    bearers.add(headers['Authorization']);
    if (bearers.length <= unauthorizedCalls) {
      throw ProviderHttpException(401, '{"error":{"message":"expired"}}');
    }
    for (final m in sse) {
      yield m;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

/// A [ProviderTokenResolver] handing out `t1`, `t2`, … and recording whether
/// each call asked for a forced re-mint.
class _TokenScript {
  int issued = 0;
  final List<bool> forced = [];

  Future<String?> resolve({bool force = false}) async {
    forced.add(force);
    issued++;
    return 't$issued';
  }
}

/// A [ProviderHttp] returning a canned JSON body for `getJson`.
class _FakeCatalogHttp implements ProviderHttp {
  _FakeCatalogHttp({required this.body});
  final String body;

  @override
  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    return jsonDecode(body) as Map<String, dynamic>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _CatalogThrowingHttp implements ProviderHttp {
  @override
  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    throw ProviderHttpException(500, 'boom');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
