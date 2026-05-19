import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// Talks to the Anthropic Messages API (`POST /v1/messages`, streaming SSE).
///
/// Converts the harness message format to Anthropic's wire shape (system prompt
/// as a request field, tool results as user-role content blocks) and decodes
/// the SSE event stream into [LlmEvent]s. Extended thinking uses adaptive mode
/// (`thinking: {type: "adaptive"}`) — the current models reject a fixed
/// `budget_tokens` — and sampling parameters are sent only when explicitly set,
/// since the current models reject them too.
class AnthropicProvider implements LlmProviderPort {
  /// Creates an [AnthropicProvider].
  ///
  /// Authenticates with an [apiKey] (`x-api-key`) or, when [oauthAccessToken]
  /// is set, a Claude Pro/Max OAuth token (`Authorization: Bearer` + the
  /// `oauth-2025-04-20` / `claude-code-20250219` betas, plus the required
  /// Claude-Code system-identity block — the API rejects OAuth tokens without
  /// it).
  AnthropicProvider({
    String? apiKey,
    String? oauthAccessToken,
    ProviderTokenResolver? tokenResolver,
    String baseUrl = 'https://api.anthropic.com',
    String defaultModel = 'claude-opus-4-8',
    String anthropicVersion = '2023-06-01',
    ProviderHttp? http,
  }) : _apiKey = apiKey,
       _oauthAccessToken = oauthAccessToken,
       _tokenResolver = tokenResolver,
       _baseUrl = baseUrl,
       _defaultModel = defaultModel,
       _anthropicVersion = anthropicVersion,
       _http = http ?? ProviderHttp.shared;

  final String? _apiKey;
  final String? _oauthAccessToken;

  /// Resolves the OAuth bearer just before each request, so a run that outlives
  /// the token renews it instead of 401ing. Null for a static API key.
  final ProviderTokenResolver? _tokenResolver;
  final String _baseUrl;
  final String _defaultModel;
  final String _anthropicVersion;
  final ProviderHttp _http;

  /// The exact identity block the Anthropic API requires as the first system
  /// block when authenticating with a Claude Code OAuth token.
  static const String claudeCodeIdentity =
      "You are Claude Code, Anthropic's official CLI for Claude.";

  bool get _isOAuth =>
      _oauthAccessToken != null && _oauthAccessToken.isNotEmpty;

  /// Auth + version headers, differing by credential kind.
  ///
  /// The OAuth bearer is resolved per request (not captured at build time) so a
  /// run outliving its access token renews it mid-flight; [force] re-mints even
  /// a token that still looks valid, which is the answer to a 401.
  Future<Map<String, String>> _authHeaders({bool force = false}) async {
    if (!_isOAuth) {
      return {
        'x-api-key': _apiKey ?? '',
        'anthropic-version': _anthropicVersion,
      };
    }
    final resolver = _tokenResolver;
    final token = resolver == null
        ? _oauthAccessToken
        : (await resolver(force: force)) ?? _oauthAccessToken;
    return {
      'Authorization': 'Bearer $token',
      'anthropic-version': _anthropicVersion,
      'anthropic-beta': 'oauth-2025-04-20,claude-code-20250219',
    };
  }

  @override
  String get displayName => 'Anthropic';

  @override
  String get defaultModel => _defaultModel;

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
      events = _stream(uri, body);
    } on ProviderHttpException catch (e) {
      yield _mapHttpError(e);
      yield const LlmDone(stopReason: LlmStopReason.unknown);
      return;
    }
    yield* events;
  }

  Stream<LlmEvent> _stream(Uri uri, Map<String, dynamic> body) async* {
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
        retryOnUnauthorized: _tokenResolver != null,
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
            final usage =
                (json['message'] as Map<String, dynamic>?)?['usage']
                    as Map<String, dynamic>?;
            if (usage != null) {
              inputTokens = (usage['input_tokens'] as num?)?.toInt() ?? 0;
              cacheReadTokens =
                  (usage['cache_read_input_tokens'] as num?)?.toInt() ?? 0;
              cacheWriteTokens =
                  (usage['cache_creation_input_tokens'] as num?)?.toInt() ?? 0;
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
    // The stable system prefix. Only the CONFIG system prompt (and, for OAuth,
    // the mandatory Claude-Code identity as its own exact first block) lives
    // here — it must stay byte-identical across turns so the prompt cache hits.
    // Mid-conversation `system` messages (stream-rule reminders, advisor notes,
    // budget steers) are NOT hoisted here; that would mutate the cached prefix
    // on every turn after the first and drop the note's chronological position.
    final systemBlocks = <Map<String, dynamic>>[];
    if (_isOAuth) {
      systemBlocks.add({'type': 'text', 'text': claudeCodeIdentity});
    }
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
          wireMessages.add({'role': 'user', 'content': _userContent(message)});
        case HarnessRole.assistant:
          wireMessages.add({
            'role': 'assistant',
            'content': _assistantContent(message),
          });
      }
    }

    // Prompt caching: mark the stable prefix (system + tools) and the tail of
    // the latest turn with ephemeral cache breakpoints (≤4 total). The
    // system+tools prefix is constant across turns, so it is a cache hit on
    // every turn after the first.
    const cacheControl = {'type': 'ephemeral'};
    if (config.cacheEnabled && wireMessages.isNotEmpty) {
      final lastContent = wireMessages.last['content'];
      if (lastContent is List && lastContent.isNotEmpty) {
        final lastBlock = lastContent.last;
        if (lastBlock is Map<String, dynamic>) {
          lastBlock['cache_control'] = cacheControl;
        }
      }
    }

    final request = <String, dynamic>{
      'model': config.model ?? _defaultModel,
      'max_tokens': config.maxTokens,
      'messages': wireMessages,
      'stream': true,
    };
    if (systemBlocks.isNotEmpty) {
      if (config.cacheEnabled) {
        // Cache the stable system prefix by marking its last block; the OAuth
        // identity stays its own first block.
        systemBlocks.last = {
          ...systemBlocks.last,
          'cache_control': cacheControl,
        };
        request['system'] = systemBlocks;
      } else {
        // No caching: send a plain joined string (the identity, when present,
        // remains the leading text).
        request['system'] = systemBlocks
            .map((b) => b['text'] as String)
            .join('\n\n');
      }
    }
    if (tools.isNotEmpty) {
      final toolList = <Map<String, dynamic>>[
        for (final tool in tools)
          {
            'name': tool.name,
            'description': tool.description,
            'input_schema': tool.inputSchema,
          },
      ];
      if (config.cacheEnabled) {
        toolList.last['cache_control'] = cacheControl;
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

  List<Map<String, dynamic>> _userContent(HarnessMessage message) {
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
        ):
          blocks.add({
            'type': 'tool_result',
            'tool_use_id': toolUseId,
            // A tool_result's content is either a plain string or a block
            // array. Only widen to the array form when there are images —
            // the string form is what every existing test and cache entry
            // sees, and changing it unconditionally would break prompt-cache
            // prefixes for every run that returns no images.
            'content': images.isEmpty
                ? content
                : [
                    if (content.isNotEmpty) {'type': 'text', 'text': content},
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
    // A 401 that survived the token refresh is an account problem, not a
    // transient one — name the remedy instead of reporting a bad key.
    final reauth = e.statusCode == 401 && _tokenResolver != null
        ? ' — the OAuth token could not be renewed. Reconnect the account in '
              'Settings → Providers.'
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
