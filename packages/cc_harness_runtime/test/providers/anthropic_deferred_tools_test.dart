import 'dart:convert';

import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_provider.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_tool_deferral.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

/// Captures the request body a provider builds, without making a request.
class _CapturingHttp extends ProviderHttp {
  Map<String, dynamic>? body;
  bool sawBodyByte = false;

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    void Function()? onRequestSent,
    void Function()? onFirstBodyByte,
  }) async* {
    this.body = body;
    onFirstBodyByte?.call();
    sawBodyByte = true;
    // The first response body byte, then a minimal stream so the caller ends.
    yield SseMessage(
      event: 'message_start',
      data: jsonEncode({
        'type': 'message_start',
        'message': {
          'model': 'claude-opus-4-8-wire',
          'usage': {'input_tokens': 12, 'output_tokens': 0},
        },
      }),
    );
    yield const SseMessage(
      event: 'message_stop',
      data: '{"type":"message_stop"}',
    );
  }
}

Future<Map<String, dynamic>> _capture(
  LlmProviderPort provider,
  _CapturingHttp http, {
  List<LlmToolSchema> tools = const [],
  List<HarnessMessage> messages = const [],
  String? model,
}) async {
  await provider
      .complete(
        messages: messages,
        tools: tools,
        config: LlmCompleteConfig(model: model, maxTokens: 100),
      )
      .drain<void>();
  final body = http.body;
  expect(body, isNotNull, reason: 'the provider never built a request');
  return body!;
}

List<Map<String, dynamic>> _tools(Map<String, dynamic> body) =>
    (body['tools'] as List).cast<Map<String, dynamic>>();

Map<String, dynamic> _firstToolResult(Map<String, dynamic> body) {
  for (final message
      in (body['messages'] as List).cast<Map<String, dynamic>>()) {
    final content = message['content'];
    if (content is List) {
      for (final block in content) {
        if (block is Map<String, dynamic> && block['type'] == 'tool_result') {
          return block;
        }
      }
    }
  }
  fail('no tool_result block in the request');
}

const _resident = LlmToolSchema(
  name: 'read_file',
  description: 'read',
  inputSchema: {'type': 'object'},
);
const _deferred = LlmToolSchema(
  name: 'write_file',
  description: 'write',
  inputSchema: {'type': 'object'},
  deferLoading: true,
);

void main() {
  group('anthropicSupportsToolDeferral', () {
    test('accepts the documented model families', () {
      for (final model in const [
        'claude-opus-4-8',
        'claude-opus-4-5-20251101',
        'claude-sonnet-4-5-20250929',
        'claude-haiku-4-5-20251001',
        'claude-sonnet-5',
        'claude-opus-5-5',
        'anthropic/claude-opus-4-8',
      ]) {
        expect(anthropicSupportsToolDeferral(model), isTrue, reason: model);
      }
    });

    test('rejects older models and unknown endpoints', () {
      for (final model in const [
        'claude-opus-4-1',
        'claude-3-5-sonnet-20241022',
        'gpt-4o',
        'qwen2.5-coder',
        '',
      ]) {
        expect(anthropicSupportsToolDeferral(model), isFalse, reason: model);
      }
      expect(anthropicSupportsToolDeferral(null), isFalse);
    });
  });

  group('deferral helpers', () {
    test('drops the flags when every tool would be deferred', () {
      final tools = <Map<String, dynamic>>[
        {'name': 'a', 'defer_loading': true},
        {'name': 'b', 'defer_loading': true},
      ];
      expect(applyAnthropicDeferral(tools), isFalse);
      expect(tools.every((t) => !t.containsKey('defer_loading')), isTrue);
    });

    test('keeps the flags when at least one tool stays resident', () {
      final tools = <Map<String, dynamic>>[
        {'name': 'a'},
        {'name': 'b', 'defer_loading': true},
      ];
      expect(applyAnthropicDeferral(tools), isTrue);
    });

    test('snaps the breakpoint back to the last resident tool', () {
      final tools = <Map<String, dynamic>>[
        {'name': 'a'},
        {'name': 'b'},
        {'name': 'c', 'defer_loading': true},
      ];
      expect(residentToolBreakpointIndex(tools, null), 1);
      expect(residentToolBreakpointIndex(tools, 2), 1);
      expect(residentToolBreakpointIndex(tools, 0), 0);
      expect(residentToolBreakpointIndex(tools, 99), 1);
    });
  });

  group('native deferred tool loading', () {
    test(
      'sends the whole catalog, deferring only the marked schemas',
      () async {
        final http = _CapturingHttp();
        final body = await _capture(
          AnthropicProvider(apiKey: 'test', http: http),
          http,
          tools: const [_resident, _deferred],
          model: 'claude-opus-4-8',
        );

        final tools = _tools(body);
        expect(
          tools.map((t) => t['name']),
          ['read_file', 'write_file'],
          reason:
              'the admitted catalog travels in full — the API expands a '
              'reference server-side and needs the schema to do it',
        );
        expect(tools[0].containsKey('defer_loading'), isFalse);
        expect(tools[1]['defer_loading'], isTrue);
        // The breakpoint stays on the resident block so activation cannot move
        // the cached tools+system prefix.
        expect(tools[0]['cache_control'], isNotNull);
        expect(tools[1].containsKey('cache_control'), isFalse);
      },
    );

    test('anchors the breakpoint to the last resident tool', () async {
      final http = _CapturingHttp();
      final body = await _capture(
        AnthropicProvider(apiKey: 'test', http: http),
        http,
        tools: const [_resident, _resident, _deferred],
        model: 'claude-opus-4-8',
      );
      final tools = _tools(body);
      expect(tools[1]['cache_control'], isNotNull);
      expect(tools[2].containsKey('cache_control'), isFalse);
    });

    test('does not defer on a model without tool search', () async {
      final http = _CapturingHttp();
      final body = await _capture(
        AnthropicProvider(apiKey: 'test', http: http),
        http,
        tools: const [_resident, _deferred],
        model: 'claude-opus-4-1',
      );
      final tools = _tools(body);
      expect(tools.every((t) => !t.containsKey('defer_loading')), isTrue);
      expect(
        tools[1]['cache_control'],
        isNotNull,
        reason: 'without deferral the last tool is the stable prefix boundary',
      );
    });

    test('does not defer on a custom Anthropic-compatible endpoint', () async {
      final http = _CapturingHttp();
      final body = await _capture(
        AnthropicProvider(
          apiKey: 'test',
          baseUrl: 'http://127.0.0.1:8000',
          defaultModel: 'claude-opus-4-8',
          http: http,
        ),
        http,
        tools: const [_resident, _deferred],
        model: 'claude-opus-4-8',
      );
      expect(
        _tools(body).every((t) => !t.containsKey('defer_loading')),
        isTrue,
        reason:
            'a local Messages-compatible server rejects tool-search fields '
            'even when the model id looks supported',
      );
      final provider = AnthropicProvider(
        apiKey: 'test',
        baseUrl: 'http://127.0.0.1:8000',
        defaultModel: 'claude-opus-4-8',
      );
      expect(provider.supportsDeferredTools(model: 'claude-opus-4-8'), isFalse);
      expect(
        AnthropicProvider(
          apiKey: 'k',
        ).supportsDeferredTools(model: 'claude-opus-4-8'),
        isTrue,
      );
    });

    test('degrades to a plain catalog when every tool is deferred', () async {
      final http = _CapturingHttp();
      final body = await _capture(
        AnthropicProvider(apiKey: 'test', http: http),
        http,
        tools: const [_deferred, _deferred],
        model: 'claude-opus-4-8',
      );
      final tools = _tools(body);
      expect(tools, hasLength(2));
      expect(tools.every((t) => !t.containsKey('defer_loading')), isTrue);
    });

    test('carries capability into the decorator used for accounting', () {
      final observed = ObservedLlmProvider(
        AnthropicProvider(apiKey: 'test'),
        observer: ProviderCallLedger(),
      );
      expect(
        providerSupportsDeferredTools(observed, model: 'claude-opus-4-8'),
        isTrue,
      );
      expect(
        providerSupportsDeferredTools(observed, model: 'claude-opus-4-1'),
        isFalse,
      );
    });
  });

  group('tool references', () {
    const reference = ToolOutputReference(
      handle: 'h-1',
      toolName: 'search_tools',
      byteLength: 10,
      charLength: 10,
    );

    test('serializes tool_reference blocks for a supporting model', () async {
      final http = _CapturingHttp();
      final body = await _capture(
        AnthropicProvider(apiKey: 'test', http: http),
        http,
        tools: const [_resident, _deferred],
        model: 'claude-opus-4-8',
        messages: [
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(
              toolUseId: 't1',
              content: 'matched write_file',
              toolReferences: ['write_file'],
              outputReference: reference,
            ),
          ]),
        ],
      );

      final content = _firstToolResult(body)['content'] as List;
      expect((content.first as Map)['type'], 'text');
      expect((content.first as Map)['text'], 'matched write_file');
      final refBlock = content[1] as Map<String, dynamic>;
      expect(refBlock, {'type': 'tool_reference', 'tool_name': 'write_file'});
      expect(
        jsonEncode(body),
        isNot(contains('output_reference')),
        reason: 'the transcript handle is internal and would 400 on the wire',
      );
    });

    test(
      'names the tool in text when the model cannot expand a reference',
      () async {
        final http = _CapturingHttp();
        final body = await _capture(
          AnthropicProvider(apiKey: 'test', http: http),
          http,
          tools: const [_resident],
          model: 'claude-opus-4-1',
          messages: [
            HarnessMessage.toolResults(const [
              HarnessToolResultBlock(
                toolUseId: 't1',
                content: 'matched write_file',
                toolReferences: ['write_file'],
              ),
            ]),
          ],
        );

        final block = _firstToolResult(body);
        expect(block['content'], isA<String>());
        expect(block['content'], contains('Activated tools: write_file.'));
        expect(jsonEncode(body), isNot(contains('tool_reference')));
      },
    );

    test('names a referenced tool the request does not offer', () async {
      final http = _CapturingHttp();
      final body = await _capture(
        AnthropicProvider(apiKey: 'test', http: http),
        http,
        tools: const [_resident],
        model: 'claude-opus-4-8',
        messages: [
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(
              toolUseId: 't1',
              content: 'matched',
              toolReferences: ['write_file'],
            ),
          ]),
        ],
      );

      final block = _firstToolResult(body);
      expect(
        block['content'],
        contains('Activated tools: write_file.'),
        reason:
            'a dangling reference is a rejected request, and dropping it '
            'silently would hide the activation',
      );
    });

    test('keeps the plain string form when nothing extra is carried', () async {
      final http = _CapturingHttp();
      final body = await _capture(
        AnthropicProvider(apiKey: 'test', http: http),
        http,
        tools: const [_resident, _deferred],
        model: 'claude-opus-4-8',
        messages: [
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(toolUseId: 't1', content: 'ok'),
          ]),
        ],
      );
      expect(_firstToolResult(body)['content'], 'ok');
    });
  });

  group('usage ledger integration', () {
    test('records the served model and the transport first byte', () async {
      final http = _CapturingHttp();
      final ledger = ProviderCallLedger(runId: 'run-9');
      final provider = ObservedLlmProvider(
        AnthropicProvider(apiKey: 'test', http: http),
        observer: ledger,
        runId: 'run-9',
      );

      await provider
          .complete(
            messages: [HarnessMessage.user('hi')],
            config: const LlmCompleteConfig(
              model: 'claude-opus-4-8',
              purpose: LlmCallPurpose.compaction,
            ),
          )
          .toList();

      final record = ledger.records.single;
      expect(record.purpose, LlmCallPurpose.compaction);
      expect(record.model, 'claude-opus-4-8-wire');
      expect(record.transportFirstByteMs, isNotNull);
      expect(record.usage.inputTokens, 12);
      expect(record.outcome, ProviderCallOutcome.success);
      expect(http.sawBodyByte, isTrue);
    });
  });
}
