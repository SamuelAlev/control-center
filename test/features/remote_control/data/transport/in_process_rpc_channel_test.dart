import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A trivial dispatcher that echoes the request method back — enough to prove a
/// frame made the full round trip through the session and the channel.
class _EchoDispatcher implements RpcDispatcher {
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async {
    return <String, dynamic>{
      'jsonrpc': '2.0',
      'id': request.id,
      'result': <String, dynamic>{'echoed': request.method},
    };
  }
}

void main() {
  group('InProcessRpcChannel', () {
    test('frames flow both ways and close propagates to the peer', () async {
      final (server, client) = InProcessRpcChannel.pair();
      final got = <Map<String, dynamic>>[];
      final sub = server.incoming.listen(got.add);

      await client.send({'hello': 'world'});
      await Future<void>.delayed(Duration.zero);
      expect(got, [
        {'hello': 'world'},
      ]);

      final clientClosed = client.state.firstWhere(
        (s) => s == RemoteChannelState.closed,
      );
      await server.close();
      expect(
        await clientClosed.timeout(const Duration(seconds: 1)),
        RemoteChannelState.closed,
      );
      await sub.cancel();
    });

    test(
      'RemoteRpcSession pumps requests through the in-process channel',
      () async {
        final (server, client) = InProcessRpcChannel.pair();
        final session = RemoteRpcSession(
          deviceId: 'd1',
          channel: server,
          dispatcher: _EchoDispatcher(),
          capability: SessionCapability.fullClient,
          workspaceResolver: () async => const [(id: 'ws1', name: 'WS One')],
        );
        await session.start();

        final responses = <Map<String, dynamic>>[];
        final sub = client.incoming.listen(responses.add);

        await client.send(JsonRpcRequest(method: 'initialize', id: 1).toJson());
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(responses, hasLength(1));
        expect(responses.single['id'], 1);
        expect((responses.single['result'] as Map)['echoed'], 'initialize');

        await session.stop();
        await sub.cancel();
      },
    );

    test(
      'initialize advertises the repo-RPC catalog when repoOps is wired',
      () async {
        final (server, client) = InProcessRpcChannel.pair();
        final repoOps = RepoOpDispatcher(
          registry: RepoOpRegistry([
            RepoOp(
              name: 'tickets.list',
              kind: RepoOpKind.read,
              handler: (ctx) async => const {},
            ),
          ], catalogVersion: 5),
        );
        final session = RemoteRpcSession(
          deviceId: 'd1',
          channel: server,
          dispatcher: _EchoDispatcher(),
          capability: SessionCapability.fullClient,
          workspaceResolver: () async => const [],
          repoOps: repoOps,
        );
        await session.start();

        final responses = <Map<String, dynamic>>[];
        final sub = client.incoming.listen(responses.add);
        await client.send(JsonRpcRequest(method: 'initialize', id: 1).toJson());
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final caps = (responses.single['result'] as Map)['capabilities'] as Map;
        expect((caps['repoRpc'] as Map)['catalogVersion'], 5);

        await session.stop();
        await sub.cancel();
      },
    );

    test(
      'a scoped repo/call carries its workspace_id in args end-to-end',
      () async {
        // The server is stateless — there is no `session/set_workspace`. A
        // workspace-scoped op carries its target workspace in `params.args`, and
        // that value reaches the handler's `ctx.workspaceId` unchanged.
        final (server, client) = InProcessRpcChannel.pair();
        final repoOps = RepoOpDispatcher(
          registry: RepoOpRegistry([
            RepoOp(
              name: 'tickets.list',
              kind: RepoOpKind.read,
              handler: (ctx) async => {'workspace_id': ctx.workspaceId},
            ),
          ], catalogVersion: 5),
        );
        final session = RemoteRpcSession(
          deviceId: 'd1',
          channel: server,
          dispatcher: _EchoDispatcher(),
          capability: SessionCapability.fullClient,
          workspaceResolver: () async => const [],
          repoOps: repoOps,
        );
        await session.start();

        final responses = <Map<String, dynamic>>[];
        final sub = client.incoming.listen(responses.add);

        await client.send(
          JsonRpcRequest(
            method: RpcMethods.repoCall,
            params: const {
              'op': 'tickets.list',
              'args': {'workspace_id': 'ws2'},
            },
            id: 7,
          ).toJson(),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        final result = responses.single['result'] as Map;
        expect((result['data'] as Map)['workspace_id'], 'ws2');

        await session.stop();
        await sub.cancel();
      },
    );
  });
}
