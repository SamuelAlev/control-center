import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_comment_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/cc_infra.dart'
    show AgentRunGrant, AgentRunPushedBranch, AgentRunView;
import 'package:cc_server_core/src/pr_review/agent_pull_request_comment_service.dart';
import 'package:cc_server_core/src/pr_review/agent_run_pull_request_scope.dart';
import 'package:test/test.dart';

Repo _repo(String id) => Repo(
  id: id,
  name: id,
  path: '/tmp/$id',
  remoteOwner: 'acme',
  remoteName: id,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

/// An agent run comments on its own pull request through the server, as the
/// bot bounded by its requester: the run's token only reads.
void main() {
  late List<AgentRunView> runs;
  late Map<String, Map<String, String>> spaceBranches;
  late Map<String, String> spaceHeads;
  late Set<String> members;
  late Set<String> readers;
  late List<({String repo, String? actor})> clients;
  late _Forge forge;

  final widgets = _repo('widgets');

  setUp(() {
    runs = [];
    spaceBranches = {};
    spaceHeads = {};
    members = {'alice'};
    readers = {'alice'};
    clients = [];
    forge = _Forge();
  });

  const pushedSha = 'aaaaaaa1111111111111111111111111111111bb';

  AgentRunView run({
    String? actingUserId = 'alice',
    List<String> pushed = const ['feature/x'],
  }) => AgentRunView(
    grant: AgentRunGrant(
      workspaceId: 'w1',
      conversationId: 'c1',
      mcpEndpoint: true,
      claudeHook: true,
      readOnly: false,
      spaceId: 's1',
      actingUserId: actingUserId,
      repos: const [(forge: ForgeHost.github, owner: 'acme', name: 'widgets')],
    ),
    pushedBranches: {
      for (final b in pushed)
        AgentRunPushedBranch(
          owner: 'acme',
          name: 'widgets',
          branch: b,
          sha: pushedSha,
        ),
    },
  );

  AgentPullRequestCommentService service() => AgentPullRequestCommentService(
    scope: AgentRunPullRequestScope(
      openRuns: ({required workspaceId, required conversationId}) => [
        for (final r in runs)
          if (r.grant.workspaceId == workspaceId &&
              r.grant.conversationId == conversationId)
            r,
      ],
      linkedRepos: (ws) async => ws == 'w1' ? [widgets] : const [],
      spaceBranches: (ws, space) async => spaceBranches['$ws/$space'] ?? {},
      spaceBranchHead: (ws, space, repo, branch) async =>
          spaceHeads['$ws/$space/${repo.id}/$branch'],
      isMember: (ws, user) async => members.contains(user),
      mayRead: (ws, user, repo) async => readers.contains(user),
    ),
    clientFor: (repo, {required workspaceId, actingUserId}) {
      clients.add((repo: repo.fullName, actor: actingUserId));
      return forge;
    },
    attribution: (repo, {required workspaceId, actingUserId}) async =>
        actingUserId == null
        ? null
        : (body) => '**Control Center** (for @$actingUserId): $body',
  );

  AgentPullRequestComment comment({
    int number = 42,
    String body = 'Tests pass now.',
    String? repo,
  }) => AgentPullRequestComment(
    workspaceId: 'w1',
    conversationId: 'c1',
    repo: repo,
    number: number,
    body: body,
  );

  test(
    'posts on the run\'s own pull request as the bot for its requester',
    () async {
      runs = [run()];
      final result = await service().comment(comment());

      expect(result.toWire(), {
        'repo': 'acme/widgets',
        'number': 42,
        'url': 'https://github.com/acme/widgets/pull/42',
        'author': 'bot',
      });
      // The automation client bounded by the requester, never their token.
      expect(clients.single, (repo: 'acme/widgets', actor: 'alice'));
      expect(forge.posted.single, (
        42,
        '**Control Center** (for @alice): Tests pass now.',
      ));
    },
  );

  test('the space branch at its checkout\'s commit counts as the run\'s '
      'own', () async {
    runs = [run(pushed: const [])];
    forge
      ..headRef = 'space/s1'
      ..headSha = 'cccccccc22222222222222222222222222222222';
    spaceBranches['w1/s1'] = {'widgets': 'space/s1'};
    // The checkout has moved on (or never had it): not the run's commit.
    spaceHeads['w1/s1/widgets/space/s1'] =
        'dddddddd33333333333333333333333333333333';
    await expectLater(
      service().comment(comment()),
      throwsA(isA<ValidationException>()),
    );
    spaceHeads['w1/s1/widgets/space/s1'] = forge.headSha;
    await service().comment(comment());
    expect(forge.posted, hasLength(1));
  });

  test('a pull request from a fork reusing the run\'s branch name is '
      'refused', () async {
    runs = [run()];
    forge.headRepoId = '777';
    await expectLater(
      service().comment(comment()),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('a fork'),
        ),
      ),
    );
    // A payload that does not say where the head lives is refused too.
    forge.headRepoId = '';
    await expectLater(
      service().comment(comment()),
      throwsA(isA<ValidationException>()),
    );
    expect(forge.posted, isEmpty);
  });

  test('the run\'s branch at a commit it did not push is refused', () async {
    runs = [run()];
    forge.headSha = 'eeeeeeee44444444444444444444444444444444';
    await expectLater(
      service().comment(comment()),
      throwsA(isA<ValidationException>()),
    );
    // An abbreviated id (Bitbucket's 12 characters) of the pushed commit
    // matches.
    forge.headSha = pushedSha.substring(0, 12);
    await service().comment(comment());
    expect(forge.posted, hasLength(1));
  });

  test(
    'mentions in the comment are made inert; the attribution stays',
    () async {
      runs = [run()];
      await service().comment(
        comment(body: 'cc @acme/security and @all, see `@Override`'),
      );
      expect(
        forge.posted.single.$2,
        '**Control Center** (for @alice): cc @\u200Bacme/security and '
        '@\u200Ball, see `@Override`',
      );
    },
  );

  test('another pull request is refused before anything is posted', () async {
    runs = [run()];
    forge.headRef = 'someone-else/feature';
    await expectLater(
      service().comment(comment()),
      throwsA(isA<ValidationException>()),
    );
    expect(forge.posted, isEmpty);
  });

  test('a missing pull request, an unlinked repo, an empty comment or no '
      'running run are refused', () async {
    await expectLater(
      service().comment(comment()),
      throwsA(isA<ValidationException>()),
    );
    runs = [run()];
    forge.missing = true;
    await expectLater(
      service().comment(comment()),
      throwsA(isA<NotFoundException>()),
    );
    forge.missing = false;
    await expectLater(
      service().comment(comment(repo: 'acme/elsewhere')),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      service().comment(comment(body: '   ')),
      throwsA(isA<ValidationException>()),
    );
    expect(forge.posted, isEmpty);
  });

  test('a requester who left or cannot read the repo posts nothing', () async {
    runs = [run()];
    readers = {};
    await expectLater(
      service().comment(comment()),
      throwsA(isA<AuthException>()),
    );
    members = {};
    await expectLater(
      service().comment(comment()),
      throwsA(isA<AuthException>()),
    );
    expect(forge.posted, isEmpty);
  });

  test('a run nobody requested posts as the bot with no prefix', () async {
    runs = [run(actingUserId: null)];
    await service().comment(comment());
    expect(clients.single.actor, isNull);
    expect(forge.posted.single.$2, 'Tests pass now.');
  });
}

class _Forge implements ForgePrClient {
  final posted = <(int, String)>[];
  String headRef = 'feature/x';
  String headSha = 'aaaaaaa1111111111111111111111111111111bb';
  String headRepoId = '42';
  bool missing = false;

  @override
  Future<PullRequest?> getPullRequest(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  }) async => missing
      ? null
      : PullRequest(
          id: 1,
          number: prNumber,
          title: 't',
          body: '',
          state: PrState.open,
          isDraft: false,
          author: null,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          repoFullName: 'acme/widgets',
          htmlUrl: 'https://github.com/acme/widgets/pull/$prNumber',
          headRef: headRef,
          headSha: headSha,
          baseRepoId: '42',
          headRepoId: headRepoId,
        );

  @override
  Future<void> postIssueComment({
    required int prNumber,
    required String body,
    ForgeCancelToken? cancelToken,
  }) async => posted.add((prNumber, body));

  @override
  ForgeHost get forge => ForgeHost.github;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
