import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drives an [AcpClient] with scripted JSON-RPC fixtures: each enqueued line is
/// fed to [AcpClient.feedLine] in order; captured `send` output is recorded.
class _Harness {
  _Harness() {
    client = AcpClient(send: _out.add, onDone: _done.complete);
  }

  late final AcpClient client;
  final _done = Completer<void>();
  final _out = <String>[];

  List<String> get sent => _out;

  /// Feeds [line] (a raw JSON-RPC line) to the client.
  void feed(String line) => client.feedLine(line);

  /// Feeds a decoded object as a JSON-RPC line.
  void feedJson(Map<String, dynamic> obj) => client.feedLine(jsonEncode(obj));

  Future<void> get done => _done.future;

  void close() => client.close();
}

void main() {
  group('AcpClient', () {
    test('initialize returns the agent result', () async {
      final h = _Harness();
      final init = h.client.initialize();
      await Future<void>.delayed(Duration.zero);
      // Respond to the initialize request (id 1).
      final sentReq = jsonDecode(h.sent.single) as Map<String, dynamic>;
      expect(sentReq['method'], 'initialize');
      h.feedJson({
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'protocolVersion': '2025-07-01'},
      });
      final result = await init;
      expect(result['protocolVersion'], '2025-07-01');
      h.close();
    });

    test('translates session/update notifications into events', () async {
      final h = _Harness();
      final events = <AgentProcessEvent>[];
      final sub = h.client.events.listen(events.add);

      // An assistant text chunk → TextEvent.
      h.feedJson({
        'jsonrpc': '2.0',
        'method': 'session/update',
        'params': {
          'sessionId': 's1',
          'update': {
            'sessionUpdate': 'agent_message_chunk',
            'content': {'type': 'text', 'text': 'Hello '},
          },
        },
      });
      // A reasoning chunk → ThinkingEvent.
      h.feedJson({
        'jsonrpc': '2.0',
        'method': 'session/update',
        'params': {
          'sessionId': 's1',
          'update': {
            'sessionUpdate': 'agent_thought_chunk',
            'content': {'type': 'text', 'text': 'reasoning'},
          },
        },
      });
      // A tool call → ToolCallEvent.
      h.feedJson({
        'jsonrpc': '2.0',
        'method': 'session/update',
        'params': {
          'sessionId': 's1',
          'update': {
            'sessionUpdate': 'tool_call',
            'toolCallId': 'tc1',
            'toolName': 'Bash',
            'rawInput': {'command': 'ls'},
          },
        },
      });
      // A second text chunk (array content form).
      h.feedJson({
        'jsonrpc': '2.0',
        'method': 'session/update',
        'params': {
          'sessionId': 's1',
          'update': {
            'sessionUpdate': 'agent_message_chunk',
            'content': [
              {'type': 'text', 'text': 'world'},
            ],
          },
        },
      });

      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(4));
      expect(events[0], isA<TextEvent>());
      expect((events[0] as TextEvent).content, 'Hello ');
      expect(events[1], isA<ThinkingEvent>());
      expect((events[1] as ThinkingEvent).content, 'reasoning');
      expect(events[2], isA<ToolCallEvent>());
      expect((events[2] as ToolCallEvent).toolName, 'Bash');
      expect(events[3], isA<TextEvent>());
      expect((events[3] as TextEvent).content, 'world');

      await sub.cancel();
      h.close();
    });

    test('ignores non-JSON banner lines', () async {
      final h = _Harness();
      final events = <AgentProcessEvent>[];
      final sub = h.client.events.listen(events.add);

      h.feed('some agent banner output');
      h.feed('');
      await sub.cancel();
      h.close();
    });

    test('onDone fires when session/prompt result arrives', () async {
      final h = _Harness();
      // Issue a prompt (id 1) and respond with a result.
      final prompt = h.client.sessionPrompt(sessionId: 's1', prompt: 'hi');
      await Future<void>.delayed(Duration.zero);
      h.feedJson({'jsonrpc': '2.0', 'id': 1, 'result': {}});
      await prompt;
      await expectLater(h.done, completes);
      h.close();
    });

    test('surfaces RPC errors as AcpRpcException', () async {
      final h = _Harness();
      final init = h.client.initialize();
      await Future<void>.delayed(Duration.zero);
      h.feedJson({
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': -32_600, 'message': 'bad'},
      });
      await expectLater(init, throwsA(isA<AcpRpcException>()));
      h.close();
    });
  });
}

// Workaround for the analyzer complaint about the cascade in the first test.
AcpClient get client => _holder!;
AcpClient? _holder;
