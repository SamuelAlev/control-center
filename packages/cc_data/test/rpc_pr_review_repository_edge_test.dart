import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Edge-case coverage for [RpcPrReviewRepository] and [RpcForgeProviderFactory]
/// — the fallback / non-Map branches the broad `remote_repositories_test.dart`
/// host stub doesn't drive: empty-string diff/content fallbacks, null draft,
/// non-Map mutation results, pr/commit preview null paths and the assignable /
/// requestable user list skips.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  RpcPrReviewRepository repo() => RpcPrReviewRepository(
    client,
    workspaceId: 'ws',
    owner: 'acme',
    repo: 'cc',
  );

  group('RpcPrReviewRepository reads + previews', () {
    test('getDraft returns null when absent', () async {
      expect(await repo().getDraft(42), isNull);
    });

    test('getDraft returns the stored draft', () async {
      host.callResults['pr_review.getDraft'] = {'draft': 'WIP'};
      expect(await repo().getDraft(42), 'WIP');
    });

    test('uploadContent returns empty url when absent', () async {
      expect(await repo().uploadContent('p', 'b64', 'm'), '');
    });

    test('uploadContent returns the blob url', () async {
      host.callResults['pr_review.uploadContent'] = {'url': 'https://b/x'};
      expect(await repo().uploadContent('p', 'b64', 'm'), 'https://b/x');
    });

    test('listAssignableUsers skips non-Map rows', () async {
      host.callResults['pr_review.listAssignableUsers'] = {
        'users': [
          {'login': 'sam', 'avatar_url': 'https://a/sam.png'},
          'bad',
        ],
      };
      final users = await repo().listAssignableUsers();
      expect(users.single.login, 'sam');
      expect(users.single.name, isNull);
    });

    test('listAssignableUsers maps display name', () async {
      host.callResults['pr_review.listAssignableUsers'] = {
        'users': [
          {
            'login': 'sam',
            'avatar_url': 'https://a/sam.png',
            'name': 'Sam Alev',
          },
        ],
      };
      final users = await repo().listAssignableUsers();
      expect(users.single.displayLabel, 'sam (Sam Alev)');
    });

    test('listRequestableReviewers maps user + team candidates', () async {
      host.callResults['pr_review.listRequestableReviewers'] = {
        'candidates': [
          {'kind': 'team', 'key': 't/platform', 'label': 'Platform'},
          {
            'kind': 'user',
            'key': 'u/sam',
            'label': 'Sam',
            'avatar_url': 'https://a/sam.png',
          },
        ],
      };
      final candidates = await repo().listRequestableReviewers();
      expect(candidates.length, 2);
      expect(candidates[0].kind, ReviewerKind.team);
      expect(candidates[1].kind, ReviewerKind.user);
    });

    test('prPreview returns null when preview is not a Map', () async {
      expect(await repo().prPreview(42), isNull);
    });

    test('prPreview returns the preview DTO', () async {
      host.callResults['pr_review.prPreview'] = {
        'preview': {
          'title': 'Fix',
          'state': 'open',
          'is_draft': true,
          'is_merged': false,
          'html_url': 'https://pr/42',
        },
      };
      final p = await repo().prPreview(42);
      expect(p, isNotNull);
      expect(p!.title, 'Fix');
      expect(p.isDraft, isTrue);
      expect(p.htmlUrl, 'https://pr/42');
    });

    test('commitPreview returns null when preview is absent', () async {
      expect(await repo().commitPreview('abc'), isNull);
    });

    test('commitPreview returns the preview DTO', () async {
      host.callResults['pr_review.commitPreview'] = {
        'preview': {'title': 'm', 'short_sha': 'abc'},
      };
      final p = await repo().commitPreview('abc');
      expect(p, isNotNull);
      expect(p!.shortSha, 'abc');
      expect(p.title, 'm');
    });
  });

  group('RpcPrReviewRepository watches with empty fallbacks', () {
    test('watchDiff falls back to empty string', () async {
      host.snapshotFor('pr_review.watchDiff', const {});
      expect(await repo().watchDiff(42).first, '');
    });

    test('watchFileContent falls back to empty string', () async {
      host.snapshotFor('pr_review.watchFileContent', const {});
      expect(await repo().watchFileContent('lib/x.dart', 'main').first, '');
    });

    test(
      'watchPullRequest returns null when pull_request is not a Map',
      () async {
        host.snapshotFor('pr_review.watchPullRequest', {'pull_request': 'bad'});
        expect(await repo().watchPullRequest(42).first, isNull);
      },
    );

    test('watchFiles skips non-Map rows', () async {
      host.snapshotFor('pr_review.watchFiles', {
        'files': ['bad'],
      });
      expect(await repo().watchFiles(42).first, isEmpty);
    });

    test('watchReviewers maps a team reviewer', () async {
      host.snapshotFor('pr_review.watchReviewers', {
        'reviewers': [
          {
            'kind': 'team',
            'name': 'Platform',
            'slug': 'platform',
            'state': 'APPROVED',
            'is_code_owner': true,
          },
        ],
      });
      final reviewers = await repo().watchReviewers(42).first;
      expect(reviewers.single, isA<PrTeamReviewer>());
    });
  });

  group('RpcPrReviewRepository mutation result maps', () {
    test('postReviewComment returns empty map when result absent', () async {
      expect(
        await repo().postReviewComment(
          prNumber: 42,
          commitSha: 'abc',
          path: 'p',
          line: 5,
          side: 'RIGHT',
          body: 'b',
        ),
        isEmpty,
      );
    });

    test(
      'postReviewComment returns the result map + forwards start fields',
      () async {
        host.callResults['pr_review.postReviewComment'] = {
          'result': {'id': 9},
        };
        final result = await repo().postReviewComment(
          prNumber: 42,
          commitSha: 'abc',
          path: 'p',
          line: 5,
          side: 'RIGHT',
          body: 'b',
          startLine: 1,
          startSide: 'LEFT',
        );
        expect(result['id'], 9);
        final args = host.lastCall('pr_review.postReviewComment')!.args;
        expect(args['start_line'], 1);
        expect(args['start_side'], 'LEFT');
      },
    );

    test('mergePullRequest returns empty map when result absent', () async {
      expect(
        await repo().mergePullRequest(prNumber: 42, mergeMethod: 'squash'),
        isEmpty,
      );
    });

    test(
      'mergePullRequest returns the result map + forwards idempotency',
      () async {
        host.callResults['pr_review.mergePullRequest'] = {
          'result': {'sha': 'abc'},
        };
        final result = await repo().mergePullRequest(
          prNumber: 42,
          mergeMethod: 'squash',
          commitTitle: 'T',
          commitMessage: 'M',
          idempotencyKey: 'k-1',
        );
        expect(result['sha'], 'abc');
        expect(host.calls.last.idempotencyKey, 'k-1');
      },
    );

    test(
      'requestReviewers / removeRequestedReviewers forward user + team lists',
      () async {
        final r = repo();
        await r.requestReviewers(
          prNumber: 42,
          userLogins: const ['sam'],
          teamSlugs: const ['platform'],
        );
        var args = host.lastCall('pr_review.requestReviewers')!.args;
        expect(args['user_logins'], ['sam']);
        expect(args['team_slugs'], ['platform']);

        await r.removeRequestedReviewers(
          prNumber: 42,
          userLogins: const ['sam'],
        );
        args = host.lastCall('pr_review.removeRequestedReviewers')!.args;
        expect(args['user_logins'], ['sam']);
      },
    );

    test('reactions forward the optional current_user_login', () async {
      final r = repo();
      await r.toggleReviewCommentReaction(
        commentId: 1,
        prNumber: 42,
        content: '+1',
        add: true,
        currentUserLogin: 'sam',
      );
      expect(
        host
            .lastCall('pr_review.toggleReviewCommentReaction')!
            .args['current_user_login'],
        'sam',
      );

      await r.toggleIssueCommentReaction(
        commentId: 1,
        prNumber: 42,
        content: '+1',
        add: true,
      );
      expect(
        host
            .lastCall('pr_review.toggleIssueCommentReaction')!
            .args
            .containsKey('current_user_login'),
        isFalse,
      );

      await r.togglePullRequestReaction(prNumber: 42, content: '+1', add: true);
      expect(host.lastCall('pr_review.togglePullRequestReaction'), isNotNull);
    });

    test('submitReview + addAssignees/removeAssignees forward args', () async {
      final r = repo();
      await r.submitReview(prNumber: 42, event: 'APPROVE', body: 'lgtm');
      var args = host.lastCall('pr_review.submitReview')!.args;
      expect(args['event'], 'APPROVE');
      expect(args['body'], 'lgtm');

      await r.addAssignees(prNumber: 42, logins: const ['sam']);
      args = host.lastCall('pr_review.addAssignees')!.args;
      expect(args['logins'], ['sam']);

      await r.removeAssignees(prNumber: 42, logins: const ['sam']);
      args = host.lastCall('pr_review.removeAssignees')!.args;
      expect(args['logins'], ['sam']);
    });

    test('close/update pull request forward args', () async {
      final r = repo();
      await r.closePullRequest(prNumber: 42);
      expect(host.lastCall('pr_review.closePullRequest'), isNotNull);

      await r.updatePullRequest(prNumber: 42, title: 'T', body: 'B');
      final args = host.lastCall('pr_review.updatePullRequest')!.args;
      expect(args['title'], 'T');
      expect(args['body'], 'B');
    });

    group('stacks', () {
      const stackWire = <String, dynamic>{
        'id': 7,
        'number': 3,
        'external_id': 'S_1',
        'url': 'https://api.github.com/repos/acme/cc/stacks/3',
        'base_ref': 'main',
        'open': true,
        'created_at': '2026-01-01T00:00:00Z',
        'pull_requests': [
          {
            'number': 101,
            'state': 'open',
            'is_draft': false,
            'head_ref': 'feat-a',
            'head_sha': 'sha1',
          },
          {
            'number': 102,
            'state': 'closed',
            'is_draft': false,
            'head_ref': 'feat-b',
            'head_sha': 'sha2',
            'merged_at': '2026-01-02T00:00:00Z',
          },
        ],
      };

      test('listStacks forwards the PR filter and maps entries', () async {
        host.callResults['pr_review.listStacks'] = {
          'stacks': [stackWire],
        };
        final stacks = await repo().listStacks(prNumber: 101);
        expect(stacks.single.number, 3);
        expect(stacks.single.pullRequests, hasLength(2));
        expect(stacks.single.pullRequests.first.state.name, 'open');
        expect(stacks.single.pullRequests.last.isMerged, isTrue);
        final args = host.lastCall('pr_review.listStacks')!.args;
        expect(args['pr_number'], 101);
        expect(args['owner'], 'acme');
        expect(args['workspace_id'], 'ws');
      });

      test('createStack sends the ordered numbers and maps the stack', () async {
        host.callResults['pr_review.createStack'] = {'stack': stackWire};
        final stack = await repo().createStack(prNumbers: const [101, 102]);
        expect(stack.baseRef, 'main');
        expect(
          host.lastCall('pr_review.createStack')!.args['pull_requests'],
          [101, 102],
        );
      });

      test('addToStack forwards the stack number and PRs', () async {
        host.callResults['pr_review.addToStack'] = {'stack': stackWire};
        final stack = await repo().addToStack(
          stackNumber: 3,
          prNumbers: const [103],
        );
        expect(stack, isNotNull);
        final args = host.lastCall('pr_review.addToStack')!.args;
        expect(args['stack_number'], 3);
        expect(args['pull_requests'], [103]);
      });

      test('unstack maps a dissolved stack (null) through', () async {
        host.callResults['pr_review.unstack'] = {'stack': null};
        expect(await repo().unstack(stackNumber: 3), isNull);
        expect(
          host.lastCall('pr_review.unstack')!.args['stack_number'],
          3,
        );
      });
    });

    test('invalidate + mark-viewed + draft + reply ops forward args', () async {
      final r = repo();
      await r.invalidatePullRequest(42);
      expect(host.lastCall('pr_review.invalidatePullRequest'), isNotNull);

      await r.invalidateDiff(42);
      expect(host.lastCall('pr_review.invalidateDiff'), isNotNull);

      await r.markFileAsViewed(
        prNumber: 42,
        externalId: 'n',
        path: 'p',
        viewed: true,
      );
      final args = host.lastCall('pr_review.markFileAsViewed')!.args;
      expect(args['viewed'], true);

      await r.replyToReviewComment(prNumber: 42, parentCommentId: 9, body: 'b');
      expect(
        host
            .lastCall('pr_review.replyToReviewComment')!
            .args['parent_comment_id'],
        9,
      );

      await r.upsertDraft(42, 'WIP');
      expect(host.lastCall('pr_review.upsertDraft')!.args['text'], 'WIP');

      await r.clearDraft(42);
      expect(host.lastCall('pr_review.clearDraft'), isNotNull);
    });
  });

  group('RpcForgeProviderFactory', () {
    test('reports the GitHub VCS host', () {
      expect(RpcForgeProviderFactory(client).forge, ForgeHost.github);
    });

    test(
      'create returns an RpcPrReviewRepository for the repo coordinates',
      () {
        final factory = RpcForgeProviderFactory(client);
        final repo = factory.create(
          ForgeProviderContext(
            workspaceId: 'ws',
            repo: Repo(
              id: 'r1',
              name: 'cc',
              path: '/r',
              remoteOwner: 'acme',
              remoteName: 'cc',
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
            ),
          ),
        );
        expect(repo, isA<RpcPrReviewRepository>());
      },
    );
  });
}

/// Records a `repo/call` invocation (with optional idempotency key).
class _Call {
  const _Call({required this.op, required this.args, this.idempotencyKey});
  final String op;
  final Map<String, dynamic> args;
  final String? idempotencyKey;
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
        final idem =
            (params['idempotency_key'] as String?) ??
            (params['idempotencyKey'] as String?);
        calls.add(_Call(op: op, args: args, idempotencyKey: idem));
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
