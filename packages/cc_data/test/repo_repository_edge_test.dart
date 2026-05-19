import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// The workspace every repo op in this file is scoped to. Repos are
/// workspace-scoped, so a repo id is meaningless without it.
const _ws = 'ws1';

/// Edge-case coverage for [RemoteRepoRepository] and [RpcRepoRepository] — the
/// branches the broad `remote_repositories_test.dart` host stub doesn't drive:
/// `get` non-Map -> null, `upsert` id fallback, `addFromPath`, `delete`,
/// epoch timestamp fallbacks and the `getById` notFound -> null / rethrow
/// paths.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteRepoRepository', () {
    test('get returns null when repo is not a Map', () async {
      host.callResults['repos.get'] = {'repo': 'nope'};
      final repo = RemoteRepoRepository(client);
      expect(await repo.get(_ws, 'r1'), isNull);
    });

    test('get maps a repo map', () async {
      host.callResults['repos.get'] = {
        'repo': {
          'id': 'r1',
          'name': 'cc',
          'path': '/r',
          'remote_owner': 'acme',
          'remote_name': 'cc',
        },
      };
      final repo = RemoteRepoRepository(client);
      final dto = await repo.get(_ws, 'r1');
      expect(dto, isNotNull);
      expect(dto!.id, 'r1');
      expect(dto.remoteOwner, 'acme');
      expect(host.lastCall('repos.get')!.args, {
        'workspace_id': _ws,
        'repo_id': 'r1',
      });
    });

    test('upsert falls back to the dto id when repo_id is absent', () async {
      final repo = RemoteRepoRepository(client);
      final id = await repo.upsert(
        _ws,
        RepoDto(
          id: 'fallback',
          name: 'n',
          path: '/p',
          remoteOwner: 'o',
          remoteName: 'r',
        ),
      );
      expect(id, 'fallback');
      final upsertArgs = host.lastCall('repos.upsert')!.args;
      expect(upsertArgs['workspace_id'], _ws);
      expect((upsertArgs['repo'] as Map)['id'], 'fallback');
    });

    test('delete forwards workspace_id + repo_id', () async {
      final repo = RemoteRepoRepository(client);
      await repo.delete(_ws, 'r9');
      expect(host.lastCall('repos.delete')!.args, {
        'workspace_id': _ws,
        'repo_id': 'r9',
      });
    });

    test('addFromPath maps the returned repo', () async {
      host.callResults['repos.addFromPath'] = {
        'repo': {'id': 'r3', 'name': 'added', 'path': '/srv/checkout'},
      };
      final repo = RemoteRepoRepository(client);
      final dto = await repo.addFromPath(_ws, '/srv/checkout');
      expect(dto.id, 'r3');
      expect(host.lastCall('repos.addFromPath')!.args, {
        'workspace_id': _ws,
        'path': '/srv/checkout',
      });
    });

    test('watchAll skips non-Map rows', () async {
      host.snapshotFor('repos.watchAll', {
        'repos': [
          {'id': 'r1', 'name': 'a'},
          'garbage',
        ],
      });
      final repo = RemoteRepoRepository(client);
      final dtos = await repo.watchAll(_ws).first;
      expect(dtos.length, 1);
      expect(dtos.first.id, 'r1');
      expect(host.lastSubscribe!.args, {'workspace_id': _ws});
    });

    test('watchAll tolerates a missing repos key', () async {
      host.snapshotFor('repos.watchAll', const {});
      final repo = RemoteRepoRepository(client);
      expect(await repo.watchAll(_ws).first, isEmpty);
    });
  });

  group('RpcRepoRepository', () {
    test('getById returns null on notFound', () async {
      host.errorCodes['repos.get'] = RpcErrorCodes.notFound;
      final repo = RpcRepoRepository(client);
      expect(await repo.getById(_ws, 'missing'), isNull);
    });

    test('getById rethrows non-notFound errors', () async {
      host.errorCodes['repos.get'] = RpcErrorCodes.internalError;
      final repo = RpcRepoRepository(client);
      expect(
        () => repo.getById(_ws, 'boom'),
        throwsA(isA<RemoteRpcException>()),
      );
    });

    test('getById maps a found repo with epoch timestamp fallbacks', () async {
      host.callResults['repos.get'] = {
        'repo': {'id': 'r1', 'name': 'cc', 'path': '/r'},
      };
      final repo = RpcRepoRepository(client);
      final r = await repo.getById(_ws, 'r1');
      expect(r, isNotNull);
      expect(r!.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(r.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(host.lastCall('repos.get')!.args['workspace_id'], _ws);
    });

    test('upsert round-trips the entity through a DTO', () async {
      final repo = RpcRepoRepository(client);
      final id = await repo.upsert(
        _ws,
        Repo(
          id: 'r2',
          name: 'tool',
          path: '/r2',
          remoteOwner: 'acme',
          remoteName: 'tool',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      );
      expect(id, 'r2');
      final args = host.lastCall('repos.upsert')!.args;
      expect(args['workspace_id'], _ws);
      final sent = args['repo'] as Map;
      expect(sent['created_at'], isNotNull);
      expect(sent['updated_at'], isNotNull);
    });

    test('delete forwards the workspace + id', () async {
      final repo = RpcRepoRepository(client);
      await repo.delete(_ws, 'r9');
      expect(host.lastCall('repos.delete')!.args, {
        'workspace_id': _ws,
        'repo_id': 'r9',
      });
    });

    test('watchAll maps DTOs to entities', () async {
      host.snapshotFor('repos.watchAll', {
        'repos': [
          {
            'id': 'r1',
            'name': 'a',
            'path': '/r',
            'created_at': '2026-01-01T00:00:00.000',
          },
        ],
      });
      final repo = RpcRepoRepository(client);
      final live = await repo.watchAll(_ws).first;
      expect(live.single.id, 'r1');
      expect(host.lastSubscribe!.args, {'workspace_id': _ws});
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
  final Map<String, int> errorCodes = {};
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
        final err = errorCodes[op];
        if (err != null) {
          channel.send({
            'jsonrpc': '2.0',
            'id': id,
            'error': {'code': err, 'message': 'scripted'},
          });
        } else {
          _reply(id, {
            'op': op,
            'data': callResults[op] ?? const <String, dynamic>{},
          });
        }
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
