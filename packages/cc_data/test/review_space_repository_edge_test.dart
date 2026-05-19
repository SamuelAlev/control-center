import 'package:cc_data/src/repositories/remote_review_space_repository.dart';
import 'package:cc_data/src/repositories/rpc_review_space_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for the review-space repositories — drives the paths
/// the broad `remote_repositories_test.dart` host stub leaves cold: the
/// `watchBySpace` / `watchAllBySpace` subscriptions on [RpcReviewSpaceRepository]
/// and the [RemoteReviewSpaceRepository] non-Map association + null-timestamp
/// fallbacks + the `_associations` non-Map skip + the unknown-status default.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  Map<String, dynamic> json({
    String id = 'rc1',
    String spaceId = 'c1',
    String prExternalId = 'pr-node-1',
    int prNumber = 42,
    String repoFullName = 'acme/cc',
    String status = 'requested',
    String? createdAt,
    String? updatedAt,
  }) => {
    'id': id,
    'space_id': spaceId,
    'workspace_id': 'ws1',
    'pr_external_id': prExternalId,
    'pr_number': prNumber,
    'repo_full_name': repoFullName,
    'status': status,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };

  group('RpcReviewSpaceRepository watches', () {
    test('watchBySpace maps the DTO and resolves a known status', () async {
      host.snapshotFor('review_space.watchBySpace', {
        'association': json(status: 'completed'),
      });
      final assoc = await RpcReviewSpaceRepository(
        client,
      ).watchBySpace('ws1', 'c1').first;
      expect(assoc, isNotNull);
      expect(assoc!.status, ReviewSpaceStatus.completed);
      // A space id is a uuid, not an access boundary: the workspace that
      // selects the database file travels in the subscribe args.
      expect(host.lastSubscribe!.args, {
        'workspace_id': 'ws1',
        'space_id': 'c1',
      });
    });

    test('watchBySpace returns null when association is not a Map', () async {
      host.snapshotFor('review_space.watchBySpace', {'association': 'bad'});
      expect(
        await RpcReviewSpaceRepository(
          client,
        ).watchBySpace('ws1', 'c1').first,
        isNull,
      );
    });

    test('watchBySpace defaults an unknown status to requested', () async {
      host.snapshotFor('review_space.watchBySpace', {
        'association': json(status: 'nope'),
      });
      final assoc = await RpcReviewSpaceRepository(
        client,
      ).watchBySpace('ws1', 'c1').first;
      expect(assoc!.status, ReviewSpaceStatus.requested);
    });

    test(
      'watchBySpace falls back to the epoch when timestamps are absent',
      () async {
        host.snapshotFor('review_space.watchBySpace', {
          'association': json(),
        });
        final assoc = await RpcReviewSpaceRepository(
          client,
        ).watchBySpace('ws1', 'c1').first;
        expect(assoc!.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(assoc.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      },
    );

    test('watchAllBySpace maps every association', () async {
      host.snapshotFor('review_space.watchAllBySpace', {
        'associations': [
          json(id: 'rc1', spaceId: 'c1'),
          json(id: 'rc2', spaceId: 'c1', prExternalId: 'pr-node-2'),
        ],
      });
      final assocs = await RpcReviewSpaceRepository(
        client,
      ).watchAllBySpace('ws1', 'c1').first;
      expect(assocs.length, 2);
      expect(assocs[0].id, 'rc1');
      expect(assocs[1].prExternalId, 'pr-node-2');
    });

    test('watchAllBySpace skips non-Map rows', () async {
      host.snapshotFor('review_space.watchAllBySpace', {
        'associations': ['bad', json(id: 'rc1')],
      });
      final assocs = await RpcReviewSpaceRepository(
        client,
      ).watchAllBySpace('ws1', 'c1').first;
      expect(assocs.single.id, 'rc1');
    });

    test('watchByPr maps a present association', () async {
      host.snapshotFor('review_space.watchByPr', {
        'association': json(prExternalId: 'pr-node-9'),
      });
      final assoc = await RpcReviewSpaceRepository(
        client,
      ).watchByPr('ws1', 'pr-node-9').first;
      expect(assoc!.prExternalId, 'pr-node-9');
    });
  });

  group('RemoteReviewSpaceRepository', () {
    test('create returns the parsed DTO', () async {
      host.callResults['review_space.create'] = {
        'association': json(id: 'rc-new'),
      };
      final dto = await RemoteReviewSpaceRepository(client).create(
        workspaceId: 'ws1',
        spaceId: 'c1',
        prExternalId: 'pr-node-9',
        prNumber: 42,
        repoFullName: 'acme/cc',
      );
      expect(dto.id, 'rc-new');
      expect(
        host.lastCall('review_space.create')!.args['workspace_id'],
        'ws1',
      );
    });

    test('updateStatus forwards the workspace + id + status name', () async {
      await RemoteReviewSpaceRepository(
        client,
      ).updateStatus('ws1', 'rc-1', 'completed');
      final call = host.lastCall('review_space.updateStatus')!;
      expect(call.args['workspace_id'], 'ws1');
      expect(call.args['id'], 'rc-1');
      expect(call.args['status'], 'completed');
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
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
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
          space.send({
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
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
