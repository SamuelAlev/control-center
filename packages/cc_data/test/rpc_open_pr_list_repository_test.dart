import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcOpenPrListRepository] — the thin-client PR-list adapter.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcOpenPrListRepository', () {
    test('listOpenForWorkspace decodes repos + PRs', () async {
      host.callResults['pr.listOpenForWorkspace'] = {
        'authenticated': true,
        'repos': [
          {
            'repo_id': 'o/r',
            'has_more': false,
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
      final repo = RpcOpenPrListRepository(client);
      final result = await repo.listOpenForWorkspace('ws');
      expect(result.authenticated, isTrue);
      expect(result.groups.length, 1);
      expect(result.groups.first.repoId, 'o/r');
      expect(result.groups.first.prs.first.number, 42);
    });

    test(
      'listOpenForWorkspace defaults to unauthenticated when missing',
      () async {
        host.callResults['pr.listOpenForWorkspace'] = {};
        final repo = RpcOpenPrListRepository(client);
        final result = await repo.listOpenForWorkspace('ws');
        expect(result.authenticated, isFalse);
        expect(result.groups, isEmpty);
      },
    );

    test('listOpenForWorkspace decodes repo access and hidden repos', () async {
      host.callResults['pr.listOpenForWorkspace'] = {
        'authenticated': true,
        'repos': <Map<String, dynamic>>[],
        'repo_access': [
          'junk',
          {
            'forge': 'github',
            'owner': 'acme',
            'name': 'api',
            'repo_full_name': 'acme/api',
            'repo_id': 'r1',
            'state': 'app_not_installed',
            'since': '2026-08-23T17:08:44.000Z',
            'checked_at': '2026-08-23T18:00:00.000Z',
            'install_url': 'https://github.com/apps/cc/installations/new',
          },
          {'owner': 'acme', 'name': 'web', 'state': 'from_the_future'},
        ],
        'hidden_repos': [
          {'forge': 'github', 'reason': 'sign_in_required', 'count': 3},
          {'forge': 'gitlab', 'reason': 'checking', 'count': 0},
          {'forge': 'gitlab', 'reason': 'unknown_reason', 'count': 2},
        ],
      };
      final repo = RpcOpenPrListRepository(client);
      final result = await repo.listOpenForWorkspace('ws');
      final entry = result.repoAccess.single;
      expect(entry.forge, ForgeHost.github);
      expect(entry.repoFullName, 'acme/api');
      expect(entry.repoId, 'r1');
      expect(entry.state, RepoAccessState.appNotInstalled);
      expect(entry.since, DateTime.utc(2026, 8, 23, 17, 8, 44));
      expect(entry.checkedAt, DateTime.utc(2026, 8, 23, 18));
      expect(entry.installUrl, 'https://github.com/apps/cc/installations/new');
      expect(result.hiddenRepos, [
        HiddenRepos(
          forge: ForgeHost.github,
          reason: HiddenRepoReason.signInRequired,
          count: 3,
        ),
      ]);
    });

    test('a snapshot without access keys decodes to empty lists', () async {
      host.callResults['pr.listOpenForWorkspace'] = {
        'authenticated': true,
        'repos': <Map<String, dynamic>>[],
      };
      final repo = RpcOpenPrListRepository(client);
      final result = await repo.listOpenForWorkspace('ws');
      expect(result.repoAccess, isEmpty);
      expect(result.hiddenRepos, isEmpty);
    });

    test('reviewRequestedForWorkspace decodes reviews', () async {
      host.callResults['pr.searchReviewRequestedForWorkspace'] = {
        'reviews': [
          {
            'repo_id': 'o/r',
            'pr': {
              'id': 1,
              'number': 7,
              'title': 'T',
              'body': '',
              'state': 'open',
              'is_draft': false,
              'repo_full_name': 'o/r',
              'html_url': 'u',
            },
          },
        ],
      };
      final repo = RpcOpenPrListRepository(client);
      final reviews = await repo.reviewRequestedForWorkspace('ws');
      expect(reviews.length, 1);
      expect(reviews.first.repoId, 'o/r');
      expect(reviews.first.pr.number, 7);
    });

    test('reviewedByKeysForWorkspace decodes a key set', () async {
      host.callResults['pr.searchReviewedByForWorkspace'] = {
        'keys': ['o/r/42', 'o/r/43'],
      };
      final repo = RpcOpenPrListRepository(client);
      final keys = await repo.reviewedByKeysForWorkspace('ws');
      expect(keys, {'o/r/42', 'o/r/43'});
    });

    test('closedByAuthorForWorkspace sends no login', () async {
      host.callResults['pr.closedByAuthorForWorkspace'] = {'repos': []};
      final repo = RpcOpenPrListRepository(client);
      await repo.closedByAuthorForWorkspace('ws');
      final args = host.lastCall('pr.closedByAuthorForWorkspace')!.args;
      expect(args['workspace_id'], 'ws');
      expect(args.containsKey('login'), isFalse);
    });

    test('reviewRequestedForWorkspace names the workspace', () async {
      host.callResults['pr.searchReviewRequestedForWorkspace'] = {
        'reviews': <Object>[],
      };
      final repo = RpcOpenPrListRepository(client);
      await repo.reviewRequestedForWorkspace('ws');
      expect(host.lastCall('pr.searchReviewRequestedForWorkspace')!.args, {
        'workspace_id': 'ws',
      });
    });

    test(
      'closedByAuthorForWorkspace maps repo groups + PRs and skips non-Maps',
      () async {
        host.callResults['pr.closedByAuthorForWorkspace'] = {
          'repos': [
            'junk',
            {
              'repo_id': 'o/r',
              'has_more': true,
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
            null,
          ],
        };
        final repo = RpcOpenPrListRepository(client);
        final groups = await repo.closedByAuthorForWorkspace('ws');
        expect(groups.length, 1);
        expect(groups.first.repoId, 'o/r');
        expect(groups.first.hasMore, isTrue);
        expect(groups.first.prs.first.number, 42);
      },
    );

    test(
      'closedByAuthorForWorkspace defaults repo_id + has_more when absent',
      () async {
        host.callResults['pr.closedByAuthorForWorkspace'] = {
          'repos': [
            {'prs': []},
          ],
        };
        final repo = RpcOpenPrListRepository(client);
        final groups = await repo.closedByAuthorForWorkspace('ws');
        expect(groups.single.repoId, '');
        expect(groups.single.hasMore, isFalse);
        expect(groups.single.prs, isEmpty);
      },
    );
  });
}

class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }
  final RemoteRpcChannelPort space;
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
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
