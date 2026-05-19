import 'dart:convert';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:cc_harness_runtime/src/providers/sse.dart';
import 'package:test/test.dart';

/// Captures the headers + body of the request, then ends the stream.
class _CapturingHttp extends ProviderHttp {
  Map<String, String>? headers;
  Map<String, dynamic>? body;

  @override
  Stream<SseMessage> postSse(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    this.headers = headers;
    this.body = body;
    yield SseMessage(
      event: 'message_stop',
      data: jsonEncode({'type': 'message_stop'}),
    );
  }
}

/// Extracts the joined system text whether `system` is a plain string or the
/// cache-aware block list (`[{type:text, text, cache_control}]`).
String _systemText(Object? system) {
  if (system is String) {
    return system;
  }
  if (system is List) {
    return system
        .whereType<Map>()
        .map((b) => b['text'] as String? ?? '')
        .join('\n\n');
  }
  return '';
}

void main() {
  group('AnthropicProvider auth', () {
    test('API-key mode sends x-api-key and no OAuth beta', () async {
      final http = _CapturingHttp();
      final provider = AnthropicProvider(apiKey: 'sk-1', http: http);
      await provider
          .complete(
            messages: [HarnessMessage.user('hi')],
            config: const LlmCompleteConfig(systemPrompt: 'Base'),
          )
          .toList();
      expect(http.headers?['x-api-key'], 'sk-1');
      expect(http.headers?.containsKey('Authorization'), isFalse);
      expect(http.headers?.containsKey('anthropic-beta'), isFalse);
      expect(_systemText(http.body?['system']), 'Base');
    });

    test(
      'OAuth mode sends Bearer + beta + the Claude-Code identity block',
      () async {
        final http = _CapturingHttp();
        final provider = AnthropicProvider(
          oauthAccessToken: 'oauth-tok',
          http: http,
        );
        await provider
            .complete(
              messages: [HarnessMessage.user('hi')],
              config: const LlmCompleteConfig(systemPrompt: 'Base'),
            )
            .toList();
        expect(http.headers?['Authorization'], 'Bearer oauth-tok');
        expect(http.headers?['anthropic-beta'], contains('oauth-2025-04-20'));
        expect(http.headers?.containsKey('x-api-key'), isFalse);
        // The required identity is the FIRST system block.
        final system = _systemText(http.body?['system']);
        expect(system.startsWith(AnthropicProvider.claudeCodeIdentity), isTrue);
        expect(system, contains('Base'));
      },
    );
  });
}
