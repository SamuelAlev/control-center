import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_tool_deferral.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// Talks to the Anthropic Messages API (`POST /v1/messages`, streaming SSE).
///
/// Converts the harness message format to Anthropic's wire shape (system prompt
/// as a request field, tool results as user-role content blocks) and decodes
/// the SSE event stream into [LlmEvent]s. Extended thinking uses adaptive mode
/// (`thinking: {type: "adaptive"}`) — the current models reject a fixed
/// `budget_tokens` — and sampling parameters are sent only when explicitly set,
/// since the current models reject them too.
///
/// Implements [LlmDeferredToolSupport]: on a model that supports tool search,
/// schemas marked [LlmToolSchema.deferLoading] travel in the `tools` array with
/// `defer_loading: true` (still sent in full — the API expands references
/// server-side) and a tool result may carry `tool_reference` blocks, so an
/// activation no longer rewrites the cached tools+system prefix.
class AnthropicProvider implements LlmProviderPort, LlmDeferredToolSupport {
  /// Creates an [AnthropicProvider].
  ///
  /// Authenticates with an [_apiKey] (`x-api-key`) and nothing else. A Claude
  /// Pro/Max subscription is NOT an authentication method here: reaching it
  /// would mean minting a token against Claude Code's OAuth client and sending
  /// the `claude-code-20250219` beta plus Claude Code's system identity — that
  /// is presenting this app as Claude Code, which its terms do not allow. Use
  /// the `claude-code` ADAPTER when you want to run on the subscription; it is
  /// Claude Code, driving its own login.
  ///
  /// [_nativeToolSearch] overrides the endpoint's native-deferral capability.
  /// Null (the default) derives it from the base URL, because the same class
  /// serves user-defined Anthropic-COMPATIBLE endpoints (vLLM, LM Studio, a
  /// private gateway) that accept the Messages shape but not `defer_loading` —
  /// and there, a model id that looks like a supported Claude would otherwise
  /// earn a request the endpoint rejects. Set it explicitly only for a proxy
  /// that passes tool search through to the real API.
  AnthropicProvider({
    this._apiKey,
    this._baseUrl = 'https://api.anthropic.com',
    this._defaultModel = 'claude-opus-4-8',
    this._anthropicVersion = '2023-06-01',
    this._nativeToolSearch,
    ProviderHttp? http,
  }) : _http = http ?? ProviderHttp.shared;

  final String? _apiKey;
  final String _baseUrl;
  final String _defaultModel;
  final String _anthropicVersion;
  final bool? _nativeToolSearch;
  final ProviderHttp _http;

  /// Auth + version headers. One credential kind, so no branch.
  Future<Map<String, String>> _authHeaders({bool force = false}) async => {
    'x-api-key': _apiKey ?? '',
    'anthropic-version': _anthropicVersion,
  };

  @override
  String get displayName => 'Anthropic';

  @override
  String get defaultModel => _defaultModel;

  @override
  bool supportsDeferredTools({String? model}) =>
      _supportsNativeToolSearch &&
      anthropicSupportsToolDeferral(model ?? _defaultModel);

  /// Whether this ENDPOINT implements native tool search.
  ///
  /// Derived from the base URL unless explicitly overridden: the official API
  /// is the only endpoint this class can assume implements `defer_loading`.
  bool get _supportsNativeToolSearch =>
      _nativeToolSearch ?? _isAnthropicApiHost(_baseUrl);

  static bool _isAnthropicApiHost(String baseUrl) {
    final host = Uri.tryParse(baseUrl)?.host ?? '';
    return host == 'anthropic.com' || host.endsWith('.anthropic.com');
  }

  @override
  Future<List<ProviderModel>> listModels() async {
    try {
      final json = await _http.getJson(
        Uri.parse('$_baseUrl/v1/models?limit=1000'),
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
              displayName: m['display_name'] as String?,
            ),
      ];
    } on Object {
      return const [];
    }
  }

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final uri = Uri.parse('$_baseUrl/v1/messages');
    final body = _buildRequest(messages, tools, config);

    final Stream<LlmEvent> events;
    try {
      events = _stream(uri, body, config.trace);
    } on ProviderHttpException catch (e) {
      yield _mapHttpError(e);
      yield const LlmDone(stopReason: LlmStopReason.unknown);
      return;
    }
    yield* events;
  }

  Stream<LlmEvent> _stream(
    Uri uri,
    Map<String, dynamic> body,
    LlmCallTrace? trace,
  ) async* {
    // Accumulators keyed by content-block index.
    final toolNames = <int, String>{};
    final toolIds = <int, String>{};
    final toolJson = <int, StringBuffer>{};
    final signatures = <int, StringBuffer>{};
    final blockTypes = <int, String>{};
    var inputTokens = 0;
    var cacheReadTokens = 0;
    var cacheWriteTokens = 0;
    var outputTokens = 0;
    var stopReason = LlmStopReason.unknown;

    try {
      final events = await _http.postSseReauthorizing(
        uri,
        headers: _authHeaders,
        body: body,
        // An API key does not renew, so a 401 is a bad key — retrying the
        // request with the same header would only spend a second round trip.
        retryOnUnauthorized: false,
        // The earliest transport boundary this client can observe: the first
        // byte of the response BODY (headers complete earlier, and the first
        // TCP/TLS byte is not surfaced at all). Reported per response, so an
        // auth retry does not move the boundary already recorded.
        onFirstBodyByte: trace?.transportFirstByte,
        onRequestSent: trace?.requestSent,
      );
      await for (final sse in events) {
        final data = sse.data;
        if (data.isEmpty) {
          continue;
        }
        final Map<String, dynamic> json;
        try {
          json = jsonDecode(data) as Map<String, dynamic>;
        } on FormatException {
          continue;
        }
        final type = json['type'] as String?;
        switch (type) {
          case 'message_start':
            final message = json['message'] as Map<String, dynamic>?;
            // A proxy or router may serve a different model than requested;
            // report the authoritative one so the ledger prices the right row.
            final served = message?['model'] as String?;
            if (served != null) {
              trace?.servedModel(served);
            }
            final usage = message?['usage'] as Map<String, dynamic>?;
            if (usage != null) {
              inputTokens = (usage['input_tokens'] as num?)?.toInt() ?? 0;
              outputTokens = (usage['output_tokens'] as num?)?.toInt() ?? 0;
              cacheReadTokens =
                  (usage['cache_read_input_tokens'] as num?)?.toInt() ?? 0;
              cacheWriteTokens =
                  (usage['cache_creation_input_tokens'] as num?)?.toInt() ?? 0;
              yield LlmUsage(
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
              );
            }
          case 'content_block_start':
            final index = (json['index'] as num?)?.toInt() ?? 0;
            final block = json['content_block'] as Map<String, dynamic>?;
            final blockType = block?['type'] as String?;
            if (blockType != null) {
              blockTypes[index] = blockType;
            }
            if (blockType == 'tool_use') {
              toolIds[index] = block?['id'] as String? ?? '';
              toolNames[index] = block?['name'] as String? ?? '';
              toolJson[index] = StringBuffer();
            }
          case 'content_block_delta':
            final index = (json['index'] as num?)?.toInt() ?? 0;
            final delta = json['delta'] as Map<String, dynamic>?;
            switch (delta?['type']) {
              case 'text_delta':
                yield LlmTextDelta(delta!['text'] as String? ?? '');
              case 'thinking_delta':
                yield LlmThinkingDelta(delta!['thinking'] as String? ?? '');
              case 'input_json_delta':
                toolJson[index]?.write(delta!['partial_json'] as String? ?? '');
              case 'signature_delta':
                (signatures[index] ??= StringBuffer()).write(
                  delta!['signature'] as String? ?? '',
                );
            }
          case 'content_block_stop':
            final index = (json['index'] as num?)?.toInt() ?? 0;
            if (blockTypes[index] == 'tool_use') {
              final raw = toolJson[index]?.toString() ?? '';
              yield LlmToolUseDelta(
                id: toolIds[index] ?? '',
                name: toolNames[index] ?? '',
                argumentsJson: raw.isEmpty ? '{}' : raw,
              );
            } else if (blockTypes[index] == 'thinking') {
              // Emit the assembled block signature (empty-text carrier) so the
              // loop can store it on the thinking block and replay it verbatim
              // on later tool-use turns — the API rejects modified thinking.
              final sig = signatures[index]?.toString() ?? '';
              if (sig.isNotEmpty) {
                yield LlmThinkingDelta('', signature: sig);
              }
            }
          case 'message_delta':
            final delta = json['delta'] as Map<String, dynamic>?;
            final reason = delta?['stop_reason'] as String?;
            if (reason != null) {
              stopReason = LlmStopReason.fromWire(reason);
            }
            final usage = json['usage'] as Map<String, dynamic>?;
            if (usage != null) {
              outputTokens = (usage['output_tokens'] as num?)?.toInt() ?? 0;
              yield LlmUsage(
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
              );
            }
          case 'message_stop':
            yield LlmUsage(
              inputTokens: inputTokens,
              outputTokens: outputTokens,
              cacheReadTokens: cacheReadTokens,
              cacheWriteTokens: cacheWriteTokens,
            );
            yield LlmDone(
              stopReason: stopReason,
              usage: LlmUsage(
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
              ),
            );
            return;
          case 'error':
            // Surface any usage accrued before the error so those tokens are
            // still counted/billed rather than silently lost.
            if (inputTokens > 0 || outputTokens > 0 || cacheReadTokens > 0) {
              yield LlmUsage(
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
              );
            }
            final err = json['error'] as Map<String, dynamic>?;
            final code = err?['type'] as String?;
            yield LlmError(
              err?['message'] as String? ?? 'Anthropic stream error',
              code: code,
              retryable: _isRetryableCode(code),
            );
            yield const LlmDone(stopReason: LlmStopReason.unknown);
            return;
        }
      }
      // Stream ended without an explicit message_stop: still emit usage as an
      // LlmUsage event (the loop counts those, not LlmDone.usage).
      if (inputTokens > 0 || outputTokens > 0 || cacheReadTokens > 0) {
        yield LlmUsage(
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          cacheReadTokens: cacheReadTokens,
          cacheWriteTokens: cacheWriteTokens,
        );
      }
      yield LlmDone(
        stopReason: stopReason,
        usage: LlmUsage(inputTokens: inputTokens, outputTokens: outputTokens),
      );
    } on ProviderHttpException catch (e) {
      yield _mapHttpError(e);
      yield const LlmDone(stopReason: LlmStopReason.unknown);
    } on Object catch (e) {
      yield LlmError('Anthropic request failed: $e', retryable: true);
      yield const LlmDone(stopReason: LlmStopReason.unknown);
    }
  }

  Map<String, dynamic> _buildRequest(
    List<HarnessMessage> messages,
    List<LlmToolSchema> tools,
    LlmCompleteConfig config,
  ) {
    final model = config.model ?? _defaultModel;
    // Native deferral is a capability of the ENDPOINT AND the model, and
    // sending `defer_loading` (or a `tool_reference`) to one that does not
    // implement tool search is a rejected request rather than an ignored field
    // — so the decision is made once, up front, and both the tools array and
    // the message content consult it.
    final deferralSupported = supportsDeferredTools(model: model);
    final toolList = <Map<String, dynamic>>[
      for (final tool in tools)
        {
          'name': tool.name,
          'description': tool.description,
          'input_schema': tool.inputSchema,
          // The definition is still sent in FULL: `defer_loading` controls what
          // enters the context window, not what travels on the wire — the API
          // needs the schema server-side to expand a reference back into it.
          if (deferralSupported && tool.deferLoading) 'defer_loading': true,
        },
    ];
    // When every tool would be deferred the API rejects the request, so the
    // flags are dropped and the catalog is sent plainly (the pre-existing
    // behavior) instead of failing the run.
    final deferralApplied =
        deferralSupported && applyAnthropicDeferral(toolList);
    final availableTools = deferralSupported
        ? {for (final tool in toolList) tool['name'] as String}
        : const <String>{};

    // The stable system prefix. Only the CONFIG system prompt lives here — it
    // must stay byte-identical across turns so the prompt cache hits.
    // Mid-conversation `system` messages (stream-rule reminders, advisor notes,
    // budget steers) are NOT hoisted here; that would mutate the cached prefix
    // on every turn after the first and drop the note's chronological position.
    final systemBlocks = <Map<String, dynamic>>[];
    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      systemBlocks.add({'type': 'text', 'text': config.systemPrompt!});
    }
    final wireMessages = <Map<String, dynamic>>[];
    for (final message in messages) {
      switch (message.role) {
        case HarnessRole.system:
          // Rendered in place as a user-role reminder so it keeps its position
          // and never touches the cached system prefix.
          wireMessages.add({
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    '<system-reminder>\n${message.textContent}\n'
                    '</system-reminder>',
              },
            ],
          });
        case HarnessRole.user:
        case HarnessRole.tool:
          wireMessages.add({
            'role': 'user',
            'content': _userContent(
              message,
              nativeReferences: deferralSupported,
              availableTools: availableTools,
            ),
          });
        case HarnessRole.assistant:
          wireMessages.add({
            'role': 'assistant',
            'content': _assistantContent(message),
          });
      }
    }

    // Four cache breakpoints: (1) last resident tool + (2) last system block
    // on the long TTL (stable prefix); (3) previous turn's tail (read anchor) +
    // (4) this turn's tail (write) as a rolling pair — a single tail breakpoint
    // can miss when parallel tool calls overrun the provider's backward lookup
    // window.
    const shortTtl = {'type': 'ephemeral'};
    final stableTtl = config.stablePrefixTtl == LlmCacheTtl.fiveMinutes
        ? shortTtl
        : {'type': 'ephemeral', 'ttl': config.stablePrefixTtl.wire};
    void markTail(int index) {
      if (index < 0 || index >= wireMessages.length) {
        return;
      }
      final content = wireMessages[index]['content'];
      if (content is List && content.isNotEmpty) {
        final block = content.last;
        if (block is Map<String, dynamic>) {
          block['cache_control'] = shortTtl;
        }
      }
    }

    if (config.cacheEnabled && wireMessages.isNotEmpty) {
      final anchor = config.cacheAnchorIndex;
      if (anchor != null && anchor < wireMessages.length - 1) {
        markTail(anchor);
      }
      markTail(wireMessages.length - 1);
    }

    final request = <String, dynamic>{
      'model': config.model ?? _defaultModel,
      'max_tokens': config.maxTokens,
      'messages': wireMessages,
      'stream': true,
    };
    if (systemBlocks.isNotEmpty) {
      if (config.cacheEnabled) {
        // Cache the stable system prefix by marking its last block.
        systemBlocks.last = {...systemBlocks.last, 'cache_control': stableTtl};
        request['system'] = systemBlocks;
      } else {
        request['system'] = systemBlocks
            .map((b) => b['text'] as String)
            .join('\n\n');
      }
    }
    if (tools.isNotEmpty) {
      if (config.cacheEnabled) {
        // Anchored to the last RESIDENT tool, not the last tool sent: tools
        // activated mid-run are appended after this point, so a breakpoint at
        // the end would move every time one loads and invalidate the whole
        // tools+system prefix — turning a ~200-token append into a full
        // rebuild of the largest cached region in the request.
        //
        // With native deferral the whole admitted catalog is present from the
        // first turn, so the boundary is the last NON-deferred tool and is
        // derived from the flags rather than trusted from the caller.
        final index = deferralApplied
            ? residentToolBreakpointIndex(
                toolList,
                config.toolCacheBreakpointIndex,
              )
            : _plainBreakpointIndex(toolList.length, config);
        if (index >= 0) {
          toolList[index]['cache_control'] = stableTtl;
        }
      }
      request['tools'] = toolList;
    }
    if (config.stopSequences.isNotEmpty) {
      request['stop_sequences'] = config.stopSequences;
    }
    // Sampling params are rejected by the current models; send only when set.
    if (config.temperature != null) {
      request['temperature'] = config.temperature;
    }
    if (config.topP != null) {
      request['top_p'] = config.topP;
    }
    if (config.topK != null) {
      request['top_k'] = config.topK;
    }
    // Extended thinking: adaptive mode + reasoning depth via output_config.effort
    // (current models reject a fixed budget_tokens). Omitted entirely = off.
    final effort = config.effort;
    if (effort != null) {
      request['thinking'] = {'type': 'adaptive', 'display': 'summarized'};
      request['output_config'] = {'effort': anthropicEffort(effort)};
    }
    return request;
  }

  /// The plain (non-deferring) tools-array cache breakpoint: the last tool, or
  /// the caller's resident-block index when it supplies one.
  int _plainBreakpointIndex(int length, LlmCompleteConfig config) {
    final requested = config.toolCacheBreakpointIndex;
    return (requested == null || requested < 0)
        ? length - 1
        : requested.clamp(0, length - 1);
  }

  List<Map<String, dynamic>> _userContent(
    HarnessMessage message, {
    required bool nativeReferences,
    required Set<String> availableTools,
  }) {
    final blocks = <Map<String, dynamic>>[];
    for (final block in message.content) {
      switch (block) {
        case HarnessTextBlock(:final text):
          blocks.add({'type': 'text', 'text': text});
        case HarnessImageBlock(:final data, :final mediaType):
          blocks.add({
            'type': 'image',
            'source': {'type': 'base64', 'media_type': mediaType, 'data': data},
          });
        case HarnessToolResultBlock(
          :final toolUseId,
          :final content,
          :final isError,
          :final images,
          :final toolReferences,
        ):
          // A reference is only valid for a tool the request actually offers
          // (the API rejects a dangling one), and only on a model that
          // implements tool search. Anything else — an unsupported model, a
          // provider-independent history replayed against a smaller catalog —
          // degrades to naming the activated tools in the text instead of
          // dropping the activation or sending a rejected block.
          final references = <String>[
            if (nativeReferences)
              for (final name in toolReferences)
                if (availableTools.contains(name)) name,
          ];
          final unlisted = <String>[
            for (final name in toolReferences)
              if (!references.contains(name)) name,
          ];
          final text = unlisted.isEmpty
              ? content
              : _activatedNote(content, unlisted);
          blocks.add({
            'type': 'tool_result',
            'tool_use_id': toolUseId,
            // A tool_result's content is either a plain string or a block
            // array. Only widen to the array form when there is something the
            // string form cannot carry — references or images. The string form
            // is what every existing test and cache entry sees, and changing it
            // unconditionally would break prompt-cache prefixes for every run
            // that returns neither.
            'content': (references.isEmpty && images.isEmpty)
                ? text
                : [
                    if (text.isNotEmpty) {'type': 'text', 'text': text},
                    for (final name in references)
                      {'type': 'tool_reference', 'tool_name': name},
                    for (final image in images)
                      {
                        'type': 'image',
                        'source': {
                          'type': 'base64',
                          'media_type': image.mediaType,
                          'data': image.data,
                        },
                      },
                  ],
            if (isError) 'is_error': true,
          });
        case _:
          break;
      }
    }
    if (blocks.isEmpty) {
      blocks.add({'type': 'text', 'text': message.textContent});
    }
    return blocks;
  }

  /// Appends the portable "these tools are now callable" note to [content].
  static String _activatedNote(String content, List<String> names) {
    final note = 'Activated tools: ${names.join(', ')}.';
    return content.isEmpty ? note : '$content\n\n$note';
  }

  List<Map<String, dynamic>> _assistantContent(HarnessMessage message) {
    final blocks = <Map<String, dynamic>>[];
    for (final block in message.content) {
      switch (block) {
        case HarnessThinkingBlock(:final thinking, :final signature)
            when signature != null:
          blocks.add({
            'type': 'thinking',
            'thinking': thinking,
            'signature': signature,
          });
        case HarnessTextBlock(:final text):
          // Anthropic rejects empty text blocks — skip them.
          if (text.isNotEmpty) {
            blocks.add({'type': 'text', 'text': text});
          }
        case HarnessToolUseBlock(:final id, :final name, :final input):
          blocks.add({
            'type': 'tool_use',
            'id': id,
            'name': name,
            'input': input,
          });
        case _:
          break;
      }
    }
    // Assistant content must be non-empty on the wire; an empty turn (e.g. an
    // empty model response replayed on a later turn) would otherwise 400.
    if (blocks.isEmpty) {
      blocks.add({'type': 'text', 'text': '(no content)'});
    }
    return blocks;
  }

  LlmError _mapHttpError(ProviderHttpException e) {
    String? code;
    try {
      final decoded = jsonDecode(e.body) as Map<String, dynamic>;
      code = (decoded['error'] as Map<String, dynamic>?)?['type'] as String?;
    } on Object {
      code = null;
    }
    // Anthropic authenticates by API key here, so a 401 is a key problem —
    // name the remedy instead of leaving the raw body to be read as transient.
    final reauth = e.statusCode == 401
        ? ' — the API key was rejected. Update it in Settings → Adapters → '
              'Providers & models.'
        : '';
    return LlmError(
      'Anthropic API error ${e.statusCode}: ${e.body}$reauth',
      code: code ?? 'http_${e.statusCode}',
      retryable: e.statusCode == 429 || e.statusCode >= 500,
      retryAfterMs: e.retryAfter?.inMilliseconds,
    );
  }

  static bool _isRetryableCode(String? code) =>
      code == 'rate_limit_error' ||
      code == 'overloaded_error' ||
      code == 'api_error';
}
