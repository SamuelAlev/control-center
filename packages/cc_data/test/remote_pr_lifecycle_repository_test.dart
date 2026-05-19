import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RemotePrLifecycleRepository] and [RpcPrLifecycleRepository] — the
/// compose-PR lifecycle over RPC. Pins the ops + args, the watch query, the
/// DTO→entity mapping and the GitHub publish result map.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  const prPayload = {
    'id': 'pr-1',
    'workspace_id': 'ws-1',
    'status': 'draft',
    'title': 'Ship it',
    'body': 'body',
    'branch': 'feature',
    'created_at': '2026-07-01T09:00:00.000',
    'updated_at': '2026-07-01T09:00:00.000',
  };

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemotePrLifecycleRepository', () {
    test(
      'watchByWorkspace subscribes with its workspace and maps the prs array',
      () async {
        host.snapshotFor('pr_lifecycle.watchByWorkspace', {
          'prs': [prPayload],
        });
        final repo = RemotePrLifecycleRepository(client);
        final list = await repo.watchByWorkspace('ws-1').first;
        expect(list.length, 1);
        expect(list.first.id, 'pr-1');
        expect(list.first.title, 'Ship it');
        final sub = host.lastSubscribe!;
        expect(sub.query, 'pr_lifecycle.watchByWorkspace');
        // The workspace id selects the database file server-side, so the
        // subscription carries it — it is never inferred from a bound session.
        expect(sub.args, {'workspace_id': 'ws-1'});
      },
    );

    test('getById maps the pr when present', () async {
      host.callResults['pr_lifecycle.getById'] = {'pr': prPayload};
      final repo = RemotePrLifecycleRepository(client);
      final pr = await repo.getById('ws-1', 'pr-1');
      expect(pr, isNotNull);
      expect(pr!.id, 'pr-1');
      final args = host.lastCall('pr_lifecycle.getById')!.args;
      expect(args['workspace_id'], 'ws-1');
      expect(args['id'], 'pr-1');
    });

    test('getById returns null when absent', () async {
      host.callResults['pr_lifecycle.getById'] = const {};
      final repo = RemotePrLifecycleRepository(client);
      expect(await repo.getById('ws-1', 'pr-1'), isNull);
    });

    test('getById returns null when pr is not a Map', () async {
      host.callResults['pr_lifecycle.getById'] = {'pr': 'nope'};
      final repo = RemotePrLifecycleRepository(client);
      expect(await repo.getById('ws-1', 'pr-1'), isNull);
    });

    test(
      'createDraft forwards workspace + title + body + diff_summary',
      () async {
        host.callResults['pr_lifecycle.createDraft'] = {'id': 'pr-2'};
        final repo = RemotePrLifecycleRepository(client);
        expect(
          await repo.createDraft(
            workspaceId: 'ws-1',
            title: 'T',
            body: 'B',
            diffSummary: 'diff',
          ),
          'pr-2',
        );
        final call = host.lastCall('pr_lifecycle.createDraft')!;
        expect(call.args['workspace_id'], 'ws-1');
        expect(call.args['title'], 'T');
        expect(call.args['body'], 'B');
        expect(call.args['diff_summary'], 'diff');
      },
    );

    test('updateDraft forwards the workspace + the optional fields', () async {
      final repo = RemotePrLifecycleRepository(client);
      await repo.updateDraft(
        'ws-1',
        'pr-1',
        title: 'T',
        body: 'B',
        status: 'created',
        prNumber: 42,
        prUrl: 'https://x',
      );
      final call = host.lastCall('pr_lifecycle.updateDraft')!;
      expect(call.args['workspace_id'], 'ws-1');
      expect(call.args['pr_id'], 'pr-1');
      expect(call.args['title'], 'T');
      expect(call.args['status'], 'created');
      expect(call.args['pr_number'], 42);
      expect(call.args['pr_url'], 'https://x');
    });

    test(
      'publishToForge forwards the publish args and returns the result map',
      () async {
        host.callResults['pr_lifecycle.publish'] = {
          'result': {'number': 7, 'html_url': 'u'},
        };
        final repo = RemotePrLifecycleRepository(client);
        final result = await repo.publishToForge(
          workspaceId: 'ws-1',
          prId: 'pr-1',
          owner: 'o',
          repo: 'r',
          title: 'T',
          body: 'B',
          head: 'feature',
          base: 'main',
          draft: true,
        );
        expect(result['number'], 7);
        expect(result['html_url'], 'u');
        final call = host.lastCall('pr_lifecycle.publish')!;
        expect(call.args['workspace_id'], 'ws-1');
        expect(call.args['pr_id'], 'pr-1');
        expect(call.args['owner'], 'o');
        expect(call.args['draft'], isTrue);
        expect(call.args['assignees'], const <String>[]);
      },
    );

    test('publishToForge returns an empty map when result is absent', () async {
      host.callResults['pr_lifecycle.publish'] = const {};
      final repo = RemotePrLifecycleRepository(client);
      expect(
        await repo.publishToForge(
          workspaceId: 'ws-1',
          prId: 'pr-1',
          owner: 'o',
          repo: 'r',
          title: 'T',
          body: 'B',
          head: 'h',
          base: 'b',
        ),
        isEmpty,
      );
    });

    test('delete forwards the workspace + the id', () async {
      final repo = RemotePrLifecycleRepository(client);
      await repo.delete('ws-1', 'pr-1');
      expect(host.lastCall('pr_lifecycle.delete')!.args, {
        'workspace_id': 'ws-1',
        'id': 'pr-1',
      });
    });
  });

  group('RpcPrLifecycleRepository', () {
    test('watchByWorkspace maps the DTO to the entity', () async {
      host.snapshotFor('pr_lifecycle.watchByWorkspace', {
        'prs': [prPayload],
      });
      final repo = RpcPrLifecycleRepository(client);
      final list = await repo.watchByWorkspace('ws-1').first;
      expect(list.first.id, 'pr-1');
      expect(list.first.status, const Draft());
      expect(list.first.createdAt, DateTime(2026, 7, 1, 9));
    });

    test('getById maps the DTO to the entity', () async {
      host.callResults['pr_lifecycle.getById'] = {'pr': prPayload};
      final repo = RpcPrLifecycleRepository(client);
      final pr = await repo.getById('ws-1', 'pr-1');
      expect(pr, isNotNull);
      expect(pr!.title, 'Ship it');
      expect(pr.workspaceId, 'ws-1');
    });

    test('getById returns null when absent', () async {
      host.callResults['pr_lifecycle.getById'] = const {};
      final repo = RpcPrLifecycleRepository(client);
      expect(await repo.getById('ws-1', 'pr-1'), isNull);
    });

    test('write helpers delegate to the remote layer', () async {
      host.callResults['pr_lifecycle.createDraft'] = {'id': 'pr-2'};
      final repo = RpcPrLifecycleRepository(client);
      await repo.createDraft(workspaceId: 'ws-1', title: 'T', body: 'B');
      await repo.updateDraft('ws-1', 'pr-1', status: 'created');
      await repo.delete('ws-1', 'pr-1');
      // Every write names the workspace whose database file it addresses.
      expect(host.lastCall('pr_lifecycle.createDraft')!.args['title'], 'T');
      expect(
        host.lastCall('pr_lifecycle.createDraft')!.args['workspace_id'],
        'ws-1',
      );
      expect(
        host.lastCall('pr_lifecycle.updateDraft')!.args['status'],
        'created',
      );
      expect(
        host.lastCall('pr_lifecycle.updateDraft')!.args['workspace_id'],
        'ws-1',
      );
      expect(host.lastCall('pr_lifecycle.delete')!.args['id'], 'pr-1');
      expect(
        host.lastCall('pr_lifecycle.delete')!.args['workspace_id'],
        'ws-1',
      );
    });

    test('publishToForge delegates and returns the result map', () async {
      host.callResults['pr_lifecycle.publish'] = {
        'result': {'number': 9},
      };
      final repo = RpcPrLifecycleRepository(client);
      final result = await repo.publishToForge(
        workspaceId: 'ws-1',
        prId: 'pr-1',
        owner: 'o',
        repo: 'r',
        title: 'T',
        body: 'B',
        head: 'h',
        base: 'b',
      );
      expect(result['number'], 9);
      expect(
        host.lastCall('pr_lifecycle.publish')!.args['workspace_id'],
        'ws-1',
      );
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// A recorded `sub/subscribe`.
class _Sub {
  const _Sub({required this.query, required this.args});
  final String query;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final List<_Sub> subs = [];
  final Map<String, Map<String, dynamic>> callResults = {};
  final Map<String, Map<String, dynamic>> snapshots = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );
  _Sub? get lastSubscribe => subs.isEmpty ? null : subs.last;

  void snapshotFor(String query, Map<String, dynamic> data) =>
      snapshots[query] = data;

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        final query = params['query'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        subs.add(_Sub(query: query, args: args));
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
        final snapshot = snapshots[query];
        if (snapshot != null) {
          channel.send({
            'jsonrpc': '2.0',
            'method': RpcMethods.subSnapshot,
            'params': {
              'subscriptionId': 's1',
              'rev': 1,
              'full': true,
              'data': snapshot,
            },
          });
        }
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
