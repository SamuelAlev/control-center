import 'dart:convert';
import 'dart:io';

import 'package:control_center/features/sandboxing/data/claude_relay/anthropic_proxy.dart';
import 'package:control_center/features/sandboxing/data/claude_relay/sse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer upstream;

  tearDown(() async {
    await upstream.close(force: true);
  });

  test('forwards /v1/messages and tees SSE events to the callback', () async {
    // Fake upstream that emits a small SSE stream then closes.
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    upstream.listen((req) async {
      final res = req.response
        ..statusCode = 200
        ..headers.contentType = ContentType('text', 'event-stream');
      res.write('event: message_start\n'
          'data: {"type":"message_start","message":{"id":"m","model":"x"}}\n\n');
      res.write('event: content_block_delta\n'
          'data: {"type":"content_block_delta","delta":'
          '{"type":"text_delta","text":"hi"}}\n\n');
      await res.close();
    });

    final teed = <SseEvent>[];
    final proxy = AnthropicProxy(
      ProxyCallbacks(
        onSseEvent: (event, path, {required bool observe}) {
          if (observe) {
            teed.add(event);
          }
        },
      ),
      upstreamHost: '127.0.0.1',
      upstreamScheme: 'http',
      upstreamPort: upstream.port,
    );
    await proxy.start();
    addTearDown(proxy.stop);

    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final req = await client.postUrl(Uri.parse('${proxy.baseUrl}/v1/messages'));
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode({
      'model': 'x',
      'messages': [
        {'role': 'user', 'content': 'hi'},
      ],
    })));
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();

    // Claude (the client) received the upstream SSE bytes verbatim.
    expect(resp.statusCode, 200);
    expect(body, contains('message_start'));
    expect(body, contains('text_delta'));

    // And the relay teed the parsed events.
    expect(teed, hasLength(2));
    expect((teed.first.parsed! as Map)['type'], 'message_start');
    expect((teed.last.parsed! as Map)['type'], 'content_block_delta');
  });

  test('skips teeing for filtered session-title requests but still forwards',
      () async {
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    upstream.listen((req) async {
      final res = req.response
        ..statusCode = 200
        ..headers.contentType = ContentType('text', 'event-stream');
      res.write('event: message_start\n'
          'data: {"type":"message_start"}\n\n');
      await res.close();
    });

    var observedCount = 0;
    final proxy = AnthropicProxy(
      ProxyCallbacks(
        onSseEvent: (event, path, {required bool observe}) {
          if (observe) {
            observedCount++;
          }
        },
      ),
      upstreamHost: '127.0.0.1',
      upstreamScheme: 'http',
      upstreamPort: upstream.port,
    );
    await proxy.start();
    addTearDown(proxy.stop);

    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final req = await client.postUrl(Uri.parse('${proxy.baseUrl}/v1/messages'));
    req.headers.contentType = ContentType.json;
    req.add(utf8.encode(jsonEncode({
      'system': 'Generate a concise, sentence-case title for this session.',
      'response_format': {
        'type': 'json_schema',
        'schema': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
          },
          'required': ['title'],
        },
      },
    })));
    final resp = await req.close();
    final body = await resp.transform(utf8.decoder).join();

    // Forwarded to Claude unchanged, but not surfaced as agent output.
    expect(body, contains('message_start'));
    expect(observedCount, 0);
  });
}
