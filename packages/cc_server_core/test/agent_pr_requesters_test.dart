import 'package:cc_domain/cc_domain.dart'
    show NetworkException, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/pr_review/agent_pr_requesters.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

Repo _repo(String id, {String owner = 'acme', String name = 'widgets'}) => Repo(
  id: id,
  name: id,
  path: '/tmp/$id',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

/// The pull request the guard reads before deciding.
class _Forge implements ForgePrClient {
  String author = 'octo-author';
  String authorId = '';
  String head = 'agent/feature';
  String repoId = '4242';
  bool exists = true;
  PrState state = PrState.open;

  @override
  Future<PullRequest?> getPullRequest(
    int prNumber, {
    ForgeCancelToken? cancelToken,
  }) async => !exists
      ? null
      : PullRequest(
          id: prNumber,
          number: prNumber,
          title: 't',
          body: '',
          state: state,
          isDraft: false,
          author: author.isEmpty
              ? null
              : PrUser(login: author, avatarUrl: '', accountId: authorId),
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          repoFullName: 'acme/widgets',
          htmlUrl: 'https://github.com/acme/widgets/pull/$prNumber',
          headRef: head,
          baseRepoId: repoId,
          headRepoId: repoId,
        );

  @override
  ForgeHost get forge => ForgeHost.github;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A cross-workspace read where one workspace could not be read.
class _FailingCross implements CrossWorkspaceQueries {
  @override
  Future<List<T>> fanOut<T>(
    Future<T> Function(WorkspaceDatabase db) read, {
    void Function(String workspaceId, Object error)? onError,
    bool includeDeleted = false,
  }) async {
    onError?.call('ws2', StateError('database is locked'));
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Matcher _refusal(String text) => throwsA(
  isA<ValidationException>().having(
    (e) => e.message,
    'message',
    contains(text),
  ),
);

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late Map<String, String> logins;
  late Map<String, String> accountIds;
  late _Forge forge;
  final inWs1 = _repo('r1');
  // The same forge repository, linked in another workspace under another id.
  final inWs2 = _repo('r2', owner: 'ACME', name: 'Widgets');

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    await seedTestWorkspace(global, dbs, 'ws2');
    logins = {'alice': 'alice-gh', 'bob': 'bob-gh'};
    accountIds = {};
    forge = _Forge();
  });

  AgentPrRequesters store({CrossWorkspaceQueries? cross}) => AgentPrRequesters(
    cacheFor: (ws) => dbs.of(ws).cacheDao,
    crossWorkspace: cross ?? CrossWorkspaceQueries(dbs),
    viewer: (forge, userId, ws) async => logins[userId] == null
        ? null
        : (login: logins[userId]!, id: accountIds[userId] ?? ''),
  );

  Future<void> approve(
    Repo repo,
    int number, {
    String workspaceId = 'ws1',
    String? as,
    AgentPrRequesters? using,
  }) => (using ?? store()).guardFor(
    repo,
    workspaceId: workspaceId,
    actingUserId: as,
  )(forge, number);

  PullRequest pr(
    int number,
    String head, {
    PrState state = PrState.open,
    String repoId = '4242',
  }) => PullRequest(
    id: number,
    number: number,
    title: 't',
    body: '',
    state: state,
    isDraft: false,
    author: null,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    repoFullName: 'acme/widgets',
    htmlUrl: 'https://github.com/acme/widgets/pull/$number',
    headRef: head,
    baseRepoId: repoId,
    headRepoId: repoId,
  );

  Future<Set<String>> requesters(Repo repo, int number, {String? head}) =>
      store().requestersOf(repo, number, repoId: '4242', headBranch: head);

  Future<void> opened(
    String ws,
    Repo repo,
    int number,
    Set<String> requesters,
  ) => store().recordOpened(
    ws,
    repo,
    head: forge.head,
    pr: pr(number, forge.head),
    requesterUserIds: requesters,
  );

  test('the requester cannot approve the agent PR they asked for', () async {
    await opened('ws1', inWs1, 7, {'alice'});
    await expectLater(
      approve(inWs1, 7, as: 'alice'),
      _refusal('another reviewer has to approve it'),
    );
  });

  test('survives a restart (a fresh store over the same database)', () async {
    await opened('ws1', inWs1, 7, {'alice'});
    expect(await requesters(inWs1, 7), {'alice'});
  });

  test('other reviewers and other pull requests pass', () async {
    await opened('ws1', inWs1, 7, {'alice'});
    await approve(inWs1, 7, as: 'bob');
    forge.head = 'someone/else';
    await approve(inWs1, 8, as: 'alice');
  });

  test(
    'the same forge pull request through another workspace is refused '
    '(keyed by the forge repository id, not the workspace repo id)',
    () async {
      await opened('ws1', inWs1, 7, {'alice'});
      expect(await requesters(inWs2, 7), {'alice'});
      await expectLater(
        approve(inWs2, 7, workspaceId: 'ws2', as: 'alice'),
        _refusal('another reviewer has to approve it'),
      );
    },
  );

  test('a deleted workspace\'s record still refuses', () async {
    await opened('ws2', inWs2, 7, {'alice'});
    await global.workspaceRegistryDao.deleteWorkspace('ws2');
    await expectLater(
      approve(inWs1, 7, as: 'alice'),
      _refusal('another reviewer has to approve it'),
    );
  });

  test('a pull request still pending is matched by its head branch', () async {
    await store().recordPending(
      'ws1',
      inWs1,
      head: 'agent/feature',
      requesterUserIds: {'alice'},
    );
    await expectLater(
      approve(inWs1, 9, as: 'alice'),
      _refusal('another reviewer has to approve it'),
    );
    // Once opened, the pending row is gone and the number guards it.
    await opened('ws1', inWs1, 9, {'alice'});
    forge.head = 'renamed';
    await expectLater(
      approve(inWs1, 9, as: 'alice'),
      _refusal('another reviewer has to approve it'),
    );
    expect(
      await dbs
          .of('ws1')
          .cacheDao
          .read(
            'ws1',
            'agent_pr_requester_pending_v1',
            'github|github.com|acme/widgets@agent/feature',
          ),
      isNull,
    );
  });

  test('the pull request\'s own author is refused by forge login', () async {
    forge.author = 'Alice-GH';
    await expectLater(
      approve(inWs1, 3, as: 'alice'),
      _refusal('You opened this pull request'),
    );
    await approve(inWs1, 3, as: 'bob');
  });

  test('fails closed: an unconfirmed caller account or author refuses, '
      'with a message to try again', () async {
    // The caller's forge account could not be resolved (no credential,
    // timeout, 5xx): the author check cannot run, so nothing passes.
    logins.remove('bob');
    await expectLater(
      approve(inWs1, 3, as: 'bob'),
      _refusal("Couldn't confirm your GitHub account. Try again."),
    );
    logins['bob'] = '';
    await expectLater(
      approve(inWs1, 3, as: 'bob'),
      _refusal("Couldn't confirm your GitHub account. Try again."),
    );
    logins['bob'] = 'bob-gh';
    // The pull request came back without an author.
    forge.author = '';
    await expectLater(
      approve(inWs1, 3, as: 'bob'),
      _refusal("Couldn't confirm who opened this pull request on GitHub"),
    );
    // Or could not be read at all, or names no repository id.
    forge
      ..author = 'octo-author'
      ..exists = false;
    await expectLater(
      approve(inWs1, 3, as: 'bob'),
      _refusal("Couldn't confirm this pull request on GitHub"),
    );
    forge
      ..exists = true
      ..repoId = '';
    await expectLater(
      approve(inWs1, 3, as: 'bob'),
      _refusal("Couldn't confirm this pull request on GitHub"),
    );
  });

  test('a renamed or transferred repository keeps its records (keyed by '
      'the forge repository id)', () async {
    await opened('ws1', inWs1, 7, {'alice'});
    final moved = _repo('r1', owner: 'new-org', name: 'gizmos');
    await expectLater(
      approve(moved, 7, as: 'alice'),
      _refusal('another reviewer has to approve it'),
    );
    // A different repository now at the old name is not the same one.
    forge.repoId = '9999';
    await approve(inWs1, 7, as: 'alice');
  });

  test('every recorded owner is refused, and records merge', () async {
    await opened('ws1', inWs1, 7, {'alice', 'bob'});
    await opened('ws1', inWs1, 7, {'carol'});
    logins['carol'] = 'carol-gh';
    logins['dave'] = 'dave-gh';
    expect(await requesters(inWs1, 7), {'alice', 'bob', 'carol'});
    for (final who in ['alice', 'bob', 'carol']) {
      await expectLater(
        approve(inWs1, 7, as: who),
        _refusal('another reviewer has to approve it'),
      );
    }
    await approve(inWs1, 7, as: 'dave');
  });

  test('Bitbucket matches the author by account_id, not by nickname', () async {
    final bb = Repo(
      id: 'bb',
      name: 'bb',
      path: '/tmp/bb',
      forge: ForgeHost.bitbucket,
      remoteOwner: 'acme',
      remoteName: 'widgets',
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );
    // Same account under a nickname that differs from the stored login.
    forge
      ..author = 'alice-renamed'
      ..authorId = '557058:aaaa';
    accountIds['alice'] = '557058:aaaa';
    accountIds['bob'] = '557058:bbbb';
    await expectLater(
      approve(bb, 3, as: 'alice'),
      _refusal('You opened this pull request'),
    );
    // Another account that happens to share the nickname is not the author.
    forge.author = 'bob-gh';
    forge.authorId = '557058:cccc';
    await approve(bb, 3, as: 'bob');
  });

  test('ids decide when both sides carry one; logins only otherwise', () {
    const author = PrUser(login: 'Dev', avatarUrl: '', accountId: '42');
    expect(AgentPrRequesters.isAuthor(author, (login: 'x', id: '42')), isTrue);
    expect(
      AgentPrRequesters.isAuthor(author, (login: 'dev', id: '43')),
      isFalse,
    );
    // GitLab/GitHub sources without an id fall back to the login.
    expect(
      AgentPrRequesters.isAuthor(const PrUser(login: 'Dev', avatarUrl: ''), (
        login: 'dev',
        id: '42',
      )),
      isTrue,
    );
    expect(AgentPrRequesters.isAuthor(author, (login: 'dev', id: '')), isTrue);
    expect(
      AgentPrRequesters.isAuthor(const PrUser(login: '', avatarUrl: ''), (
        login: '',
        id: '',
      )),
      isFalse,
    );
  });

  test('an approval with no person behind it is refused', () async {
    await expectLater(approve(inWs1, 3), _refusal('Only a person can approve'));
    await expectLater(
      approve(inWs1, 3, as: ''),
      _refusal('Only a person can approve'),
    );
  });

  test('a workspace that cannot be read refuses rather than passing', () async {
    await expectLater(
      approve(
        inWs1,
        7,
        as: 'bob',
        using: store(cross: _FailingCross()),
      ),
      _refusal('could not check who asked for this pull request'),
    );
  });

  group('reconcile', () {
    Future<String?> pendingRow(String ws, String head) => dbs
        .of(ws)
        .cacheDao
        .read(
          ws,
          'agent_pr_requester_pending_v1',
          'github|github.com|acme/widgets@$head',
        );

    Future<void> pending(String head, {String ws = 'ws1'}) => store()
        .recordPending(ws, inWs1, head: head, requesterUserIds: {'alice'});

    test(
      'an open PR on the pending head branch promotes it to its number',
      () async {
        await pending('agent/feature');
        await store().reconcile('ws1', inWs1, [
          pr(12, 'agent/feature'),
          pr(13, 'someone/else'),
        ], complete: true);
        expect(await pendingRow('ws1', 'agent/feature'), isNull);
        expect(await requesters(inWs1, 12), {'alice'});
        expect(await requesters(inWs1, 13), isEmpty);
      },
    );

    test('an open PR listed without a repository id keeps the row', () async {
      await pending('agent/feature');
      await store().reconcile('ws1', inWs1, [
        pr(12, 'agent/feature', repoId: ''),
      ], complete: true);
      expect(await pendingRow('ws1', 'agent/feature'), 'alice');
    });

    test('a closed PR on the branch does not promote it', () async {
      await pending('agent/feature');
      await store().reconcile('ws1', inWs1, [
        pr(12, 'agent/feature', state: PrState.closed),
      ], complete: true);
      expect(await pendingRow('ws1', 'agent/feature'), 'alice');
      expect(await requesters(inWs1, 12), isEmpty);
    });

    test('a pending row older than seven days with no open PR is dropped '
        'only from a complete list', () async {
      await pending('agent/stale');
      await pending('agent/young');
      final later = DateTime.now().add(const Duration(days: 8));
      // A partial list (more pages) cannot tell it was never opened.
      await store().reconcile('ws1', inWs1, [], complete: false, now: later);
      expect(await pendingRow('ws1', 'agent/stale'), 'alice');
      // A young row stays even on a complete list.
      await store().reconcile('ws1', inWs1, [], complete: true);
      expect(await pendingRow('ws1', 'agent/young'), 'alice');
      await store().reconcile('ws1', inWs1, [], complete: true, now: later);
      expect(await pendingRow('ws1', 'agent/stale'), isNull);
      expect(await pendingRow('ws1', 'agent/young'), isNull);
    });

    test('only touches the reconciled repository and workspace', () async {
      final other = _repo('r3', name: 'gadgets');
      await store().recordPending(
        'ws1',
        other,
        head: 'agent/feature',
        requesterUserIds: {'alice'},
      );
      await pending('agent/feature', ws: 'ws2');
      final later = DateTime.now().add(const Duration(days: 8));
      await store().reconcile('ws1', inWs1, [], complete: true, now: later);
      expect(await requesters(other, 0, head: 'agent/feature'), {'alice'});
      expect(await pendingRow('ws2', 'agent/feature'), 'alice');
    });

    test(
      'the approval check promotes a pending row an open PR carries',
      () async {
        await pending('agent/feature', ws: 'ws2');
        await expectLater(
          approve(inWs1, 21, as: 'alice'),
          _refusal('another reviewer has to approve it'),
        );
        expect(await pendingRow('ws2', 'agent/feature'), isNull);
        // Now guarded by number even once the branch is renamed.
        forge.head = 'renamed';
        await expectLater(
          approve(inWs1, 21, as: 'alice'),
          _refusal('another reviewer has to approve it'),
        );
      },
    );

    test(
      'the approval check leaves a pending row a closed PR carries',
      () async {
        await pending('agent/feature');
        forge.state = PrState.closed;
        await expectLater(
          approve(inWs1, 21, as: 'alice'),
          _refusal('another reviewer has to approve it'),
        );
        expect(await pendingRow('ws1', 'agent/feature'), 'alice');
      },
    );
  });

  group('open', () {
    Future<int> open({
      Set<String> owners = const {'alice'},
      Object? failure,
      String workspaceId = 'ws1',
      String repoId = '4242',
    }) async => (await store().open(
      workspaceId: workspaceId,
      repo: inWs1,
      head: 'agent/feature',
      approvalOwnerUserIds: owners,
      create: () async {
        // The pending row is written before the forge is asked.
        expect(await requesters(inWs1, 0, head: 'agent/feature'), owners);
        if (failure != null) {
          throw failure;
        }
        return pr(11, 'agent/feature', repoId: repoId);
      },
    )).number;

    test('records pending first, then by number', () async {
      expect(await open(), 11);
      expect(await requesters(inWs1, 11), {'alice'});
      expect(await requesters(inWs1, 0, head: 'agent/feature'), isEmpty);
    });

    test('every owner is recorded', () async {
      expect(await open(owners: {'alice', 'bob'}), 11);
      expect(await requesters(inWs1, 11), {'alice', 'bob'});
    });

    test('a result without a repository id keeps the pending row', () async {
      expect(await open(repoId: ''), 11);
      expect(await requesters(inWs1, 0, head: 'agent/feature'), {'alice'});
    });

    test('nobody to record opens without a record', () async {
      expect(await open(owners: const {}), 11);
      expect(await requesters(inWs1, 11), isEmpty);
    });

    test('a failed pending write aborts the open', () async {
      var asked = false;
      await expectLater(
        AgentPrRequesters(
          cacheFor: (_) => throw StateError('disk full'),
          crossWorkspace: CrossWorkspaceQueries(dbs),
          viewer: (_, _, _) async => null,
        ).open(
          workspaceId: 'ws1',
          repo: inWs1,
          head: 'agent/feature',
          approvalOwnerUserIds: {'alice'},
          create: () async {
            asked = true;
            return pr(1, 'agent/feature');
          },
        ),
        throwsA(isA<StateError>()),
      );
      expect(asked, isFalse);
    });

    test('a definite refusal drops the pending row; an unclear failure '
        'keeps it', () async {
      await expectLater(
        open(failure: const NetworkException('nope', statusCode: 422)),
        throwsA(isA<NetworkException>()),
      );
      expect(await requesters(inWs1, 0, head: 'agent/feature'), isEmpty);
      await expectLater(
        open(failure: const NetworkException('timeout', statusCode: 504)),
        throwsA(isA<NetworkException>()),
      );
      expect(await requesters(inWs1, 0, head: 'agent/feature'), {'alice'});
    });
  });
}
