import 'dart:async';
import 'dart:io';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:test/test.dart';

/// A local server whose response HEADERS are flushed immediately while the
/// BODY is released on demand, so "headers arrived" and "a body byte arrived"
/// are separately observable.
class _GatedServer {
  _GatedServer._(this._server, this.port);

  final HttpServer _server;
  final int port;

  /// Completed when the response headers have been flushed.
  final headersFlushed = Completer<void>();

  /// Completed by the test to let the body be written.
  final releaseBody = Completer<void>();

  /// Set by the test before the request arrives: the response status.
  int status = 200;

  /// Set by the test before the request arrives: the body written after
  /// [releaseBody] completes. Empty = headers only, no body at all.
  String body = '';

  static Future<_GatedServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final gated = _GatedServer._(server, server.port);
    server.listen((request) async {
      request.response.statusCode = gated.status;
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      // No buffering: the flush below must actually reach the client.
      request.response.bufferOutput = false;
      await request.response.flush();
      gated.headersFlushed.complete();
      if (gated.body.isNotEmpty) {
        await gated.releaseBody.future;
        request.response.write(gated.body);
        await request.response.flush();
      }
      await request.response.close();
    });
    return gated;
  }

  Uri get uri => Uri.parse('http://127.0.0.1:$port/v1/messages');

  Future<void> stop() => _server.close(force: true);
}

/// Records the ORDER in which boundaries were observed.
class _Timeline {
  final List<String> entries = [];

  void add(String entry) => entries.add(entry);

  /// The index of [entry], or -1.
  int indexOf(String entry) => entries.indexOf(entry);
}

void main() {
  test('fires on the first body byte, never on headers alone', () async {
    final server = await _GatedServer.start();
    addTearDown(server.stop);
    server.body =
        'data: {"type":"content_block_delta","index":0,'
        '"delta":{"type":"text_delta","text":"hi"}}\n\n'
        'data: {"type":"message_stop"}\n\n';

    final timeline = _Timeline();
    final http = ProviderHttp();
    final stream = http.postSse(
      server.uri,
      headers: const {'x-api-key': 'k', 'anthropic-version': '2023-06-01'},
      body: const {'model': 'm', 'stream': true},
      onRequestSent: () => timeline.add('requestSent'),
      onFirstBodyByte: () => timeline.add('bodyByte'),
    );

    final done = stream.listen((message) {
      if (message.data.isNotEmpty) {
        timeline.add(
          'parsed:${message.data.contains('message_stop') ? 'stop' : 'delta'}',
        );
      }
    }).asFuture<void>();

    // Headers are flushed and the body is still withheld: the callback must not
    // have fired yet — that is exactly the difference between the header
    // boundary and the body-byte boundary.
    await server.headersFlushed.future;
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(
      timeline.entries,
      ['requestSent'],
      reason:
          'headers alone are not a response byte; dart:io completes '
          'request.close() before any body arrives',
    );

    server.releaseBody.complete();
    await done;

    expect(timeline.entries.take(2), ['requestSent', 'bodyByte']);
    expect(
      timeline.indexOf('bodyByte'),
      lessThan(timeline.indexOf('parsed:delta')),
      reason:
          'the byte signal must precede the parsed model event, or it is '
          'measuring the parser rather than the transport',
    );
  });

  test('stays null when the response carries no body', () async {
    final server = await _GatedServer.start();
    addTearDown(server.stop);
    // headers only; the body is never written
    var fired = 0;
    await ProviderHttp()
        .postSse(
          server.uri,
          headers: const {},
          body: const {},
          onFirstBodyByte: () => fired++,
        )
        .drain<void>();
    expect(fired, 0);
  });

  test('fires for a non-2xx error body too', () async {
    final server = await _GatedServer.start();
    addTearDown(server.stop);
    server.status = 429;
    server.body = '{"error":{"type":"rate_limit_error","message":"slow down"}}';

    var fired = 0;
    // The server releases its error body as soon as the request arrives; the
    // completer is completed up front so no test-side wait can deadlock on a
    // request that has not been sent yet.
    server.releaseBody.complete();
    await expectLater(
      ProviderHttp()
          .postSse(
            server.uri,
            headers: const {},
            body: const {},
            onFirstBodyByte: () => fired++,
          )
          .drain<void>(),
      throwsA(
        isA<ProviderHttpException>()
            .having((e) => e.statusCode, 'statusCode', 429)
            .having((e) => e.body, 'body', contains('rate_limit_error')),
      ),
    );
    expect(fired, 1, reason: 'an error body is still a response body');
  });

  test(
    'the ledger records a byte boundary the model event comes after',
    () async {
      final server = await _GatedServer.start();
      addTearDown(server.stop);
      server.body =
          'data: {"type":"message_start","message":{"model":"wire-model",'
          '"usage":{"input_tokens":7,"output_tokens":0}}}\n\n'
          'data: {"type":"content_block_delta","index":0,'
          '"delta":{"type":"text_delta","text":"hi"}}\n\n'
          'data: {"type":"message_stop"}\n\n';

      final ledger = ProviderCallLedger(runId: 'run-1');
      final provider = ObservedLlmProvider(
        AnthropicProvider(
          apiKey: 'k',
          baseUrl: 'http://127.0.0.1:${server.port}',
          http: ProviderHttp(),
        ),
        observer: ledger,
        identity: ledger.identity,
      );

      final stream = provider
          .complete(
            messages: [HarnessMessage.user('hi')],
            config: const LlmCompleteConfig(model: 'claude-opus-4-8'),
          )
          .drain<void>();
      await server.headersFlushed.future;
      server.releaseBody.complete();
      await stream;

      final record = ledger.records.single;
      expect(record.requestSentMs, isNotNull);
      expect(record.transportFirstByteMs, isNotNull);
      expect(record.firstModelEventMs, isNotNull);
      expect(
        record.transportFirstByteMs!,
        lessThanOrEqualTo(record.firstModelEventMs!),
        reason:
            'the transport boundary is by construction not after the model '
            'delta it precedes',
      );
      expect(
        record.requestSentMs!,
        lessThanOrEqualTo(record.transportFirstByteMs!),
      );
      expect(record.model, 'wire-model');
    },
  );

  test(
    'cancellation after message start preserves known input and cache usage',
    () async {
      final server = await _GatedServer.start();
      addTearDown(server.stop);
      server.body =
          'data: {"type":"message_start","message":{"model":"wire-model",'
          '"usage":{"input_tokens":77,"output_tokens":0,'
          '"cache_creation_input_tokens":33}}}\n\n';
      final ledger = ProviderCallLedger(runId: 'cancelled');
      final provider = ObservedLlmProvider(
        AnthropicProvider(
          apiKey: 'test',
          baseUrl: 'http://127.0.0.1:${server.port}',
          http: ProviderHttp(),
        ),
        observer: ledger,
        identity: ledger.identity,
      );
      final first = provider
          .complete(messages: [HarnessMessage.user('work')])
          .take(1)
          .toList();
      await server.headersFlushed.future;
      server.releaseBody.complete();
      expect((await first).single, isA<LlmUsage>());
      final record = ledger.records.single;
      expect(record.outcome, ProviderCallOutcome.cancelled);
      expect(record.usageReported, isTrue);
      expect(record.usage.inputTokens, 77);
      expect(record.usage.cacheWriteTokens, 33);
    },
  );
}
