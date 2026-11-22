import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/dispatch/acp/acp_client.dart';
import 'package:test/test.dart';

/// The agent→client half of ACP: requests are answered, and only ids this
/// client sent complete its calls.
void main() {
  late List<Map<String, dynamic>> sent;
  setUp(() => sent = []);

  AcpClient client({
    Future<Object?> Function(String, Map<String, dynamic>)? onRequest,
  }) => AcpClient(
    send: (line) => sent.add(jsonDecode(line) as Map<String, dynamic>),
    onRequest: onRequest,
  );

  test(
    'an agent request reusing a pending id does not answer our call',
    () async {
      final c = client(
        onRequest: (method, params) async => {
          'outcome': 'ok',
          'method': method,
        },
      );
      final init = c.initialize();
      final ourId = sent.single['id'];
      // The agent counts from 1 too: its request carries OUR pending id.
      c.feedLine(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': ourId,
          'method': 'session/request_permission',
          'params': {'sessionId': 's'},
        }),
      );
      await Future<void>.delayed(Duration.zero);
      // The request was answered...
      expect(sent.last['id'], ourId);
      expect(sent.last['result'], {
        'outcome': 'ok',
        'method': 'session/request_permission',
      });
      // ...and our initialize is still waiting for ITS response.
      var done = false;
      unawaited(init.then((_) => done = true));
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse);
      c.feedLine(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': ourId,
          'result': {'protocolVersion': 1},
        }),
      );
      expect(await init, {'protocolVersion': 1});
      await c.close();
    },
  );

  test('a response to an id we never sent is ignored', () async {
    final c = client();
    final init = c.initialize();
    c.feedLine(jsonEncode({'jsonrpc': '2.0', 'id': 999, 'result': {}}));
    var done = false;
    unawaited(init.then((_) => done = true, onError: (_) => done = true));
    await Future<void>.delayed(Duration.zero);
    expect(done, isFalse);
    await c.close();
  });

  test('without a handler every agent request is refused', () async {
    final c = client();
    c.feedLine(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 7,
        'method': 'fs/read_text_file',
        'params': {'path': '/etc/passwd'},
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(sent.single['id'], 7);
    expect((sent.single['error'] as Map)['code'], AcpClient.methodNotFound);
    await c.close();
  });

  test('a handler refusal is an error reply with its code', () async {
    final c = client(
      onRequest: (method, params) async =>
          throw AcpRpcException('outside the run', code: -32000),
    );
    c.feedLine(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 'abc',
        'method': 'fs/write_text_file',
        'params': {'path': '/etc/x', 'content': ''},
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(sent.single['id'], 'abc');
    expect(sent.single['error'], {
      'code': -32000,
      'message': 'outside the run',
    });
    await c.close();
  });

  test(
    'initialize advertises fs only when it can answer, never a terminal',
    () {
      final withFs = client(onRequest: (_, _) async => null);
      unawaited(withFs.initialize().catchError((_) => <String, dynamic>{}));
      final caps = (sent.single['params'] as Map)['clientCapabilities'] as Map;
      expect(caps['fs'], {'readTextFile': true, 'writeTextFile': true});
      expect(caps['terminal'], isFalse);
      sent.clear();
      final without = client();
      unawaited(without.initialize().catchError((_) => <String, dynamic>{}));
      final caps2 = (sent.single['params'] as Map)['clientCapabilities'] as Map;
      expect(caps2['fs'], {'readTextFile': false, 'writeTextFile': false});
      unawaited(withFs.close());
      unawaited(without.close());
    },
  );

  test('a usage update in dollars is the run cost so far', () async {
    final c = client();
    final events = <AgentProcessEvent>[];
    final sub = c.events.listen(events.add);
    for (final cost in [
      {'amount': 0.42, 'currency': 'USD'},
      {'amount': 9, 'currency': 'EUR'},
    ]) {
      c.feedLine(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'session/update',
          'params': {
            'sessionId': 's',
            'update': {'sessionUpdate': 'usage_update', 'cost': cost},
          },
        }),
      );
    }
    await Future<void>.delayed(Duration.zero);

    final usage = events.whereType<UsageEvent>().single;
    expect(usage.scope, UsageScope.runCumulative);
    expect(usage.usage.costMicros, 420000);
    await sub.cancel();
    await c.close();
  });

  test('cancel is a session/cancel notification for the session', () async {
    final c = client();

    c.sessionCancel('sess-9');

    expect(sent.single, {
      'jsonrpc': '2.0',
      'method': 'session/cancel',
      'params': {'sessionId': 'sess-9'},
    });
    await c.close();
  });
}
