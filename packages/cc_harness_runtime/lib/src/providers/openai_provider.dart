import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// Talks to an OpenAI-compatible Chat Completions API
/// (`POST /v1/chat/completions`, streaming SSE).
///
/// The same implementation drives OpenAI, OpenRouter, Groq, LM Studio and
/// other OpenAI-compatible endpoints — only the base URL and auth differ. The
/// local Ollama provider subclasses it.
class OpenAiProvider implements LlmProviderPort {
  /// Creates an [OpenAiProvider].
  OpenAiProvider({
    String? apiKey,
    ProviderTokenResolver? tokenResolver,
    String baseUrl = 'https://api.openai.com/v1',
    String defaultModel = 'gpt-4o',
    String providerName = 'OpenAI',
    bool extractThinkTags = false,
    bool supportsReasoningEffort = false,
    bool supportsPromptCacheKey = false,
    Map<String, String> extraHeaders = const {},
    ProviderHttp? http,
  }) : _apiKey = apiKey,
       _tokenResolver = tokenResolver,
       _baseUrl = baseUrl,
       _defaultModel = defaultModel,
       _providerName = providerName,
       _extractThinkTags = extractThinkTags,
       _supportsReasoningEffort = supportsReasoningEffort,
       _supportsPromptCacheKey = supportsPromptCacheKey,
       _extraHeaders = extraHeaders,
       _http = http ?? ProviderHttp.shared;

  final String? _apiKey;

  /// Resolves the bearer just before each request, for credentials whose token
  /// expires (OAuth). Null for a static API key.
  final ProviderTokenResolver? _tokenResolver;
  final String _baseUrl;
  final String _defaultModel;
  final String _providerName;

  /// Extra request headers (e.g. an OAuth account id) merged into every call.
  final Map<String, String> _extraHeaders;

  /// Some local reasoning models (QwQ, DeepSeek-R1) emit `<think>…</think>`
  /// tags in the content stream; when true, that text is surfaced as
  /// [LlmThinkingDelta] instead of [LlmTextDelta].
  final bool _extractThinkTags;

  /// Whether this endpoint/model accepts a `reasoning_effort` field (OpenAI
  /// reasoning models, some routers). Others 400 on it, so it is gated.
  final bool _supportsReasoningEffort;

  /// Whether this endpoint accepts an explicit `prompt_cache_key`.
  final bool _supportsPromptCacheKey;
  final ProviderHttp _http;

  @override
  String get displayName => _providerName;

  @override
  String get defaultModel => _defaultModel;

  /// Auth + extra headers shared by streaming and catalog requests.
  ///
  /// Resolved per request: an OAuth bearer expires mid-run (a Kimi Code token
  /// lives ~15 minutes), so capturing it when the provider was built is what
  /// turns a long run into a 401. [force] re-mints the token even when it still
  /// looks valid — the answer to a server that rejected it anyway.
  Future<Map<String, String>> _authHeaders({bool force = false}) async {
    final resolver = _tokenResolver;
    final token = resolver == null
        ? _apiKey
        : (await resolver(force: force)) ?? _apiKey;
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ..._extraHeaders,
    };
  }

  @override
  Future<List<ProviderModel>> listModels() async {
    try {
      final json = await _http.getJson(
        Uri.parse('$_baseUrl/models'),
        headers: await _authHeaders(),
      );
      final data = json['data'] as List<dynamic>?;
      if (data == null) {
        return const [];
      }
      return [
        for (final m in data)
          if (m is Map<String, dynamic> && m['id'] is String)
            ProviderModel(
              id: m['id'] as String,
              displayName: m['name'] as String?,
              // OpenRouter reports per-token pricing as strings; scale to per-1M.
              inputCostPerMTokens: _perMillion(_pricing(m)?['prompt']),
              outputCostPerMTokens: _perMillion(_pricing(m)?['completion']),
              contextWindow: (m['context_length'] as num?)?.toInt(),
            ),
      ];
    } on Object {
      return const [];
    }
  }

  static Map<String, dynamic>? _pricing(Map<String, dynamic> model) {
    final pricing = model['pricing'];
    return pricing is Map<String, dynamic> ? pricing : null;
  }

  static double? _perMillion(Object? perToken) {
    if (perToken == null) {
      return null;
    }
    final value = perToken is num
        ? perToken.toDouble()
        : double.tryParse('$perToken');
    return value == null ? null : value * 1000000;
  }

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final uri = Uri.parse('$_baseUrl/chat/completions');
    final body = _buildRequest(messages, tools, config);

    // Tool-call accumulators keyed by choice index.
    final toolIds = <int, String>{};
    final toolNames = <int, String>{};
    final toolArgs = <int, StringBuffer>{};
    var stopReason = LlmStopReason.unknown;
    var sawToolCalls = false;
    final thinkSplitter = _ThinkSplitter();
    // Every assistant text character, kept so a tool call the model wrote as
    // prose can still be recovered at end of stream (see [TextToolCallSalvage]).
    final assistantText = StringBuffer();
    // Withholds text from the moment it starts looking like a tool-call
    // envelope, so a recovered call never also renders as XML soup in the
    // transcript. Released verbatim when nothing is recovered.
    final textGate = _ToolTextGate();
    final knownToolNames = {for (final t in tools) t.name};

    try {
      final stream = await _http.postSseReauthorizing(
        uri,
        headers: _authHeaders,
        body: body,
        retryOnUnauthorized: _tokenResolver != null,
      );
      await for (final sse in stream) {
        final data = sse.data.trim();
        if (data.isEmpty) {
          continue;
        }
        if (data == '[DONE]') {
          break;
        }
        final Map<String, dynamic> json;
        try {
          json = jsonDecode(data) as Map<String, dynamic>;
        } on FormatException {
          continue;
        }

        final usage = json['usage'] as Map<String, dynamic>?;
        if (usage != null) {
          final prompt = (usage['prompt_tokens'] as num?)?.toInt() ?? 0;
          // Cached prompt tokens are billed at the discounted cache-read rate;
          // OpenAI reports them inside prompt_tokens, so split them out so cost
          // isn't over-charged at the full input rate.
          final promptDetails =
              usage['prompt_tokens_details'] as Map<String, dynamic>?;
          final cached =
              (promptDetails?['cached_tokens'] as num?)?.toInt() ?? 0;
          final completionDetails =
              usage['completion_tokens_details'] as Map<String, dynamic>?;
          final reasoning =
              (completionDetails?['reasoning_tokens'] as num?)?.toInt() ?? 0;
          yield LlmUsage(
            inputTokens: (prompt - cached).clamp(0, prompt),
            outputTokens: (usage['completion_tokens'] as num?)?.toInt() ?? 0,
            cacheReadTokens: cached,
            thoughtTokens: reasoning,
          );
        }

        final choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          continue;
        }
        final choice = choices.first as Map<String, dynamic>;
        final delta = choice['delta'] as Map<String, dynamic>?;

        // DeepSeek / OpenRouter / some routers stream reasoning as a separate
        // `reasoning_content` (or `reasoning`) delta field — surface it as
        // thinking rather than dropping it.
        final reasoning =
            (delta?['reasoning_content'] ?? delta?['reasoning']) as String?;
        if (reasoning != null && reasoning.isNotEmpty) {
          yield LlmThinkingDelta(reasoning);
        }

        final content = delta?['content'] as String?;
        if (content != null && content.isNotEmpty) {
          if (_extractThinkTags) {
            for (final event in thinkSplitter.split(content)) {
              if (event is LlmTextDelta) {
                assistantText.write(event.text);
                final safe = textGate.add(event.text);
                if (safe.isNotEmpty) {
                  yield LlmTextDelta(safe);
                }
              } else {
                yield event;
              }
            }
          } else {
            assistantText.write(content);
            final safe = textGate.add(content);
            if (safe.isNotEmpty) {
              yield LlmTextDelta(safe);
            }
          }
        }

        final toolCalls = delta?['tool_calls'] as List<dynamic>?;
        if (toolCalls != null) {
          sawToolCalls = true;
          for (final raw in toolCalls) {
            final call = raw as Map<String, dynamic>;
            final index = (call['index'] as num?)?.toInt() ?? 0;
            final fn = call['function'] as Map<String, dynamic>?;
            if (call['id'] != null) {
              toolIds[index] = call['id'] as String;
            }
            if (fn?['name'] != null) {
              toolNames[index] = fn!['name'] as String;
            }
            if (fn?['arguments'] != null) {
              (toolArgs[index] ??= StringBuffer()).write(
                fn!['arguments'] as String,
              );
            }
          }
        }

        final finish = choice['finish_reason'] as String?;
        if (finish != null) {
          stopReason = LlmStopReason.fromWire(finish);
        }
      }

      if (sawToolCalls) {
        // Iterate every index seen across id / name / args deltas — not just
        // those that carried an `id`. Some OpenAI-compatible servers omit the
        // id in streaming deltas; keying on toolIds alone silently dropped
        // those calls. Synthesize `call_$index` when the id is absent.
        final indices = <int>{
          ...toolIds.keys,
          ...toolNames.keys,
          ...toolArgs.keys,
        }.toList()..sort();
        for (final index in indices) {
          final name = toolNames[index];
          if (name == null || name.isEmpty) {
            continue; // incomplete call with no name — cannot invoke
          }
          final raw = toolArgs[index]?.toString() ?? '';
          yield LlmToolUseDelta(
            id: toolIds[index] ?? 'call_$index',
            name: name,
            argumentsJson: raw.isEmpty ? '{}' : raw,
          );
        }
        if (stopReason == LlmStopReason.unknown) {
          stopReason = LlmStopReason.toolUse;
        }
      } else {
        // No structured tool calls arrived. Before accepting the turn as prose,
        // check whether the model wrote its calls as text — a real and recurring
        // failure on local/merged models and on any server whose tool-call
        // parser does not recognize the dialect the model actually emitted. The
        // declared tool list bounds what can be recovered and recovered calls
        // still face the loop's approval gate.
        final salvaged = const TextToolCallSalvage().parse(
          assistantText.toString(),
          knownToolNames: knownToolNames,
        );
        if (salvaged.isEmpty) {
          // Ordinary text after all: release whatever the gate withheld.
          final held = textGate.flush();
          if (held.isNotEmpty) {
            yield LlmTextDelta(held);
          }
        } else {
          for (var i = 0; i < salvaged.length; i++) {
            yield LlmToolUseDelta(
              id: 'salvaged_$i',
              name: salvaged[i].name,
              argumentsJson: jsonEncode(salvaged[i].arguments),
            );
          }
          // Leave a `maxTokens` stop intact — the turn really was cut off and
          // the loop needs that fact for its own accounting.
          if (stopReason != LlmStopReason.maxTokens) {
            stopReason = LlmStopReason.toolUse;
          }
        }
      }
      yield LlmDone(stopReason: stopReason);
    } on ProviderHttpException catch (e) {
      // A 401 that survived the token refresh is an account problem, not a
      // transient one — say so, or the user reads "invalid API key" for an
      // account they never typed a key for.
      final reauth = e.statusCode == 401 && _tokenResolver != null
          ? ' — the OAuth token could not be renewed. Reconnect the account in '
                'Settings → Providers.'
          : '';
      // The body's error code distinguishes a hard quota exhaustion
      // (`insufficient_quota` — billing; retrying the same key can never
      // succeed, so it is NON-retryable and a fallback chain rotates away
      // immediately) from a transient rate limit (retryable, backed off).
      String? wireCode;
      try {
        final decoded = jsonDecode(e.body) as Map<String, dynamic>;
        final err = decoded['error'] as Map<String, dynamic>?;
        wireCode = (err?['code'] ?? err?['type']) as String?;
      } on Object {
        wireCode = null;
      }
      final hardQuota =
          wireCode == 'insufficient_quota' || wireCode == 'billing_not_active';
      yield LlmError(
        '$_providerName API error ${e.statusCode}: ${e.body}$reauth',
        code: wireCode ?? 'http_${e.statusCode}',
        retryable: !hardQuota && (e.statusCode == 429 || e.statusCode >= 500),
        retryAfterMs: e.retryAfter?.inMilliseconds,
      );
      yield const LlmDone(stopReason: LlmStopReason.unknown);
    } on Object catch (e) {
      yield LlmError('$_providerName request failed: $e', retryable: true);
      yield const LlmDone(stopReason: LlmStopReason.unknown);
    }
  }

  Map<String, dynamic> _buildRequest(
    List<HarnessMessage> messages,
    List<LlmToolSchema> tools,
    LlmCompleteConfig config,
  ) {
    final wire = <Map<String, dynamic>>[];
    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      wire.add({'role': 'system', 'content': config.systemPrompt});
    }
    for (final message in messages) {
      switch (message.role) {
        case HarnessRole.system:
          wire.add({'role': 'system', 'content': message.textContent});
        case HarnessRole.user:
          wire.add({'role': 'user', 'content': message.textContent});
        case HarnessRole.tool:
          // A Chat Completions `tool` message carries a string only — there is
          // no image slot in it. Images returned by a tool are therefore
          // relayed as a following `user` turn (the documented workaround),
          // labelled so the model knows they are the tool's output and not a
          // new human instruction. Dropping them instead would make a rig
          // screenshot silently invisible on this provider.
          final trailingImages = <HarnessImageBlock>[];
          for (final block in message.content) {
            if (block is HarnessToolResultBlock) {
              wire.add({
                'role': 'tool',
                'tool_call_id': block.toolUseId,
                'content': block.content,
              });
              trailingImages.addAll(block.images);
            }
          }
          if (trailingImages.isNotEmpty) {
            wire.add({
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Image output from the preceding tool call'
                      '${trailingImages.length > 1 ? 's' : ''}.',
                },
                for (final image in trailingImages)
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:${image.mediaType};base64,${image.data}',
                    },
                  },
              ],
            });
          }
        case HarnessRole.assistant:
          final text = message.textContent;
          final toolUses = message.toolUses;
          wire.add({
            'role': 'assistant',
            if (text.isNotEmpty) 'content': text else 'content': null,
            if (toolUses.isNotEmpty)
              'tool_calls': [
                for (final t in toolUses)
                  {
                    'id': t.id,
                    'type': 'function',
                    'function': {'name': t.name, 'arguments': t.encodedInput},
                  },
              ],
          });
      }
    }

    final request = <String, dynamic>{
      'model': config.model ?? _defaultModel,
      'messages': wire,
      'max_tokens': config.maxTokens,
      'stream': true,
      'stream_options': {'include_usage': true},
    };
    if (tools.isNotEmpty) {
      request['tools'] = [
        for (final tool in tools)
          {
            'type': 'function',
            'function': {
              'name': tool.name,
              'description': tool.description,
              'parameters': tool.inputSchema,
            },
          },
      ];
    }
    if (config.temperature != null) {
      request['temperature'] = config.temperature;
    }
    if (config.topP != null) {
      request['top_p'] = config.topP;
    }
    if (config.topK != null) {
      request['top_k'] = config.topK;
    }
    if (config.stopSequences.isNotEmpty) {
      request['stop'] = config.stopSequences;
    }
    final effort = config.effort;
    if (effort != null && _supportsReasoningEffort) {
      request['reasoning_effort'] = openAiEffort(effort);
    }
    // OpenAI-compatible endpoints cache automatically; an explicit key improves
    // hit rates when the endpoint supports it.
    if (config.cacheEnabled &&
        _supportsPromptCacheKey &&
        config.cacheKey != null) {
      request['prompt_cache_key'] = config.cacheKey;
    }
    return request;
  }
}

/// Withholds streamed text from the moment it starts to look like a tool-call
/// envelope.
///
/// A tool call the model wrote as text is recoverable ([TextToolCallSalvage]),
/// but only at end of stream — the envelope has to be complete before it can be
/// parsed. Streaming the text through in the meantime would put raw XML in the
/// transcript for every salvaged call. So once a tag appears, text is buffered
/// instead of emitted: if a call is recovered the buffer is dropped and if
/// nothing is recovered it is released verbatim, which makes the gate invisible
/// in both outcomes.
///
/// Only tool-call tags trigger it, never a plain `<` — normal prose and code
/// stream through untouched.
class _ToolTextGate {
  /// Tag openings that begin a tool-call envelope in any dialect we recognize.
  static const List<String> _triggers = [
    '<tool_call',
    '<function=',
    '<function ',
    '<function>',
    '<invoke',
    '<parameter',
  ];

  final StringBuffer _held = StringBuffer();
  bool _holding = false;

  /// A trailing run that could be the start of a trigger, held until the next
  /// chunk so a tag split across SSE frames is not leaked.
  String _pending = '';

  /// Feeds [chunk] in and returns the portion safe to emit now.
  String add(String chunk) {
    if (_holding) {
      _held.write(chunk);
      return '';
    }
    var rest = _pending + chunk;
    _pending = '';
    var at = -1;
    for (final trigger in _triggers) {
      final i = rest.indexOf(trigger);
      if (i >= 0 && (at < 0 || i < at)) {
        at = i;
      }
    }
    if (at >= 0) {
      _holding = true;
      _held.write(rest.substring(at));
      return rest.substring(0, at);
    }
    final hold = _partialTriggerSuffix(rest);
    if (hold > 0) {
      _pending = rest.substring(rest.length - hold);
      rest = rest.substring(0, rest.length - hold);
    }
    return rest;
  }

  /// Releases everything withheld and resets. Call this when no tool call was
  /// recovered, so held text still reaches the transcript.
  String flush() {
    final out = '$_pending$_held';
    _pending = '';
    _held.clear();
    _holding = false;
    return out;
  }

  /// The length of the longest suffix of [s] that is a proper prefix of any
  /// trigger, or 0 when there is none.
  static int _partialTriggerSuffix(String s) {
    var best = 0;
    for (final trigger in _triggers) {
      final maxK = trigger.length - 1 < s.length
          ? trigger.length - 1
          : s.length;
      for (var k = maxK; k > best; k--) {
        if (s.substring(s.length - k) == trigger.substring(0, k)) {
          best = k;
          break;
        }
      }
    }
    return best;
  }
}

/// Splits a streamed content string into thinking / text [LlmEvent]s around
/// `<think>`…`</think>` markers, carrying the open/closed state AND any partial
/// tag across chunks — so a `<think>` / `</think>` split across two SSE chunks
/// (e.g. `...<thi` then `nk>...`) is not leaked as literal text.
class _ThinkSplitter {
  bool _inThink = false;

  /// A trailing run that could be the start of a tag, held until the next chunk.
  String _pending = '';

  List<LlmEvent> split(String content) {
    final events = <LlmEvent>[];
    var rest = _pending + content;
    _pending = '';
    while (rest.isNotEmpty) {
      if (_inThink) {
        final close = rest.indexOf('</think>');
        if (close == -1) {
          final hold = _partialTagSuffix(rest, '</think>');
          if (hold > 0) {
            _pending = rest.substring(rest.length - hold);
            rest = rest.substring(0, rest.length - hold);
          }
          if (rest.isNotEmpty) {
            events.add(LlmThinkingDelta(rest));
          }
          rest = '';
        } else {
          if (close > 0) {
            events.add(LlmThinkingDelta(rest.substring(0, close)));
          }
          rest = rest.substring(close + '</think>'.length);
          _inThink = false;
        }
      } else {
        final open = rest.indexOf('<think>');
        if (open == -1) {
          final hold = _partialTagSuffix(rest, '<think>');
          if (hold > 0) {
            _pending = rest.substring(rest.length - hold);
            rest = rest.substring(0, rest.length - hold);
          }
          if (rest.isNotEmpty) {
            events.add(LlmTextDelta(rest));
          }
          rest = '';
        } else {
          if (open > 0) {
            events.add(LlmTextDelta(rest.substring(0, open)));
          }
          rest = rest.substring(open + '<think>'.length);
          _inThink = true;
        }
      }
    }
    return events;
  }

  /// The length of the longest suffix of [s] that is a proper prefix of [tag]
  /// (a possible split tag to hold back), or 0 when there is none.
  static int _partialTagSuffix(String s, String tag) {
    final maxK = tag.length - 1 < s.length ? tag.length - 1 : s.length;
    for (var k = maxK; k >= 1; k--) {
      if (s.substring(s.length - k) == tag.substring(0, k)) {
        return k;
      }
    }
    return 0;
  }
}
