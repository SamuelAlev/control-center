import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_provider.dart';
import 'package:cc_harness_runtime/src/providers/openai_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

/// Captures the request body a provider builds, without making a request.
class _CapturingHttp extends ProviderHttp {
  Map<String, dynamic>? body;

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    this.body = body;
    // One terminal event so the stream completes and the caller stops.
    yield const SseMessage(event: 'message_stop', data: '{}');
  }
}

/// How each provider carries an image that a tool returned.
///
/// The two wires differ in a way that matters: Anthropic accepts image blocks
/// inside a `tool_result`, while a Chat Completions `tool` message has no
/// image slot at all. Dropping them on the second would make a rig screenshot
/// silently invisible there — the kind of failure nobody reports because
/// nothing errors.
void main() {
  const image = HarnessImageBlock(data: 'QUJD', mediaType: 'image/jpeg');

  Future<Map<String, dynamic>> capture(
    LlmProviderPort provider,
    _CapturingHttp http,
    List<HarnessMessage> messages,
  ) async {
    await provider
        .complete(
          messages: messages,
          tools: const [],
          config: const LlmCompleteConfig(maxTokens: 100),
        )
        .drain<void>();
    final body = http.body;
    expect(body, isNotNull, reason: 'the provider never built a request');
    return body!;
  }

  group('Anthropic', () {
    test('a text-only tool result keeps the plain string form', () async {
      // Widening this unconditionally would change every existing prompt-cache
      // prefix, so the string form has to survive for results with no images.
      final http = _CapturingHttp();
      final body = await capture(
        AnthropicProvider(apiKey: 'test', http: http),
        http,
        [
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(toolUseId: 't1', content: 'ok'),
          ]),
        ],
      );
      final block = _firstToolResult(body);
      expect(block['content'], isA<String>());
      expect(block['content'], 'ok');
    });

    test('an image-bearing result widens to a block array', () async {
      final http = _CapturingHttp();
      final body = await capture(
        AnthropicProvider(apiKey: 'test', http: http),
        http,
        [
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(
              toolUseId: 't1',
              content: 'a screenshot',
              images: [image],
            ),
          ]),
        ],
      );
      final content = _firstToolResult(body)['content'] as List;
      expect(content.first, containsPair('type', 'text'));
      final imageBlock = content.last as Map<String, dynamic>;
      expect(imageBlock['type'], 'image');
      final source = imageBlock['source'] as Map<String, dynamic>;
      expect(source['type'], 'base64');
      expect(source['media_type'], 'image/jpeg');
      expect(source['data'], 'QUJD');
    });
  });

  group('OpenAI', () {
    test('the tool message itself stays a string', () async {
      final http = _CapturingHttp();
      final body = await capture(
        OpenAiProvider(apiKey: 'test', http: http),
        http,
        [
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(
              toolUseId: 't1',
              content: 'a screenshot',
              images: [image],
            ),
          ]),
        ],
      );
      final messages = (body['messages'] as List).cast<Map<String, dynamic>>();
      final toolMessage = messages.firstWhere((m) => m['role'] == 'tool');
      expect(toolMessage['content'], 'a screenshot');
    });

    test('images are relayed as a following user turn', () async {
      final http = _CapturingHttp();
      final body = await capture(
        OpenAiProvider(apiKey: 'test', http: http),
        http,
        [
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(
              toolUseId: 't1',
              content: 'a screenshot',
              images: [image],
            ),
          ]),
        ],
      );
      final messages = (body['messages'] as List).cast<Map<String, dynamic>>();
      final toolIndex = messages.indexWhere((m) => m['role'] == 'tool');
      final relay = messages[toolIndex + 1];
      expect(relay['role'], 'user');
      final content = relay['content'] as List;
      expect(
        (content.first as Map)['text'],
        contains('tool call'),
        reason:
            'The relay must say where the image came from, or the model reads '
            'it as a new human instruction.',
      );
      final imagePart = content.last as Map<String, dynamic>;
      expect(imagePart['type'], 'image_url');
      expect(
        (imagePart['image_url'] as Map)['url'],
        'data:image/jpeg;base64,QUJD',
      );
    });

    test('a text-only result adds no extra turn', () async {
      final http = _CapturingHttp();
      final body = await capture(
        OpenAiProvider(apiKey: 'test', http: http),
        http,
        [
          HarnessMessage.toolResults(const [
            HarnessToolResultBlock(toolUseId: 't1', content: 'ok'),
          ]),
        ],
      );
      final messages = (body['messages'] as List).cast<Map<String, dynamic>>();
      expect(messages.where((m) => m['role'] == 'user'), isEmpty);
    });
  });
}

Map<String, dynamic> _firstToolResult(Map<String, dynamic> request) {
  final messages = (request['messages'] as List).cast<Map<String, dynamic>>();
  for (final message in messages) {
    final content = message['content'];
    if (content is List) {
      for (final block in content) {
        if (block is Map<String, dynamic> && block['type'] == 'tool_result') {
          return block;
        }
      }
    }
  }
  fail('No tool_result block in the request');
}
