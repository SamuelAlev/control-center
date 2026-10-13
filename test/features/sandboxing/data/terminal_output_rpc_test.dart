import 'dart:async';
import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/catalog/terminal_watch_queries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

class _Terminals extends Fake implements TerminalSessionPort {
  final chunks = StreamController<List<int>>.broadcast();

  @override
  Stream<List<int>> output({
    required String workspaceId,
    required String sessionId,
  }) => chunks.stream;

  Future<void> dispose() => chunks.close();
}

void main() {
  late _Terminals terminals;
  late RemoteTerminalRepository repository;

  setUp(() {
    terminals = _Terminals();
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final manager = SubscriptionManager(
      registry: WatchQueryRegistry(buildTerminalWatchQueries(terminals)),
      deviceId: 'device',
      userId: 'user',
      send: (frame) => unawaited(serverChannel.send(frame)),
    );
    final requests = serverChannel.incoming.listen((frame) {
      final params = (frame['params'] as Map).cast<String, dynamic>();
      final response = switch (frame['method']) {
        RpcMethods.subscribe => manager.subscribe(
          id: frame['id'],
          params: params,
        ),
        RpcMethods.unsubscribe => manager.unsubscribe(
          id: frame['id'],
          params: params,
        ),
        _ => throw StateError('Unexpected method: ${frame['method']}'),
      };
      unawaited(serverChannel.send(response));
    });
    final client = RemoteRpcClient(clientChannel)
      ..activeWorkspaceId = 'workspace'
      ..start();
    repository = RemoteTerminalRepository(client);
    addTearDown(() async {
      await client.close();
      await manager.dispose();
      await requests.cancel();
      await terminals.dispose();
      await serverChannel.close();
    });
  });

  Future<Terminal> renderOutput() async {
    final terminal = Terminal()..resize(80, 24);
    final subscription = repository
        .output('pty-1')
        .transform(const Utf8Decoder())
        .listen(terminal.write);
    addTearDown(subscription.cancel);
    await pumpEventQueue(times: 10);
    return terminal;
  }

  test('preserves burst output with split ANSI and UTF-8 sequences', () async {
    final terminal = await renderOutput();
    final unicode = utf8.encode('café 世界');
    for (final chunk in [
      utf8.encode('stale prompt'),
      utf8.encode('\r\x1b['),
      utf8.encode('2K\x1b[32m> '),
      unicode.sublist(0, 4),
      unicode.sublist(4, 7),
      unicode.sublist(7),
      utf8.encode('\x1b[0m'),
    ]) {
      terminals.chunks.add(chunk);
    }
    await pumpEventQueue(times: 10);

    expect(terminal.buffer.lines[0].getText().trimRight(), '> café 世界');
  });

  test('repeated key echoes remain visible across separate turns', () async {
    final terminal = await renderOutput();
    for (var i = 0; i < 4; i++) {
      terminals.chunks.add(utf8.encode('l'));
      await pumpEventQueue(times: 10);
    }

    expect(terminal.buffer.lines[0].getText().trimRight(), 'llll');
  });
}
