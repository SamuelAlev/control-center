import 'package:cc_data/src/repositories/remote_review_channel_repository.dart';
import 'package:cc_data/src/repositories/rpc_review_channel_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for the review-channel repositories — drives the paths
/// the broad `remote_repositories_test.dart` host stub leaves cold: the
/// `watchByChannel` / `watchAllByChannel` subscriptions on [RpcReviewChannelRepository]
/// and the [RemoteReviewChannelRepository] non-Map association + null-timestamp
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
    String channelId = 'c1',
    String prExternalId = 'pr-node-1',
    int prNumber = 42,
    String repoFullName = 'acme/cc',
    String status = 'requested',
    String? createdAt,
    String? updatedAt,
  }) => {
    'id': id,
    'channel_id': channelId,
    'workspace_id': 'ws1',
    'pr_external_id': prExternalId,
    'pr_number': prNumber,
    'repo_full_name': repoFullName,
    'status': status,
    'created_at': ?createdAt,
    'updated_at': ?updatedAt,
  };

  group('RpcReviewChannelRepository watches', () {
    test('watchByChannel maps the DTO and resolves a known status', () async {
      host.snapshotFor('review_channel.watchByChannel', {
        'association': json(status: 'completed'),
      });
      final assoc = await RpcReviewChannelRepository(
        client,
      ).watchByChannel('ws1', 'c1').first;
      expect(assoc, isNotNull);
      expect(assoc!.status, ReviewChannelStatus.completed);
      // A channel id is a uuid, not an access boundary: the workspace that
      // selects the database file travels in the subscribe args.
      expect(host.lastSubscribe!.args, {
        'workspace_id': 'ws1',
        'channel_id': 'c1',
      });
    });

    test('watchByChannel returns null when association is not a Map', () async {
      host.snapshotFor('review_channel.watchByChannel', {'association': 'bad'});
      expect(
        await RpcReviewChannelRepository(
          client,
        ).watchByChannel('ws1', 'c1').first,
        isNull,
      );
    });

    test('watchByChannel defaults an unknown status to requested', () async {
      host.snapshotFor('review_channel.watchByChannel', {
        'association': json(status: 'nope'),
      });
      final assoc = await RpcReviewChannelRepository(
        client,
      ).watchByChannel('ws1', 'c1').first;
      expect(assoc!.status, ReviewChannelStatus.requested);
    });

    test(
      'watchByChannel falls back to the epoch when timestamps are absent',
      () async {
        host.snapshotFor('review_channel.watchByChannel', {
          'association': json(),
        });
        final assoc = await RpcReviewChannelRepository(
          client,
        ).watchByChannel('ws1', 'c1').first;
        expect(assoc!.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
        expect(assoc.updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
      },
    );

    test('watchAllByChannel maps every association', () async {
      host.snapshotFor('review_channel.watchAllByChannel', {
        'associations': [
          json(id: 'rc1', channelId: 'c1'),
          json(id: 'rc2', channelId: 'c1', prExternalId: 'pr-node-2'),
        ],
      });
      final assocs = await RpcReviewChannelRepository(
        client,
      ).watchAllByChannel('ws1', 'c1').first;
      expect(assocs.length, 2);
      expect(assocs[0].id, 'rc1');
      expect(assocs[1].prExternalId, 'pr-node-2');
    });

    test('watchAllByChannel skips non-Map rows', () async {
      host.snapshotFor('review_channel.watchAllByChannel', {
        'associations': ['bad', json(id: 'rc1')],
      });
      final assocs = await RpcReviewChannelRepository(
        client,
      ).watchAllByChannel('ws1', 'c1').first;
      expect(assocs.single.id, 'rc1');
    });

    test('watchByPr maps a present association', () async {
      host.snapshotFor('review_channel.watchByPr', {
        'association': json(prExternalId: 'pr-node-9'),
      });
      final assoc = await RpcReviewChannelRepository(
        client,
      ).watchByPr('ws1', 'pr-node-9').first;
      expect(assoc!.prExternalId, 'pr-node-9');
    });
  });

  group('RemoteReviewChannelRepository', () {
    test('create returns the parsed DTO', () async {
      host.callResults['review_channel.create'] = {
        'association': json(id: 'rc-new'),
      };
      final dto = await RemoteReviewChannelRepository(client).create(
        workspaceId: 'ws1',
        channelId: 'c1',
        prExternalId: 'pr-node-9',
        prNumber: 42,
        repoFullName: 'acme/cc',
      );
      expect(dto.id, 'rc-new');
      expect(
        host.lastCall('review_channel.create')!.args['workspace_id'],
        'ws1',
      );
    });

    test('updateStatus forwards the workspace + id + status name', () async {
      await RemoteReviewChannelRepository(
        client,
      ).updateStatus('ws1', 'rc-1', 'completed');
      final call = host.lastCall('review_channel.updateStatus')!;
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
