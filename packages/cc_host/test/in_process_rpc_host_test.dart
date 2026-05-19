import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// A minimal [RpcDispatcher]: a real `initialize` result, everything else echoes.
/// The host's repo-RPC + subscription surface does not route through the
/// dispatcher (the session handles `repo/call` / `sub/*` itself), so this only
/// needs to satisfy `initialize`.
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
  group('InProcessRpcHost', () {
    late StreamController<Map<String, dynamic>> tick;
    late RepoOpDispatcher repoOps;
    late WatchQueryRegistry watchQueries;
    late InProcessRpcHost host;

    setUp(() {
      // A trigger the watch-query handler can pump a snapshot from, so we can
      // observe the workspace the handler was opened under.
      tick = StreamController<Map<String, dynamic>>.broadcast();

      repoOps = RepoOpDispatcher(
        registry: RepoOpRegistry([
          // One workspace-scoped op: it echoes the workspace the client
          // injected into args as `workspace_id` (from `activeWorkspaceId`).
          // If that didn't flow through, ctx.workspaceId would be null/wrong.
          RepoOp(
            name: 'probe.whoami',
            kind: RepoOpKind.read,
            handler: (ctx) async => {'bound_workspace': ctx.workspaceId},
          ),
        ], catalogVersion: 7),
        mapException: (e) => null,
      );

      watchQueries = WatchQueryRegistry([
        // One workspace-scoped query: the FIRST snapshot it emits carries the
        // workspace the subscription was opened under, so a re-subscribe after
        // a binding change proves the new workspace took effect.
        WatchQuery(
          name: 'probe.watchWorkspace',
          handler: (ctx) async* {
            // Emit an immediate snapshot tagged with the bound workspace, then
            // relay any further ticks (also tagged) — covers both the initial
            // reconciliation and live updates.
            yield {'bound_workspace': ctx.workspaceId};
            yield* tick.stream.map(
              (d) => {'bound_workspace': ctx.workspaceId, ...d},
            );
          },
        ),
      ]);

      host = InProcessRpcHost(
        dispatcher: _BaseDispatcher(),
        workspaceResolver: () async => const [
          (id: 'ws-A', name: 'Workspace A'),
          (id: 'ws-B', name: 'Workspace B'),
        ],
        repoOps: repoOps,
        watchQueries: watchQueries,
        initialWorkspaceId: 'ws-A',
        deviceId: 'desktop-self',
      );
    });

    tearDown(() async {
      await host.dispose();
      await tick.close();
    });

    test('initialize advertises the repo-RPC catalog + subscriptions', () async {
      final init = await host.client.initialize();
      final caps = (init['capabilities'] as Map).cast<String, dynamic>();
      expect((caps['repoRpc'] as Map)['catalogVersion'], 7);
      expect((caps['subscriptions'] as Map)['snapshot'], isTrue);
    });

    test('the seeded binding flows through repo/call as the workspace', () async {
      final res = await host.client.call('probe.whoami', const {});
      expect(res['bound_workspace'], 'ws-A');
    });

    test(
      'a workspace-scoped subscription opens under the bound workspace',
      () async {
        final first = await host.client
            .subscribe('probe.watchWorkspace', const {})
            .first;
        expect(first['bound_workspace'], 'ws-A');
      },
    );

    test(
      'changing the binding re-scopes a fresh repo/call and subscribe',
      () async {
        // Sanity: starts on ws-A.
        final before = await host.client.call('probe.whoami', const {});
        expect(before['bound_workspace'], 'ws-A');

        // Follow a desktop active-workspace switch.
        host.rebindWorkspace('ws-B');

        // A fresh repo/call now resolves to ws-B.
        final after = await host.client.call('probe.whoami', const {});
        expect(after['bound_workspace'], 'ws-B');

        // A FRESH subscription opens under ws-B (its first snapshot is tagged).
        final firstAfter = await host.client
            .subscribe('probe.watchWorkspace', const {})
            .first;
        expect(firstAfter['bound_workspace'], 'ws-B');
      },
    );

    test(
      'a workspace-scoped op with no workspace_id is rejected (no default-allow)',
      () async {
        // Clear the active workspace so the client injects no `workspace_id`
        // into args — the stateless server has nothing to scope by.
        host.rebindWorkspace(null);
        await expectLater(
          host.client.call('probe.whoami', const {}),
          throwsA(
            isA<RemoteRpcException>()
                .having((e) => e.code, 'code', RpcErrorCodes.validation)
                .having(
                  (e) => e.message,
                  'message',
                  contains('Missing required argument: workspace_id'),
                ),
          ),
        );
      },
    );
  });
}
