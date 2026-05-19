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

Future<_CapturingHttp> _request({
  String? apiKey,
  bool cacheEnabled = true,
}) async {
  final http = _CapturingHttp();
  final provider = AnthropicProvider(apiKey: apiKey, http: http);
  await provider
      .complete(
        messages: [HarnessMessage.user('hi')],
        config: LlmCompleteConfig(
          systemPrompt: 'Base',
          cacheEnabled: cacheEnabled,
        ),
      )
      .toList();
  return http;
}

void main() {
  group('AnthropicProvider auth', () {
    test('sends x-api-key and the version header', () async {
      final http = await _request(apiKey: 'sk-1');
      expect(http.headers?['x-api-key'], 'sk-1');
      expect(http.headers?['anthropic-version'], '2023-06-01');
      expect(_systemText(http.body?['system']), 'Base');
    });

    // The ratchet. Claude Pro/Max is reachable through the `claude-code`
    // ADAPTER, which runs the real CLI under its own login; it is NOT reachable
    // by having this provider impersonate Claude Code. Re-adding a bearer, the
    // `claude-code-*` beta or the identity block would put that impersonation
    // back, so each is pinned absent rather than merely untested.
    group('never presents itself as Claude Code', () {
      test('no Authorization bearer, whatever the credential', () async {
        for (final key in <String?>[null, '', 'sk-1', 'sk-ant-oat01-abc']) {
          final http = await _request(apiKey: key);
          expect(
            http.headers?.containsKey('Authorization'),
            isFalse,
            reason: 'apiKey=$key must not produce a bearer',
          );
        }
      });

      test('no anthropic-beta header at all', () async {
        final http = await _request(apiKey: 'sk-1');
        expect(http.headers?.containsKey('anthropic-beta'), isFalse);
      });

      test('no Claude Code identity in the system prompt', () async {
        for (final cache in [true, false]) {
          final http = await _request(apiKey: 'sk-1', cacheEnabled: cache);
          final system = _systemText(http.body?['system']);
          expect(system, 'Base', reason: 'cacheEnabled=$cache');
          expect(system.toLowerCase(), isNot(contains('claude code')));
        }
      });

      test('the constructor takes no OAuth token', () {
        // A compile-time guarantee expressed as a runtime assertion: the only
        // credential the constructor accepts is an API key. If someone adds an
        // `oauthAccessToken` back, this file stops compiling at `_request`.
        expect(AnthropicProvider(apiKey: 'sk-1').displayName, 'Anthropic');
      });
    });
  });
}
