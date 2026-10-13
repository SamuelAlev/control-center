import 'dart:async';
import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  test(
    'late terminal listeners receive only live output, not replayed bytes',
    () async {
      final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
      final subscriptions = <String>{};
      var nextId = 0;
      final requests = serverChannel.incoming.listen((frame) {
        final params = (frame['params'] as Map).cast<String, dynamic>();
        final Map<String, dynamic> result;
        switch (frame['method']) {
          case RpcMethods.subscribe:
            final id = 's${++nextId}';
            subscriptions.add(id);
            result = {'subscriptionId': id};
          case RpcMethods.unsubscribe:
            subscriptions.remove(params['subscriptionId']);
            result = const {'ok': true};
          default:
            throw StateError('Unexpected method: ${frame['method']}');
        }
        unawaited(
          serverChannel.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'result': result,
          }),
        );
      });
      final client = RemoteRpcClient(clientChannel)..start();
      addTearDown(() async {
        await client.close();
        await requests.cancel();
        await serverChannel.close();
      });
      final repository = RemoteTerminalRepository(client);
      final firstOutput = StringBuffer();
      final secondOutput = StringBuffer();
      final first = repository
          .output('pty-1')
          .transform(utf8.decoder)
          .listen(firstOutput.write);
      addTearDown(first.cancel);
      await pumpEventQueue(times: 10);

      Future<void> emit(String text) async {
        for (final id in subscriptions) {
          unawaited(
            serverChannel.send({
              'jsonrpc': '2.0',
              'method': RpcMethods.subSnapshot,
              'params': {
                'subscriptionId': id,
                'full': false,
                'data': {'chunk': base64Encode(utf8.encode(text))},
              },
            }),
          );
        }
        await pumpEventQueue(times: 10);
      }

      await emit('old prompt\r\n');
      final second = repository
          .output('pty-1')
          .transform(utf8.decoder)
          .listen(secondOutput.write);
      addTearDown(second.cancel);
      await pumpEventQueue(times: 10);
      await emit('live output');

      expect(firstOutput.toString(), 'old prompt\r\nlive output');
      expect(secondOutput.toString(), 'live output');
    },
  );
}
