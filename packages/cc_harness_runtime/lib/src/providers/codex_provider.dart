import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/codex_oauth.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';

/// Talks to the OpenAI Responses API as Codex uses it.
///
/// Two lanes, same wire:
///
/// - **ChatGPT OAuth** (`chatgpt: true`):
///   `POST https://chatgpt.com/backend-api/codex/responses` with the Codex
///   identity headers. This is the Plus/Pro subscription.
/// - **API key** (`chatgpt: false`):
///   `POST https://api.openai.com/v1/responses` with a bearer key.
///
/// Codex rejects `temperature`. Tools are flat Responses function objects
/// (`{type:function,name,…}`), not the Chat Completions `{type,function:{}}`
/// wrapper.
class CodexProvider implements LlmProviderPort {
  /// Creates a [CodexProvider].
  CodexProvider({
    this._apiKey,
    this._tokenResolver,
    this._accountId,
    String? baseUrl,
    this.chatgpt = true,
    this._defaultModel = 'gpt-5.5',
    ProviderHttp? http,
  }) : _baseUrl = _normalizeBase(
         baseUrl,
         chatgpt
             ? CodexOAuth.backendApi
             : CodexOAuth.apiKeyBase,
       ),
       _http = http ?? ProviderHttp.shared;

  final String? _apiKey;
  final ProviderTokenResolver? _tokenResolver;
  final String? _accountId;
  final String _baseUrl;
  final String _defaultModel;
  final ProviderHttp _http;

  /// Whether this instance talks to the ChatGPT Codex backend (OAuth).
  final bool chatgpt;

  @override
  String get displayName => 'Codex';

  @override
  String get defaultModel => _defaultModel;

  Future<Map<String, String>> _authHeaders({
    bool force = false,
    String? model,
    String? conversationId,
  }) async {
    final resolver = _tokenResolver;
    final token = resolver == null
        ? _apiKey
        : (await resolver(force: force)) ?? _apiKey;
    if (token == null || token.isEmpty) {
      return const {};
    }
    if (!chatgpt) {
      return {'Authorization': 'Bearer $token'};
    }
    return {
      ...CodexOAuth.chatgptHeaders(
        accessToken: token,
        accountId: _accountId,
      ),
      'session_id': _uuidV4(),
      'conversation_id': conversationId ?? _uuidV4(),
      if (model != null && model.isNotEmpty)
        'x-codex-routing-hint': 'model=$model',
    };
  }

  @override
  Future<List<ProviderModel>> listModels() async {
    try {
      final uri = chatgpt
          ? Uri.parse('$_baseUrl${CodexOAuth.modelsPath}').replace(
              queryParameters: {'client_version': CodexOAuth.clientVersion},
            )
          : Uri.parse('$_baseUrl/models');
      final json = await _http.getJson(uri, headers: await _authHeaders());
      return _parseModels(json);
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
    final model = config.model ?? _defaultModel;
    final conversationId = config.cacheKey;
    final uri = Uri.parse(
      chatgpt
          ? '$_baseUrl${CodexOAuth.responsesPath}'
          : '$_baseUrl/responses',
    );
    final body = buildCodexResponsesBody(
      messages: messages,
      tools: tools,
      config: config,
      model: model,
      chatgpt: chatgpt,
    );
    final calls = <String, _PendingCall>{};
    LlmUsage? usage;
    var stopReason = LlmStopReason.unknown;
    var failed = false;

    try {
      final stream = await _http.postSseReauthorizing(
        uri,
        headers: ({bool force = false}) => _authHeaders(
          force: force,
          model: model,
          conversationId: conversationId,
        ),
        body: body,
        retryOnUnauthorized: _tokenResolver != null,
      );
      await for (final sse in stream) {
        final data = sse.data.trim();
        if (data.isEmpty || data == '[DONE]') {
          continue;
        }
        final Map<String, dynamic> json;
        try {
          json = jsonDecode(data) as Map<String, dynamic>;
        } on FormatException {
          continue;
        }
        final type = sse.event ?? json['type'] as String? ?? '';
        switch (type) {
          case 'response.output_text.delta':
            final text = _deltaText(json);
            if (text.isNotEmpty) {
              yield LlmTextDelta(text);
            }
          case 'response.reasoning_summary_text.delta':
          case 'response.reasoning_text.delta':
            final thinking = _deltaText(json);
            if (thinking.isNotEmpty) {
              yield LlmThinkingDelta(thinking);
            }
          case 'response.output_item.added':
            _noteItem(calls, json['item']);
          case 'response.function_call_arguments.delta':
            final key = _callKey(json);
            final delta = _deltaText(json);
            if (key.isNotEmpty && delta.isNotEmpty) {
              (calls[key] ??= _PendingCall()).args.write(delta);
            }
          case 'response.output_item.done':
            final item = json['item'];
            _noteItem(calls, item);
            if (item is Map<String, dynamic> &&
                item['type'] == 'reasoning') {
              final encrypted = item['encrypted_content'] as String?;
              if (encrypted != null && encrypted.isNotEmpty) {
                yield LlmThinkingDelta('', signature: encrypted);
              }
            }
          case 'response.completed':
            final response = json['response'];
            if (response is Map<String, dynamic>) {
              usage = _usageOf(response['usage']) ?? usage;
              _noteOutput(calls, response['output']);
              final status = response['status'] as String?;
              if (status == 'incomplete') {
                stopReason = LlmStopReason.maxTokens;
              }
            }
          case 'response.incomplete':
            stopReason = LlmStopReason.maxTokens;
          case 'response.failed':
          case 'error':
            failed = true;
            yield LlmError(
              _errorMessage(json),
              code: _errorCode(json) ?? type,
              retryable: false,
            );
          default:
            final maybeUsage = _usageOf(json['usage']);
            if (maybeUsage != null) {
              usage = maybeUsage;
            }
        }
      }

      if (failed) {
        yield LlmDone(stopReason: LlmStopReason.unknown, usage: usage);
        return;
      }

      final named = calls.values
          .where((c) => (c.name ?? '').isNotEmpty)
          .toList();
      for (final call in named) {
        final raw = call.args.toString();
        yield LlmToolUseDelta(
          id: call.callId ?? call.itemId ?? 'call_${named.indexOf(call)}',
          name: call.name!,
          argumentsJson: raw.isEmpty ? '{}' : raw,
        );
      }
      if (named.isNotEmpty) {
        stopReason = LlmStopReason.toolUse;
      } else if (stopReason == LlmStopReason.unknown) {
        stopReason = LlmStopReason.endTurn;
      }
      if (usage != null) {
        yield usage;
      }
      yield LlmDone(stopReason: stopReason, usage: usage);
    } on ProviderHttpException catch (e) {
      final reauth = e.statusCode == 401 && _tokenResolver != null
          ? ' — the OAuth token could not be renewed. Reconnect the account in '
                'Settings → Providers.'
          : '';
      String? wireCode;
      try {
        final decoded = jsonDecode(e.body) as Map<String, dynamic>;
        final err = decoded['error'] as Map<String, dynamic>?;
        wireCode = (err?['code'] ?? err?['type']) as String?;
      } on Object {
        wireCode = null;
      }
      yield LlmError(
        'Codex API error ${e.statusCode}: ${e.body}$reauth',
        code: wireCode ?? 'http_${e.statusCode}',
        retryable: e.statusCode == 429 || e.statusCode >= 500,
        retryAfterMs: e.retryAfter?.inMilliseconds,
      );
      yield const LlmDone(stopReason: LlmStopReason.unknown);
    } on Object catch (e) {
      yield LlmError('Codex request failed: $e', retryable: true);
      yield const LlmDone(stopReason: LlmStopReason.unknown);
    }
  }

  static String _normalizeBase(String? baseUrl, String fallback) {
    final raw = (baseUrl == null || baseUrl.trim().isEmpty)
        ? fallback
        : baseUrl.trim();
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }
}

/// Builds the Responses request body. Visible for tests.
Map<String, dynamic> buildCodexResponsesBody({
  required List<HarnessMessage> messages,
  required List<LlmToolSchema> tools,
  required LlmCompleteConfig config,
  required String model,
  required bool chatgpt,
}) {
  final instructions = StringBuffer();
  if (config.systemPrompt != null && config.systemPrompt!.trim().isNotEmpty) {
    instructions.write(config.systemPrompt!.trim());
  }
  final input = <Map<String, dynamic>>[];
  for (final message in messages) {
    switch (message.role) {
      case HarnessRole.system:
        if (message.textContent.trim().isEmpty) {
          break;
        }
        if (instructions.isNotEmpty) {
          instructions.write('\n\n');
        }
        instructions.write(message.textContent.trim());
      case HarnessRole.user:
        input.add(_userItem(message));
      case HarnessRole.assistant:
        input.addAll(_assistantItems(message));
      case HarnessRole.tool:
        for (final block in message.content) {
          if (block is! HarnessToolResultBlock) {
            continue;
          }
          input.add({
            'type': 'function_call_output',
            'call_id': block.toolUseId,
            'output': block.isError
                ? 'ERROR: ${block.content}'
                : block.content,
          });
          if (block.images.isNotEmpty) {
            input.add({
              'type': 'message',
              'role': 'user',
              'content': [
                {
                  'type': 'input_text',
                  'text':
                      'Image output from the preceding tool call'
                      '${block.images.length > 1 ? 's' : ''}.',
                },
                for (final image in block.images) _imagePart(image),
              ],
            });
          }
        }
    }
  }

  final body = <String, dynamic>{
    'model': model,
    'input': input,
    'store': false,
    'stream': true,
    'max_output_tokens': config.maxTokens,
  };
  if (instructions.isNotEmpty) {
    body['instructions'] = instructions.toString();
  }
  if (tools.isNotEmpty) {
    body['tools'] = [
      for (final tool in tools)
        {
          'type': 'function',
          'name': tool.name,
          'description': tool.description,
          'parameters': tool.inputSchema,
          'strict': false,
        },
    ];
  }
  // Codex rejects temperature (and usually top_p) on this endpoint.
  final effort = config.effort;
  if (effort != null) {
    body['reasoning'] = {
      // Native Codex scale includes `xhigh` — do not collapse it.
      'effort': effort.id,
      'summary': 'auto',
    };
  }
  if (chatgpt) {
    body['include'] = const ['reasoning.encrypted_content'];
  }
  if (config.cacheEnabled && config.cacheKey != null) {
    body['prompt_cache_key'] = config.cacheKey;
  }
  return body;
}

Map<String, dynamic> _userItem(HarnessMessage message) {
  final parts = <Map<String, dynamic>>[];
  for (final block in message.content) {
    if (block is HarnessTextBlock && block.text.isNotEmpty) {
      parts.add({'type': 'input_text', 'text': block.text});
    } else if (block is HarnessImageBlock) {
      parts.add(_imagePart(block));
    }
  }
  if (parts.isEmpty) {
    parts.add({'type': 'input_text', 'text': message.textContent});
  }
  return {'type': 'message', 'role': 'user', 'content': parts};
}

List<Map<String, dynamic>> _assistantItems(HarnessMessage message) {
  final items = <Map<String, dynamic>>[];
  for (final block in message.content) {
    if (block is HarnessThinkingBlock &&
        block.signature != null &&
        block.signature!.isNotEmpty) {
      items.add({
        'type': 'reasoning',
        'encrypted_content': block.signature,
      });
    }
  }
  final text = message.textContent;
  if (text.isNotEmpty) {
    items.add({
      'type': 'message',
      'role': 'assistant',
      'content': [
        {'type': 'output_text', 'text': text},
      ],
    });
  }
  for (final call in message.toolUses) {
    items.add({
      'type': 'function_call',
      'call_id': call.id,
      'name': call.name,
      'arguments': call.encodedInput,
    });
  }
  return items;
}

Map<String, dynamic> _imagePart(HarnessImageBlock image) => {
  'type': 'input_image',
  'image_url': 'data:${image.mediaType};base64,${image.data}',
};

List<ProviderModel> _parseModels(Map<String, dynamic> json) {
  final raw = json['models'] ?? json['data'];
  if (raw is! List) {
    return const [];
  }
  return [
    for (final entry in raw)
      if (entry is Map<String, dynamic>)
        if (_modelId(entry) != null)
          ProviderModel(
            id: _modelId(entry)!,
            displayName: (entry['display_name'] ?? entry['name']) as String?,
            contextWindow:
                (entry['context_window'] as num?)?.toInt() ??
                (entry['max_context_window'] as num?)?.toInt(),
          ),
  ];
}

String? _modelId(Map<String, dynamic> entry) {
  for (final key in const ['slug', 'id']) {
    final value = entry[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String _deltaText(Map<String, dynamic> json) {
  final delta = json['delta'];
  if (delta is String) {
    return delta;
  }
  if (delta is Map && delta['text'] is String) {
    return delta['text'] as String;
  }
  final text = json['text'];
  return text is String ? text : '';
}

String _callKey(Map<String, dynamic> json) {
  for (final key in const ['item_id', 'itemId', 'output_index']) {
    final value = json[key];
    if (value != null && '$value'.isNotEmpty) {
      return '$value';
    }
  }
  return '';
}

void _noteItem(Map<String, _PendingCall> calls, Object? raw) {
  if (raw is! Map) {
    return;
  }
  final item = Map<String, dynamic>.from(raw);
  if (item['type'] != 'function_call') {
    return;
  }
  final itemId = item['id'] as String?;
  final callId = item['call_id'] as String?;
  final key = itemId ?? callId ?? '';
  if (key.isEmpty) {
    return;
  }
  final call = calls[key] ??= _PendingCall();
  call.itemId = itemId ?? call.itemId;
  call.callId = callId ?? call.callId;
  final name = item['name'] as String?;
  if (name != null && name.isNotEmpty) {
    call.name = name;
  }
  final args = item['arguments'];
  if (args is String && args.isNotEmpty && call.args.isEmpty) {
    call.args.write(args);
  }
}

void _noteOutput(Map<String, _PendingCall> calls, Object? raw) {
  if (raw is! List) {
    return;
  }
  for (final entry in raw) {
    _noteItem(calls, entry);
  }
}

LlmUsage? _usageOf(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final usage = Map<String, dynamic>.from(raw);
  final input =
      (usage['input_tokens'] as num?)?.toInt() ??
      (usage['prompt_tokens'] as num?)?.toInt() ??
      0;
  final output =
      (usage['output_tokens'] as num?)?.toInt() ??
      (usage['completion_tokens'] as num?)?.toInt() ??
      0;
  final inputDetails =
      usage['input_tokens_details'] ?? usage['prompt_tokens_details'];
  final cached = inputDetails is Map
      ? (inputDetails['cached_tokens'] as num?)?.toInt() ?? 0
      : 0;
  final outputDetails =
      usage['output_tokens_details'] ?? usage['completion_tokens_details'];
  final reasoning = outputDetails is Map
      ? (outputDetails['reasoning_tokens'] as num?)?.toInt() ?? 0
      : 0;
  if (input == 0 && output == 0 && cached == 0 && reasoning == 0) {
    return null;
  }
  return LlmUsage(
    inputTokens: (input - cached).clamp(0, input),
    outputTokens: output,
    cacheReadTokens: cached,
    thoughtTokens: reasoning,
  );
}

String _errorMessage(Map<String, dynamic> json) {
  final error = json['error'];
  if (error is Map && error['message'] is String) {
    return error['message'] as String;
  }
  if (error is String && error.isNotEmpty) {
    return error;
  }
  final response = json['response'];
  if (response is Map) {
    final inner = response['error'];
    if (inner is Map && inner['message'] is String) {
      return inner['message'] as String;
    }
  }
  return 'Codex request failed.';
}

String? _errorCode(Map<String, dynamic> json) {
  final error = json['error'];
  if (error is Map) {
    final code = error['code'] ?? error['type'];
    if (code is String && code.isNotEmpty) {
      return code;
    }
  }
  return null;
}

class _PendingCall {
  String? itemId;
  String? callId;
  String? name;
  final StringBuffer args = StringBuffer();
}

String _uuidV4() {
  final rnd = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => rnd.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
  return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
      '${hex(4)}${hex(5)}-'
      '${hex(6)}${hex(7)}-'
      '${hex(8)}${hex(9)}-'
      '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
}
