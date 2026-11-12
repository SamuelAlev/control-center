import 'package:cc_domain/cc_domain.dart'
    show
        AuthException,
        NeedsSignInException,
        NotFoundException,
        ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        AgentRunGrant,
        AgentRunPushedBranch,
        AgentRunView,
        ForgeCredentialUnavailable;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/pr_review/agent_pr_requesters.dart';
import 'package:cc_server_core/src/pr_review/agent_pull_request_service.dart';
import 'package:cc_server_core/src/pr_review/agent_run_pull_request_scope.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

import 'helpers/seed_platform.dart';
import 'helpers/test_database.dart';

Repo _repo(String id, {String owner = 'acme', String? name}) => Repo(
  id: id,
  name: id,
  path: '/tmp/$id',
  remoteOwner: owner,
  remoteName: name ?? id,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

/// An agent run opens a pull request through the server: as the person who
/// requested it (their own one-repository token), or the bot when nobody
/// did; only on a repo linked to the run's workspace and from the run's own
/// branch; only on a repo the requester may read there; the requester (or,
/// for a run nobody requested, the admin who armed its trigger) is recorded
/// before the forge is asked; and the body names who asked.
/// The forge's durable id of acme/widgets.
const _repoId = '9001';

/// The commit the run pushed its branch to.
const _pushedSha = 'aaaaaaa1111111111111111111111111111111bb';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late AgentPrRequesters requesters;
  late List<AgentRunView> runs;
  late Map<String, List<Repo>> linked;
  late Map<String, Map<String, String>> spaceBranches;
  late Map<String, String> spaceHeads;
  late Set<String> members;
  late Set<String> readers;
  late Map<String, String> logins;
  late List<ForgeHost> loginForges;
  late Set<String> armedBy;
  late List<({String repo, String? actor, bool viaPerson})> clients;
  late _Forge forge;

  final widgets = _repo('widgets');
  final other = _repo('other-ws-repo');

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w1');
    await seedTestWorkspace(global, dbs, 'w2');
    await seedUsers(global, ['alice', 'bob', 'admin', 'other-admin']);
    logins = {'alice': 'alice-gh'};
    loginForges = [];
    requesters = AgentPrRequesters(
      records: DaoAgentPullRequestRequesterRepository(global),
      viewer: (forge, user, ws) async =>
          logins[user] == null ? null : (login: logins[user]!, id: ''),
    );
    runs = [];
    linked = {
      'w1': [widgets],
      'w2': [other],
    };
    spaceBranches = {};
    spaceHeads = {};
    members = {'alice'};
    readers = {'alice'};
    armedBy = {};
    clients = [];
    forge = _Forge(
      (head) => requesters.requestersOf(
        widgets,
        0,
        repoId: _repoId,
        headBranch: head,
      ),
    );
  });

  AgentRunView run({
    String? actingUserId = 'alice',
    String workspaceId = 'w1',
    String? spaceId = 's1',
    List<String> pushed = const ['feature/x'],
  }) => AgentRunView(
    grant: AgentRunGrant(
      workspaceId: workspaceId,
      conversationId: 'c1',
      spaceId: spaceId,
      actingUserId: actingUserId,
      repos: const [(forge: ForgeHost.github, owner: 'acme', name: 'widgets')],
    ),
    pushedBranches: {
      for (final b in pushed)
        AgentRunPushedBranch(
          owner: 'acme',
          name: 'widgets',
          branch: b,
          sha: _pushedSha,
        ),
    },
  );

  AgentPullRequestService service() => AgentPullRequestService(
    scope: AgentRunPullRequestScope(
      openRuns: ({required workspaceId, required conversationId}) => [
        for (final r in runs)
          if (r.grant.workspaceId == workspaceId &&
              r.grant.conversationId == conversationId)
            r,
      ],
      linkedRepos: (ws) async => linked[ws] ?? const [],
      spaceBranches: (ws, space) async => spaceBranches['$ws/$space'] ?? {},
      spaceBranchHead: (ws, space, repo, branch) async =>
          spaceHeads['$ws/$space/${repo.id}/$branch'],
      isMember: (ws, user) async => members.contains(user),
      mayRead: (ws, user, repo) async =>
          linked[ws]?.any((r) => r.id == repo.id) == true &&
          ws == 'w1' &&
          readers.contains(user),
    ),
    clientFor: (repo, {required workspaceId, actingUserId, viaPerson = false}) {
      clients.add((
        repo: repo.fullName,
        actor: actingUserId,
        viaPerson: viaPerson,
      ));
      return forge;
    },
    requesters: requesters,
    viewerLogin: (forge, user, ws) async {
      loginForges.add(forge);
      final login = logins[user];
      if (login == null) {
        throw StateError('no sign-in');
      }
      return login;
    },
    armedBy: (ws, conversation) async => armedBy,
  );

  Future<Set<String>> recorded(int number) =>
      requesters.requestersOf(widgets, number, repoId: _repoId);

  AgentPullRequestDraft draft({
    String workspaceId = 'w1',
    String? repo,
    String head = 'feature/x',
    String base = 'main',
    String body = 'Adds it.',
  }) => AgentPullRequestDraft(
    workspaceId: workspaceId,
    conversationId: 'c1',
    repo: repo,
    head: head,
    base: base,
    title: 'Add the widget',
    body: body,
  );

  test(
    'opens as the requester, on their own token, and records them',
    () async {
      runs = [run()];
      final result = await service().open(draft());

      expect(result.author, AgentPullRequestAuthor.requester);
      expect(result.number, 42);
      expect(result.repoFullName, 'acme/widgets');
      expect(clients.single, (
        repo: 'acme/widgets',
        actor: 'alice',
        viaPerson: true,
      ));
      expect(forge.opened.single, ('feature/x', 'main'));
      // Recorded before the forge was asked, matched by head branch.
      expect(forge.pendingAtCreate.single, {'alice'});
      expect(await recorded(42), {'alice'});
      expect(
        forge.bodies.single,
        'Adds it.\n\n'
        '_Opened by a Control Center agent at the request of @alice-gh._',
      );
      // And so the requester's own approval is refused.
      forge.author = 'alice-gh';
      await expectLater(
        requesters.guardFor(widgets, workspaceId: 'w1', actingUserId: 'alice')(
          forge,
          42,
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('a marker the agent wrote is replaced, never duplicated', () async {
    runs = [run()];
    await service().open(
      draft(
        body:
            'Adds it.\n\n_Opened by a Control Center agent at the request of '
            '@mallory._',
      ),
    );
    expect(
      forge.bodies.single,
      'Adds it.\n\n'
      '_Opened by a Control Center agent at the request of @alice-gh._',
    );
  });

  test('a requester without read access to the repo is refused', () async {
    runs = [run()];
    readers = {};
    await expectLater(
      service().open(draft()),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('no access to acme/widgets'),
        ),
      ),
    );
    expect(forge.opened, isEmpty);
    expect(clients, isEmpty);
  });

  test(
    'a run nobody requested opens it as the bot, recording nobody',
    () async {
      runs = [run(actingUserId: null)];
      final result = await service().open(draft());

      expect(result.author, AgentPullRequestAuthor.bot);
      expect(clients.single.actor, isNull);
      expect(clients.single.viaPerson, isFalse);
      expect(await recorded(42), isEmpty);
      expect(
        forge.bodies.single,
        'Adds it.\n\n_Opened by a Control Center agent._',
      );
    },
  );

  test(
    'a run started by an armed trigger records every arming admin',
    () async {
      runs = [run(actingUserId: null)];
      armedBy = {'admin', 'other-admin'};
      await service().open(draft());
      expect(forge.pendingAtCreate.single, {'admin', 'other-admin'});
      expect(await recorded(42), {'admin', 'other-admin'});
      expect(
        await service().approvalOwnersOf(
          workspaceId: 'w1',
          conversationId: 'c1',
        ),
        {'admin', 'other-admin'},
      );
      runs = [run()];
      expect(
        await service().approvalOwnersOf(
          workspaceId: 'w1',
          conversationId: 'c1',
        ),
        {'alice'},
      );
    },
  );

  test('without an open run in the conversation nothing is opened', () async {
    runs = [run(workspaceId: 'w2')];
    await expectLater(
      service().open(draft()),
      throwsA(isA<ValidationException>()),
    );
    expect(forge.opened, isEmpty);
  });

  test('a repo not linked to the run\'s workspace is refused', () async {
    runs = [run()];
    for (final repo in ['acme/other-ws-repo', 'acme/unknown']) {
      await expectLater(
        service().open(draft(repo: repo)),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('not linked to this workspace'),
          ),
        ),
        reason: repo,
      );
    }
    expect(forge.opened, isEmpty);
  });

  test('only the run\'s own branch can be the head', () async {
    runs = [
      run(pushed: const ['feature/x']),
    ];
    await expectLater(
      service().open(draft(head: 'someone-elses-branch')),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.message,
          'message',
          contains('not this run\'s branch'),
        ),
      ),
    );
    // The space's own branch for that repo is the run's too.
    spaceBranches['w1/s1'] = {widgets.id: 'space/abc'};
    final result = await service().open(draft(head: 'space/abc'));
    expect(result.number, 42);
  });

  test('a fork-prefixed or malformed branch is refused', () async {
    runs = [
      run(pushed: const ['feature/x']),
    ];
    for (final head in ['evil:feature/x', '-x', 'a..b', 'feature x']) {
      await expectLater(
        service().open(draft(head: head)),
        throwsA(isA<ValidationException>()),
        reason: head,
      );
    }
    expect(forge.opened, isEmpty);
  });

  test('runs for two different people make the requester unclear', () async {
    runs = [run(), run(actingUserId: 'bob')];
    await expectLater(
      service().open(draft()),
      throwsA(isA<ValidationException>()),
    );
    expect(forge.opened, isEmpty);
  });

  test('a requester who left the workspace cannot be acted for', () async {
    runs = [run(actingUserId: 'mallory')];
    await expectLater(service().open(draft()), throwsA(isA<AuthException>()));
    expect(forge.opened, isEmpty);
  });

  test('a stack publish reads the same requester from the run', () async {
    runs = [run()];
    expect(
      await service().requesterOf(workspaceId: 'w1', conversationId: 'c1'),
      'alice',
    );
    runs = [run(actingUserId: null)];
    expect(
      await service().requesterOf(workspaceId: 'w1', conversationId: 'c1'),
      isNull,
    );
    runs = [run(actingUserId: 'mallory')];
    await expectLater(
      service().requesterOf(workspaceId: 'w1', conversationId: 'c1'),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      service().requesterOf(workspaceId: 'w2', conversationId: 'c1'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('a stack publish holds pushes to the runs\' own commit identities, '
      'from the server, once each', () async {
    final alice = AgentCommitIdentity.person((
      name: 'Alice',
      email: '7+alice@users.noreply.github.com',
    ));
    AgentRunView withIdentity(AgentCommitIdentity? identity) => AgentRunView(
      grant: AgentRunGrant(
        workspaceId: 'w1',
        conversationId: 'c1',
        actingUserId: 'alice',
        identity: identity,
      ),
      pushedBranches: const {},
    );
    runs = [withIdentity(alice), withIdentity(alice), withIdentity(null)];
    expect(
      await service().commitIdentitiesOf(
        workspaceId: 'w1',
        conversationId: 'c1',
      ),
      [alice],
    );
    runs = [withIdentity(alice)];
    await expectLater(
      service().commitIdentitiesOf(workspaceId: 'w2', conversationId: 'c1'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('a requester without a sign-in is told to sign in', () async {
    runs = [run()];
    forge.failure = const ForgeCredentialUnavailable.needsSignIn(
      'github',
      'Sign in to GitHub.',
    ).asStatusFailure(HttpRequest(url: 'https://api.github.com/x'));

    await expectLater(
      service().open(draft()),
      throwsA(
        isA<NeedsSignInException>().having((e) => e.lane, 'lane', 'github'),
      ),
    );
    expect(await recorded(42), isEmpty);
    // The forge refused outright, so the pending row is dropped too.
    expect(
      await requesters.requestersOf(
        widgets,
        0,
        repoId: _repoId,
        headBranch: 'feature/x',
      ),
      isEmpty,
    );
  });

  group('update', () {
    AgentPullRequestEdit edit({
      int number = 42,
      String? repo,
      String? title,
      String? body,
    }) => AgentPullRequestEdit(
      workspaceId: 'w1',
      conversationId: 'c1',
      repo: repo,
      number: number,
      title: title,
      body: body,
    );

    test('edits the run\'s own pull request as the requester, on their own '
        'token, keeping the marker', () async {
      runs = [run()];
      forge.currentBody =
          'Adds it.\n\n'
          '_Opened by a Control Center agent at the request of @alice-gh._';
      final result = await service().update(
        edit(title: '  Add the widget  ', body: 'Adds it, tested.'),
      );

      expect(result.toWire(), {
        'repo': 'acme/widgets',
        'number': 42,
        'url': 'https://github.com/acme/widgets/pull/42',
      });
      expect(clients.single, (
        repo: 'acme/widgets',
        actor: 'alice',
        viaPerson: true,
      ));
      expect(forge.updates.single, (
        number: 42,
        title: 'Add the widget',
        body:
            'Adds it, tested.\n\n'
            '_Opened by a Control Center agent at the request of @alice-gh._',
      ));
    });

    test('a title alone leaves the body untouched', () async {
      runs = [run()];
      await service().update(edit(title: 'Add the widget'));
      expect(forge.updates.single, (
        number: 42,
        title: 'Add the widget',
        body: null,
      ));
    });

    test('a pull request a person opened says an agent edited it, and a '
        'marker the agent wrote is replaced', () async {
      runs = [run()];
      forge.currentBody = 'Written by hand.';
      await service().update(
        edit(
          body:
              'Rewritten.\n\n_Opened by a Control Center agent at the '
              'request of @mallory._',
        ),
      );
      expect(
        forge.updates.single.body,
        'Rewritten.\n\n'
        '_Edited by a Control Center agent at the request of @alice-gh._',
      );
    });

    test('a new body keeps its mentions', () async {
      runs = [run()];
      await service().update(
        edit(body: 'cc @acme/security and @all, see `@Override`'),
      );
      expect(
        forge.updates.single.body,
        'cc @acme/security and @all, see `@Override`\n\n'
        '_Edited by a Control Center agent at the request of @alice-gh._',
      );
    });

    test('a run nobody requested edits as the bot', () async {
      runs = [run(actingUserId: null)];
      forge.currentBody = '_Opened by a Control Center agent._';
      await service().update(edit(body: 'Adds it.'));
      expect(clients.single, (
        repo: 'acme/widgets',
        actor: null,
        viaPerson: false,
      ));
      expect(
        forge.updates.single.body,
        'Adds it.\n\n_Opened by a Control Center agent._',
      );
    });

    test('the space branch at its checkout\'s commit counts as the run\'s '
        'own', () async {
      runs = [run(pushed: const [])];
      forge
        ..headRef = 'space/s1'
        ..headSha = 'cccccccc22222222222222222222222222222222';
      spaceBranches['w1/s1'] = {widgets.id: 'space/s1'};
      spaceHeads['w1/s1/widgets/space/s1'] =
          'dddddddd33333333333333333333333333333333';
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(isA<ValidationException>()),
      );
      spaceHeads['w1/s1/widgets/space/s1'] = forge.headSha;
      await service().update(edit(title: 'x'));
      expect(forge.updates, hasLength(1));
    });

    test('another pull request, a fork head or a commit the run did not push '
        'is refused before anything is sent', () async {
      runs = [run()];
      forge.headRef = 'someone-else/feature';
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('is not this run\'s pull request'),
          ),
        ),
      );
      forge
        ..headRef = 'feature/x'
        ..headRepoId = '777';
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('a fork'),
          ),
        ),
      );
      forge
        ..headRepoId = _repoId
        ..headSha = 'eeeeeeee44444444444444444444444444444444';
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(isA<ValidationException>()),
      );
      forge
        ..headSha = _pushedSha
        ..missing = true;
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(isA<NotFoundException>()),
      );
      expect(forge.updates, isEmpty);
    });

    test('a merged or closed pull request is refused', () async {
      runs = [run()];
      for (final (state, word) in [
        (PrState.merged, 'is merged'),
        (PrState.closed, 'is closed'),
      ]) {
        forge.state = state;
        await expectLater(
          service().update(edit(title: 'x')),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              allOf(contains(word), contains('only an open pull request')),
            ),
          ),
        );
      }
      expect(forge.updates, isEmpty);
    });

    test('no running run, runs for two people, an unlinked repo, or a '
        'requester who left or cannot read it edits nothing', () async {
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('can edit its pull request'),
          ),
        ),
      );
      runs = [run(), run(actingUserId: 'bob')];
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(isA<ValidationException>()),
      );
      runs = [run()];
      await expectLater(
        service().update(edit(repo: 'acme/other-ws-repo', title: 'x')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('not linked to this workspace'),
          ),
        ),
      );
      readers = {};
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('no access to acme/widgets'),
          ),
        ),
      );
      members = {};
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('no longer a member'),
          ),
        ),
      );
      expect(clients, isEmpty);
      expect(forge.updates, isEmpty);
    });

    test('an edit without a title or body, an empty or long title, a long '
        'body or no number is refused before the forge is asked', () async {
      runs = [run()];
      for (final bad in [
        edit(),
        edit(title: '   '),
        edit(title: 'x' * (AgentPullRequestEdit.maxTitleLength + 1)),
        edit(body: 'x' * (AgentPullRequestEdit.maxBodyLength + 1)),
        edit(number: 0, title: 'x'),
      ]) {
        await expectLater(
          service().update(bad),
          throwsA(isA<ValidationException>()),
          reason: '${bad.title?.length} ${bad.body?.length} ${bad.number}',
        );
      }
      expect(clients, isEmpty);
      // A body that only fits without the marker is refused too.
      await expectLater(
        service().update(edit(body: 'x' * AgentPullRequestEdit.maxBodyLength)),
        throwsA(isA<ValidationException>()),
      );
      expect(forge.updates, isEmpty);
      // The longest title is fine.
      await service().update(
        edit(title: 'x' * AgentPullRequestEdit.maxTitleLength),
      );
      expect(forge.updates, hasLength(1));
    });

    test('a requester without a sign-in is told to sign in', () async {
      runs = [run()];
      forge.failure = const ForgeCredentialUnavailable.needsSignIn(
        'github',
        'Sign in to GitHub.',
      ).asStatusFailure(HttpRequest(url: 'https://api.github.com/x'));
      await expectLater(
        service().update(edit(title: 'x')),
        throwsA(
          isA<NeedsSignInException>()
              .having((e) => e.lane, 'lane', 'github')
              .having(
                (e) => e.message,
                'message',
                contains('before an agent can edit its pull request'),
              ),
        ),
      );
    });

    test('a GitLab merge request is edited the same way, as the requester '
        'on that forge', () async {
      final shopUi = Repo(
        id: 'shop-ui',
        name: 'shop-ui',
        path: '/tmp/shop-ui',
        remoteOwner: 'acme',
        remoteName: 'shop-ui',
        forge: ForgeHost.gitlab,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      linked['w1'] = [widgets, shopUi];
      logins['alice'] = 'alice-gl';
      runs = [
        AgentRunView(
          grant: const AgentRunGrant(
            workspaceId: 'w1',
            conversationId: 'c1',
            actingUserId: 'alice',
            repos: [(forge: ForgeHost.github, owner: 'acme', name: 'shop-ui')],
          ),
          pushedBranches: {
            AgentRunPushedBranch(
              owner: 'acme',
              name: 'shop-ui',
              branch: 'feature/x',
              sha: _pushedSha,
            ),
          },
        ),
      ];
      await service().update(edit(body: 'Adds it.'));
      expect(clients.single, (
        repo: 'acme/shop-ui',
        actor: 'alice',
        viaPerson: true,
      ));
      expect(loginForges, [ForgeHost.gitlab]);
      expect(
        forge.updates.single.body,
        'Adds it.\n\n'
        '_Edited by a Control Center agent at the request of @alice-gl._',
      );
    });
  });
}

class _Forge implements ForgePrClient {
  _Forge(this.pending);

  /// Reads who is recorded for the head branch while the PR is being opened.
  final Future<Set<String>> Function(String head) pending;
  final opened = <(String, String)>[];
  final bodies = <String>[];
  final pendingAtCreate = <Set<String>>[];
  final updates = <({int number, String? title, String? body})>[];
  RhttpException? failure;
  String author = '';
  bool missing = false;
  String headRef = 'feature/x';
  String headSha = _pushedSha;
  String headRepoId = _repoId;
  PrState state = PrState.open;
  String currentBody = '';

  @override
  Future<PullRequest> createPullRequest({
    required String title,
    required String body,
    required String headBranch,
    required String baseBranch,
    bool draft = false,
    ForgeCancelToken? cancelToken,
  }) async {
    pendingAtCreate.add(await pending(headBranch));
    if (failure case final failure?) {
      throw failure;
    }
    opened.add((headBranch, baseBranch));
    bodies.add(body);
    return PullRequest(
      id: 1,
      number: 42,
      title: title,
      body: body,
      state: PrState.open,
      isDraft: draft,
      author: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      repoFullName: 'acme/widgets',
      htmlUrl: 'https://github.com/acme/widgets/pull/42',
      headRef: headBranch,
      baseRepoId: _repoId,
      headRepoId: _repoId,
    );
  }

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
          body: currentBody,
          state: state,
          isDraft: false,
          author: author.isEmpty ? null : PrUser(login: author, avatarUrl: ''),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          repoFullName: 'acme/widgets',
          htmlUrl: 'https://github.com/acme/widgets/pull/$prNumber',
          headRef: headRef,
          headSha: headSha,
          baseRepoId: _repoId,
          headRepoId: headRepoId,
        );

  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
    ForgeCancelToken? cancelToken,
  }) async {
    if (failure case final failure?) {
      throw failure;
    }
    updates.add((number: prNumber, title: title, body: body));
  }

  @override
  ForgeHost get forge => ForgeHost.github;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
