import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_search_query.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcPrSearchPort] — the thin-client PR-queue search over RPC.
/// Pins the op name, the query.text arg, the repo join, the wire→entity
/// mapping and the empty-repos short-circuit.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  Repo repo(String id) => Repo(
    id: id,
    name: id,
    path: '/srv/$id',
    remoteOwner: 'o',
    remoteName: id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcPrSearchPort.search', () {
    test('joins repos + maps PRs and forwards query.text', () async {
      host.callResults['pr.searchForWorkspace'] = {
        'repos': [
          {
            'repo_id': 'o/r',
            'prs': [
              {
                'id': 1,
                'number': 42,
                'title': 'Fix',
                'body': '',
                'state': 'open',
                'is_draft': false,
                'repo_full_name': 'o/r',
                'html_url': 'u',
              },
            ],
          },
        ],
      };
      final port = RpcPrSearchPort(client);
      final groups = await port.search(
        query: const PrSearchQuery(text: 'fix'),
        repos: [repo('o/r')],
      );
      expect(groups.length, 1);
      expect(groups.first.repo.id, 'o/r');
      expect(groups.first.prs.first.number, 42);
      expect(host.lastCall('pr.searchForWorkspace')!.args['query'], 'fix');
    });

    test('returns empty when no repos are supplied', () async {
      final port = RpcPrSearchPort(client);
      expect(
        await port.search(
          query: const PrSearchQuery(text: 'x'),
          repos: const [],
        ),
        isEmpty,
      );
      // The short-circuit must not have called the host.
      expect(host.calls, isEmpty);
    });

    test('skips repos not in the caller list and non-Map rows', () async {
      host.callResults['pr.searchForWorkspace'] = {
        'repos': [
          'not-a-map',
          {'repo_id': 'unknown', 'prs': []},
          {
            'repo_id': 'o/r',
            'prs': [
              {
                'id': 1,
                'number': 7,
                'title': 'T',
                'state': 'open',
                'repo_full_name': 'o/r',
                'html_url': 'u',
              },
            ],
          },
        ],
      };
      final port = RpcPrSearchPort(client);
      final groups = await port.search(
        query: const PrSearchQuery(text: 'x'),
        repos: [repo('o/r')],
      );
      expect(groups.length, 1);
      expect(groups.first.repo.id, 'o/r');
    });

    test('drops a repo group with no PRs', () async {
      host.callResults['pr.searchForWorkspace'] = {
        'repos': [
          {'repo_id': 'o/r', 'prs': []},
        ],
      };
      final port = RpcPrSearchPort(client);
      expect(
        await port.search(
          query: const PrSearchQuery(text: 'x'),
          repos: [repo('o/r')],
        ),
        isEmpty,
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

class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
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
