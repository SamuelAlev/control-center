import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal dispatcher: a real initialize result, everything else echoes.
class _BaseDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async {
    if (request.method == 'initialize') {
      return <String, dynamic>{
        'jsonrpc': '2.0',
        'id': request.id,
        'result': <String, dynamic>{
          'protocolVersion': '2025-01-01',
          'capabilities': <String, dynamic>{'tools': <String, dynamic>{}},
        },
      };
    }
    return <String, dynamic>{
      'jsonrpc': '2.0',
      'id': request.id,
      'result': <String, dynamic>{'echoed': request.method},
    };
  }
}

void main() {
  test(
    'full client↔server protocol round trip over the in-process channel',
    () async {
      final ticketStream = StreamController<Map<String, dynamic>>.broadcast();

      final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
      final session = RemoteRpcSession(
        deviceId: 'dev-1',
        channel: serverChannel,
        dispatcher: _BaseDispatcher(),
        capability: SessionCapability.fullClient,
        workspaceResolver: () async => const [(id: 'ws1', name: 'WS One')],
        repoOps: RepoOpDispatcher(
          registry: RepoOpRegistry([
            RepoOp(
              name: 'tickets.assign',
              kind: RepoOpKind.mutate,
              requiredArgs: ['ticket_id'],
              handler: (ctx) async => {
                'ticket_id': ctx.args['ticket_id'],
                'workspace_id': ctx.workspaceId,
              },
            ),
          ], catalogVersion: 4),
        ),
        watchQueries: WatchQueryRegistry([
          WatchQuery(
            name: 'tickets.watchForWorkspace',
            handler: (ctx) =>
                ticketStream.stream.map((d) => {'ws': ctx.workspaceId, ...d}),
          ),
        ]),
      );
      await session.start();

      // The server is stateless: the client carries its active workspace into
      // every scoped call/subscribe as `workspace_id`.
      final client = RemoteRpcClient(clientChannel)
        ..activeWorkspaceId = 'ws1'
        ..start();

      // 1. initialize → repo-RPC catalog advertised.
      final init = await client.initialize();
      final caps = (init['capabilities'] as Map).cast<String, dynamic>();
      expect((caps['repoRpc'] as Map)['catalogVersion'], 4);

      // 2. repo/call mutate — the workspace_id the client carries reaches the
      // handler unchanged (no server-side override).
      final assigned = await client.call('tickets.assign', {
        'ticket_id': 'T-1',
      });
      expect(assigned['ticket_id'], 'T-1');
      expect(assigned['workspace_id'], 'ws1');

      // 3. validation error surfaces as a typed exception (the required
      // `ticket_id` arg is missing).
      await expectLater(
        client.call('tickets.assign', const {}),
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.validation,
          ),
        ),
      );

      // 4. subscribe → server proxies the watch stream as snapshots.
      final snapshots = <Map<String, dynamic>>[];
      final sub = client
          .subscribe('tickets.watchForWorkspace', {})
          .listen(snapshots.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      ticketStream.add({
        'tickets': [1, 2, 3],
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(snapshots, hasLength(1));
      expect(snapshots.single['ws'], 'ws1'); // workspace carried by the client
      expect(snapshots.single['tickets'], [1, 2, 3]);

      await sub.cancel();
      await client.close();
      await session.stop();
      await ticketStream.close();
    },
  );
}
